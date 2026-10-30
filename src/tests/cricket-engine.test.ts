import { describe, it, expect } from 'vitest';
import { isDeliveryLegal, isBowlerWicket, formatOvers, processDelivery } from '../lib/cricket-engine/rules';
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
