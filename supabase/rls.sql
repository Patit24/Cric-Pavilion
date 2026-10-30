-- ====================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ====================================================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE tournaments ENABLE ROW LEVEL SECURITY;
ALTER TABLE teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE players ENABLE ROW LEVEL SECURITY;
ALTER TABLE tournament_players ENABLE ROW LEVEL SECURITY;
ALTER TABLE auctions ENABLE ROW LEVEL SECURITY;
ALTER TABLE auction_player_pool ENABLE ROW LEVEL SECURITY;
ALTER TABLE auction_bids ENABLE ROW LEVEL SECURITY;
ALTER TABLE auction_purchases ENABLE ROW LEVEL SECURITY;
ALTER TABLE auction_purse_ledger ENABLE ROW LEVEL SECURITY;
ALTER TABLE matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE match_squads ENABLE ROW LEVEL SECURITY;
ALTER TABLE innings ENABLE ROW LEVEL SECURITY;
ALTER TABLE deliveries ENABLE ROW LEVEL SECURITY;
ALTER TABLE batting_scorecards ENABLE ROW LEVEL SECURITY;
ALTER TABLE bowling_scorecards ENABLE ROW LEVEL SECURITY;
ALTER TABLE tournament_standings ENABLE ROW LEVEL SECURITY;

-- Helper function to check role
CREATE OR REPLACE FUNCTION current_user_role()
RETURNS TEXT AS $$
    SELECT role FROM profiles WHERE id = auth.uid();
$$ LANGUAGE sql STABLE SECURITY DEFINER;

-- 1. PROFILES
CREATE POLICY "Public profiles are viewable by everyone" ON profiles FOR SELECT USING (true);
CREATE POLICY "Users can update their own profile" ON profiles FOR UPDATE USING (auth.uid() = id);

-- 2. TOURNAMENTS
CREATE POLICY "Tournaments viewable by everyone" ON tournaments FOR SELECT USING (true);
CREATE POLICY "Organizers and superadmins can insert tournaments" ON tournaments FOR INSERT WITH CHECK (
    auth.uid() = organizer_id OR current_user_role() IN ('organizer', 'super_admin')
);
CREATE POLICY "Organizers can update their tournaments" ON tournaments FOR UPDATE USING (
    auth.uid() = organizer_id OR current_user_role() = 'super_admin'
);

-- 3. TEAMS & PLAYERS
CREATE POLICY "Teams viewable by everyone" ON teams FOR SELECT USING (true);
CREATE POLICY "Tournament organizers manage teams" ON teams FOR ALL USING (
    EXISTS (SELECT 1 FROM tournaments WHERE tournaments.id = teams.tournament_id AND (tournaments.organizer_id = auth.uid() OR current_user_role() = 'super_admin'))
);

CREATE POLICY "Players viewable by everyone" ON players FOR SELECT USING (true);
CREATE POLICY "Players managed by organizer or player themselves" ON players FOR ALL USING (
    auth.uid() = user_id OR current_user_role() IN ('organizer', 'super_admin')
);

-- 4. AUCTIONS & POOL
CREATE POLICY "Auctions viewable by everyone" ON auctions FOR SELECT USING (true);
CREATE POLICY "Organizers manage auctions" ON auctions FOR ALL USING (
    EXISTS (SELECT 1 FROM tournaments WHERE tournaments.id = auctions.tournament_id AND (tournaments.organizer_id = auth.uid() OR current_user_role() = 'super_admin'))
);

CREATE POLICY "Auction pool viewable by everyone" ON auction_player_pool FOR SELECT USING (true);
CREATE POLICY "Auction pool managed by organizers" ON auction_player_pool FOR ALL USING (
    EXISTS (
        SELECT 1 FROM auctions JOIN tournaments ON tournaments.id = auctions.tournament_id 
        WHERE auctions.id = auction_player_pool.auction_id AND (tournaments.organizer_id = auth.uid() OR current_user_role() = 'super_admin')
    )
);

-- 5. BIDS: ONLY AUTHORIZED TEAM OWNERS CAN BID FOR THEIR ASSIGNED TEAM!
CREATE POLICY "Bids viewable by everyone" ON auction_bids FOR SELECT USING (true);
CREATE POLICY "Only authorized team owners can place bids for their own team" ON auction_bids FOR INSERT WITH CHECK (
    auth.uid() = user_id AND (
        EXISTS (
            SELECT 1 FROM teams 
            WHERE teams.id = auction_bids.team_id 
              AND teams.owner_id = auth.uid()
        )
        OR current_user_role() = 'super_admin'
    )
);

-- 6. MATCHES & SCORING: ONLY ASSIGNED SCORER OR ORGANIZER
CREATE POLICY "Matches viewable by everyone" ON matches FOR SELECT USING (true);
CREATE POLICY "Organizers and Scorers manage matches" ON matches FOR UPDATE USING (
    auth.uid() = scorer_id OR 
    EXISTS (SELECT 1 FROM tournaments WHERE tournaments.id = matches.tournament_id AND tournaments.organizer_id = auth.uid()) OR
    current_user_role() = 'super_admin'
);

CREATE POLICY "Deliveries viewable by everyone" ON deliveries FOR SELECT USING (true);
CREATE POLICY "Only assigned scorer or organizer can insert deliveries" ON deliveries FOR INSERT WITH CHECK (
    EXISTS (
        SELECT 1 FROM matches 
        WHERE matches.id = deliveries.match_id 
          AND (matches.scorer_id = auth.uid() OR current_user_role() IN ('organizer', 'super_admin'))
    )
);

CREATE POLICY "Scorecards viewable by everyone" ON batting_scorecards FOR SELECT USING (true);
CREATE POLICY "Scorecards viewable by everyone bowling" ON bowling_scorecards FOR SELECT USING (true);
CREATE POLICY "Standings viewable by everyone" ON tournament_standings FOR SELECT USING (true);
