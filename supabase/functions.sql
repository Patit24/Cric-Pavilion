-- ====================================================================
-- ATOMIC STORED PROCEDURES & CONCURRENCY CONTROLS
-- ====================================================================

-- 1. ATOMIC BID PLACEMENT
CREATE OR REPLACE FUNCTION place_bid_atomic(
    p_auction_id UUID,
    p_pool_id UUID,
    p_team_id UUID,
    p_user_id UUID,
    p_amount BIGINT
) RETURNS JSONB AS $$
DECLARE
    v_auction RECORD;
    v_pool RECORD;
    v_team RECORD;
    v_min_increment BIGINT;
    v_required_bid BIGINT;
BEGIN
    -- Check auction status
    SELECT * INTO v_auction FROM auctions WHERE id = p_auction_id FOR UPDATE;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Auction not found');
    END IF;
    IF v_auction.status != 'live' THEN
        RETURN jsonb_build_object('success', false, 'error', 'Auction is not live');
    END IF;

    -- Lock and inspect pool record
    SELECT * INTO v_pool FROM auction_player_pool WHERE id = p_pool_id AND auction_id = p_auction_id FOR UPDATE;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Player pool record not found');
    END IF;
    IF v_pool.status != 'active' THEN
        RETURN jsonb_build_object('success', false, 'error', 'Player is not active for bidding');
    END IF;

    -- Lock and verify team
    SELECT * INTO v_team FROM teams WHERE id = p_team_id AND tournament_id = v_auction.tournament_id FOR UPDATE;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Team not found in this tournament');
    END IF;

    -- Validate purse
    IF v_team.remaining_purse < p_amount THEN
        RETURN jsonb_build_object('success', false, 'error', 'Insufficient purse. Remaining: ₹' || v_team.remaining_purse);
    END IF;

    -- Check min increment
    v_min_increment := COALESCE(v_auction.min_bid_increment, 10000);
    IF v_pool.current_bid IS NULL THEN
        v_required_bid := v_pool.base_price;
    ELSE
        v_required_bid := v_pool.current_bid + v_min_increment;
    END IF;

    IF p_amount < v_required_bid THEN
        RETURN jsonb_build_object('success', false, 'error', 'Bid must be at least ₹' || v_required_bid);
    END IF;

    -- Prevent self-outbidding if already highest bidder
    IF v_pool.highest_bidder_team_id = p_team_id THEN
        RETURN jsonb_build_object('success', false, 'error', 'Your team already holds the highest bid');
    END IF;

    -- Record Bid
    INSERT INTO auction_bids (auction_id, pool_id, team_id, user_id, amount, timestamp)
    VALUES (p_auction_id, p_pool_id, p_team_id, p_user_id, p_amount, NOW());

    -- Update Player Pool
    UPDATE auction_player_pool
    SET current_bid = p_amount,
        highest_bidder_team_id = p_team_id,
        version = version + 1,
        updated_at = NOW()
    WHERE id = p_pool_id;

    -- Reset auction countdown timer
    UPDATE auctions
    SET timer_started_at = NOW(),
        updated_at = NOW()
    WHERE id = p_auction_id;

    RETURN jsonb_build_object(
        'success', true,
        'current_bid', p_amount,
        'team_id', p_team_id,
        'team_name', v_team.name,
        'timestamp', NOW()
    );
END;
$$ LANGUAGE plpgsql;


-- 2. ATOMIC PLAYER SALE & SQUAD ASSIGNMENT
CREATE OR REPLACE FUNCTION confirm_sold_atomic(
    p_auction_id UUID,
    p_pool_id UUID
) RETURNS JSONB AS $$
DECLARE
    v_auction RECORD;
    v_pool RECORD;
    v_team RECORD;
    v_sale_price BIGINT;
    v_winning_team_id UUID;
BEGIN
    SELECT * INTO v_auction FROM auctions WHERE id = p_auction_id FOR UPDATE;
    IF NOT FOUND OR v_auction.status != 'live' THEN
        RETURN jsonb_build_object('success', false, 'error', 'Auction is not live');
    END IF;

    SELECT * INTO v_pool FROM auction_player_pool WHERE id = p_pool_id AND auction_id = p_auction_id FOR UPDATE;
    IF NOT FOUND OR v_pool.status != 'active' THEN
        RETURN jsonb_build_object('success', false, 'error', 'Player lot is not active');
    END IF;

    IF v_pool.highest_bidder_team_id IS NULL OR v_pool.current_bid IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'No valid bid placed on this player');
    END IF;

    v_winning_team_id := v_pool.highest_bidder_team_id;
    v_sale_price := v_pool.current_bid;

    SELECT * INTO v_team FROM teams WHERE id = v_winning_team_id FOR UPDATE;
    IF v_team.remaining_purse < v_sale_price THEN
        RETURN jsonb_build_object('success', false, 'error', 'Team has insufficient funds to finalize purchase');
    END IF;

    -- 1. Deduct purse exactly once
    UPDATE teams
    SET remaining_purse = remaining_purse - v_sale_price,
        updated_at = NOW()
    WHERE id = v_winning_team_id;

    -- 2. Insert into purchase table
    INSERT INTO auction_purchases (auction_id, pool_id, player_id, team_id, amount, purchased_at)
    VALUES (p_auction_id, p_pool_id, v_pool.player_id, v_winning_team_id, v_sale_price, NOW());

    -- 3. Insert into financial purse ledger
    INSERT INTO auction_purse_ledger (auction_id, team_id, delta_amount, balance_after, reason, related_pool_id)
    VALUES (p_auction_id, v_winning_team_id, -v_sale_price, (v_team.remaining_purse - v_sale_price), 'player_sold_in_auction', p_pool_id);

    -- 4. Automatically assign player to winning team squad
    UPDATE tournament_players
    SET team_id = v_winning_team_id,
        status = 'sold',
        final_price = v_sale_price
    WHERE id = v_pool.tournament_player_id;

    -- 5. Mark lot as sold
    UPDATE auction_player_pool
    SET status = 'sold',
        winning_team_id = v_winning_team_id,
        sold_price = v_sale_price,
        sold_at = NOW(),
        updated_at = NOW()
    WHERE id = p_pool_id;

    -- 6. Reset current active lot on auction
    UPDATE auctions
    SET current_pool_id = NULL,
        timer_started_at = NULL,
        updated_at = NOW()
    WHERE id = p_auction_id;

    RETURN jsonb_build_object(
        'success', true,
        'sold_to_team_id', v_winning_team_id,
        'sold_to_team_name', v_team.name,
        'sold_price', v_sale_price,
        'remaining_purse', (v_team.remaining_purse - v_sale_price)
    );
END;
$$ LANGUAGE plpgsql;


-- 3. RECALCULATE TOURNAMENT STANDINGS & NET RUN RATE (NRR)
CREATE OR REPLACE FUNCTION recalculate_standings_atomic(p_tournament_id UUID)
RETURNS VOID AS $$
DECLARE
    v_team RECORD;
    v_match RECORD;
    v_tourn RECORD;
    v_pts_win INTEGER;
    v_pts_tie INTEGER;
    v_pts_nr INTEGER;
    
    v_played INTEGER;
    v_won INTEGER;
    v_lost INTEGER;
    v_tied INTEGER;
    v_no_result INTEGER;
    v_points INTEGER;
    
    v_runs_for INTEGER;
    v_balls_for INTEGER;
    v_runs_against INTEGER;
    v_balls_against INTEGER;
    
    v_inn1 RECORD;
    v_inn2 RECORD;
    v_max_balls INTEGER;
    v_nrr NUMERIC(6,3);
BEGIN
    SELECT * INTO v_tourn FROM tournaments WHERE id = p_tournament_id;
    IF NOT FOUND THEN RETURN; END IF;

    v_pts_win := COALESCE(v_tourn.points_win, 2);
    v_pts_tie := COALESCE(v_tourn.points_tie, 1);
    v_pts_nr  := COALESCE(v_tourn.points_no_result, 1);
    v_max_balls := COALESCE(v_tourn.overs_per_innings, 20) * 6;

    FOR v_team IN SELECT * FROM teams WHERE tournament_id = p_tournament_id LOOP
        v_played := 0; v_won := 0; v_lost := 0; v_tied := 0; v_no_result := 0; v_points := 0;
        v_runs_for := 0; v_balls_for := 0; v_runs_against := 0; v_balls_against := 0;

        FOR v_match IN SELECT * FROM matches 
                       WHERE tournament_id = p_tournament_id 
                         AND (team_a_id = v_team.id OR team_b_id = v_team.id)
                         AND status IN ('completed', 'tied', 'abandoned') LOOP
            
            v_played := v_played + 1;

            IF v_match.status = 'abandoned' THEN
                v_no_result := v_no_result + 1;
                v_points := v_points + v_pts_nr;
            ELSIF v_match.status = 'tied' OR v_match.win_type = 'tie' THEN
                v_tied := v_tied + 1;
                v_points := v_points + v_pts_tie;
            ELSIF v_match.winner_id = v_team.id THEN
                v_won := v_won + 1;
                v_points := v_points + v_pts_win;
            ELSE
                v_lost := v_lost + 1;
            END IF;

            -- Calculate runs & balls for NRR from completed innings
            IF v_match.status = 'completed' OR v_match.status = 'tied' THEN
                SELECT * INTO v_inn1 FROM innings WHERE match_id = v_match.id AND innings_number = 1;
                SELECT * INTO v_inn2 FROM innings WHERE match_id = v_match.id AND innings_number = 2;

                -- If this team batted in Innings 1
                IF v_inn1.batting_team_id = v_team.id THEN
                    v_runs_for := v_runs_for + v_inn1.total_runs;
                    -- All-out rule: if team is all out (10 wickets in standard 11-a-side), full quota of overs is charged!
                    IF v_inn1.wickets >= 10 THEN
                        v_balls_for := v_balls_for + v_max_balls;
                    ELSE
                        v_balls_for := v_balls_for + v_inn1.legal_balls;
                    END IF;

                    -- Innings 2 bowling
                    IF v_inn2.id IS NOT NULL THEN
                        v_runs_against := v_runs_against + v_inn2.total_runs;
                        IF v_inn2.wickets >= 10 THEN
                            v_balls_against := v_balls_against + v_max_balls;
                        ELSE
                            v_balls_against := v_balls_against + v_inn2.legal_balls;
                        END IF;
                    END IF;
                ELSE
                    -- This team batted in Innings 2
                    IF v_inn2.id IS NOT NULL THEN
                        v_runs_for := v_runs_for + v_inn2.total_runs;
                        IF v_inn2.wickets >= 10 THEN
                            v_balls_for := v_balls_for + v_max_balls;
                        ELSE
                            v_balls_for := v_balls_for + v_inn2.legal_balls;
                        END IF;
                    END IF;

                    -- Innings 1 bowling
                    v_runs_against := v_runs_against + v_inn1.total_runs;
                    IF v_inn1.wickets >= 10 THEN
                        v_balls_against := v_balls_against + v_max_balls;
                    ELSE
                        v_balls_against := v_balls_against + v_inn1.legal_balls;
                    END IF;
                END IF;
            END IF;
        END LOOP;

        -- NRR calculation: (Runs For / (Balls For / 6)) - (Runs Against / (Balls Against / 6))
        IF v_balls_for > 0 AND v_balls_against > 0 THEN
            v_nrr := ROUND(
                ((v_runs_for::NUMERIC / (v_balls_for::NUMERIC / 6.0)) - 
                 (v_runs_against::NUMERIC / (v_balls_against::NUMERIC / 6.0))), 3
            );
        ELSE
            v_nrr := 0.000;
        END IF;

        -- Upsert standings record
        INSERT INTO tournament_standings (
            tournament_id, team_id, matches_played, won, lost, tied, no_result,
            points, runs_scored, balls_faced, runs_conceded, balls_bowled, net_run_rate
        ) VALUES (
            p_tournament_id, v_team.id, v_played, v_won, v_lost, v_tied, v_no_result,
            v_points, v_runs_for, v_balls_for, v_runs_against, v_balls_against, v_nrr
        ) ON CONFLICT (tournament_id, team_id) DO UPDATE SET
            matches_played = EXCLUDED.matches_played,
            won = EXCLUDED.won,
            lost = EXCLUDED.lost,
            tied = EXCLUDED.tied,
            no_result = EXCLUDED.no_result,
            points = EXCLUDED.points,
            runs_scored = EXCLUDED.runs_scored,
            balls_faced = EXCLUDED.balls_faced,
            runs_conceded = EXCLUDED.runs_conceded,
            balls_bowled = EXCLUDED.balls_bowled,
            net_run_rate = EXCLUDED.net_run_rate;
    END LOOP;
END;
$$ LANGUAGE plpgsql;
