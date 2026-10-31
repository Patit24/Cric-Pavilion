// ====================================================================
// NET RUN RATE (NRR) ENGINE (OFFICIAL ICC / BCCI RULES)
// ====================================================================

export interface InningsNrrData {
  runs: number;
  legalBalls: number;
  isAllOut: boolean;
  maxOversForInnings: number;
}

export interface MatchNrrData {
  matchStatus: 'completed' | 'tied' | 'abandoned';
  teamBatted: InningsNrrData;
  teamBowled: InningsNrrData;
}

/**
 * Converts balls to decimal overs according to ICC rules:
 * Completed overs + (remaining balls / 6.0)
 * Note: If team was all out, the quota is full max overs!
 */
export function getOversForNrr(innings: InningsNrrData): number {
  if (innings.isAllOut) {
    return innings.maxOversForInnings;
  }
  const completedOvers = Math.floor(innings.legalBalls / 6);
  const remainingBalls = innings.legalBalls % 6;
  return completedOvers + remainingBalls / 6.0;
}

/**
 * Calculates aggregate Net Run Rate across tournament matches for a team
 */
export function calculateNetRunRate(matches: MatchNrrData[]): number {
  let totalRunsFor = 0;
  let totalOversFor = 0;
  let totalRunsAgainst = 0;
  let totalOversAgainst = 0;

  for (const m of matches) {
    // Only completed or tied matches contribute to NRR
    if (m.matchStatus !== 'completed' && m.matchStatus !== 'tied') {
      continue;
    }

    totalRunsFor += m.teamBatted.runs;
    totalOversFor += getOversForNrr(m.teamBatted);

    totalRunsAgainst += m.teamBowled.runs;
    totalOversAgainst += getOversForNrr(m.teamBowled);
  }

  if (totalOversFor === 0 || totalOversAgainst === 0) {
    return 0.0;
  }

  const runRateFor = totalRunsFor / totalOversFor;
  const runRateAgainst = totalRunsAgainst / totalOversAgainst;
  const nrr = runRateFor - runRateAgainst;

  // Standard 3 decimal precision
  return Math.round(nrr * 1000) / 1000;
}
