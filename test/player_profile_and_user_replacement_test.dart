import 'package:flutter_test/flutter_test.dart';
import 'package:cricket_app/models/models.dart';
import 'package:cricket_app/services/mock_database.dart';

void main() {
  group('Authenticated User Player Profile & Stats Replacement Tests', () {
    late MockDatabase db;

    setUp(() {
      db = MockDatabase(loadDemoSeed: false);
    });

    test('1. Unauthenticated guest: isAuthenticated is false and currentPlayer is null', () {
      expect(db.isAuthenticated, isFalse);
      expect(db.currentUser, isNull);
      expect(db.currentPlayer, isNull);
    });

    test('2. Authenticated user with existing registered player matches and returns player profile', () {
      // 1. Existing player in tournament/team
      final player = db.registerPermanentPlayer(
        fullName: 'Shubman Gill',
        mobileNumber: '9830219911',
        role: PlayerRole.batsman,
        battingStyle: 'Right Hand Bat',
        bowlingStyle: 'Right Arm Off Break',
      );

      // 2. User registers and logs in with same mobile
      db.registerUser(
        fullName: 'Shubman Gill',
        email: 'shubman@cricket.in',
        mobileNumber: '9830219911',
        password: 'pass123',
      );

      expect(db.isAuthenticated, isTrue);
      final myPlayer = db.currentPlayer;
      expect(myPlayer, isNotNull);
      expect(myPlayer?.id, equals(player.id));
      expect(myPlayer?.fullName, equals('Shubman Gill'));
      expect(myPlayer?.permanentPlayerCode, startsWith('PLY-'));
    });

    test('3. Authenticated user without pre-existing player profile gets auto-provisioned identity', () {
      // User registers new account
      db.registerUser(
        fullName: 'New Player Star',
        email: 'star@cricket.in',
        mobileNumber: '9830198888',
        password: 'pass123',
      );

      expect(db.isAuthenticated, isTrue);
      final myPlayer = db.currentPlayer;
      expect(myPlayer, isNotNull);
      expect(myPlayer?.fullName, equals('New Player Star'));
      expect(myPlayer?.permanentPlayerCode, startsWith('PLY-'));
      expect(db.currentUser?.linkedPlayerId, equals(myPlayer?.id));

      // Subsequent access returns the same player record
      final myPlayerAgain = db.currentPlayer;
      expect(myPlayerAgain?.id, equals(myPlayer?.id));
    });

    test('4. Player Career Stats & Match Performance Logs are computed accurately', () {
      db.registerPermanentPlayer(
        fullName: 'Rishabh Pant',
        mobileNumber: '9830219922',
        role: PlayerRole.wicketKeeper,
      );

      db.registerUser(
        fullName: 'Rishabh Pant',
        email: 'pant@cricket.in',
        mobileNumber: '9830219922',
        password: 'pass123',
      );

      final myPlayer = db.currentPlayer!;

      // Simulate match stats
      myPlayer.runs = 180;
      myPlayer.matches = 4;
      myPlayer.wickets = 0;

      final stats = db.getPlayerCareerStats(myPlayer.id);
      expect(stats.playerId, equals(myPlayer.id));
      expect(stats.runs, equals(180));
      expect(stats.matches, equals(4));
    });

    test('5. Player Directory search filters by Name, PLY code, and Mobile Number', () {
      final p1 = db.registerPermanentPlayer(
        fullName: 'Jasprit Bumrah',
        mobileNumber: '9830219933',
        role: PlayerRole.bowler,
      );
      final p2 = db.registerPermanentPlayer(
        fullName: 'Mohammed Siraj',
        mobileNumber: '9830219944',
        role: PlayerRole.bowler,
      );

      // Search by name
      final byName = db.players.where((p) => p.fullName.toLowerCase().contains('bumrah')).toList();
      expect(byName.length, equals(1));
      expect(byName.first.id, equals(p1.id));

      // Search by permanent code
      final codeQuery = p2.permanentPlayerCode.toLowerCase();
      final byCode = db.players.where((p) => p.permanentPlayerCode.toLowerCase().contains(codeQuery)).toList();
      expect(byCode.length, equals(1));
      expect(byCode.first.id, equals(p2.id));

      // Search by mobile
      final byMobile = db.players.where((p) => p.mobileNumber.contains('9830219933')).toList();
      expect(byMobile.length, equals(1));
      expect(byMobile.first.id, equals(p1.id));
    });
  });
}
