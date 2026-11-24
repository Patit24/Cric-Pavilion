import 'package:flutter_test/flutter_test.dart';
import 'package:cricket_app/models/models.dart';
import 'package:cricket_app/services/mock_database.dart';
import 'package:cricket_app/services/cricket_rules_engine.dart';

void main() {
  group('Quick Match, Crease Lineup & Wicket Analysis Tests', () {
    late MockDatabase db;

    setUp(() {
      db = MockDatabase();
    });

    test('1. Direct Quick Match creation supports custom opening crease lineup', () {
      final p1 = db.registerPermanentPlayer(fullName: 'Rohit Sharma', mobileNumber: '9876543210', role: PlayerRole.batsman);
      final p2 = db.registerPermanentPlayer(fullName: 'KL Rahul', mobileNumber: '9876543211', role: PlayerRole.batsman);
      final p3 = db.registerPermanentPlayer(fullName: 'Virat Kohli', mobileNumber: '9876543212', role: PlayerRole.batsman);

      final p4 = db.registerPermanentPlayer(fullName: 'Mitchell Starc', mobileNumber: '9876543213', role: PlayerRole.bowler);
      final p5 = db.registerPermanentPlayer(fullName: 'Pat Cummins', mobileNumber: '9876543214', role: PlayerRole.bowler);

      final match = db.createDirectMatch(
        matchName: 'Ind vs Aus Quick Derby',
        teamAName: 'India',
        teamBName: 'Australia',
        overs: 5,
        venue: 'MCG',
        tossWonBy: 'team_direct_a',
        tossDecision: 'bat',
        playingXIA: [p1.id, p2.id, p3.id],
        playingXIB: [p4.id, p5.id],
        strikerId: p1.id,
        nonStrikerId: p2.id,
        bowlerId: p4.id,
      );

      expect(match.status, MatchStatus.live);
      final inn1 = db.inningsList.firstWhere((i) => i.matchId == match.id && i.inningsNumber == 1);
      expect(inn1.currentStrikerId, p1.id);
      expect(inn1.currentNonStrikerId, p2.id);
      expect(inn1.currentBowlerId, p4.id);
    });

    test('2. Over completion clears currentBowlerId and ICC Law 17.8 validates next bowler', () {
      final p1 = db.registerPermanentPlayer(fullName: 'Batter One', mobileNumber: '9111111111', role: PlayerRole.batsman);
      final p2 = db.registerPermanentPlayer(fullName: 'Batter Two', mobileNumber: '9111111112', role: PlayerRole.batsman);
      final b1 = db.registerPermanentPlayer(fullName: 'Bowler Fast', mobileNumber: '9111111113', role: PlayerRole.bowler);
      final b2 = db.registerPermanentPlayer(fullName: 'Bowler Spin', mobileNumber: '9111111114', role: PlayerRole.bowler);

      final match = db.createDirectMatch(
        matchName: 'Over Completion Test',
        teamAName: 'Team Bat',
        teamBName: 'Team Bowl',
        overs: 2,
        venue: 'Eden Gardens',
        playingXIA: [p1.id, p2.id],
        playingXIB: [b1.id, b2.id],
        strikerId: p1.id,
        nonStrikerId: p2.id,
        bowlerId: b1.id,
      );

      final inn1 = db.inningsList.firstWhere((i) => i.matchId == match.id && i.inningsNumber == 1);

      // Bowl 5 legal deliveries
      for (int i = 0; i < 5; i++) {
        db.recordDelivery(inningsId: inn1.id, runsBatter: 1);
        expect(inn1.currentBowlerId, b1.id);
      }

      // 6th legal delivery completes the over
      db.recordDelivery(inningsId: inn1.id, runsBatter: 0);
      expect(inn1.legalBalls, 6);
      // Bowler is reset to null to mandate next bowler selection
      expect(inn1.currentBowlerId, isNull);

      // Validate ICC Law 17.8: b1 cannot bowl consecutive over
      final checkB1 = CricketRulesEngine.validateBowler(
        bowlerId: b1.id,
        previousOverBowlerId: b1.id,
        deliveries: db.deliveries,
        inningsId: inn1.id,
        maxOversPerBowler: 4,
      );
      expect(checkB1.isEligible, isFalse);
      expect(checkB1.reason, contains('Law 17.8'));

      // b2 is eligible
      final checkB2 = CricketRulesEngine.validateBowler(
        bowlerId: b2.id,
        previousOverBowlerId: b1.id,
        deliveries: db.deliveries,
        inningsId: inn1.id,
        maxOversPerBowler: 4,
      );
      expect(checkB2.isEligible, isTrue);

      // Set b2 as new bowler
      db.setBowler(inn1.id, b2.id);
      expect(inn1.currentBowlerId, b2.id);
    });

    test('3. Wicket dismissal analysis produces standard cricket notation', () {
      final batter = db.registerPermanentPlayer(fullName: 'Shubman Gill', mobileNumber: '9222222221', role: PlayerRole.batsman);
      final nonStriker = db.registerPermanentPlayer(fullName: 'Yashasvi Jaiswal', mobileNumber: '9222222222', role: PlayerRole.batsman);
      final nextBatter = db.registerPermanentPlayer(fullName: 'Sanju Samson', mobileNumber: '9222222223', role: PlayerRole.batsman);
      final bowler = db.registerPermanentPlayer(fullName: 'Jasprit Bumrah', mobileNumber: '9222222224', role: PlayerRole.bowler);
      final fielder = db.registerPermanentPlayer(fullName: 'Ravindra Jadeja', mobileNumber: '9222222225', role: PlayerRole.allRounder);

      final match = db.createDirectMatch(
        matchName: 'Wicket Analysis Test',
        teamAName: 'Warriors',
        teamBName: 'Titans',
        overs: 2,
        venue: 'Ahmedabad',
        playingXIA: [batter.id, nonStriker.id, nextBatter.id],
        playingXIB: [bowler.id, fielder.id],
        strikerId: batter.id,
        nonStrikerId: nonStriker.id,
        bowlerId: bowler.id,
      );

      final inn1 = db.inningsList.firstWhere((i) => i.matchId == match.id && i.inningsNumber == 1);

      // Record a caught dismissal
      db.recordDelivery(
        inningsId: inn1.id,
        runsBatter: 0,
        isWicket: true,
        dismissalType: DismissalType.caught,
        dismissedPlayerId: batter.id,
        fielderId: fielder.id,
        nextBatterId: nextBatter.id,
      );

      expect(inn1.wickets, 1);
      expect(inn1.currentStrikerId, nextBatter.id);

      final outCard = db.battingScorecards.firstWhere((b) => b.inningsId == inn1.id && b.playerId == batter.id);
      expect(outCard.isOut, isTrue);
      expect(outCard.dismissalText, 'c Ravindra Jadeja b Jasprit Bumrah');

      final bowlerCard = db.bowlingScorecards.firstWhere((b) => b.inningsId == inn1.id && b.playerId == bowler.id);
      expect(bowlerCard.wickets, 1);
    });

    test('4. Innings 2 start supports explicit crease selection (striker, non-striker, bowler)', () {
      final pA1 = db.registerPermanentPlayer(fullName: 'Team A Batter 1', mobileNumber: '9333333331', role: PlayerRole.batsman);
      final pA2 = db.registerPermanentPlayer(fullName: 'Team A Batter 2', mobileNumber: '9333333332', role: PlayerRole.batsman);
      final pB1 = db.registerPermanentPlayer(fullName: 'Team B Chase Striker', mobileNumber: '9333333333', role: PlayerRole.batsman);
      final pB2 = db.registerPermanentPlayer(fullName: 'Team B Chase Non-Striker', mobileNumber: '9333333334', role: PlayerRole.batsman);
      final paBowler = db.registerPermanentPlayer(fullName: 'Team A Opening Bowler', mobileNumber: '9333333335', role: PlayerRole.bowler);

      final match = db.createDirectMatch(
        matchName: 'Innings 2 Chase Test',
        teamAName: 'Team A',
        teamBName: 'Team B',
        overs: 1,
        venue: 'Wankhede',
        playingXIA: [pA1.id, pA2.id, paBowler.id],
        playingXIB: [pB1.id, pB2.id],
      );

      // End Innings 1 and start Innings 2
      final inn2 = db.startInnings2(
        matchId: match.id,
        strikerId: pB1.id,
        nonStrikerId: pB2.id,
        bowlerId: paBowler.id,
      );

      expect(inn2.inningsNumber, 2);
      expect(inn2.currentStrikerId, pB1.id);
      expect(inn2.currentNonStrikerId, pB2.id);
      expect(inn2.currentBowlerId, paBowler.id);
      expect(match.currentInningsNumber, 2);
    });
  });
}
