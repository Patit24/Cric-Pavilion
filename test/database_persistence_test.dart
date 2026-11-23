import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cricket_app/models/models.dart';
import 'package:cricket_app/services/mock_database.dart';
import 'package:cricket_app/services/database_persistence_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Database Permanent Persistence Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      DatabasePersistenceService.isPersistenceEnabled = true;
    });

    test('1. Every match result and score is permanently saved and restored across database restarts', () async {
      final db1 = MockDatabase(loadDemoSeed: false);

      // Create players
      final p1 = db1.registerPermanentPlayer(fullName: 'Rohit Star', mobileNumber: '9830111111');
      final p2 = db1.registerPermanentPlayer(fullName: 'Jasprit Pace', mobileNumber: '9830122222', role: PlayerRole.bowler);

      // Create direct match
      final match = db1.createDirectMatch(
        matchName: 'Final Trophy 2026',
        teamAName: 'Titans',
        teamBName: 'Royals',
        overs: 2,
        venue: 'Eden Gardens',
        playingXIA: [p1.id],
        playingXIB: [p2.id],
        tossWonBy: 'team_direct_a',
        tossDecision: 'bat',
      );

      // Record innings and deliveries
      final inn1 = db1.inningsList.firstWhere((i) => i.matchId == match.id);
      db1.recordDelivery(inningsId: inn1.id, runsBatter: 6, extrasRuns: 0);
      db1.recordDelivery(inningsId: inn1.id, runsBatter: 4, extrasRuns: 0);

      // Complete match
      match.status = MatchStatus.completed;
      match.winnerId = match.teamAId;
      match.winMargin = 'Titans won by 10 runs';

      // Explicitly persist
      await db1.persistState();

      // Simulate complete app restart / reload with a fresh brand-new MockDatabase instance
      final db2 = MockDatabase(loadDemoSeed: false);
      expect(db2.matches.isEmpty, isTrue);

      // Restore from permanent storage
      final loaded = await DatabasePersistenceService.loadDatabase(db2);
      expect(loaded, isTrue);

      // Verify match results are restored permanently
      expect(db2.matches.length, equals(1));
      final restoredMatch = db2.matches.first;
      expect(restoredMatch.id, equals(match.id));
      expect(restoredMatch.stage, equals('Final Trophy 2026'));
      expect(restoredMatch.status, equals(MatchStatus.completed));
      expect(restoredMatch.winMargin, equals('Titans won by 10 runs'));

      // Verify deliveries and batting scorecards are restored
      expect(db2.deliveries.length, equals(2));
      final restoredScorecard = db2.battingScorecards.where((b) => b.matchId == match.id && b.playerId == p1.id).firstOrNull;
      expect(restoredScorecard, isNotNull);
      expect(restoredScorecard?.runs, equals(10));
      expect(restoredScorecard?.sixes, equals(1));
      expect(restoredScorecard?.fours, equals(1));
    });

    test('2. User accounts, verified mobile numbers, and linked player identities are permanently saved', () async {
      final db1 = MockDatabase(loadDemoSeed: false);

      // Register player
      final player = db1.registerPermanentPlayer(
        fullName: 'Patit Roy',
        mobileNumber: '9014842370',
        role: PlayerRole.allRounder,
      );

      // Register user
      db1.registerUser(
        fullName: 'Patit Roy',
        email: 'patitroy29@gmail.com',
        mobileNumber: '9014842370',
        password: 'securePassword123',
      );

      // Verify mobile with OTP
      final verified = db1.verifyUserMobileOtp(mobileNumber: '9014842370', otp: '123456');
      expect(verified, isTrue);
      expect(db1.currentUser?.isMobileVerified, isTrue);
      expect(db1.currentUser?.linkedPlayerId, equals(player.id));

      // Persist to storage
      await db1.persistState();

      // Simulate app restart / browser reload
      final db2 = MockDatabase(loadDemoSeed: false);
      expect(db2.users.isEmpty, isTrue);
      expect(db2.currentUser, isNull);

      // Restore from storage
      final loaded = await DatabasePersistenceService.loadDatabase(db2);
      expect(loaded, isTrue);

      // Verify user accounts restored
      expect(db2.users.length, equals(1));
      final restoredUser = db2.users.first;
      expect(restoredUser.fullName, equals('Patit Roy'));
      expect(restoredUser.email, equals('patitroy29@gmail.com'));
      expect(restoredUser.mobileNumber, equals('9014842370'));
      expect(restoredUser.isMobileVerified, isTrue);
      expect(restoredUser.linkedPlayerId, equals(player.id));

      // Verify current user session restored
      expect(db2.currentUser, isNotNull);
      expect(db2.currentUser?.email, equals('patitroy29@gmail.com'));

      // Verify player identity restored
      expect(db2.players.length, equals(1));
      expect(db2.currentPlayer?.id, equals(player.id));
      expect(db2.currentPlayer?.permanentPlayerCode, startsWith('PLY-'));
    });
  });
}
