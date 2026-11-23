import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cricket_app/models/models.dart';
import 'package:cricket_app/services/mock_database.dart';
import 'package:cricket_app/widgets/add_existing_player_dialog.dart';

void main() {
  group('Player Identity, Mobile Lookup & Direct Match Integration Tests', () {
    late MockDatabase db;

    setUp(() {
      // Start with clean database
      db = MockDatabase(loadDemoSeed: false);
    });

    test('1. Mobile Normalization handles raw formats consistently', () {
      expect(MockDatabase.normalizeMobile('9830112233'), equals('9830112233'));
      expect(MockDatabase.normalizeMobile('+91 98301 12233'), equals('9830112233'));
      expect(MockDatabase.normalizeMobile('09830112233'), equals('9830112233'));
      expect(MockDatabase.normalizeMobile('+91-98301-12233'), equals('9830112233'));
    });

    test('2. Permanent Player Registration generates unique PLY code & preserves record', () {
      final player1 = db.registerPermanentPlayer(
        fullName: 'Virat Kohli',
        mobileNumber: '+91 98301 00001',
        role: PlayerRole.batsman,
        battingStyle: 'Right Hand Bat',
        bowlingStyle: 'Right Arm Medium',
      );

      expect(player1.id, isNotEmpty);
      expect(player1.permanentPlayerCode, startsWith('PLY-'));
      expect(player1.fullName, equals('Virat Kohli'));
      expect(player1.mobileNumber, equals('9830100001'));
      expect(player1.isMobileVerified, isTrue);

      // Register second player
      final player2 = db.registerPermanentPlayer(
        fullName: 'Jasprit Bumrah',
        mobileNumber: '9830100002',
        role: PlayerRole.bowler,
      );

      expect(player2.id, isNot(equals(player1.id)));
      expect(player2.permanentPlayerCode, isNot(equals(player1.permanentPlayerCode)));
      expect(db.players.length, equals(2));
    });

    test('3. Mobile Number Lookup finds existing player profile', () {
      db.registerPermanentPlayer(
        fullName: 'Rohit Sharma',
        mobileNumber: '9830100003',
        role: PlayerRole.batsman,
      );

      // Lookup with different formats of same number
      final lookup1 = db.lookupPlayerByMobile('9830100003');
      expect(lookup1.isFound, isTrue);
      expect(lookup1.player?.fullName, equals('Rohit Sharma'));
      expect(lookup1.player?.permanentPlayerCode, startsWith('PLY-'));

      final lookupFormatted = db.lookupPlayerByMobile('+91 98301 00003');
      expect(lookupFormatted.isFound, isTrue);
      expect(lookupFormatted.player?.fullName, equals('Rohit Sharma'));

      // Lookup unknown number returns not found
      final unknownLookup = db.lookupPlayerByMobile('9999999999');
      expect(unknownLookup.isFound, isFalse);
      expect(unknownLookup.player, isNull);
    });

    test('4. Add Existing Player to Team prevents duplicate squad addition and tournament conflicts', () {
      final teamA = Team(
        id: 'team_a',
        tournamentId: 'tourn_ipl',
        name: 'Mumbai Indians',
        shortName: 'MI',
        primaryColor: const Color(0xFF004BA0),
        logoUrl: '',
        purseRemaining: 10000000,
        maxPurse: 10000000,
        squadCount: 0,
      );
      final teamB = Team(
        id: 'team_b',
        tournamentId: 'tourn_ipl',
        name: 'Chennai Super Kings',
        shortName: 'CSK',
        primaryColor: const Color(0xFFFDB913),
        logoUrl: '',
        purseRemaining: 10000000,
        maxPurse: 10000000,
        squadCount: 0,
      );
      db.teams.addAll([teamA, teamB]);

      // Register player
      final p = db.registerPermanentPlayer(
        fullName: 'Hardik Pandya',
        mobileNumber: '9830100004',
        role: PlayerRole.allRounder,
      );

      // 1. Add to Team A succeeds
      final addRes1 = db.addPlayerToTeamByMobile(
        teamId: 'team_a',
        mobileNumber: '9830100004',
        tournamentId: 'tourn_ipl',
      );
      expect(addRes1['success'], isTrue);
      expect(p.teamId, equals('team_a'));
      expect(p.teamHistory.length, equals(1));
      expect(p.teamHistory.first.teamName, equals('Mumbai Indians'));

      // 2. Add same player again to Team A fails with duplicate warning
      final addDup = db.addPlayerToTeamByMobile(
        teamId: 'team_a',
        mobileNumber: '9830100004',
        tournamentId: 'tourn_ipl',
      );
      expect(addDup['success'], isFalse);
      expect(addDup['message'], contains('already in this team squad'));

      // 3. Add to conflicting Team B in same tournament fails with tournament conflict warning
      final addConflict = db.addPlayerToTeamByMobile(
        teamId: 'team_b',
        mobileNumber: '9830100004',
        tournamentId: 'tourn_ipl',
      );
      expect(addConflict['success'], isFalse);
      expect(addConflict['message'], contains('already registered with Mumbai Indians in this tournament'));
    });

    test('5. User Registration & Mobile OTP links player identity', () {
      // 1. Organizer registers a player with phone 9830100005
      final player = db.registerPermanentPlayer(
        fullName: 'KL Rahul',
        mobileNumber: '9830100005',
        role: PlayerRole.wicketKeeper,
      );

      // 2. User registers account with email
      db.registerUser(
        fullName: 'KL Rahul',
        email: 'kl@cricket.in',
        mobileNumber: '',
        password: 'password123',
      );
      expect(db.currentUser, isNotNull);
      expect(db.currentUser?.isMobileVerified, isFalse);
      expect(db.currentUser?.linkedPlayerId, isNull);

      // 3. User verifies mobile with OTP
      final verified = db.verifyUserMobileOtp(mobileNumber: '9830100005', otp: '123456');
      expect(verified, isTrue);
      expect(db.currentUser?.isMobileVerified, isTrue);
      expect(db.currentUser?.linkedPlayerId, equals(player.id));
    });

    test('6. Create Direct 2-Team Match works without a tournament and records live scoring', () {
      final pA1 = db.registerPermanentPlayer(fullName: 'Batter 1', mobileNumber: '9830100011');
      final pA2 = db.registerPermanentPlayer(fullName: 'Batter 2', mobileNumber: '9830100012');
      final pB1 = db.registerPermanentPlayer(fullName: 'Bowler 1', mobileNumber: '9830100021', role: PlayerRole.bowler);
      final pB2 = db.registerPermanentPlayer(fullName: 'Bowler 2', mobileNumber: '9830100022', role: PlayerRole.bowler);

      final match = db.createDirectMatch(
        matchName: 'Weekend Super Cup',
        teamAName: 'Thunder Bolts',
        teamBName: 'Fire Hawks',
        overs: 5,
        venue: 'Kolkata Stadium',
        playingXIA: [pA1.id, pA2.id],
        playingXIB: [pB1.id, pB2.id],
        captainAId: pA1.id,
        captainBId: pB1.id,
        tossWonBy: 'team_direct_a',
        tossDecision: 'bat',
      );

      expect(match.isStandalone, isTrue);
      expect(match.tournamentId, equals('standalone'));
      expect(match.status, equals(MatchStatus.live));

      final inn1 = db.inningsList.where((i) => i.matchId == match.id && i.inningsNumber == 1).first;
      expect(inn1.battingTeamId, equals(match.teamAId));

      // Record deliveries
      db.recordDelivery(
        inningsId: inn1.id,
        runsBatter: 4,
        extrasRuns: 0,
      );
      db.recordDelivery(
        inningsId: inn1.id,
        runsBatter: 6,
        extrasRuns: 0,
      );

      expect(inn1.totalRuns, equals(10));
      expect(inn1.legalBalls, equals(2));

      // Verify Batter 1 scorecard
      final bCard = db.battingScorecards.where((b) => b.matchId == match.id && b.playerId == pA1.id).first;
      expect(bCard.runs, equals(10));
      expect(bCard.fours, equals(1));
      expect(bCard.sixes, equals(1));

      // Verify career stats calculation
      final stats = db.getPlayerCareerStats(pA1.id);
      expect(stats.matches, equals(1));
      expect(stats.runs, equals(10));
      expect(stats.fours, equals(1));
      expect(stats.sixes, equals(1));
      expect(stats.highestScore, equals(10));
      expect(stats.battingStrikeRate, equals(500.0)); // 10 runs in 2 balls = 500 SR
    });

    test('7. Completed Match is permanent and appears in completedMatches list', () {
      final pA1 = db.registerPermanentPlayer(fullName: 'Striker A', mobileNumber: '9830100031');
      final pB1 = db.registerPermanentPlayer(fullName: 'Bowler B', mobileNumber: '9830100032', role: PlayerRole.bowler);

      final match = db.createDirectMatch(
        matchName: 'Final Derby',
        teamAName: 'Team Alpha',
        teamBName: 'Team Beta',
        overs: 1,
        venue: 'Eden Gardens',
        playingXIA: [pA1.id],
        playingXIB: [pB1.id],
      );

      expect(db.completedMatches.length, equals(0));

      // Complete the match
      match.status = MatchStatus.completed;
      match.winnerId = match.teamAId;
      match.winMargin = 'Team Alpha won by 15 runs';

      expect(db.completedMatches.length, equals(1));
      expect(db.completedMatches.first.id, equals(match.id));
      expect(db.completedMatches.first.winMargin, equals('Team Alpha won by 15 runs'));

      // Match logs for player reflect the match and win
      final logs = db.getPlayerMatchLogs(pA1.id);
      expect(logs.length, equals(1));
      expect(logs.first.matchName, equals('Final Derby'));
      expect(logs.first.isWin, isTrue);
    });

    test('8. Automatic registration for unregistered player & auto-linking for registered player', () {
      // 1. Unregistered player is looked up -> not found
      final lookupNew = db.lookupPlayerByMobile('9830199999');
      expect(lookupNew.isFound, isFalse);

      // 2. Auto-register unregistered player directly
      final autoRegistered = db.registerPermanentPlayer(
        fullName: 'New Star Batter',
        mobileNumber: '9830199999',
        role: PlayerRole.batsman,
        teamId: 'team_auto_1',
      );
      expect(autoRegistered.id, isNotEmpty);
      expect(autoRegistered.permanentPlayerCode, startsWith('PLY-'));
      expect(autoRegistered.fullName, equals('New Star Batter'));
      expect(autoRegistered.mobileNumber, equals('9830199999'));

      // 3. Re-registering with same number does not duplicate, returns existing profile
      final countBefore = db.players.length;
      final autoExisting = db.registerPermanentPlayer(
        fullName: 'New Star Batter',
        mobileNumber: '9830199999',
      );
      expect(db.players.length, equals(countBefore));
      expect(autoExisting.id, equals(autoRegistered.id));
      expect(autoExisting.permanentPlayerCode, equals(autoRegistered.permanentPlayerCode));

      // 4. Mobile lookup now finds them instantly
      final lookupExisting = db.lookupPlayerByMobile('9830199999');
      expect(lookupExisting.isFound, isTrue);
      expect(lookupExisting.player?.id, equals(autoRegistered.id));
    });

    test('9. Player can log in later and watch their match results, scorecard & career stats', () {
      // 1. Player registered and added to a direct match
      final matchPlayer = db.registerPermanentPlayer(
        fullName: 'Shubman Fan',
        mobileNumber: '9830177777',
        role: PlayerRole.allRounder,
      );

      final opponent = db.registerPermanentPlayer(
        fullName: 'Opponent Bowler',
        mobileNumber: '9830188888',
        role: PlayerRole.bowler,
      );

      final match = db.createDirectMatch(
        matchName: 'Championship Final',
        teamAName: 'Warriors',
        teamBName: 'Knights',
        overs: 2,
        venue: 'Wankhede',
        playingXIA: [matchPlayer.id],
        playingXIB: [opponent.id],
        tossWonBy: 'team_direct_a',
        tossDecision: 'bat',
      );

      // 2. Play deliveries and complete match
      final inn1 = db.inningsList.firstWhere((i) => i.matchId == match.id);
      db.recordDelivery(inningsId: inn1.id, runsBatter: 6, extrasRuns: 0);
      db.recordDelivery(inningsId: inn1.id, runsBatter: 4, extrasRuns: 0);
      match.status = MatchStatus.completed;
      match.winnerId = match.teamAId;
      match.winMargin = 'Warriors won by 10 runs';

      // 3. Later, the player logs in with their mobile number:
      db.registerUser(
        fullName: 'Shubman Fan',
        email: 'shubman@cricket.com',
        mobileNumber: '9830177777',
        password: 'pass',
      );
      // Verify mobile OTP once
      db.verifyUserMobileOtp(mobileNumber: '9830177777', otp: '123456');

      // 4. Verify player is automatically linked to their profile
      expect(db.currentUser?.linkedPlayerId, equals(matchPlayer.id));
      expect(db.currentPlayer?.id, equals(matchPlayer.id));
      expect(db.currentPlayer?.fullName, equals('Shubman Fan'));

      // 5. Verify the player can watch their match summary and performance log
      final playerLogs = db.getPlayerMatchLogs(matchPlayer.id);
      expect(playerLogs.length, equals(1));
      expect(playerLogs.first.matchId, equals(match.id));
      expect(playerLogs.first.matchName, equals('Championship Final'));
      expect(playerLogs.first.runsScored, equals(10));
      expect(playerLogs.first.sixes, equals(1));
      expect(playerLogs.first.fours, equals(1));
      expect(playerLogs.first.isWin, isTrue);

      // 6. Verify full scorecard contains player's batting performance
      final scorecard = db.battingScorecards.where((b) => b.matchId == match.id && b.playerId == matchPlayer.id).first;
      expect(scorecard.runs, equals(10));
      expect(scorecard.fours, equals(1));
      expect(scorecard.sixes, equals(1));
    });

    testWidgets('10. AddExistingPlayerDialog auto-registers unregistered player into DB on submit', (tester) async {
      Player? addedPlayer;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<MockDatabase>.value(
              value: db,
              child: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => ChangeNotifierProvider<MockDatabase>.value(
                        value: db,
                        child: AddExistingPlayerDialog(
                          teamId: 'direct_team_a',
                          tournamentId: 'standalone',
                          onPlayerAdded: (p) => addedPlayer = p,
                        ),
                      ),
                    );
                  },
                  child: const Text('Open Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Verify Player Name and Mobile fields are visible simultaneously
      expect(find.text('Player Full Name *'), findsOneWidget);
      expect(find.text('Player Mobile Number (10 Digits) *'), findsOneWidget);

      // Enter name and mobile number for a new unregistered player
      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(2));

      await tester.enterText(textFields.at(0), 'Ravindra Jadeja');
      await tester.enterText(textFields.at(1), '9830155555');
      await tester.pumpAndSettle();

      // Verify the button says "Auto-Register & Add to Squad"
      final submitButton = find.text('Auto-Register & Add to Squad');
      expect(submitButton, findsOneWidget);
      await tester.ensureVisible(submitButton);
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Verify player is now in database with permanent code
      expect(addedPlayer, isNotNull);
      expect(addedPlayer?.fullName, equals('Ravindra Jadeja'));
      expect(addedPlayer?.mobileNumber, equals('9830155555'));
      expect(addedPlayer?.permanentPlayerCode, startsWith('PLY-'));

      // In db.players, this player is permanently recorded
      final inDb = db.players.where((p) => p.mobileNumber == '9830155555').firstOrNull;
      expect(inDb, isNotNull);
      expect(inDb?.fullName, equals('Ravindra Jadeja'));
    });
  });
}
