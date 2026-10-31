import { describe, it, expect, beforeEach } from 'vitest';
import { calculateNextValidBid, validateBid } from '../lib/auction-engine/bidding';
import { store } from '../lib/store/mock-db';
import { Auction, AuctionPlayerPoolItem, Team, UserProfile } from '../lib/types';

describe('Auction Bidding & Validation Rules', () => {
  const mockAuction: Auction = {
    id: 'auc_1',
    tournamentId: 'tourn_1',
    title: 'Premier Auction',
    status: 'live',
    minBidIncrement: 50000,
    countdownSeconds: 20,
    currentPoolId: 'pool_1',
    createdAt: new Date().toISOString(),
  };

  const mockPoolItem: AuctionPlayerPoolItem = {
    id: 'pool_1',
    auctionId: 'auc_1',
    tournamentPlayerId: 'tp_1',
    playerId: 'p1',
    category: 'batter',
    basePrice: 100000,
    lotNumber: 1,
    status: 'active',
    currentBid: 300000,
    highestBidderTeamId: 'team_kolkata',
    winningTeamId: null,
    soldPrice: null,
    version: 1,
  };

  const mockTeam: Team = {
    id: 'team_barasat',
    tournamentId: 'tourn_1',
    name: 'Barasat Blasters',
    shortName: 'BBL',
    logoUrl: '',
    primaryColor: '#16a34a',
    secondaryColor: '#0f172a',
    ownerId: 'user_barasat',
    initialPurse: 10000000,
    remainingPurse: 5000000, // 50 Lakhs
    createdAt: new Date().toISOString(),
  };

  const mockUser: UserProfile = {
    id: 'user_barasat',
    email: 'owner@barasat.com',
    fullName: 'Barasat Owner',
    role: 'team_owner',
    createdAt: new Date().toISOString(),
  };

  it('calculates the next valid bid correctly with increments', () => {
    // Current bid is 300,000, min increment is 50,000 -> next is 350,000
    const nextBid = calculateNextValidBid(300000, 100000, 50000);
    expect(nextBid).toBe(350000);

    // Initial bid (currentBid is null) should be base price
    const initialBid = calculateNextValidBid(null, 100000, 50000);
    expect(initialBid).toBe(100000);
  });

  it('accepts a valid bid from authorized team owner with sufficient purse', () => {
    const result = validateBid({
      auction: mockAuction,
      poolItem: mockPoolItem,
      team: mockTeam,
      user: mockUser,
      bidAmount: 350000,
      squadCount: 5,
      maxSquadSize: 18,
      minSquadSize: 11,
    });

    expect(result.isValid).toBe(true);
    expect(result.error).toBeUndefined();
  });

  it('rejects an unauthorized user attempting to bid for another team', () => {
    const unauthorizedUser: UserProfile = {
      id: 'attacker_id',
      email: 'attacker@evil.com',
      fullName: 'Spectator',
      role: 'spectator',
      createdAt: new Date().toISOString(),
    };

    const result = validateBid({
      auction: mockAuction,
      poolItem: mockPoolItem,
      team: mockTeam,
      user: unauthorizedUser,
      bidAmount: 350000,
      squadCount: 5,
      maxSquadSize: 18,
      minSquadSize: 11,
    });

    expect(result.isValid).toBe(false);
    expect(result.error).toContain('not authorized');
  });

  it('rejects a bid that exceeds remaining team purse', () => {
    const poorTeam: Team = {
      ...mockTeam,
      remainingPurse: 200000, // Only 2 Lakhs remaining
    };

    const result = validateBid({
      auction: mockAuction,
      poolItem: mockPoolItem,
      team: poorTeam,
      user: mockUser,
      bidAmount: 350000, // Exceeds 200,000!
      squadCount: 5,
      maxSquadSize: 18,
      minSquadSize: 11,
    });

    expect(result.isValid).toBe(false);
    expect(result.error).toContain('Insufficient purse');
  });

  it('prevents self-outbidding when team already holds highest bid', () => {
    const teamAlreadyLeading: AuctionPlayerPoolItem = {
      ...mockPoolItem,
      highestBidderTeamId: mockTeam.id,
    };

    const result = validateBid({
      auction: mockAuction,
      poolItem: teamAlreadyLeading,
      team: mockTeam,
      user: mockUser,
      bidAmount: 400000,
      squadCount: 5,
      maxSquadSize: 18,
      minSquadSize: 11,
    });

    expect(result.isValid).toBe(false);
    expect(result.error).toContain('already holds the highest bid');
  });
});

describe('Store Integrated Auction Operations', () => {
  beforeEach(() => {
    store.resetToDefaults();
  });

  it('atomically confirms a sale, deducts purse exactly once, and assigns player to winning squad', () => {
    const state = store.getState();
    const activeLot = state.auctionPlayerPool.find((p) => p.id === 'pool_6')!;
    const team = state.teams.find((t) => t.id === 'team_barasat')!;
    const initialPurse = team.remainingPurse;
    const initialSquadCount = team.squadCount || 0;

    // Highest bid on pool_6 is 450,000 by team_barasat
    expect(activeLot.currentBid).toBe(450000);
    expect(activeLot.highestBidderTeamId).toBe('team_barasat');

    // Confirm sold
    const result = store.confirmSold('auc_bpl_2026', 'pool_6');
    expect(result.success).toBe(true);

    // Verify team purse deducted exactly once
    expect(team.remainingPurse).toBe(initialPurse - 450000);
    expect(team.squadCount).toBe(initialSquadCount + 1);

    // Verify player is now marked sold and assigned to team_barasat
    expect(activeLot.status).toBe('sold');
    expect(activeLot.winningTeamId).toBe('team_barasat');
    expect(activeLot.soldPrice).toBe(450000);

    const tp = state.tournamentPlayers.find((x) => x.id === activeLot.tournamentPlayerId)!;
    expect(tp.teamId).toBe('team_barasat');
    expect(tp.status).toBe('sold');
    expect(tp.finalPrice).toBe(450000);

    // Verify auction current lot was cleared
    const auction = state.auctions.find((a) => a.id === 'auc_bpl_2026')!;
    expect(auction.currentPoolId).toBeNull();
  });
});
