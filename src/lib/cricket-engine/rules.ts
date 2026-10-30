// ====================================================================
// CRICKET RULES DOMAIN ENGINE
// ====================================================================

import { Delivery, DismissalType, ExtrasType, Innings } from '../types';

export interface RecordDeliveryInput {
  innings: Innings;
  strikerId: string;
  nonStrikerId: string;
  bowlerId: string;
  runsBatter: number; // 0, 1, 2, 3, 4, 5, 6
  extrasType?: ExtrasType | null;
  extrasRuns?: number; // e.g. 1 for wide, or 1 for no-ball + runs, etc.
  isWicket?: boolean;
  dismissalType?: DismissalType | null;
  dismissedPlayerId?: string | null;
  assistedByPlayerId?: string | null;
  nextBatterId?: string | null;
  commentaryText?: string;
  maxOvers?: number;
}

export interface DeliveryExecutionResult {
  updatedInnings: Innings;
  delivery: Delivery;
  nextStrikerId: string;
  nextNonStrikerId: string;
  isOverComplete: boolean;
  isMatchWon: boolean;
  isAllOut: boolean;
}

/**
 * Validates whether a delivery is legal (increments ball count in over).
 * Wides and No-Balls are NOT legal balls.
 * Byes, Leg-Byes, Penalty, and regular deliveries ARE legal balls.
 */
export function isDeliveryLegal(extrasType?: ExtrasType | null): boolean {
  if (extrasType === 'wide' || extrasType === 'no_ball') {
    return false;
  }
  return true;
}

/**
 * Checks whether a dismissal is credited to the bowler's stats.
 * Bowled, Caught, Caught & Bowled, LBW, Stumped, Hit Wicket are credited to bowler.
 * Run out, Retired out/hurt, Obstructing field, Timed out are NOT credited to bowler.
 */
export function isBowlerWicket(dismissalType?: DismissalType | null): boolean {
  if (!dismissalType) return false;
  const nonBowlerWickets: DismissalType[] = [
    'run_out',
    'retired_out',
    'retired_hurt',
    'obstructing_field',
    'timed_out',
  ];
  return !nonBowlerWickets.includes(dismissalType);
}

/**
 * Formats balls into standard cricket overs string (e.g. 11 balls = "1.5", 12 balls = "2.0")
 */
export function formatOvers(legalBalls: number): string {
  const completedOvers = Math.floor(legalBalls / 6);
  const remainingBalls = legalBalls % 6;
  return `${completedOvers}.${remainingBalls}`;
}

/**
 * Executes a single delivery with strict adherence to cricket laws
 */
export function processDelivery(input: RecordDeliveryInput): DeliveryExecutionResult {
  const {
    innings,
    strikerId,
    nonStrikerId,
    bowlerId,
    runsBatter,
    extrasType = null,
    extrasRuns = 0,
    isWicket = false,
    dismissalType = null,
    dismissedPlayerId = null,
    assistedByPlayerId = null,
    nextBatterId = null,
    commentaryText = '',
    maxOvers = 20,
  } = input;

  const isLegal = isDeliveryLegal(extrasType);
  
  // Calculate total runs scored on this delivery
  let deliveryTotalRuns = runsBatter + extrasRuns;
  if (extrasType === 'wide' && extrasRuns === 0) {
    deliveryTotalRuns = 1; // Default 1 wide run if not specified
  } else if (extrasType === 'no_ball' && extrasRuns === 0) {
    deliveryTotalRuns = 1 + runsBatter; // Default 1 no ball run + batter runs
  }

  // Calculate new legal balls and overs
  const newLegalBalls = isLegal ? innings.legalBalls + 1 : innings.legalBalls;
  const newOversStr = formatOvers(newLegalBalls);
  const isOverComplete = isLegal && newLegalBalls % 6 === 0;

  // Over number and ball in over
  const currentOverIndex = Math.floor(innings.legalBalls / 6);
  const ballInCurrentOver = (innings.legalBalls % 6) + (isLegal ? 1 : 0);

  // Extras breakdown
  let wides = innings.extrasWides;
  let noBalls = innings.extrasNoBalls;
  let byes = innings.extrasByes;
  let legByes = innings.extrasLegByes;
  let penalty = innings.extrasPenalty;

  if (extrasType === 'wide') wides += Math.max(1, extrasRuns);
  if (extrasType === 'no_ball') noBalls += 1;
  if (extrasType === 'bye') byes += extrasRuns;
  if (extrasType === 'leg_bye') legByes += extrasRuns;
  if (extrasType === 'penalty') penalty += extrasRuns;

  const totalExtras = wides + noBalls + byes + legByes + penalty;
  const newTotalRuns = innings.totalRuns + deliveryTotalRuns;
  const newWickets = isWicket ? innings.wickets + 1 : innings.wickets;

  // Determine all-out condition (10 wickets in standard 11-player cricket)
  const isAllOut = newWickets >= 10;
  
  // Check if target chased down in 2nd innings
  const isMatchWon = Boolean(innings.targetRuns && newTotalRuns >= innings.targetRuns);
  
  // Check if innings completed (all out, target reached, or all overs bowled)
  const isCompleted = isAllOut || isMatchWon || (newLegalBalls >= maxOvers * 6);

  // STRIKE ROTATION RULES:
  // Runs that cause batters to physically cross and swap ends:
  // - Batter runs: 1, 3, 5 swap ends.
  // - Bye / Leg-Bye: odd runs swap ends.
  // - Wide / No-ball with odd completed runs: swap ends.
  let runsForCross = runsBatter;
  if (extrasType === 'bye' || extrasType === 'leg_bye') {
    runsForCross = extrasRuns;
  }
  const isOddRuns = runsForCross % 2 === 1;

  let currentStriker = strikerId;
  let currentNonStriker = nonStrikerId;

  // If a wicket fell, replace dismissed batter with nextBatter
  if (isWicket && nextBatterId) {
    if (dismissedPlayerId === strikerId) {
      currentStriker = nextBatterId;
    } else if (dismissedPlayerId === nonStrikerId) {
      currentNonStriker = nextBatterId;
    }
  }

  // Cross ends if odd runs
  if (isOddRuns) {
    const temp = currentStriker;
    currentStriker = currentNonStriker;
    currentNonStriker = temp;
  }

  // If over is complete, batters swap ends because bowler will bowl from opposite end!
  if (isOverComplete && !isCompleted) {
    const temp = currentStriker;
    currentStriker = currentNonStriker;
    currentNonStriker = temp;
  }

  const delivery: Delivery = {
    id: `del_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`,
    inningsId: innings.id,
    matchId: innings.matchId,
    overNumber: currentOverIndex,
    ballInOver: ballInCurrentOver,
    deliverySequence: (innings.legalBalls || 0) + (isLegal ? 1 : 0),
    strikerId,
    nonStrikerId,
    bowlerId,
    runsBatter,
    extrasType,
    extrasRuns: extrasType ? (extrasRuns || 1) : 0,
    isLegal,
    isWicket,
    dismissalType,
    dismissedPlayerId,
    assistedByPlayerId,
    commentaryText,
    timestamp: new Date().toISOString(),
  };

  const updatedInnings: Innings = {
    ...innings,
    totalRuns: newTotalRuns,
    wickets: newWickets,
    legalBalls: newLegalBalls,
    oversStr: newOversStr,
    extrasWides: wides,
    extrasNoBalls: noBalls,
    extrasByes: byes,
    extrasLegByes: legByes,
    extrasPenalty: penalty,
    totalExtras,
    isCompleted,
    currentStrikerId: currentStriker,
    currentNonStrikerId: currentNonStriker,
    currentBowlerId: isOverComplete ? null : bowlerId, // Reset bowler on over end
  };

  return {
    updatedInnings,
    delivery,
    nextStrikerId: currentStriker,
    nextNonStrikerId: currentNonStriker,
    isOverComplete,
    isMatchWon,
    isAllOut,
  };
}
