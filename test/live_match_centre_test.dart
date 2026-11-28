import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cricket_app/main.dart';
import 'package:cricket_app/models/models.dart';
import 'package:cricket_app/screens/matches/match_detail_screen.dart';
import 'package:cricket_app/services/database_persistence_service.dart';
import 'package:cricket_app/services/mock_database.dart';

void main() {
  group('Public Live Match Centre Tests', () {
    late MockDatabase db;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      DatabasePersistenceService.isPersistenceEnabled = false;
      db = MockDatabase(loadDemoSeed: false);
    });

    Widget wrapWithDb(Widget child) {
      return ChangeNotifierProvider<MockDatabase>.value(
        value: db,
        child: MaterialApp(home: child),
      );
    }

    test('extractPublicMatchId parses /match/{id}/live and query params', () {
      expect(CricPavilionApp.extractPublicMatchId('/match/match_abc_123/live'), 'match_abc_123');
      expect(CricPavilionApp.extractPublicMatchId('/match/match_abc_123'), 'match_abc_123');
      expect(CricPavilionApp.extractPublicMatchId('/?matchId=match_xyz'), 'match_xyz');
      expect(CricPavilionApp.extractPublicMatchId('/'), isNull);
    });

    testWidgets('Viewer sees read-only Live Match Centre with 5 tabs and zero scorer controls', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1200, 900);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Register players for Team A and Team B
      final pA1 = db.registerPermanentPlayer(fullName: 'Virat Tester', mobileNumber: '9000000001');
      final pA2 = db.registerPermanentPlayer(fullName: 'Rohit Tester', mobileNumber: '9000000002');
      final pB1 = db.registerPermanentPlayer(fullName: 'Bumrah Tester', mobileNumber: '9000000003');
      final pB2 = db.registerPermanentPlayer(fullName: 'Jadeja Tester', mobileNumber: '9000000004');

      // Scorer creates a match & records deliveries
      final match = db.createDirectMatch(
        matchName: 'Qualifier 1',
        teamAName: 'Royal Strikers',
        teamBName: 'Super Giants',
        overs: 10,
        venue: 'Eden Gardens',
        playingXIA: [pA1.id, pA2.id],
        playingXIB: [pB1.id, pB2.id],
        strikerId: pA1.id,
        nonStrikerId: pA2.id,
        bowlerId: pB1.id,
      );
      final inn1 = db.inningsList.firstWhere((i) => i.matchId == match.id && i.inningsNumber == 1);
      final batter1 = pA1;
      final bowler1 = pB1;

      // Record 4 runs, then 1 run, then a wide
      db.recordDelivery(inningsId: inn1.id, runsBatter: 4);
      db.recordDelivery(inningsId: inn1.id, runsBatter: 1);
      db.recordDelivery(inningsId: inn1.id, runsBatter: 0, extrasType: ExtrasType.wide, extrasRuns: 1);

      // Guest (unauthenticated) opens MatchDetailScreen
      expect(db.isAuthenticated, isFalse);

      await tester.pumpWidget(wrapWithDb(MatchDetailScreen(matchId: match.id)));
      await tester.pump(const Duration(milliseconds: 300));

      // 5 tabs present
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Scorecard'), findsOneWidget);
      expect(find.text('Commentary'), findsOneWidget);
      expect(find.text('Teams'), findsOneWidget);
      expect(find.text('Info'), findsOneWidget);

      // Strictly read-only: no scorer controls anywhere
      expect(find.textContaining('Open Scorer Console'), findsNothing);
      expect(find.text('Scorer Pad'), findsNothing);
      expect(find.text('End Innings'), findsNothing);

      // Live status & score shown
      expect(find.text('LIVE'), findsOneWidget);
      expect(find.text('Royal Strikers'), findsWidgets);
      expect(find.textContaining('6/0 (0.2)'), findsOneWidget);
      expect(find.textContaining(batter1.fullName), findsWidgets);
      expect(find.textContaining(bowler1.fullName), findsWidgets);

      // Live update: Scorer records a SIX -> viewer updates automatically
      db.recordDelivery(inningsId: inn1.id, runsBatter: 6);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('12/0 (0.3)'), findsOneWidget);

      // Commentary tab shows over grouping and SIX highlight
      await tester.tap(find.text('Commentary'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('OVER 1'), findsOneWidget);
      expect(find.text('SIX'), findsOneWidget);
      expect(find.text('FOUR'), findsOneWidget);

      // Scorecard tab shows batting, extras, bowling
      await tester.tap(find.text('Scorecard'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Extras'), findsWidgets);
      expect(find.textContaining('wd 1'), findsOneWidget);

      // Undo last delivery (SIX) -> score reverts automatically
      db.undoLastDelivery(inn1.id);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Overview'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('6/0 (0.2)'), findsOneWidget);

      // Completed match never displays LIVE
      match.status = MatchStatus.completed;
      match.winnerId = match.teamAId;
      match.winMargin = 'by 15 runs';
      db.notifyListeners();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('LIVE'), findsNothing);
      expect(find.text('COMPLETED'), findsOneWidget);
      expect(find.textContaining('Royal Strikers won by 15 runs'), findsOneWidget);
    });

    test('Man of the Match is automatically assigned when match ends & Google user profile is complete', () {
      final pA1 = db.registerPermanentPlayer(fullName: 'Star Batter', mobileNumber: '9000000011');
      final pA2 = db.registerPermanentPlayer(fullName: 'Partner Batter', mobileNumber: '9000000012');
      final pB1 = db.registerPermanentPlayer(fullName: 'Star Bowler', mobileNumber: '9000000013');
      final pB2 = db.registerPermanentPlayer(fullName: 'Other Bowler', mobileNumber: '9000000014');

      final match = db.createDirectMatch(
        matchName: 'Final',
        teamAName: 'Alpha XI',
        teamBName: 'Beta XI',
        overs: 5,
        venue: 'Wankhede',
        playingXIA: [pA1.id, pA2.id],
        playingXIB: [pB1.id, pB2.id],
        strikerId: pA1.id,
        nonStrikerId: pA2.id,
        bowlerId: pB1.id,
      );
      final inn1 = db.inningsList.firstWhere((i) => i.matchId == match.id && i.inningsNumber == 1);
      db.recordDelivery(inningsId: inn1.id, runsBatter: 6);
      db.recordDelivery(inningsId: inn1.id, runsBatter: 6);
      db.endInningsEarly(inn1.id);

      final inn2 = db.inningsList.firstWhere((i) => i.matchId == match.id && i.inningsNumber == 2);
      db.endInningsEarly(inn2.id);

      expect(match.status, MatchStatus.completed);
      expect(match.playerOfTheMatchId, pA1.id);
      expect(match.playerOfTheMatchName, 'Star Batter');

      final gUser = db.signInWithGoogle(email: 'google.persist@gmail.com', displayName: 'Google Persist');
      expect(gUser.isProfileComplete, isTrue);
    });
  });
}
