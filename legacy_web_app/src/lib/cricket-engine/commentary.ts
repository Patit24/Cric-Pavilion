// ====================================================================
// CRICKET COMMENTARY GENERATOR
// ====================================================================

import { DismissalType, ExtrasType } from '../types';

export function generateCommentaryLine(params: {
  bowlerName: string;
  strikerName: string;
  runs: number;
  extrasType?: ExtrasType | null;
  extrasRuns?: number;
  isWicket?: boolean;
  dismissalType?: DismissalType | null;
  assistName?: string;
}): string {
  const { bowlerName, strikerName, runs, extrasType, extrasRuns, isWicket, dismissalType, assistName } = params;

  if (extrasType === 'wide') {
    return `${bowlerName} sprays it wide down the leg side, umpire stretches arms. Wide called.`;
  }

  if (extrasType === 'no_ball') {
    return `${bowlerName} oversteps! Siren blares for the front-foot no-ball! Free hit coming up.`;
  }

  if (extrasType === 'bye') {
    return `${bowlerName} beats the bat! Ball sneaks past the keeper and batters scamper through for ${extrasRuns} bye(s).`;
  }

  if (extrasType === 'leg_bye') {
    return `Tucked off the pads towards the square leg region. ${extrasRuns} leg bye(s) added to the total.`;
  }

  if (isWicket) {
    switch (dismissalType) {
      case 'bowled':
        return `OUT! CLEAN BOWLED! ${bowlerName} bowls a peach of a delivery, breaches the defense and sends the middle stump cartwheeling! ${strikerName} has to walk back!`;
      case 'caught':
        return `OUT! CAUGHT! ${strikerName} looks for the big aerial shot, mistimes it, and ${assistName || 'the fielder'} settles underneath to take a calm, composed catch!`;
      case 'caught_bowled':
        return `OUT! CAUGHT AND BOWLED! Smashed back hard down the ground, but ${bowlerName} sticks out a hand and snatches a stunner! What reflexes!`;
      case 'lbw':
        return `OUT! LBW! Trapped right in front! ${bowlerName} hits the pads, loud appeal from all eleven fielders, and the umpire raises the dreaded finger!`;
      case 'stumped':
        return `OUT! STUMPED! ${strikerName} steps down the pitch to go big, beaten in flight, and the wicketkeeper whips off the bails in a flash!`;
      case 'run_out':
        return `OUT! RUN OUT! Chaos in the middle! Direct hit from ${assistName || 'the fielder'} and the batter is well short of the crease!`;
      case 'hit_wicket':
        return `OUT! HIT WICKET! ${strikerName} steps deep into the crease and accidentally dislodges the bails with the boot! Unbelievable way to get out!`;
      default:
        return `OUT! Wicket falls! ${strikerName} is dismissed!`;
    }
  }

  if (runs === 6) {
    return `SIX! BOOM! ${strikerName} rocks back and launches this high and handsome deep into the grandstand! Maximum!`;
  }

  if (runs === 4) {
    return `FOUR! Glorious stroke! Leans into the drive and threads the gap between cover and mid-off with laser precision to the boundary!`;
  }

  if (runs === 2) {
    return `Tucked away into the gap in the deep. Excellent running between the wickets, turning 1 into 2 easily.`;
  }

  if (runs === 1) {
    return `Pushed down to long-on for a brisk single. Strike rotated.`;
  }

  return `${bowlerName} bowls a tight, probing line on off stump. ${strikerName} defends solidly back down the pitch. No run.`;
}
