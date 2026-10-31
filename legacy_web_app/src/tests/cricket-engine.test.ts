import { describe, it, expect } from 'vitest';
import {
  isDeliveryLegal,
  isBowlerWicket,
  formatOvers,
  processDelivery,
  validateBowlerEligibility,
  getAvailableIncomingBatsmen,
  getPreviousOverBowlerId,
} from '../lib/cricket-engine/rules';
import { calculateScorecardsFromDeliveries } from '../lib/cricket-engine/scorecard';
import { calculateNetRunRate, getOversForNrr } from '../lib/cricket-engine/nrr';
import { Innings, Player } from '../lib/types';

describe('Cricket Domain Rules & Legality', () => {
  it('correctly identifies legal vs illegal deliveries', () => {
    expect(isDeliveryLegal(null)).toBe(true);
    expect(isDeliveryLegal('bye')).toBe(true);
    expect(isDeliveryLegal('leg_bye')).toBe(true);
    expect(isDeliveryLegal('wide')).toBe(false);
    expect(isDeliveryLegal('no_ball')).toBe(false);
  });

  it('correctly credits bowler wickets vs field-only wickets', () => {
    expect(isBowlerWicket('bowled')).toBe(true);
    expect(isBowlerWicket('caught')).toBe(true);
    expect(isBowlerWicket('lbw')).toBe(true);
    expect(isBowlerWicket('stumped')).toBe(true);
    expect(isBowlerWicket('run_out')).toBe(false);
    expect(isBowlerWicket('retired_out')).toBe(false);
  });

  it('correctly formats cricket overs', () => {
    expect(formatOvers(0)).toBe('0.0');
    expect(formatOvers(1)).toBe('0.1');
    expect(formatOvers(5)).toBe('0.5');
    expect(formatOvers(6)).toBe('1.0');
    expect(formatOvers(11)).toBe('1.5');
    expect(formatOvers(120)).toBe('20.0');
  });
});

describe('Ball-by-Ball Delivery Processing', () => {
  const baseInnings: Innings = {
    id: 'test_inn',
    matchId: 'test_match',
    inningsNumber: 1,
    battingTeamId: 'team_a',
    bowlingTeamId: 'team_b',
    totalRuns: 0,
    wickets: 0,
    legalBalls: 0,
    oversStr: '0.0',
    extrasWides: 0,
    extrasNoBalls: 0,
    extrasByes: 0,
    extrasLegByes: 0,
    extrasPenalty: 0,
    totalExtras: 0,
    isCompleted: false,
    currentStrikerId: 'p1',
    currentNonStrikerId: 'p2',
    currentBowlerId: 'b1',
  };

  it('processes a single with correct strike rotation', () => {
    const result = processDelivery({
      innings: baseInnings,
      strikerId: 'p1',
      nonStrikerId: 'p2',
      bowlerId: 'b1',
      runsBatter: 1,
    });

    expect(result.updatedInnings.totalRuns).toBe(1);
    expect(result.updatedInnings.legalBalls).toBe(1);
    expect(result.updatedInnings.oversStr).toBe('0.1');
    expect(result.nextStrikerId).toBe('p2'); // Rotated strike
    expect(result.nextNonStrikerId).toBe('p1');
  });

  it('processes a boundary 4 (no strike rotation during over)', () => {
    const result = processDelivery({
      innings: baseInnings,
      strikerId: 'p1',
      nonStrikerId: 'p2',
      bowlerId: 'b1',
      runsBatter: 4,
    });

    expect(result.updatedInnings.totalRuns).toBe(4);
    expect(result.updatedInnings.legalBalls).toBe(1);
    expect(result.nextStrikerId).toBe('p1'); // Retained strike
    expect(result.nextNonStrikerId).toBe('p2');
  });

  it('processes a wide without incrementing legal balls or striker balls faced', () => {
    const result = processDelivery({
      innings: baseInnings,
      strikerId: 'p1',
      nonStrikerId: 'p2',
      bowlerId: 'b1',
      runsBatter: 0,
      extrasType: 'wide',
      extrasRuns: 1,
    });

    expect(result.updatedInnings.totalRuns).toBe(1);
    expect(result.updatedInnings.legalBalls).toBe(0); // Illegal ball!
    expect(result.updatedInnings.oversStr).toBe('0.0');
    expect(result.updatedInnings.extrasWides).toBe(1);
    expect(result.nextStrikerId).toBe('p1');
  });

  it('rotates strike at the completion of an over (6th legal ball)', () => {
    const overEndInnings: Innings = {
      ...baseInnings,
      legalBalls: 5,
      oversStr: '0.5',
    };

    // Batter takes 0 runs on 6th ball
    const result = processDelivery({
      innings: overEndInnings,
      strikerId: 'p1',
      nonStrikerId: 'p2',
      bowlerId: 'b1',
      runsBatter: 0,
    });

    expect(result.isOverComplete).toBe(true);
    expect(result.updatedInnings.legalBalls).toBe(6);
    expect(result.updatedInnings.oversStr).toBe('1.0');
    // Because over is complete, ends swap, so non-striker p2 is now striker!
    expect(result.nextStrikerId).toBe('p2');
    expect(result.nextNonStrikerId).toBe('p1');
  });

  it('replaces dismissed player when a wicket falls', () => {
    const result = processDelivery({
      innings: baseInnings,
      strikerId: 'p1',
      nonStrikerId: 'p2',
      bowlerId: 'b1',
      runsBatter: 0,
      isWicket: true,
      dismissalType: 'bowled',
      dismissedPlayerId: 'p1',
      nextBatterId: 'p3',
    });

    expect(result.updatedInnings.wickets).toBe(1);
    expect(result.nextStrikerId).toBe('p3'); // New batter on strike
    expect(result.nextNonStrikerId).toBe('p2');
  });
});

describe('Net Run Rate (NRR) with Official All-Out Quota Rule', () => {
  it('charges full quota of overs when a team is all out', () => {
    const allOutInnings = {
      runs: 120,
      legalBalls: 80, // 13.2 overs bowled
      isAllOut: true,
      maxOversForInnings: 20,
    };

    // Crucial cricket rule: All-out means divisor is 20, NOT 13.333!
    const oversCharged = getOversForNrr(allOutInnings);
    expect(oversCharged).toBe(20.0);
  });

  it('calculates correct net run rate for a completed match', () => {
    const nrr = calculateNetRunRate([
      {
        matchStatus: 'completed',
        teamBatted: {
          runs: 180,
          legalBalls: 120, // 20.0 overs
          isAllOut: false,
          maxOversForInnings: 20,
        },
        teamBowled: {
          runs: 140,
          legalBalls: 120, // 20.0 overs
          isAllOut: false,
          maxOversForInnings: 20,
        },
      },
    ]);

    // 180/20 - 140/20 = 9.0 - 7.0 = +2.000
    expect(nrr).toBe(2.0);
  });
});

describe('Bowler Eligibility & Dismissed Batsman Rules', () => {
  it('prevents the same bowler from bowling consecutive overs', () => {
    const check = validateBowlerEligibility({
      bowlerId: 'bowler_tanmoy',
      previousOverBowlerId: 'bowler_tanmoy', // Tanmoy just bowled previous over
      deliveries: [],
      inningsId: 'inn_1',
      maxOversPerBowler: 4,
    });

    expect(check.isEligible).toBe(false);
    expect(check.reason).toContain('consecutive');
  });

  it('allows a different bowler to bowl the next over', () => {
    const check = validateBowlerEligibility({
      bowlerId: 'bowler_shami',
      previousOverBowlerId: 'bowler_tanmoy', // Tanmoy bowled previous over
      deliveries: [],
      inningsId: 'inn_1',
      maxOversPerBowler: 4,
    });

    expect(check.isEligible).toBe(true);
    expect(check.reason).toBeUndefined();
  });

  it('enforces maximum overs quota limit per bowler', () => {
    // 24 legal balls = 4.0 overs
    const mockDeliveries = Array.from({ length: 24 }).map((_, idx) => ({
      id: `del_${idx}`,
      inningsId: 'inn_1',
      matchId: 'm1',
      overNumber: Math.floor(idx / 6),
      ballInOver: (idx % 6) + 1,
      deliverySequence: idx + 1,
      strikerId: 'p1',
      nonStrikerId: 'p2',
      bowlerId: 'bowler_tanmoy',
      runsBatter: 0,
      extrasRuns: 0,
      isLegal: true,
      isWicket: false,
      timestamp: new Date().toISOString(),
    }));

    const check = validateBowlerEligibility({
      bowlerId: 'bowler_tanmoy',
      previousOverBowlerId: 'bowler_other',
      deliveries: mockDeliveries,
      inningsId: 'inn_1',
      maxOversPerBowler: 4,
    });

    expect(check.isEligible).toBe(false);
    expect(check.reason).toContain('Over quota reached (4/4 ov)');
  });

  it('excludes dismissed batsmen so out batsmen cannot bat again', () => {
    const players = [
      { id: 'b1', fullName: 'Rahul Das', role: 'batter', battingStyle: 'right_hand_bat' },
      { id: 'b2', fullName: 'Aniket Sen', role: 'batter', battingStyle: 'left_hand_bat' },
      { id: 'b3', fullName: 'Subham Dey', role: 'wicket_keeper', battingStyle: 'right_hand_bat' },
      { id: 'b4', fullName: 'Tanmoy Roy', role: 'all_rounder', battingStyle: 'right_hand_bat' },
    ];

    // b1 was dismissed in a wicket delivery
    const deliveries = [
      {
        id: 'del_w',
        inningsId: 'inn_1',
        matchId: 'm1',
        overNumber: 2,
        ballInOver: 4,
        deliverySequence: 10,
        strikerId: 'b1',
        nonStrikerId: 'b2',
        bowlerId: 'bowler_x',
        runsBatter: 0,
        extrasRuns: 0,
        isLegal: true,
        isWicket: true,
        dismissedPlayerId: 'b1',
        timestamp: new Date().toISOString(),
      },
    ];

    // Check available batsmen: b1 is out, b2 is currently batting on crease
    const available = getAvailableIncomingBatsmen({
      battingTeamPlayers: players,
      deliveries,
      inningsId: 'inn_1',
      currentStrikerId: 'b2',
      currentNonStrikerId: null,
    });

    // Should only contain b3 and b4; b1 (dismissed) and b2 (on crease) MUST be excluded!
    const availableIds = available.map((p) => p.id);
    expect(availableIds).not.toContain('b1');
    expect(availableIds).not.toContain('b2');
    expect(availableIds).toContain('b3');
    expect(availableIds).toContain('b4');
  });

  it('correctly tracks previous over bowler and prevents same bowler consecutive overs', () => {
    // Over 1 (6 balls bowled by bowler_a)
    const deliveries = Array.from({ length: 6 }).map((_, idx) => ({
      id: `del_ov1_${idx}`,
      inningsId: 'inn_1',
      matchId: 'm1',
      overNumber: 0,
      ballInOver: idx + 1,
      deliverySequence: idx + 1,
      strikerId: 'p1',
      nonStrikerId: 'p2',
      bowlerId: 'bowler_a',
      runsBatter: 1,
      extrasRuns: 0,
      isLegal: true,
      isWicket: false,
      timestamp: new Date().toISOString(),
    }));

    // Check previous bowler at end of Over 1 (6 legal balls)
    const prevBowlerAtOver1End = getPreviousOverBowlerId(deliveries, 'inn_1', 6);
    expect(prevBowlerAtOver1End).toBe('bowler_a');

    // Verify bowler_a is ineligible to bowl over 2
    const checkBowlerA = validateBowlerEligibility({
      bowlerId: 'bowler_a',
      previousOverBowlerId: prevBowlerAtOver1End,
      deliveries,
      inningsId: 'inn_1',
      maxOversPerBowler: 4,
    });
    expect(checkBowlerA.isEligible).toBe(false);
    expect(checkBowlerA.reason).toBe('Cannot bowl consecutive overs');

    // Verify bowler_b IS eligible to bowl over 2
    const checkBowlerB = validateBowlerEligibility({
      bowlerId: 'bowler_b',
      previousOverBowlerId: prevBowlerAtOver1End,
      deliveries,
      inningsId: 'inn_1',
      maxOversPerBowler: 4,
    });
    expect(checkBowlerB.isEligible).toBe(true);

    // Over 2 (6 balls bowled by bowler_b)
    const over2Deliveries = Array.from({ length: 6 }).map((_, idx) => ({
      id: `del_ov2_${idx}`,
      inningsId: 'inn_1',
      matchId: 'm1',
      overNumber: 1,
      ballInOver: idx + 1,
      deliverySequence: 6 + idx + 1,
      strikerId: 'p1',
      nonStrikerId: 'p2',
      bowlerId: 'bowler_b',
      runsBatter: 0,
      extrasRuns: 0,
      isLegal: true,
      isWicket: false,
      timestamp: new Date().toISOString(),
    }));

    const allDeliveries = [...deliveries, ...over2Deliveries];
    const prevBowlerAtOver2End = getPreviousOverBowlerId(allDeliveries, 'inn_1', 12);
    expect(prevBowlerAtOver2End).toBe('bowler_b');

    // For Over 3: bowler_b is now blocked, but bowler_a is eligible again!
    const checkBAtOver3 = validateBowlerEligibility({
      bowlerId: 'bowler_b',
      previousOverBowlerId: prevBowlerAtOver2End,
      deliveries: allDeliveries,
      inningsId: 'inn_1',
      maxOversPerBowler: 4,
    });
    expect(checkBAtOver3.isEligible).toBe(false);

    const checkAAtOver3 = validateBowlerEligibility({
      bowlerId: 'bowler_a',
      previousOverBowlerId: prevBowlerAtOver2End,
      deliveries: allDeliveries,
      inningsId: 'inn_1',
      maxOversPerBowler: 4,
    });
    expect(checkAAtOver3.isEligible).toBe(true);
  });

  it('enforces strict max overs cap (e.g. 20 overs / 120 balls) and rejects deliveries once complete', () => {
    const fullInnings: Innings = {
      id: 'inn_capped',
      matchId: 'm1',
      inningsNumber: 1,
      battingTeamId: 'team_a',
      bowlingTeamId: 'team_b',
      totalRuns: 180,
      wickets: 4,
      legalBalls: 120, // 20.0 overs bowled
      oversStr: '20.0',
      extrasWides: 0,
      extrasNoBalls: 0,
      extrasByes: 0,
      extrasLegByes: 0,
      extrasPenalty: 0,
      totalExtras: 0,
      isCompleted: true,
      currentStrikerId: 'p1',
      currentNonStrikerId: 'p2',
      currentBowlerId: 'b1',
    };

    // Attempting to bowl ball 121 must throw an error and be rejected
    expect(() => {
      processDelivery({
        innings: fullInnings,
        strikerId: 'p1',
        nonStrikerId: 'p2',
        bowlerId: 'b1',
        runsBatter: 1,
        maxOvers: 20,
      });
    }).toThrow(/already completed/);
  });

  it('marks innings as complete upon bowling ball 120 (20.0 overs)', () => {
    const over19Point5Innings: Innings = {
      id: 'inn_last_ball',
      matchId: 'm1',
      inningsNumber: 1,
      battingTeamId: 'team_a',
      bowlingTeamId: 'team_b',
      totalRuns: 190,
      wickets: 3,
      legalBalls: 119, // 19.5 overs
      oversStr: '19.5',
      extrasWides: 0,
      extrasNoBalls: 0,
      extrasByes: 0,
      extrasLegByes: 0,
      extrasPenalty: 0,
      totalExtras: 0,
      isCompleted: false,
      currentStrikerId: 'p1',
      currentNonStrikerId: 'p2',
      currentBowlerId: 'b1',
    };

    const result = processDelivery({
      innings: over19Point5Innings,
      strikerId: 'p1',
      nonStrikerId: 'p2',
      bowlerId: 'b1',
      runsBatter: 4,
      maxOvers: 20,
    });

    expect(result.updatedInnings.legalBalls).toBe(120);
    expect(result.updatedInnings.oversStr).toBe('20.0');
    expect(result.updatedInnings.totalRuns).toBe(194);
    expect(result.updatedInnings.isCompleted).toBe(true);
    expect(result.isOverComplete).toBe(true);
  });
});
