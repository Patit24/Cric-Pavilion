// ====================================================================
// CRICKET TOURNAMENT PLATFORM TYPES & DOMAIN INTERFACES
// ====================================================================

export type UserRole =
  | 'super_admin'
  | 'organizer'
  | 'team_owner'
  | 'team_manager'
  | 'scorer'
  | 'player'
  | 'spectator';

export interface UserProfile {
  id: string;
  email: string;
  fullName: string;
  avatarUrl?: string;
  phone?: string;
  role: UserRole;
  createdAt: string;
}

export type TournamentFormat = 'league' | 'knockout' | 'round_robin' | 'groups_and_knockout';
export type TournamentStatus = 'draft' | 'published' | 'in_progress' | 'completed';

export interface Tournament {
  id: string;
  name: string;
  slug: string;
  description: string;
  logoUrl?: string;
  bannerUrl?: string;
  organizerId: string;
  status: TournamentStatus;
  format: TournamentFormat;
  startDate: string;
  endDate: string;
  location: string;
  oversPerInnings: number;
  squadSizeMax: number;
  squadSizeMin: number;
  playingXISize: number;
  powerplayOvers: number;
  pointsWin: number;
  pointsTie: number;
  pointsNoResult: number;
  hasAuction: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface Team {
  id: string;
  tournamentId: string;
  name: string;
  shortName: string;
  logoUrl: string;
  primaryColor: string;
  secondaryColor: string;
  ownerId?: string;
  ownerName?: string;
  managerId?: string;
  captainId?: string;
  initialPurse: number; // in whole Indian Rupees (e.g. 10000000)
  remainingPurse: number;
  squadCount?: number;
  createdAt: string;
}

export type PlayerRole = 'batter' | 'bowler' | 'all_rounder' | 'wicket_keeper';
export type BattingStyle = 'right_hand_bat' | 'left_hand_bat';
export type BowlingStyle =
  | 'right_arm_fast'
  | 'left_arm_fast'
  | 'right_arm_medium'
  | 'left_arm_medium'
  | 'right_arm_spin'
  | 'left_arm_spin'
  | 'none';

export interface Player {
  id: string;
  userId?: string;
  fullName: string;
  displayName: string;
  photoUrl: string;
  role: PlayerRole;
  battingStyle: BattingStyle;
  bowlingStyle: BowlingStyle;
  city?: string;
  dob?: string;
  // Career stats
  matches: number;
  runs: number;
  highestScore: number;
  battingAverage: number;
  strikeRate: number;
  wickets: number;
  bestBowling: string;
  economy: number;
}

export type TournamentPlayerStatus = 'registered' | 'in_auction' | 'sold' | 'unsold' | 'assigned';

export interface TournamentPlayer {
  id: string;
  tournamentId: string;
  playerId: string;
  teamId?: string | null;
  status: TournamentPlayerStatus;
  basePrice: number;
  finalPrice?: number | null;
  lotNumber?: number;
  player?: Player;
  team?: Team;
}

// ----------------------------------------------------
// AUCTION ENGINE
// ----------------------------------------------------

export type AuctionStatus = 'draft' | 'scheduled' | 'live' | 'paused' | 'completed' | 'cancelled';
export type PoolPlayerCategory = 'marquee' | 'batter' | 'bowler' | 'all_rounder' | 'wicket_keeper' | 'emerging';
export type PoolLotStatus = 'pending' | 'active' | 'sold' | 'unsold' | 'passed';

export interface Auction {
  id: string;
  tournamentId: string;
  title: string;
  status: AuctionStatus;
  minBidIncrement: number;
  countdownSeconds: number;
  currentPoolId?: string | null;
  timerStartedAt?: string | null;
  createdAt: string;
}

export interface AuctionPlayerPoolItem {
  id: string;
  auctionId: string;
  tournamentPlayerId: string;
  playerId: string;
  category: PoolPlayerCategory;
  basePrice: number;
  lotNumber: number;
  status: PoolLotStatus;
  currentBid: number | null;
  highestBidderTeamId: string | null;
  winningTeamId: string | null;
  soldPrice: number | null;
  soldAt?: string | null;
  version: number;
  player?: Player;
  highestBidderTeam?: Team;
  winningTeam?: Team;
}

export interface AuctionBid {
  id: string;
  auctionId: string;
  poolId: string;
  teamId: string;
  teamName: string;
  teamShortName: string;
  userId: string;
  amount: number;
  timestamp: string;
}

export interface AuctionPurchase {
  id: string;
  auctionId: string;
  poolId: string;
  playerId: string;
  teamId: string;
  amount: number;
  purchasedAt: string;
}

export interface AuctionPurseLedger {
  id: string;
  auctionId: string;
  teamId: string;
  deltaAmount: number;
  balanceAfter: number;
  reason: string;
  relatedPoolId?: string;
  createdAt: string;
}

// ----------------------------------------------------
// MATCHES & SCORING
// ----------------------------------------------------

export type MatchStatus =
  | 'scheduled'
  | 'toss'
  | 'live'
  | 'innings_break'
  | 'completed'
  | 'abandoned'
  | 'tied';

export type TossDecision = 'bat' | 'bowl';
export type WinType = 'runs' | 'wickets' | 'super_over' | 'tie' | 'no_result';

export interface Match {
  id: string;
  tournamentId: string;
  matchNumber: number;
  stage: string;
  groupName?: string;
  teamAId: string;
  teamBId: string;
  venue: string;
  dateTime: string;
  overs: number;
  status: MatchStatus;
  tossWonBy?: string | null;
  tossDecision?: TossDecision | null;
  battingFirstId?: string | null;
  winnerId?: string | null;
  winMargin?: number | null;
  winType?: WinType | null;
  playerOfMatchId?: string | null;
  scorerId?: string | null;
  teamA?: Team;
  teamB?: Team;
  innings1?: Innings;
  innings2?: Innings;
  currentInningsNumber?: number;
}

export interface Innings {
  id: string;
  matchId: string;
  inningsNumber: number; // 1 or 2
  battingTeamId: string;
  bowlingTeamId: string;
  totalRuns: number;
  wickets: number;
  legalBalls: number;
  oversStr: string; // e.g. "12.4"
  extrasWides: number;
  extrasNoBalls: number;
  extrasByes: number;
  extrasLegByes: number;
  extrasPenalty: number;
  totalExtras: number;
  isCompleted: boolean;
  currentStrikerId?: string | null;
  currentNonStrikerId?: string | null;
  currentBowlerId?: string | null;
  targetRuns?: number | null;
}

export type ExtrasType = 'wide' | 'no_ball' | 'bye' | 'leg_bye' | 'penalty';
export type DismissalType =
  | 'bowled'
  | 'caught'
  | 'caught_bowled'
  | 'lbw'
  | 'run_out'
  | 'stumped'
  | 'hit_wicket'
  | 'retired_out'
  | 'retired_hurt'
  | 'obstructing_field'
  | 'timed_out';

export interface Delivery {
  id: string;
  inningsId: string;
  matchId: string;
  overNumber: number; // 0 to 19
  ballInOver: number; // 1 to 6
  deliverySequence: number; // 1, 2, 3...
  strikerId: string;
  nonStrikerId: string;
  bowlerId: string;
  runsBatter: number; // 0-6
  extrasType?: ExtrasType | null;
  extrasRuns: number;
  isLegal: boolean;
  isWicket: boolean;
  dismissalType?: DismissalType | null;
  dismissedPlayerId?: string | null;
  assistedByPlayerId?: string | null;
  commentaryText?: string;
  timestamp: string;
  isUndone?: boolean;
}

export interface BattingScorecard {
  id: string;
  inningsId: string;
  matchId: string;
  playerId: string;
  teamId: string;
  playerName: string;
  battingPosition: number;
  runs: number;
  balls: number;
  fours: number;
  sixes: number;
  strikeRate: number;
  dismissalText: string;
  isOut: boolean;
}

export interface BowlingScorecard {
  id: string;
  inningsId: string;
  matchId: string;
  playerId: string;
  teamId: string;
  playerName: string;
  oversStr: string;
  legalBalls: number;
  maidens: number;
  runsConceded: number;
  wickets: number;
  dots: number;
  wides: number;
  noBalls: number;
  economy: number;
}

export interface TournamentStanding {
  id: string;
  tournamentId: string;
  teamId: string;
  teamName: string;
  teamShortName: string;
  teamLogoUrl: string;
  groupName: string;
  matchesPlayed: number;
  won: number;
  lost: number;
  tied: number;
  noResult: number;
  points: number;
  runsScored: number;
  ballsFaced: number;
  runsConceded: number;
  ballsBowled: number;
  netRunRate: number;
  rank: number;
}
