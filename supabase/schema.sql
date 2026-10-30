-- ====================================================================
-- CRICKET TOURNAMENT MANAGEMENT, LIVE SCORING & PLAYER AUCTION PLATFORM
-- PRODUCTION POSTGRESQL SCHEMA WITH RLS, CONCURRENCY CONTROLS & ATOMIC RPCs
-- ====================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. PROFILES & ROLES
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    avatar_url TEXT,
    phone TEXT,
    role TEXT NOT NULL DEFAULT 'spectator' CHECK (role IN ('super_admin', 'organizer', 'team_owner', 'team_manager', 'scorer', 'player', 'spectator')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. TOURNAMENTS
CREATE TABLE IF NOT EXISTS tournaments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    description TEXT,
    logo_url TEXT,
    banner_url TEXT,
    organizer_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'in_progress', 'completed')),
    format TEXT NOT NULL DEFAULT 'round_robin' CHECK (format IN ('league', 'knockout', 'round_robin', 'groups_and_knockout')),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    location TEXT NOT NULL,
    overs_per_innings INTEGER NOT NULL DEFAULT 20,
    squad_size_max INTEGER NOT NULL DEFAULT 18,
    squad_size_min INTEGER NOT NULL DEFAULT 11,
    playing_xi_size INTEGER NOT NULL DEFAULT 11,
    powerplay_overs INTEGER NOT NULL DEFAULT 6,
    points_win INTEGER NOT NULL DEFAULT 2,
    points_tie INTEGER NOT NULL DEFAULT 1,
    points_no_result INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. TEAMS
CREATE TABLE IF NOT EXISTS teams (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tournament_id UUID NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    short_name VARCHAR(6) NOT NULL,
    logo_url TEXT,
    primary_color VARCHAR(16) DEFAULT '#16a34a',
    secondary_color VARCHAR(16) DEFAULT '#0f172a',
    owner_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    initial_purse BIGINT NOT NULL DEFAULT 10000000, -- e.g. 1 Crore in whole rupees
    remaining_purse BIGINT NOT NULL DEFAULT 10000000,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT purse_non_negative CHECK (remaining_purse >= 0),
    UNIQUE(tournament_id, name),
    UNIQUE(tournament_id, short_name)
);

-- 4. PLAYERS
CREATE TABLE IF NOT EXISTS players (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    full_name TEXT NOT NULL,
    display_name TEXT,
    photo_url TEXT,
    role TEXT NOT NULL CHECK (role IN ('batter', 'bowler', 'all_rounder', 'wicket_keeper')),
    batting_style TEXT NOT NULL CHECK (batting_style IN ('right_hand_bat', 'left_hand_bat')),
    bowling_style TEXT NOT NULL CHECK (bowling_style IN ('right_arm_fast', 'left_arm_fast', 'right_arm_medium', 'left_arm_medium', 'right_arm_spin', 'left_arm_spin', 'none')),
    city TEXT,
    dob DATE,
    matches INTEGER NOT NULL DEFAULT 0,
    runs INTEGER NOT NULL DEFAULT 0,
    highest_score INTEGER NOT NULL DEFAULT 0,
    batting_average NUMERIC(6,2) NOT NULL DEFAULT 0.00,
    strike_rate NUMERIC(6,2) NOT NULL DEFAULT 0.00,
    wickets INTEGER NOT NULL DEFAULT 0,
    best_bowling TEXT DEFAULT '0/0',
    economy NUMERIC(5,2) NOT NULL DEFAULT 0.00,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5. TOURNAMENT PLAYERS (Squad assignments & auction registry)
CREATE TABLE IF NOT EXISTS tournament_players (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tournament_id UUID NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
    player_id UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
    team_id UUID REFERENCES teams(id) ON DELETE SET NULL,
    status TEXT NOT NULL DEFAULT 'registered' CHECK (status IN ('registered', 'in_auction', 'sold', 'unsold', 'assigned')),
    base_price BIGINT NOT NULL DEFAULT 50000,
    final_price BIGINT,
    lot_number INTEGER,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(tournament_id, player_id)
);

-- 6. AUCTIONS
CREATE TABLE IF NOT EXISTS auctions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tournament_id UUID NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'scheduled', 'live', 'paused', 'completed', 'cancelled')),
    min_bid_increment BIGINT NOT NULL DEFAULT 10000,
    countdown_seconds INTEGER NOT NULL DEFAULT 20,
    current_pool_id UUID,
    timer_started_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 7. AUCTION PLAYER POOL
CREATE TABLE IF NOT EXISTS auction_player_pool (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    auction_id UUID NOT NULL REFERENCES auctions(id) ON DELETE CASCADE,
    tournament_player_id UUID NOT NULL REFERENCES tournament_players(id) ON DELETE CASCADE,
    player_id UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
    category TEXT NOT NULL CHECK (category IN ('marquee', 'batter', 'bowler', 'all_rounder', 'wicket_keeper', 'emerging')),
    base_price BIGINT NOT NULL,
    lot_number INTEGER NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'sold', 'unsold', 'passed')),
    current_bid BIGINT,
    highest_bidder_team_id UUID REFERENCES teams(id) ON DELETE SET NULL,
    winning_team_id UUID REFERENCES teams(id) ON DELETE SET NULL,
    sold_price BIGINT,
    sold_at TIMESTAMPTZ,
    version INTEGER NOT NULL DEFAULT 0, -- optimistic lock / lot version
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 8. AUCTION BIDS (Audit Trail)
CREATE TABLE IF NOT EXISTS auction_bids (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    auction_id UUID NOT NULL REFERENCES auctions(id) ON DELETE CASCADE,
    pool_id UUID NOT NULL REFERENCES auction_player_pool(id) ON DELETE CASCADE,
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    amount BIGINT NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 9. AUCTION PURCHASES (Atomic Finalization Records)
CREATE TABLE IF NOT EXISTS auction_purchases (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    auction_id UUID NOT NULL REFERENCES auctions(id) ON DELETE CASCADE,
    pool_id UUID NOT NULL REFERENCES auction_player_pool(id) ON DELETE CASCADE,
    player_id UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    amount BIGINT NOT NULL,
    purchased_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(auction_id, pool_id)
);

-- 10. AUCTION PURSE LEDGER (Audit Log for Financial Integrity)
CREATE TABLE IF NOT EXISTS auction_purse_ledger (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    auction_id UUID NOT NULL REFERENCES auctions(id) ON DELETE CASCADE,
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    delta_amount BIGINT NOT NULL, -- Negative for purchase, positive for refund/reversal
    balance_after BIGINT NOT NULL,
    reason TEXT NOT NULL,
    related_pool_id UUID REFERENCES auction_player_pool(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 11. MATCHES
CREATE TABLE IF NOT EXISTS matches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tournament_id UUID NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
    match_number INTEGER NOT NULL,
    stage TEXT NOT NULL DEFAULT 'group',
    group_name TEXT,
    team_a_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    team_b_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    venue TEXT NOT NULL,
    date_time TIMESTAMPTZ NOT NULL,
    overs INTEGER NOT NULL DEFAULT 20,
    status TEXT NOT NULL DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'toss', 'live', 'innings_break', 'completed', 'abandoned', 'tied')),
    toss_won_by UUID REFERENCES teams(id) ON DELETE SET NULL,
    toss_decision TEXT CHECK (toss_decision IN ('bat', 'bowl')),
    batting_first_id UUID REFERENCES teams(id) ON DELETE SET NULL,
    winner_id UUID REFERENCES teams(id) ON DELETE SET NULL,
    win_margin INTEGER,
    win_type TEXT CHECK (win_type IN ('runs', 'wickets', 'super_over', 'tie', 'no_result')),
    player_of_match_id UUID REFERENCES players(id) ON DELETE SET NULL,
    scorer_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(tournament_id, match_number)
);

-- 12. MATCH SQUADS (Playing XI & Bench)
CREATE TABLE IF NOT EXISTS match_squads (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    match_id UUID NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    player_id UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
    is_playing_xi BOOLEAN NOT NULL DEFAULT true,
    is_captain BOOLEAN NOT NULL DEFAULT false,
    is_wicket_keeper BOOLEAN NOT NULL DEFAULT false,
    UNIQUE(match_id, player_id)
);

-- 13. INNINGS
CREATE TABLE IF NOT EXISTS innings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    match_id UUID NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
    innings_number INTEGER NOT NULL CHECK (innings_number IN (1, 2, 3, 4)), -- 3/4 for super overs
    batting_team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    bowling_team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    total_runs INTEGER NOT NULL DEFAULT 0,
    wickets INTEGER NOT NULL DEFAULT 0,
    legal_balls INTEGER NOT NULL DEFAULT 0,
    overs_str VARCHAR(8) NOT NULL DEFAULT '0.0',
    extras_wides INTEGER NOT NULL DEFAULT 0,
    extras_no_balls INTEGER NOT NULL DEFAULT 0,
    extras_byes INTEGER NOT NULL DEFAULT 0,
    extras_leg_byes INTEGER NOT NULL DEFAULT 0,
    extras_penalty INTEGER NOT NULL DEFAULT 0,
    total_extras INTEGER NOT NULL DEFAULT 0,
    is_completed BOOLEAN NOT NULL DEFAULT false,
    current_striker_id UUID REFERENCES players(id) ON DELETE SET NULL,
    current_non_striker_id UUID REFERENCES players(id) ON DELETE SET NULL,
    current_bowler_id UUID REFERENCES players(id) ON DELETE SET NULL,
    target_runs INTEGER,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(match_id, innings_number)
);

-- 14. DELIVERIES (Immutable Delivery Ledger)
CREATE TABLE IF NOT EXISTS deliveries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    innings_id UUID NOT NULL REFERENCES innings(id) ON DELETE CASCADE,
    match_id UUID NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
    over_number INTEGER NOT NULL, -- 0-based or 1-based (standard 0-indexed: 0 to 19)
    ball_in_over INTEGER NOT NULL, -- 1 to 6 (legal)
    delivery_sequence INTEGER NOT NULL, -- strictly ascending monotonic sequence
    striker_id UUID NOT NULL REFERENCES players(id),
    non_striker_id UUID NOT NULL REFERENCES players(id),
    bowler_id UUID NOT NULL REFERENCES players(id),
    runs_batter INTEGER NOT NULL DEFAULT 0 CHECK (runs_batter BETWEEN 0 AND 6),
    extras_type TEXT CHECK (extras_type IN ('wide', 'no_ball', 'bye', 'leg_bye', 'penalty')),
    extras_runs INTEGER NOT NULL DEFAULT 0,
    is_legal BOOLEAN NOT NULL DEFAULT true,
    is_wicket BOOLEAN NOT NULL DEFAULT false,
    dismissal_type TEXT CHECK (dismissal_type IN ('bowled', 'caught', 'caught_bowled', 'lbw', 'run_out', 'stumped', 'hit_wicket', 'retired_out', 'obstructing_field', 'timed_out', 'retired_hurt')),
    dismissed_player_id UUID REFERENCES players(id) ON DELETE SET NULL,
    assisted_by_player_id UUID REFERENCES players(id) ON DELETE SET NULL,
    commentary_text TEXT,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_undone BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 15. BATTING SCORECARD
CREATE TABLE IF NOT EXISTS batting_scorecards (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    innings_id UUID NOT NULL REFERENCES innings(id) ON DELETE CASCADE,
    match_id UUID NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
    player_id UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    batting_position INTEGER,
    runs INTEGER NOT NULL DEFAULT 0,
    balls INTEGER NOT NULL DEFAULT 0,
    fours INTEGER NOT NULL DEFAULT 0,
    sixes INTEGER NOT NULL DEFAULT 0,
    strike_rate NUMERIC(6,2) NOT NULL DEFAULT 0.00,
    dismissal_text TEXT DEFAULT 'not out',
    is_out BOOLEAN NOT NULL DEFAULT false,
    UNIQUE(innings_id, player_id)
);

-- 16. BOWLING SCORECARD
CREATE TABLE IF NOT EXISTS bowling_scorecards (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    innings_id UUID NOT NULL REFERENCES innings(id) ON DELETE CASCADE,
    match_id UUID NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
    player_id UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    overs_str VARCHAR(8) NOT NULL DEFAULT '0.0',
    legal_balls INTEGER NOT NULL DEFAULT 0,
    maidens INTEGER NOT NULL DEFAULT 0,
    runs_conceded INTEGER NOT NULL DEFAULT 0,
    wickets INTEGER NOT NULL DEFAULT 0,
    dots INTEGER NOT NULL DEFAULT 0,
    wides INTEGER NOT NULL DEFAULT 0,
    no_balls INTEGER NOT NULL DEFAULT 0,
    economy NUMERIC(5,2) NOT NULL DEFAULT 0.00,
    UNIQUE(innings_id, player_id)
);

-- 17. TOURNAMENT STANDINGS (Points Table & Net Run Rate)
CREATE TABLE IF NOT EXISTS tournament_standings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tournament_id UUID NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    group_name TEXT DEFAULT 'All',
    matches_played INTEGER NOT NULL DEFAULT 0,
    won INTEGER NOT NULL DEFAULT 0,
    lost INTEGER NOT NULL DEFAULT 0,
    tied INTEGER NOT NULL DEFAULT 0,
    no_result INTEGER NOT NULL DEFAULT 0,
    points INTEGER NOT NULL DEFAULT 0,
    runs_scored INTEGER NOT NULL DEFAULT 0,
    balls_faced INTEGER NOT NULL DEFAULT 0,
    runs_conceded INTEGER NOT NULL DEFAULT 0,
    balls_bowled INTEGER NOT NULL DEFAULT 0,
    net_run_rate NUMERIC(6,3) NOT NULL DEFAULT 0.000,
    rank INTEGER NOT NULL DEFAULT 1,
    UNIQUE(tournament_id, team_id)
);

-- INDEXES FOR FAST REAL-TIME ACCESS
CREATE INDEX IF NOT EXISTS idx_auctions_tourn ON auctions(tournament_id);
CREATE INDEX IF NOT EXISTS idx_pool_auction ON auction_player_pool(auction_id, status);
CREATE INDEX IF NOT EXISTS idx_bids_pool ON auction_bids(pool_id, amount DESC);
CREATE INDEX IF NOT EXISTS idx_matches_tourn ON matches(tournament_id, date_time);
CREATE INDEX IF NOT EXISTS idx_innings_match ON innings(match_id);
CREATE INDEX IF NOT EXISTS idx_deliveries_innings ON deliveries(innings_id, delivery_sequence);
CREATE INDEX IF NOT EXISTS idx_standings_tourn ON tournament_standings(tournament_id, points DESC, net_run_rate DESC);
