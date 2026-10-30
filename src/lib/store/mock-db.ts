// ====================================================================
// AUTHORITATIVE PLATFORM STORE & DATABASE ENGINE
// ====================================================================

import {
  Auction,
  AuctionBid,
  AuctionPlayerPoolItem,
  AuctionPurseLedger,
  BattingScorecard,
  BowlingScorecard,
  Delivery,
  Innings,
  Match,
  Player,
  Team,
  Tournament,
  TournamentPlayer,
  TournamentStanding,
  UserProfile,
} from '../types';
import { processDelivery, RecordDeliveryInput } from '../cricket-engine/rules';
import { calculateScorecardsFromDeliveries } from '../cricket-engine/scorecard';
import { calculateNetRunRate, MatchNrrData } from '../cricket-engine/nrr';
import { calculateNextValidBid, validateBid } from '../auction-engine/bidding';

export interface PlatformState {
  currentUser: UserProfile;
  tournaments: Tournament[];
  teams: Team[];
  players: Player[];
  tournamentPlayers: TournamentPlayer[];
  auctions: Auction[];
  auctionPlayerPool: AuctionPlayerPoolItem[];
  auctionBids: AuctionBid[];
  auctionPurseLedger: AuctionPurseLedger[];
  matches: Match[];
  innings: Innings[];
  deliveries: Delivery[];
  battingScorecards: BattingScorecard[];
  bowlingScorecards: BowlingScorecard[];
  tournamentStandings: TournamentStanding[];
}

// Default Seed Data
const DEFAULT_USERS: UserProfile[] = [
  {
    id: 'user_organizer',
    email: 'organizer@bengalcricket.org',
    fullName: 'Debasish Dutta (Tournament Organizer)',
    role: 'organizer',
    createdAt: new Date().toISOString(),
  },
  {
    id: 'user_barasat',
    email: 'owner@barasatblasters.com',
    fullName: 'Arijit Mukherjee (Barasat Blasters Owner)',
    role: 'team_owner',
    createdAt: new Date().toISOString(),
  },
  {
    id: 'user_kolkata',
    email: 'owner@kolkataknights.com',
    fullName: 'Sanjiv Goenka (Kolkata Knights Owner)',
    role: 'team_owner',
    createdAt: new Date().toISOString(),
  },
  {
    id: 'user_scorer',
    email: 'scorer@cricketheroes.in',
    fullName: 'Pritam Saha (Official BCCI Certified Scorer)',
    role: 'scorer',
    createdAt: new Date().toISOString(),
  },
  {
    id: 'user_admin',
    email: 'admin@cricketplatform.com',
    fullName: 'Super Administrator',
    role: 'super_admin',
    createdAt: new Date().toISOString(),
  },
];

const DEFAULT_TOURNAMENTS: Tournament[] = [
  {
    id: 'tourn_bpl_2026',
    name: 'Bengal Premier League 2026',
    slug: 'bengal-premier-league-2026',
    description: 'The premier T20 franchise cricket tournament featuring top talent from West Bengal.',
    logoUrl: 'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?w=128&auto=format&fit=crop&q=80',
    bannerUrl: 'https://images.unsplash.com/photo-1531415074868-036b1c57e359?w=1200&auto=format&fit=crop&q=80',
    organizerId: 'user_organizer',
    status: 'in_progress',
    format: 'round_robin',
    startDate: '2026-10-15',
    endDate: '2026-11-15',
    location: 'Eden Gardens, Kolkata',
    oversPerInnings: 20,
    squadSizeMax: 18,
    squadSizeMin: 11,
    playingXISize: 11,
    powerplayOvers: 6,
    pointsWin: 2,
    pointsTie: 1,
    pointsNoResult: 1,
    hasAuction: true,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  },
];

const DEFAULT_TEAMS: Team[] = [
  {
    id: 'team_barasat',
    tournamentId: 'tourn_bpl_2026',
    name: 'Barasat Blasters',
    shortName: 'BBL',
    logoUrl: 'https://images.unsplash.com/photo-1589487391730-58f20eb2c308?w=96&auto=format&fit=crop&q=80',
    primaryColor: '#16a34a',
    secondaryColor: '#0f172a',
    ownerId: 'user_barasat',
    ownerName: 'Arijit Mukherjee',
    initialPurse: 10000000,
    remainingPurse: 6850000,
    squadCount: 5,
    createdAt: new Date().toISOString(),
  },
  {
    id: 'team_kolkata',
    tournamentId: 'tourn_bpl_2026',
    name: 'Kolkata Knights',
    shortName: 'KKN',
    logoUrl: 'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=96&auto=format&fit=crop&q=80',
    primaryColor: '#6366f1',
    secondaryColor: '#1e1b4b',
    ownerId: 'user_kolkata',
    ownerName: 'Sanjiv Goenka',
    initialPurse: 10000000,
    remainingPurse: 7200000,
    squadCount: 4,
    createdAt: new Date().toISOString(),
  },
  {
    id: 'team_howrah',
    tournamentId: 'tourn_bpl_2026',
    name: 'Howrah Hurricanes',
    shortName: 'HHR',
    logoUrl: 'https://images.unsplash.com/photo-1517649763962-0c623266ddc0?w=96&auto=format&fit=crop&q=80',
    primaryColor: '#0284c7',
    secondaryColor: '#082f49',
    ownerId: 'user_organizer',
    ownerName: 'Debabrata Mukherjee',
    initialPurse: 10000000,
    remainingPurse: 8500000,
    squadCount: 3,
    createdAt: new Date().toISOString(),
  },
  {
    id: 'team_sundarbans',
    tournamentId: 'tourn_bpl_2026',
    name: 'Sundarbans Strikers',
    shortName: 'SST',
    logoUrl: 'https://images.unsplash.com/photo-1579952363873-27f3bade9f55?w=96&auto=format&fit=crop&q=80',
    primaryColor: '#ea580c',
    secondaryColor: '#431407',
    ownerId: 'user_organizer',
    ownerName: 'Subhasish Bose',
    initialPurse: 10000000,
    remainingPurse: 8900000,
    squadCount: 2,
    createdAt: new Date().toISOString(),
  },
  {
    id: 'team_siliguri',
    tournamentId: 'tourn_bpl_2026',
    name: 'Siliguri Superstars',
    shortName: 'SSS',
    logoUrl: 'https://images.unsplash.com/photo-1562077772-3ab1218829c4?w=96&auto=format&fit=crop&q=80',
    primaryColor: '#d97706',
    secondaryColor: '#451a03',
    ownerId: 'user_organizer',
    ownerName: 'Ravi Verma',
    initialPurse: 10000000,
    remainingPurse: 9100000,
    squadCount: 2,
    createdAt: new Date().toISOString(),
  },
];

const DEFAULT_PLAYERS: Player[] = [
  {
    id: 'pl_1',
    fullName: 'Rahul Das',
    displayName: 'Rahul Das',
    photoUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=256&auto=format&fit=crop&q=80',
    role: 'all_rounder',
    battingStyle: 'right_hand_bat',
    bowlingStyle: 'right_arm_medium',
    city: 'Barasat',
    matches: 48,
    runs: 1420,
    highestScore: 89,
    battingAverage: 38.37,
    strikeRate: 146.5,
    wickets: 38,
    bestBowling: '4/18',
    economy: 7.2,
  },
  {
    id: 'pl_2',
    fullName: 'Aniket Sen',
    displayName: 'Aniket Sen',
    photoUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=256&auto=format&fit=crop&q=80',
    role: 'batter',
    battingStyle: 'left_hand_bat',
    bowlingStyle: 'none',
    city: 'Kolkata',
    matches: 52,
    runs: 1890,
    highestScore: 104,
    battingAverage: 43.95,
    strikeRate: 152.2,
    wickets: 0,
    bestBowling: '0/0',
    economy: 0.0,
  },
  {
    id: 'pl_3',
    fullName: 'Subham Dey',
    displayName: 'Subham Dey',
    photoUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=256&auto=format&fit=crop&q=80',
    role: 'wicket_keeper',
    battingStyle: 'right_hand_bat',
    bowlingStyle: 'none',
    city: 'Howrah',
    matches: 39,
    runs: 980,
    highestScore: 76,
    battingAverage: 32.66,
    strikeRate: 138.8,
    wickets: 0,
    bestBowling: '0/0',
    economy: 0.0,
  },
  {
    id: 'pl_4',
    fullName: 'Tanmoy Roy',
    displayName: 'Tanmoy Roy',
    photoUrl: 'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=256&auto=format&fit=crop&q=80',
    role: 'bowler',
    battingStyle: 'right_hand_bat',
    bowlingStyle: 'right_arm_fast',
    city: 'Siliguri',
    matches: 44,
    runs: 180,
    highestScore: 24,
    battingAverage: 12.0,
    strikeRate: 105.0,
    wickets: 56,
    bestBowling: '5/14',
    economy: 6.85,
  },
  {
    id: 'pl_5',
    fullName: 'Pritam Ghosh',
    displayName: 'Pritam Ghosh',
    photoUrl: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=256&auto=format&fit=crop&q=80',
    role: 'bowler',
    battingStyle: 'right_hand_bat',
    bowlingStyle: 'left_arm_spin',
    city: 'Kalyani',
    matches: 36,
    runs: 110,
    highestScore: 18,
    battingAverage: 11.0,
    strikeRate: 98.0,
    wickets: 42,
    bestBowling: '4/12',
    economy: 6.4,
  },
  {
    id: 'pl_6',
    fullName: 'Debayan Paul',
    displayName: 'Debayan Paul',
    photoUrl: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=256&auto=format&fit=crop&q=80',
    role: 'all_rounder',
    battingStyle: 'right_hand_bat',
    bowlingStyle: 'right_arm_medium',
    city: 'Durgapur',
    matches: 41,
    runs: 1120,
    highestScore: 78,
    battingAverage: 35.0,
    strikeRate: 142.0,
    wickets: 29,
    bestBowling: '3/22',
    economy: 7.6,
  },
  {
    id: 'pl_7',
    fullName: 'Suman Biswas',
    displayName: 'Suman Biswas',
    photoUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=256&auto=format&fit=crop&q=80',
    role: 'batter',
    battingStyle: 'right_hand_bat',
    bowlingStyle: 'none',
    city: 'Malda',
    matches: 33,
    runs: 870,
    highestScore: 68,
    battingAverage: 29.0,
    strikeRate: 131.0,
    wickets: 0,
    bestBowling: '0/0',
    economy: 0.0,
  },
  {
    id: 'pl_8',
    fullName: 'Abhishek Roy',
    displayName: 'Abhishek Roy',
    photoUrl: 'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=256&auto=format&fit=crop&q=80',
    role: 'all_rounder',
    battingStyle: 'left_hand_bat',
    bowlingStyle: 'right_arm_spin',
    city: 'Midnapore',
    matches: 45,
    runs: 1350,
    highestScore: 92,
    battingAverage: 37.5,
    strikeRate: 144.0,
    wickets: 34,
    bestBowling: '4/21',
    economy: 7.1,
  },
  {
    id: 'pl_9',
    fullName: 'Rohit Sarkar',
    displayName: 'Rohit Sarkar',
    photoUrl: 'https://images.unsplash.com/photo-1501196354995-cbb51c65aaea?w=256&auto=format&fit=crop&q=80',
    role: 'bowler',
    battingStyle: 'right_hand_bat',
    bowlingStyle: 'right_arm_fast',
    city: 'Cooch Behar',
    matches: 28,
    runs: 95,
    highestScore: 16,
    battingAverage: 9.5,
    strikeRate: 85.0,
    wickets: 37,
    bestBowling: '4/19',
    economy: 7.45,
  },
  {
    id: 'pl_10',
    fullName: 'Sayak Mondal',
    displayName: 'Sayak Mondal',
    photoUrl: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=256&auto=format&fit=crop&q=80',
    role: 'batter',
    battingStyle: 'right_hand_bat',
    bowlingStyle: 'none',
    city: 'Kolkata',
    matches: 30,
    runs: 790,
    highestScore: 64,
    battingAverage: 28.2,
    strikeRate: 129.5,
    wickets: 0,
    bestBowling: '0/0',
    economy: 0.0,
  },
];

const DEFAULT_TOURNAMENT_PLAYERS: TournamentPlayer[] = [
  {
    id: 'tp_1',
    tournamentId: 'tourn_bpl_2026',
    playerId: 'pl_1',
    teamId: 'team_barasat',
    status: 'sold',
    basePrice: 100000,
    finalPrice: 1500000,
    lotNumber: 1,
  },
  {
    id: 'tp_2',
    tournamentId: 'tourn_bpl_2026',
    playerId: 'pl_2',
    teamId: 'team_kolkata',
    status: 'sold',
    basePrice: 100000,
    finalPrice: 1800000,
    lotNumber: 2,
  },
  {
    id: 'tp_3',
    tournamentId: 'tourn_bpl_2026',
    playerId: 'pl_3',
    teamId: 'team_barasat',
    status: 'sold',
    basePrice: 50000,
    finalPrice: 950000,
    lotNumber: 3,
  },
  {
    id: 'tp_4',
    tournamentId: 'tourn_bpl_2026',
    playerId: 'pl_4',
    teamId: 'team_kolkata',
    status: 'sold',
    basePrice: 50000,
    finalPrice: 1000000,
    lotNumber: 4,
  },
  {
    id: 'tp_5',
    tournamentId: 'tourn_bpl_2026',
    playerId: 'pl_5',
    teamId: 'team_barasat',
    status: 'sold',
    basePrice: 50000,
    finalPrice: 700000,
    lotNumber: 5,
  },
  {
    id: 'tp_6',
    tournamentId: 'tourn_bpl_2026',
    playerId: 'pl_6',
    teamId: null,
    status: 'in_auction',
    basePrice: 75000,
    lotNumber: 6,
  },
  {
    id: 'tp_7',
    tournamentId: 'tourn_bpl_2026',
    playerId: 'pl_7',
    teamId: null,
    status: 'in_auction',
    basePrice: 50000,
    lotNumber: 7,
  },
  {
    id: 'tp_8',
    tournamentId: 'tourn_bpl_2026',
    playerId: 'pl_8',
    teamId: null,
    status: 'in_auction',
    basePrice: 100000,
    lotNumber: 8,
  },
  {
    id: 'tp_9',
    tournamentId: 'tourn_bpl_2026',
    playerId: 'pl_9',
    teamId: null,
    status: 'in_auction',
    basePrice: 50000,
    lotNumber: 9,
  },
  {
    id: 'tp_10',
    tournamentId: 'tourn_bpl_2026',
    playerId: 'pl_10',
    teamId: null,
    status: 'in_auction',
    basePrice: 50000,
    lotNumber: 10,
  },
];

const DEFAULT_AUCTION: Auction = {
  id: 'auc_bpl_2026',
  tournamentId: 'tourn_bpl_2026',
  title: 'BPL 2026 Grand Player Auction',
  status: 'live',
  minBidIncrement: 50000,
  countdownSeconds: 20,
  currentPoolId: 'pool_6',
  timerStartedAt: new Date().toISOString(),
  createdAt: new Date().toISOString(),
};

const DEFAULT_AUCTION_POOL: AuctionPlayerPoolItem[] = [
  {
    id: 'pool_1',
    auctionId: 'auc_bpl_2026',
    tournamentPlayerId: 'tp_1',
    playerId: 'pl_1',
    category: 'marquee',
    basePrice: 100000,
    lotNumber: 1,
    status: 'sold',
    currentBid: 1500000,
    highestBidderTeamId: 'team_barasat',
    winningTeamId: 'team_barasat',
    soldPrice: 1500000,
    soldAt: new Date(Date.now() - 3600000).toISOString(),
    version: 8,
  },
  {
    id: 'pool_2',
    auctionId: 'auc_bpl_2026',
    tournamentPlayerId: 'tp_2',
    playerId: 'pl_2',
    category: 'marquee',
    basePrice: 100000,
    lotNumber: 2,
    status: 'sold',
    currentBid: 1800000,
    highestBidderTeamId: 'team_kolkata',
    winningTeamId: 'team_kolkata',
    soldPrice: 1800000,
    soldAt: new Date(Date.now() - 3000000).toISOString(),
    version: 12,
  },
  {
    id: 'pool_3',
    auctionId: 'auc_bpl_2026',
    tournamentPlayerId: 'tp_3',
    playerId: 'pl_3',
    category: 'wicket_keeper',
    basePrice: 50000,
    lotNumber: 3,
    status: 'sold',
    currentBid: 950000,
    highestBidderTeamId: 'team_barasat',
    winningTeamId: 'team_barasat',
    soldPrice: 950000,
    soldAt: new Date(Date.now() - 2400000).toISOString(),
    version: 6,
  },
  {
    id: 'pool_4',
    auctionId: 'auc_bpl_2026',
    tournamentPlayerId: 'tp_4',
    playerId: 'pl_4',
    category: 'bowler',
    basePrice: 50000,
    lotNumber: 4,
    status: 'sold',
    currentBid: 1000000,
    highestBidderTeamId: 'team_kolkata',
    winningTeamId: 'team_kolkata',
    soldPrice: 1000000,
    soldAt: new Date(Date.now() - 1800000).toISOString(),
    version: 7,
  },
  {
    id: 'pool_5',
    auctionId: 'auc_bpl_2026',
    tournamentPlayerId: 'tp_5',
    playerId: 'pl_5',
    category: 'bowler',
    basePrice: 50000,
    lotNumber: 5,
    status: 'sold',
    currentBid: 700000,
    highestBidderTeamId: 'team_barasat',
    winningTeamId: 'team_barasat',
    soldPrice: 700000,
    soldAt: new Date(Date.now() - 1200000).toISOString(),
    version: 5,
  },
  {
    id: 'pool_6',
    auctionId: 'auc_bpl_2026',
    tournamentPlayerId: 'tp_6',
    playerId: 'pl_6',
    category: 'all_rounder',
    basePrice: 75000,
    lotNumber: 6,
    status: 'active',
    currentBid: 450000,
    highestBidderTeamId: 'team_barasat',
    winningTeamId: null,
    soldPrice: null,
    version: 3,
  },
  {
    id: 'pool_7',
    auctionId: 'auc_bpl_2026',
    tournamentPlayerId: 'tp_7',
    playerId: 'pl_7',
    category: 'batter',
    basePrice: 50000,
    lotNumber: 7,
    status: 'pending',
    currentBid: null,
    highestBidderTeamId: null,
    winningTeamId: null,
    soldPrice: null,
    version: 0,
  },
  {
    id: 'pool_8',
    auctionId: 'auc_bpl_2026',
    tournamentPlayerId: 'tp_8',
    playerId: 'pl_8',
    category: 'all_rounder',
    basePrice: 100000,
    lotNumber: 8,
    status: 'pending',
    currentBid: null,
    highestBidderTeamId: null,
    winningTeamId: null,
    soldPrice: null,
    version: 0,
  },
  {
    id: 'pool_9',
    auctionId: 'auc_bpl_2026',
    tournamentPlayerId: 'tp_9',
    playerId: 'pl_9',
    category: 'bowler',
    basePrice: 50000,
    lotNumber: 9,
    status: 'pending',
    currentBid: null,
    highestBidderTeamId: null,
    winningTeamId: null,
    soldPrice: null,
    version: 0,
  },
  {
    id: 'pool_10',
    auctionId: 'auc_bpl_2026',
    tournamentPlayerId: 'tp_10',
    playerId: 'pl_10',
    category: 'batter',
    basePrice: 50000,
    lotNumber: 10,
    status: 'pending',
    currentBid: null,
    highestBidderTeamId: null,
    winningTeamId: null,
    soldPrice: null,
    version: 0,
  },
];

const DEFAULT_BIDS: AuctionBid[] = [
  {
    id: 'bid_1',
    auctionId: 'auc_bpl_2026',
    poolId: 'pool_6',
    teamId: 'team_kolkata',
    teamName: 'Kolkata Knights',
    teamShortName: 'KKN',
    userId: 'user_kolkata',
    amount: 100000,
    timestamp: new Date(Date.now() - 35000).toISOString(),
  },
  {
    id: 'bid_2',
    auctionId: 'auc_bpl_2026',
    poolId: 'pool_6',
    teamId: 'team_barasat',
    teamName: 'Barasat Blasters',
    teamShortName: 'BBL',
    userId: 'user_barasat',
    amount: 250000,
    timestamp: new Date(Date.now() - 25000).toISOString(),
  },
  {
    id: 'bid_3',
    auctionId: 'auc_bpl_2026',
    poolId: 'pool_6',
    teamId: 'team_kolkata',
    teamName: 'Kolkata Knights',
    teamShortName: 'KKN',
    userId: 'user_kolkata',
    amount: 350000,
    timestamp: new Date(Date.now() - 15000).toISOString(),
  },
  {
    id: 'bid_4',
    auctionId: 'auc_bpl_2026',
    poolId: 'pool_6',
    teamId: 'team_barasat',
    teamName: 'Barasat Blasters',
    teamShortName: 'BBL',
    userId: 'user_barasat',
    amount: 450000,
    timestamp: new Date(Date.now() - 5000).toISOString(),
  },
];

const DEFAULT_MATCHES: Match[] = [
  {
    id: 'match_1',
    tournamentId: 'tourn_bpl_2026',
    matchNumber: 1,
    stage: 'League Match 1',
    groupName: 'Group A',
    teamAId: 'team_barasat',
    teamBId: 'team_kolkata',
    venue: 'Eden Gardens, Kolkata',
    dateTime: new Date().toISOString(),
    overs: 20,
    status: 'live',
    tossWonBy: 'team_kolkata',
    tossDecision: 'bowl',
    battingFirstId: 'team_barasat',
    scorerId: 'user_scorer',
    currentInningsNumber: 1,
  },
  {
    id: 'match_2',
    tournamentId: 'tourn_bpl_2026',
    matchNumber: 2,
    stage: 'League Match 2',
    teamAId: 'team_howrah',
    teamBId: 'team_sundarbans',
    venue: 'Kalyani Stadium, Kalyani',
    dateTime: new Date(Date.now() + 86400000).toISOString(),
    overs: 20,
    status: 'scheduled',
    currentInningsNumber: 1,
  },
  {
    id: 'match_3',
    tournamentId: 'tourn_bpl_2026',
    matchNumber: 3,
    stage: 'League Match 3',
    teamAId: 'team_siliguri',
    teamBId: 'team_barasat',
    venue: 'Kanchenjunga Stadium, Siliguri',
    dateTime: new Date(Date.now() + 172800000).toISOString(),
    overs: 20,
    status: 'scheduled',
    currentInningsNumber: 1,
  },
];

const DEFAULT_INNINGS: Innings[] = [
  {
    id: 'inn_1',
    matchId: 'match_1',
    inningsNumber: 1,
    battingTeamId: 'team_barasat',
    bowlingTeamId: 'team_kolkata',
    totalRuns: 114,
    wickets: 2,
    legalBalls: 87, // 14.3 overs
    oversStr: '14.3',
    extrasWides: 3,
    extrasNoBalls: 1,
    extrasByes: 0,
    extrasLegByes: 2,
    extrasPenalty: 0,
    totalExtras: 6,
    isCompleted: false,
    currentStrikerId: 'pl_1', // Rahul Das
    currentNonStrikerId: 'pl_3', // Subham Dey
    currentBowlerId: 'pl_4', // Tanmoy Roy
  },
];

const DEFAULT_DELIVERIES: Delivery[] = [
  {
    id: 'del_1',
    inningsId: 'inn_1',
    matchId: 'match_1',
    overNumber: 14,
    ballInOver: 1,
    deliverySequence: 85,
    strikerId: 'pl_1',
    nonStrikerId: 'pl_3',
    bowlerId: 'pl_4',
    runsBatter: 1,
    extrasRuns: 0,
    isLegal: true,
    isWicket: false,
    commentaryText: 'Tanmoy Roy bowls full on middle, pushed to mid-on for a single.',
    timestamp: new Date(Date.now() - 40000).toISOString(),
  },
  {
    id: 'del_2',
    inningsId: 'inn_1',
    matchId: 'match_1',
    overNumber: 14,
    ballInOver: 2,
    deliverySequence: 86,
    strikerId: 'pl_3',
    nonStrikerId: 'pl_1',
    bowlerId: 'pl_4',
    runsBatter: 4,
    extrasRuns: 0,
    isLegal: true,
    isWicket: false,
    commentaryText: 'FOUR! Slashed past point with supreme timing to the fence!',
    timestamp: new Date(Date.now() - 25000).toISOString(),
  },
  {
    id: 'del_3',
    inningsId: 'inn_1',
    matchId: 'match_1',
    overNumber: 14,
    ballInOver: 3,
    deliverySequence: 87,
    strikerId: 'pl_3',
    nonStrikerId: 'pl_1',
    bowlerId: 'pl_4',
    runsBatter: 1,
    extrasRuns: 0,
    isLegal: true,
    isWicket: false,
    commentaryText: 'Dabbed into the covers for a quick run. Strike rotated.',
    timestamp: new Date(Date.now() - 10000).toISOString(),
  },
];

class PlatformStore {
  private state: PlatformState;
  private subscribers: Set<() => void> = new Set();
  private isBrowser: boolean = typeof window !== 'undefined';

  constructor() {
    this.state = this.loadInitialState();
  }

  private loadInitialState(): PlatformState {
    if (this.isBrowser) {
      try {
        const stored = localStorage.getItem('cricket_platform_db_v2');
        if (stored) {
          const parsed = JSON.parse(stored);
          return parsed;
        }
      } catch (e) {
        console.error('Failed to load local storage state:', e);
      }
    }

    // Default Seed State
    const playersMap = new Map(DEFAULT_PLAYERS.map((p) => [p.id, p]));
    const initialScorecards = calculateScorecardsFromDeliveries(
      DEFAULT_DELIVERIES,
      playersMap,
      'team_barasat',
      'team_kolkata',
      'inn_1',
      'match_1'
    );

    const initialStandings: TournamentStanding[] = DEFAULT_TEAMS.map((team, idx) => ({
      id: `stand_${team.id}`,
      tournamentId: 'tourn_bpl_2026',
      teamId: team.id,
      teamName: team.name,
      teamShortName: team.shortName,
      teamLogoUrl: team.logoUrl,
      groupName: 'All',
      matchesPlayed: idx === 0 || idx === 1 ? 1 : 0,
      won: idx === 0 ? 1 : 0,
      lost: idx === 1 ? 1 : 0,
      tied: 0,
      noResult: 0,
      points: idx === 0 ? 2 : 0,
      runsScored: idx === 0 ? 172 : idx === 1 ? 148 : 0,
      ballsFaced: idx === 0 ? 120 : idx === 1 ? 120 : 0,
      runsConceded: idx === 0 ? 148 : idx === 1 ? 172 : 0,
      ballsBowled: idx === 0 ? 120 : idx === 1 ? 120 : 0,
      netRunRate: idx === 0 ? 1.200 : idx === 1 ? -1.200 : 0.000,
      rank: idx + 1,
    }));

    return {
      currentUser: DEFAULT_USERS[0], // Organizer by default
      tournaments: DEFAULT_TOURNAMENTS,
      teams: DEFAULT_TEAMS,
      players: DEFAULT_PLAYERS,
      tournamentPlayers: DEFAULT_TOURNAMENT_PLAYERS,
      auctions: [DEFAULT_AUCTION],
      auctionPlayerPool: DEFAULT_AUCTION_POOL,
      auctionBids: DEFAULT_BIDS,
      auctionPurseLedger: [],
      matches: DEFAULT_MATCHES,
      innings: DEFAULT_INNINGS,
      deliveries: DEFAULT_DELIVERIES,
      battingScorecards: initialScorecards.battingScorecards,
      bowlingScorecards: initialScorecards.bowlingScorecards,
      tournamentStandings: initialStandings,
    };
  }

  private persistAndNotify() {
    if (this.isBrowser) {
      try {
        localStorage.setItem('cricket_platform_db_v2', JSON.stringify(this.state));
      } catch (e) {
        console.error('Failed to persist to localStorage:', e);
      }
    }
    this.subscribers.forEach((cb) => cb());
  }

  public subscribe(callback: () => void): () => void {
    this.subscribers.add(callback);
    return () => this.subscribers.delete(callback);
  }

  public getState(): PlatformState {
    return this.state;
  }

  public setCurrentUser(user: UserProfile) {
    this.state.currentUser = user;
    this.persistAndNotify();
  }

  public switchRole(role: UserProfile['role'], teamId?: string) {
    const existing = DEFAULT_USERS.find((u) => u.role === role);
    if (existing) {
      this.state.currentUser = { ...existing };
      if (role === 'team_owner' && teamId) {
        const t = this.state.teams.find((x) => x.id === teamId);
        if (t) {
          t.ownerId = this.state.currentUser.id;
        }
      }
      this.persistAndNotify();
    }
  }

  // ----------------------------------------------------
  // AUCTION MUTATIONS
  // ----------------------------------------------------

  /**
   * Randomly spins and selects next eligible player from pool
   */
  public spinPlayerLot(auctionId: string): AuctionPlayerPoolItem | null {
    const auction = this.state.auctions.find((a) => a.id === auctionId);
    if (!auction) return null;

    // Find all pending lots
    const eligibleLots = this.state.auctionPlayerPool.filter(
      (p) => p.auctionId === auctionId && (p.status === 'pending' || p.status === 'passed')
    );

    if (eligibleLots.length === 0) {
      return null;
    }

    // Select random player
    const randomIndex = Math.floor(Math.random() * eligibleLots.length);
    const selectedLot = eligibleLots[randomIndex];

    // Mark previous active lots as passed if any
    this.state.auctionPlayerPool.forEach((p) => {
      if (p.auctionId === auctionId && p.status === 'active') {
        p.status = 'passed';
      }
    });

    selectedLot.status = 'active';
    selectedLot.currentBid = null;
    selectedLot.highestBidderTeamId = null;
    selectedLot.version += 1;

    auction.currentPoolId = selectedLot.id;
    auction.timerStartedAt = new Date().toISOString();

    this.persistAndNotify();
    return selectedLot;
  }

  /**
   * Places an atomic bid for a team
   */
  public placeBid(params: {
    auctionId: string;
    teamId: string;
    userId: string;
    amount?: number;
  }): { success: boolean; error?: string; newBid?: number } {
    const auction = this.state.auctions.find((a) => a.id === params.auctionId);
    if (!auction || !auction.currentPoolId) {
      return { success: false, error: 'No active player lot found for bidding' };
    }

    const poolItem = this.state.auctionPlayerPool.find((p) => p.id === auction.currentPoolId);
    if (!poolItem) {
      return { success: false, error: 'Current player lot not found' };
    }

    const team = this.state.teams.find((t) => t.id === params.teamId);
    if (!team) {
      return { success: false, error: 'Team not found' };
    }

    const tournament = this.state.tournaments.find((t) => t.id === auction.tournamentId);
    const maxSquad = tournament?.squadSizeMax || 18;
    const minSquad = tournament?.squadSizeMin || 11;
    const squadCount = team.squadCount || 0;

    const bidAmount =
      params.amount ||
      calculateNextValidBid(poolItem.currentBid, poolItem.basePrice, auction.minBidIncrement);

    // Validate bid
    const validation = validateBid({
      auction,
      poolItem,
      team,
      user: this.state.currentUser,
      bidAmount,
      squadCount,
      maxSquadSize: maxSquad,
      minSquadSize: minSquad,
    });

    if (!validation.isValid) {
      return { success: false, error: validation.error };
    }

    // Execute bid
    poolItem.currentBid = bidAmount;
    poolItem.highestBidderTeamId = team.id;
    poolItem.version += 1;

    // Reset countdown timer
    auction.timerStartedAt = new Date().toISOString();

    const newBidRecord: AuctionBid = {
      id: `bid_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`,
      auctionId: auction.id,
      poolId: poolItem.id,
      teamId: team.id,
      teamName: team.name,
      teamShortName: team.shortName,
      userId: params.userId,
      amount: bidAmount,
      timestamp: new Date().toISOString(),
    };

    this.state.auctionBids.unshift(newBidRecord);

    this.persistAndNotify();
    return { success: true, newBid: bidAmount };
  }

  /**
   * Confirms a player as SOLD, automatically assigns to team squad and deducts purse
   */
  public confirmSold(auctionId: string, poolId: string): { success: boolean; error?: string } {
    const auction = this.state.auctions.find((a) => a.id === auctionId);
    const poolItem = this.state.auctionPlayerPool.find((p) => p.id === poolId);

    if (!auction || !poolItem || poolItem.status !== 'active') {
      return { success: false, error: 'Player lot is not active' };
    }

    if (!poolItem.highestBidderTeamId || !poolItem.currentBid) {
      return { success: false, error: 'No valid bid placed on this player' };
    }

    const team = this.state.teams.find((t) => t.id === poolItem.highestBidderTeamId);
    if (!team) {
      return { success: false, error: 'Winning team not found' };
    }

    const salePrice = poolItem.currentBid;
    if (team.remainingPurse < salePrice) {
      return { success: false, error: 'Team has insufficient purse to complete sale' };
    }

    // ATOMIC MUTATIONS:
    // 1. Deduct purse
    team.remainingPurse -= salePrice;
    team.squadCount = (team.squadCount || 0) + 1;

    // 2. Assign player to team squad
    const tp = this.state.tournamentPlayers.find((x) => x.id === poolItem.tournamentPlayerId);
    if (tp) {
      tp.teamId = team.id;
      tp.status = 'sold';
      tp.finalPrice = salePrice;
    }

    // 3. Update pool item status
    poolItem.status = 'sold';
    poolItem.winningTeamId = team.id;
    poolItem.soldPrice = salePrice;
    poolItem.soldAt = new Date().toISOString();

    // 4. Record in purse ledger
    this.state.auctionPurseLedger.push({
      id: `ledge_${Date.now()}`,
      auctionId,
      teamId: team.id,
      deltaAmount: -salePrice,
      balanceAfter: team.remainingPurse,
      reason: `Purchased player: ${poolItem.player?.fullName || 'Player'}`,
      relatedPoolId: poolItem.id,
      createdAt: new Date().toISOString(),
    });

    // 5. Reset auction current lot
    auction.currentPoolId = null;
    auction.timerStartedAt = null;

    this.persistAndNotify();
    return { success: true };
  }

  /**
   * Marks a player as UNSOLD
   */
  public markUnsold(auctionId: string, poolId: string): { success: boolean } {
    const auction = this.state.auctions.find((a) => a.id === auctionId);
    const poolItem = this.state.auctionPlayerPool.find((p) => p.id === poolId);

    if (poolItem) {
      poolItem.status = 'unsold';
      poolItem.currentBid = null;
      poolItem.highestBidderTeamId = null;

      const tp = this.state.tournamentPlayers.find((x) => x.id === poolItem.tournamentPlayerId);
      if (tp) {
        tp.status = 'unsold';
      }
    }

    if (auction) {
      auction.currentPoolId = null;
      auction.timerStartedAt = null;
    }

    this.persistAndNotify();
    return { success: true };
  }

  // ----------------------------------------------------
  // SCORING MUTATIONS
  // ----------------------------------------------------

  public recordDelivery(input: Omit<RecordDeliveryInput, 'innings'> & { inningsId: string }): {
    success: boolean;
    delivery?: Delivery;
    error?: string;
  } {
    const innings = this.state.innings.find((i) => i.id === input.inningsId);
    if (!innings) {
      return { success: false, error: 'Innings not found' };
    }

    const match = this.state.matches.find((m) => m.id === innings.matchId);
    if (!match) {
      return { success: false, error: 'Match not found' };
    }

    // Process delivery via domain engine
    const result = processDelivery({
      ...input,
      innings,
      maxOvers: match.overs,
    });

    // Replace updated innings
    const innIndex = this.state.innings.findIndex((i) => i.id === innings.id);
    this.state.innings[innIndex] = result.updatedInnings;

    // Add delivery record
    this.state.deliveries.push(result.delivery);

    // Recalculate scorecards
    const playersMap = new Map(this.state.players.map((p) => [p.id, p]));
    const scorecards = calculateScorecardsFromDeliveries(
      this.state.deliveries.filter((d) => d.inningsId === innings.id),
      playersMap,
      innings.battingTeamId,
      innings.bowlingTeamId,
      innings.id,
      match.id
    );

    // Upsert scorecards
    this.state.battingScorecards = this.state.battingScorecards
      .filter((b) => b.inningsId !== innings.id)
      .concat(scorecards.battingScorecards);

    this.state.bowlingScorecards = this.state.bowlingScorecards
      .filter((b) => b.inningsId !== innings.id)
      .concat(scorecards.bowlingScorecards);

    // Check if match won or innings completed
    if (result.isMatchWon) {
      match.status = 'completed';
      match.winnerId = innings.battingTeamId;
      match.winMargin = 10 - result.updatedInnings.wickets;
      match.winType = 'wickets';
      this.recalculateStandings(match.tournamentId);
    } else if (result.updatedInnings.isCompleted && innings.inningsNumber === 2) {
      // 2nd innings ended without reaching target
      match.status = 'completed';
      const inn1 = this.state.innings.find((i) => i.matchId === match.id && i.inningsNumber === 1);
      if (inn1 && inn1.totalRuns > result.updatedInnings.totalRuns) {
        match.winnerId = inn1.battingTeamId;
        match.winMargin = inn1.totalRuns - result.updatedInnings.totalRuns;
        match.winType = 'runs';
      } else if (inn1 && inn1.totalRuns === result.updatedInnings.totalRuns) {
        match.status = 'tied';
        match.winType = 'tie';
      }
      this.recalculateStandings(match.tournamentId);
    }

    this.persistAndNotify();
    return { success: true, delivery: result.delivery };
  }

  public undoLastDelivery(inningsId: string): { success: boolean; error?: string } {
    const innings = this.state.innings.find((i) => i.id === inningsId);
    if (!innings) return { success: false, error: 'Innings not found' };

    const inningsDeliveries = this.state.deliveries.filter((d) => d.inningsId === inningsId && !d.isUndone);
    if (inningsDeliveries.length === 0) {
      return { success: false, error: 'No deliveries to undo' };
    }

    // Mark last delivery as undone
    const lastDelivery = inningsDeliveries[inningsDeliveries.length - 1];
    lastDelivery.isUndone = true;

    // Replay remaining deliveries to restore precise innings state
    const remaining = inningsDeliveries.slice(0, -1);
    const playersMap = new Map(this.state.players.map((p) => [p.id, p]));
    const scorecards = calculateScorecardsFromDeliveries(
      remaining,
      playersMap,
      innings.battingTeamId,
      innings.bowlingTeamId,
      innings.id,
      innings.matchId
    );

    // Recalculate basic totals
    let runs = 0;
    let balls = 0;
    let wickets = 0;
    let wides = 0;
    let noBalls = 0;
    let byes = 0;
    let legByes = 0;

    remaining.forEach((d) => {
      let r = d.runsBatter + d.extrasRuns;
      if (d.extrasType === 'wide' && d.extrasRuns === 0) r = 1;
      if (d.extrasType === 'no_ball' && d.extrasRuns === 0) r = 1 + d.runsBatter;
      runs += r;
      if (d.isLegal) balls += 1;
      if (d.isWicket) wickets += 1;
      if (d.extrasType === 'wide') wides += Math.max(1, d.extrasRuns);
      if (d.extrasType === 'no_ball') noBalls += 1;
      if (d.extrasType === 'bye') byes += d.extrasRuns;
      if (d.extrasType === 'leg_bye') legByes += d.extrasRuns;
    });

    innings.totalRuns = runs;
    innings.wickets = wickets;
    innings.legalBalls = balls;
    innings.oversStr = `${Math.floor(balls / 6)}.${balls % 6}`;
    innings.extrasWides = wides;
    innings.extrasNoBalls = noBalls;
    innings.extrasByes = byes;
    innings.extrasLegByes = legByes;
    innings.totalExtras = wides + noBalls + byes + legByes;
    innings.isCompleted = false;

    // Replace scorecards
    this.state.battingScorecards = this.state.battingScorecards
      .filter((b) => b.inningsId !== inningsId)
      .concat(scorecards.battingScorecards);

    this.state.bowlingScorecards = this.state.bowlingScorecards
      .filter((b) => b.inningsId !== inningsId)
      .concat(scorecards.bowlingScorecards);

    this.persistAndNotify();
    return { success: true };
  }

  public recalculateStandings(tournamentId: string) {
    const teams = this.state.teams.filter((t) => t.tournamentId === tournamentId);
    const tournamentMatches = this.state.matches.filter(
      (m) => m.tournamentId === tournamentId && (m.status === 'completed' || m.status === 'tied' || m.status === 'abandoned')
    );

    const standings: TournamentStanding[] = teams.map((team) => {
      let played = 0;
      let won = 0;
      let lost = 0;
      let tied = 0;
      let nr = 0;
      let points = 0;

      const teamMatchesNrr: MatchNrrData[] = [];

      for (const m of tournamentMatches) {
        if (m.teamAId !== team.id && m.teamBId !== team.id) continue;
        played += 1;

        if (m.status === 'abandoned') {
          nr += 1;
          points += 1;
        } else if (m.status === 'tied' || m.winType === 'tie') {
          tied += 1;
          points += 1;
        } else if (m.winnerId === team.id) {
          won += 1;
          points += 2;
        } else {
          lost += 1;
        }

        if (m.status === 'completed' || m.status === 'tied') {
          const inn1 = this.state.innings.find((i) => i.matchId === m.id && i.inningsNumber === 1);
          const inn2 = this.state.innings.find((i) => i.matchId === m.id && i.inningsNumber === 2);

          if (inn1 && inn2) {
            const isTeamBat1 = inn1.battingTeamId === team.id;
            const myBattingInn = isTeamBat1 ? inn1 : inn2;
            const myBowlingInn = isTeamBat1 ? inn2 : inn1;

            teamMatchesNrr.push({
              matchStatus: m.status as 'completed' | 'tied',
              teamBatted: {
                runs: myBattingInn.totalRuns,
                legalBalls: myBattingInn.legalBalls,
                isAllOut: myBattingInn.wickets >= 10,
                maxOversForInnings: m.overs,
              },
              teamBowled: {
                runs: myBowlingInn.totalRuns,
                legalBalls: myBowlingInn.legalBalls,
                isAllOut: myBowlingInn.wickets >= 10,
                maxOversForInnings: m.overs,
              },
            });
          }
        }
      }

      const nrr = calculateNetRunRate(teamMatchesNrr);

      return {
        id: `stand_${team.id}`,
        tournamentId,
        teamId: team.id,
        teamName: team.name,
        teamShortName: team.shortName,
        teamLogoUrl: team.logoUrl,
        groupName: 'All',
        matchesPlayed: played,
        won,
        lost,
        tied,
        noResult: nr,
        points,
        runsScored: 0,
        ballsFaced: 0,
        runsConceded: 0,
        ballsBowled: 0,
        netRunRate: nrr,
        rank: 1,
      };
    });

    // Sort by Points descending, then NRR descending
    standings.sort((a, b) => {
      if (b.points !== a.points) return b.points - a.points;
      return b.netRunRate - a.netRunRate;
    });

    standings.forEach((s, idx) => {
      s.rank = idx + 1;
    });

    this.state.tournamentStandings = standings;
    this.persistAndNotify();
  }

  public resetToDefaults() {
    if (this.isBrowser) {
      localStorage.removeItem('cricket_platform_db_v2');
    }
    this.state = this.loadInitialState();
    this.persistAndNotify();
  }
}

// Global Singleton Store
export const store = new PlatformStore();
