// ====================================================================
// SCORECARD & STATS RECALCULATION ENGINE
// ====================================================================

import {
  BattingScorecard,
  BowlingScorecard,
  Delivery,
  Player,
} from '../types';
import { formatOvers, isBowlerWicket } from './rules';

export interface ScorecardCalculationResult {
  battingScorecards: BattingScorecard[];
  bowlingScorecards: BowlingScorecard[];
  fallOfWickets: { wicketNumber: number; score: number; overStr: string; playerOutId: string }[];
  currentPartnership: { runs: number; balls: number; player1Id?: string; player2Id?: string };
  overSummaries: { overNumber: number; bowlerId: string; balls: string[]; runs: number; wickets: number }[];
}

export function calculateScorecardsFromDeliveries(
  deliveries: Delivery[],
  playersMap: Map<string, Player>,
  battingTeamId: string,
  bowlingTeamId: string,
  inningsId: string,
  matchId: string
): ScorecardCalculationResult {
  const activeDeliveries = deliveries.filter((d) => !d.isUndone);
  
  // Sort deliveries chronologically by sequence / timestamp
  activeDeliveries.sort((a, b) => a.deliverySequence - b.deliverySequence);

  const battingMap = new Map<string, BattingScorecard>();
  const bowlingMap = new Map<string, BowlingScorecard>();
  const fallOfWickets: { wicketNumber: number; score: number; overStr: string; playerOutId: string }[] = [];
  
  let totalInningsRuns = 0;
  let totalWickets = 0;
  let partnerRuns = 0;
  let partnerBalls = 0;

  // Track over summaries
  const overMap = new Map<number, { overNumber: number; bowlerId: string; balls: string[]; runs: number; wickets: number }>();

  // Helper to ensure batting scorecard exists
  const getBattingEntry = (playerId: string): BattingScorecard => {
    if (!battingMap.has(playerId)) {
      const p = playersMap.get(playerId);
      battingMap.set(playerId, {
        id: `bat_${inningsId}_${playerId}`,
        inningsId,
        matchId,
        playerId,
        teamId: battingTeamId,
        playerName: p?.displayName || p?.fullName || 'Batter',
        battingPosition: battingMap.size + 1,
        runs: 0,
        balls: 0,
        fours: 0,
        sixes: 0,
        strikeRate: 0,
        dismissalText: 'not out',
        isOut: false,
      });
    }
    return battingMap.get(playerId)!;
  };

  // Helper to ensure bowling scorecard exists
  const getBowlingEntry = (playerId: string): BowlingScorecard => {
    if (!bowlingMap.has(playerId)) {
      const p = playersMap.get(playerId);
      bowlingMap.set(playerId, {
        id: `bowl_${inningsId}_${playerId}`,
        inningsId,
        matchId,
        playerId,
        teamId: bowlingTeamId,
        playerName: p?.displayName || p?.fullName || 'Bowler',
        oversStr: '0.0',
        legalBalls: 0,
        maidens: 0,
        runsConceded: 0,
        wickets: 0,
        dots: 0,
        wides: 0,
        noBalls: 0,
        economy: 0,
      });
    }
    return bowlingMap.get(playerId)!;
  };

  for (const del of activeDeliveries) {
    const strikerBat = getBattingEntry(del.strikerId);
    getBattingEntry(del.nonStrikerId); // ensure non-striker in map
    const bowler = getBowlingEntry(del.bowlerId);

    // Track total runs on this delivery
    let deliveryRuns = del.runsBatter + del.extrasRuns;
    if (del.extrasType === 'wide' && del.extrasRuns === 0) deliveryRuns = 1;
    if (del.extrasType === 'no_ball' && del.extrasRuns === 0) deliveryRuns = 1 + del.runsBatter;
    totalInningsRuns += deliveryRuns;
    partnerRuns += deliveryRuns;

    // Batting stats:
    // Wides do NOT count as balls faced for the batter!
    if (del.extrasType !== 'wide') {
      strikerBat.balls += 1;
      partnerBalls += 1;
    }

    // Batter runs:
    strikerBat.runs += del.runsBatter;
    if (del.runsBatter === 4) strikerBat.fours += 1;
    if (del.runsBatter === 6) strikerBat.sixes += 1;

    // Bowler stats:
    // Bowler conceded runs include batter runs, wides, no-balls.
    // Byes and Leg-Byes are NOT charged against bowler!
    let runsConcededOnBall = del.runsBatter;
    if (del.extrasType === 'wide') {
      bowler.wides += 1;
      runsConcededOnBall += Math.max(1, del.extrasRuns);
    } else if (del.extrasType === 'no_ball') {
      bowler.noBalls += 1;
      runsConcededOnBall += 1; // 1 run for no ball penalty
    }

    bowler.runsConceded += runsConcededOnBall;

    if (del.isLegal) {
      bowler.legalBalls += 1;
      if (runsConcededOnBall === 0) {
        bowler.dots += 1;
      }
    }

    // Wicket handling
    if (del.isWicket) {
      totalWickets += 1;
      const dismissedId = del.dismissedPlayerId || del.strikerId;
      const dismissedBat = getBattingEntry(dismissedId);
      dismissedBat.isOut = true;

      const bowlerName = bowler.playerName;
      const assistName = del.assistedByPlayerId ? playersMap.get(del.assistedByPlayerId)?.displayName || 'Fielder' : '';

      switch (del.dismissalType) {
        case 'bowled':
          dismissedBat.dismissalText = `b ${bowlerName}`;
          break;
        case 'caught':
          dismissedBat.dismissalText = `c ${assistName} b ${bowlerName}`;
          break;
        case 'caught_bowled':
          dismissedBat.dismissalText = `c & b ${bowlerName}`;
          break;
        case 'lbw':
          dismissedBat.dismissalText = `lbw b ${bowlerName}`;
          break;
        case 'stumped':
          dismissedBat.dismissalText = `st ${assistName} b ${bowlerName}`;
          break;
        case 'run_out':
          dismissedBat.dismissalText = `run out (${assistName || 'direct'})`;
          break;
        case 'hit_wicket':
          dismissedBat.dismissalText = `hit wicket b ${bowlerName}`;
          break;
        default:
          dismissedBat.dismissalText = `${del.dismissalType?.replace('_', ' ') || 'out'} b ${bowlerName}`;
      }

      // Check if credited to bowler
      if (isBowlerWicket(del.dismissalType)) {
        bowler.wickets += 1;
      }

      // Record Fall of Wicket
      const ballsInInnings = activeDeliveries.filter((d) => d.isLegal).length;
      fallOfWickets.push({
        wicketNumber: totalWickets,
        score: totalInningsRuns,
        overStr: formatOvers(ballsInInnings),
        playerOutId: dismissedId,
      });

      // Reset current partnership
      partnerRuns = 0;
      partnerBalls = 0;
    }

    // Over summary ball notation
    let ballLabel = del.runsBatter.toString();
    if (del.extrasType === 'wide') {
      ballLabel = `${Math.max(1, del.extrasRuns)}wd`;
    } else if (del.extrasType === 'no_ball') {
      ballLabel = `${del.runsBatter + 1}nb`;
    } else if (del.extrasType === 'bye') {
      ballLabel = `${del.extrasRuns}b`;
    } else if (del.extrasType === 'leg_bye') {
      ballLabel = `${del.extrasRuns}lb`;
    }
    if (del.isWicket) {
      ballLabel = del.runsBatter > 0 ? `${del.runsBatter}+W` : 'W';
    }

    if (!overMap.has(del.overNumber)) {
      overMap.set(del.overNumber, {
        overNumber: del.overNumber,
        bowlerId: del.bowlerId,
        balls: [],
        runs: 0,
        wickets: 0,
      });
    }
    const currentOverSummary = overMap.get(del.overNumber)!;
    currentOverSummary.balls.push(ballLabel);
    currentOverSummary.runs += deliveryRuns;
    if (del.isWicket) currentOverSummary.wickets += 1;
  }

  // Calculate Strike Rates
  for (const bat of Array.from(battingMap.values())) {
    if (bat.balls > 0) {
      bat.strikeRate = Math.round((bat.runs / bat.balls) * 10000) / 100;
    }
  }

  // Calculate Overs and Economy for Bowlers
  for (const bowl of Array.from(bowlingMap.values())) {
    bowl.oversStr = formatOvers(bowl.legalBalls);
    const oversDecimal = bowl.legalBalls / 6;
    if (oversDecimal > 0) {
      bowl.economy = Math.round((bowl.runsConceded / oversDecimal) * 100) / 100;
    }
  }

  // Check maidens: an over where 6 legal balls were bowled, runs conceded == 0
  for (const over of Array.from(overMap.values())) {
    if (over.runs === 0 && over.balls.filter((b) => !b.includes('wd') && !b.includes('nb')).length === 6) {
      const bowl = bowlingMap.get(over.bowlerId);
      if (bowl) bowl.maidens += 1;
    }
  }

  return {
    battingScorecards: Array.from(battingMap.values()),
    bowlingScorecards: Array.from(bowlingMap.values()),
    fallOfWickets,
    currentPartnership: { runs: partnerRuns, balls: partnerBalls },
    overSummaries: Array.from(overMap.values()),
  };
}
