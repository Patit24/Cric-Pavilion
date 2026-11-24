import 'package:flutter_test/flutter_test.dart';
import 'package:cricket_app/models/models.dart';
import 'package:cricket_app/services/mock_database.dart';

void main() {
  group('Extras (No-Ball / Wide runs) and Batter Retirement Tests', () {
    test('1. No-Ball with batsman boundary (1nb + 4): 5 runs total, 4 to batter, 1 to extras, legal balls unchanged', () {
      final db = MockDatabase(loadDemoSeed: true);
      final inn = db.inningsList.firstWhere((i) => i.id == 'inn_1');
      final initialRuns = inn.totalRuns;
      final initialLegalBalls = inn.legalBalls;
      final initialExtrasNb = inn.extrasNoBalls;
      final strikerId = inn.currentStrikerId!;
      final bowlerId = inn.currentBowlerId!;

      final strikerCardBefore = db.battingScorecards.firstWhere((b) => b.inningsId == inn.id && b.playerId == strikerId);
      final bowlerCardBefore = db.bowlingScorecards.firstWhere((b) => b.inningsId == inn.id && b.playerId == bowlerId);
      final initialBatterRuns = strikerCardBefore.runs;
      final initialBowlerRunsConceded = bowlerCardBefore.runsConceded;

      // Delivery: No-ball (1 run extra) + 4 runs off the bat
      db.recordDelivery(
        inningsId: inn.id,
        runsBatter: 4,
        extrasRuns: 1,
        extrasType: ExtrasType.noBall,
      );

      expect(inn.totalRuns, initialRuns + 5);
      expect(inn.legalBalls, initialLegalBalls, reason: 'No-ball does not count as a legal ball');
      expect(inn.extrasNoBalls, initialExtrasNb + 1);

      final strikerCardAfter = db.battingScorecards.firstWhere((b) => b.inningsId == inn.id && b.playerId == strikerId);
      final bowlerCardAfter = db.bowlingScorecards.firstWhere((b) => b.inningsId == inn.id && b.playerId == bowlerId);

      expect(strikerCardAfter.runs, initialBatterRuns + 4, reason: 'Batter is credited with boundary runs scored');
      expect(bowlerCardAfter.runsConceded, initialBowlerRunsConceded + 5, reason: 'Bowler is charged both no-ball extra and batter runs');
    });

    test('2. Wide ball with extra runs (1wd + 2 ran runs = 3 runs): charged to bowler, 0 legal balls', () {
      final db = MockDatabase(loadDemoSeed: true);
      final inn = db.inningsList.firstWhere((i) => i.id == 'inn_1');
      final initialRuns = inn.totalRuns;
      final initialLegalBalls = inn.legalBalls;
      final initialWides = inn.extrasWides;

      // Delivery: Wide with 2 additional overthrows/runs = 3 runs total
      db.recordDelivery(
        inningsId: inn.id,
        runsBatter: 0,
        extrasRuns: 3,
        extrasType: ExtrasType.wide,
      );

      expect(inn.totalRuns, initialRuns + 3);
      expect(inn.legalBalls, initialLegalBalls, reason: 'Wide ball does not count as a legal ball');
      expect(inn.extrasWides, initialWides + 3);
    });

    test('3. Retired Hurt: player marked not out, wickets count unchanged, ball is not counted, replacement takes crease', () {
      final db = MockDatabase(loadDemoSeed: true);
      final inn = db.inningsList.firstWhere((i) => i.id == 'inn_1');
      final initialWickets = inn.wickets;
      final initialLegalBalls = inn.legalBalls;
      final retiringStrikerId = inn.currentStrikerId!;
      const replacementId = 'pl_5';

      db.retireBatter(
        inningsId: inn.id,
        retiringPlayerId: retiringStrikerId,
        isHurt: true, // Retired Hurt (Injured)
        replacementPlayerId: replacementId,
      );

      // Wickets and legal balls must NOT change
      expect(inn.wickets, initialWickets, reason: 'Retired Hurt does not increment wickets');
      expect(inn.legalBalls, initialLegalBalls, reason: 'Retiring a batter does not consume a delivery ball');
      expect(inn.currentStrikerId, replacementId, reason: 'Replacement player immediately takes striker spot at crease');

      final card = db.battingScorecards.firstWhere((b) => b.inningsId == inn.id && b.playerId == retiringStrikerId);
      expect(card.isOut, isFalse, reason: 'Retired hurt player remains NOT OUT');
      expect(card.dismissalText, 'retired hurt');
    });

    test('4. Retired Out: player marked dismissed, wickets count increments, ball is not counted, replacement takes crease', () {
      final db = MockDatabase(loadDemoSeed: true);
      final inn = db.inningsList.firstWhere((i) => i.id == 'inn_1');
      final initialWickets = inn.wickets;
      final initialLegalBalls = inn.legalBalls;
      final retiringNonStrikerId = inn.currentNonStrikerId!;
      const replacementId = 'pl_5';

      db.retireBatter(
        inningsId: inn.id,
        retiringPlayerId: retiringNonStrikerId,
        isHurt: false, // Retired Out
        replacementPlayerId: replacementId,
      );

      expect(inn.wickets, initialWickets + 1, reason: 'Retired Out increments wickets count');
      expect(inn.legalBalls, initialLegalBalls, reason: 'Retiring out does not consume a delivery ball');
      expect(inn.currentNonStrikerId, replacementId, reason: 'Replacement player takes non-striker position');

      final card = db.battingScorecards.firstWhere((b) => b.inningsId == inn.id && b.playerId == retiringNonStrikerId);
      expect(card.isOut, isTrue, reason: 'Retired out player is marked OUT');
      expect(card.dismissalText, 'retired out');
    });

    test('5. Innings 1 Completion and Innings 2 explicit Crease Lineup selection', () {
      final db = MockDatabase(loadDemoSeed: true);
      final match = db.matches.firstWhere((m) => m.id == 'match_1');
      final inn1 = db.inningsList.firstWhere((i) => i.id == 'inn_1');

      // Complete Innings 1
      db.endInningsEarly(inn1.id);
      expect(inn1.isCompleted, isTrue);

      // Start Innings 2 with explicit custom lineup selection (not random/auto-assigned)
      const selectedStriker = 'pl_kol_1';
      const selectedNonStriker = 'pl_kol_2';
      const selectedBowler = 'pl_bar_bowler';

      final inn2 = db.startInnings2(
        matchId: match.id,
        strikerId: selectedStriker,
        nonStrikerId: selectedNonStriker,
        bowlerId: selectedBowler,
      );

      expect(inn2.inningsNumber, 2);
      expect(inn2.currentStrikerId, selectedStriker);
      expect(inn2.currentNonStrikerId, selectedNonStriker);
      expect(inn2.currentBowlerId, selectedBowler);
      expect(inn2.targetRuns, inn1.totalRuns + 1);
      expect(match.currentInningsNumber, 2);
    });
  });
}
