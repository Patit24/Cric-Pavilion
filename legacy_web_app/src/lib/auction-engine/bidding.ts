// ====================================================================
// AUCTION BIDDING & PURSE INTEGRITY ENGINE
// ====================================================================

import { Auction, AuctionPlayerPoolItem, Team, UserProfile } from '../types';

export interface ValidateBidParams {
  auction: Auction;
  poolItem: AuctionPlayerPoolItem;
  team: Team;
  user: UserProfile;
  bidAmount: number;
  squadCount: number;
  maxSquadSize: number;
  minSquadSize: number;
}

export interface BidValidationResult {
  isValid: boolean;
  error?: string;
  nextValidBid: number;
}

/**
 * Calculates next valid bid amount according to base price or increments
 */
export function calculateNextValidBid(
  currentBid: number | null,
  basePrice: number,
  minIncrement: number = 10000
): number {
  if (currentBid === null || currentBid === 0) {
    return basePrice;
  }
  return currentBid + minIncrement;
}

/**
 * Validates whether a bid can be accepted
 */
export function validateBid(params: ValidateBidParams): BidValidationResult {
  const { auction, poolItem, team, user, bidAmount, squadCount, maxSquadSize, minSquadSize } = params;

  const nextValidBid = calculateNextValidBid(
    poolItem.currentBid,
    poolItem.basePrice,
    auction.minBidIncrement
  );

  // 1. Auction must be live
  if (auction.status !== 'live') {
    return { isValid: false, error: 'Auction is not currently live', nextValidBid };
  }

  // 2. Pool item must be active
  if (poolItem.status !== 'active') {
    return { isValid: false, error: 'This player lot is not open for bidding', nextValidBid };
  }

  // 3. User must be authorized for this team (or super_admin)
  const isAuthorized =
    user.role === 'super_admin' ||
    (team.ownerId && team.ownerId === user.id) ||
    (user.role === 'organizer' && user.id === auction.tournamentId); // organizers can test or intervene if needed

  if (!isAuthorized) {
    return {
      isValid: false,
      error: `You are not authorized to place bids on behalf of ${team.name}`,
      nextValidBid,
    };
  }

  // 4. Team cannot outbid itself
  if (poolItem.highestBidderTeamId === team.id) {
    return {
      isValid: false,
      error: 'Your team already holds the highest bid',
      nextValidBid,
    };
  }

  // 5. Squad limit check
  if (squadCount >= maxSquadSize) {
    return {
      isValid: false,
      error: `Team squad limit of ${maxSquadSize} players reached`,
      nextValidBid,
    };
  }

  // 6. Purse check
  if (team.remainingPurse < bidAmount) {
    return {
      isValid: false,
      error: `Insufficient purse! Remaining: ₹${team.remainingPurse.toLocaleString('en-IN')}, Bid: ₹${bidAmount.toLocaleString('en-IN')}`,
      nextValidBid,
    };
  }

  // 7. Minimum squad fund reservation check (must retain base prices for minimum squad slots remaining)
  const remainingSlotsToMin = Math.max(0, minSquadSize - (squadCount + 1));
  const reservedForMinSquad = remainingSlotsToMin * 50000; // minimum ₹50,000 per slot
  if (team.remainingPurse - bidAmount < reservedForMinSquad) {
    return {
      isValid: false,
      error: `Cannot bid! Must reserve at least ₹${reservedForMinSquad.toLocaleString('en-IN')} to fulfill minimum squad requirement of ${minSquadSize} players`,
      nextValidBid,
    };
  }

  // 8. Bid amount must be >= next valid bid
  if (bidAmount < nextValidBid) {
    return {
      isValid: false,
      error: `Bid must be at least ₹${nextValidBid.toLocaleString('en-IN')}`,
      nextValidBid,
    };
  }

  return { isValid: true, nextValidBid };
}
