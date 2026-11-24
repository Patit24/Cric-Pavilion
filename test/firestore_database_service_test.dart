import 'package:flutter_test/flutter_test.dart';
import 'package:cricket_app/models/models.dart';
import 'package:cricket_app/services/database_persistence_service.dart';
import 'package:cricket_app/services/firestore_database_service.dart';
import 'package:cricket_app/services/mock_database.dart';

void main() {
  group('FirestoreDatabaseService and Cloud Sync Tests', () {
    late MockDatabase db;

    setUp(() {
      db = MockDatabase(loadDemoSeed: false);
      db.purgeAllDemoData();
    });

    test('1. isFirebaseAvailable safely handles uninitialized test VM without throwing', () {
      expect(FirestoreDatabaseService.isFirebaseAvailable, isFalse);
      expect(FirestoreDatabaseService.isInitialized, isFalse);
    });

    test('2. Match serialization and deserialization retains all fields for Firestore', () {
      final match = MatchModel(
        id: 'm_test_cloud_01',
        tournamentId: 't_tournament_01',
        stage: 'Final',
        teamAId: 'team_a',
        teamBId: 'team_b',
        venue: 'Eden Gardens',
        dateTime: DateTime.now(),
        overs: 20,
        status: MatchStatus.live,
        tossWonBy: 'team_a',
        tossDecision: 'bat',
        battingFirstId: 'team_a',
        currentInningsNumber: 1,
        playingXIA: ['p1', 'p2'],
        playingXIB: ['p3', 'p4'],
      );

      final map = DatabasePersistenceService.matchToMap(match);
      expect(map['id'], 'm_test_cloud_01');
      expect(map['stage'], 'Final');
      expect(map['status'], 'live');
      expect(map['overs'], 20);
      expect(map['tossWonBy'], 'team_a');

      final reconstructed = DatabasePersistenceService.matchFromMap(map);
      expect(reconstructed.id, match.id);
      expect(reconstructed.stage, match.stage);
      expect(reconstructed.status, MatchStatus.live);
      expect(reconstructed.playingXIA, ['p1', 'p2']);
    });

    test('3. Innings serialization and deserialization for Firestore', () {
      final innings = Innings(
        id: 'inn_cloud_01',
        matchId: 'm_test_cloud_01',
        inningsNumber: 1,
        battingTeamId: 'team_a',
        bowlingTeamId: 'team_b',
        totalRuns: 185,
        wickets: 4,
        legalBalls: 120,
        oversStr: '20.0',
        extrasWides: 6,
        extrasNoBalls: 2,
        extrasByes: 1,
        extrasLegByes: 2,
        totalExtras: 11,
        isCompleted: true,
        currentStrikerId: 'p1',
        currentNonStrikerId: 'p2',
        currentBowlerId: 'p3',
        targetRuns: 186,
      );

      final map = DatabasePersistenceService.inningsToMap(innings);
      expect(map['id'], 'inn_cloud_01');
      expect(map['totalRuns'], 185);
      expect(map['wickets'], 4);
      expect(map['isCompleted'], isTrue);

      final reconstructed = DatabasePersistenceService.inningsFromMap(map);
      expect(reconstructed.id, innings.id);
      expect(reconstructed.totalRuns, 185);
      expect(reconstructed.wickets, 4);
      expect(reconstructed.oversStr, '20.0');
    });

    test('4. Delivery serialization preserves ball-by-ball commentary and sequence', () {
      final del = Delivery(
        id: 'del_cloud_101',
        inningsId: 'inn_cloud_01',
        matchId: 'm_test_cloud_01',
        overNumber: 19,
        ballInOver: 6,
        deliverySequence: 120,
        strikerId: 'p1',
        nonStrikerId: 'p2',
        bowlerId: 'p3',
        runsBatter: 6,
        extrasRuns: 0,
        isLegal: true,
        isWicket: false,
        commentaryText: 'SIX! Smashed over deep mid-wicket!',
        timestamp: DateTime.now(),
      );

      final map = DatabasePersistenceService.deliveryToMap(del);
      expect(map['id'], 'del_cloud_101');
      expect(map['runsBatter'], 6);
      expect(map['isLegal'], isTrue);

      final reconstructed = DatabasePersistenceService.deliveryFromMap(map);
      expect(reconstructed.id, del.id);
      expect(reconstructed.runsBatter, 6);
      expect(reconstructed.deliverySequence, 120);
      expect(reconstructed.commentaryText, contains('SIX!'));
    });

    test('5. Batting and Bowling Scorecards serialization for Firestore', () {
      final bat = BattingScorecard(
        id: 'bat_01',
        inningsId: 'inn_01',
        matchId: 'm_01',
        playerId: 'p1',
        playerName: 'Virat Kohli',
        runs: 82,
        balls: 53,
        fours: 6,
        sixes: 4,
        strikeRate: 154.71,
        dismissalText: 'not out',
        isOut: false,
      );

      final batMap = DatabasePersistenceService.battingScorecardToMap(bat);
      expect(batMap['runs'], 82);
      expect(batMap['strikeRate'], 154.71);
      final reconstructedBat = DatabasePersistenceService.battingScorecardFromMap(batMap);
      expect(reconstructedBat.playerName, 'Virat Kohli');
      expect(reconstructedBat.runs, 82);

      final bowl = BowlingScorecard(
        id: 'bowl_01',
        inningsId: 'inn_01',
        matchId: 'm_01',
        playerId: 'p3',
        playerName: 'Jasprit Bumrah',
        oversStr: '4.0',
        legalBalls: 24,
        maidens: 1,
        runsConceded: 18,
        wickets: 3,
        dots: 14,
        economy: 4.5,
      );

      final bowlMap = DatabasePersistenceService.bowlingScorecardToMap(bowl);
      expect(bowlMap['wickets'], 3);
      expect(bowlMap['economy'], 4.5);
      final reconstructedBowl = DatabasePersistenceService.bowlingScorecardFromMap(bowlMap);
      expect(reconstructedBowl.playerName, 'Jasprit Bumrah');
      expect(reconstructedBowl.wickets, 3);
    });

    test('6. Graceful degradation: calling Firestore sync methods offline does not crash', () async {
      // Calling init or background push without initialized Firebase should cleanly exit
      await FirestoreDatabaseService.init(db);
      expect(FirestoreDatabaseService.isInitialized, isFalse);

      FirestoreDatabaseService.pushStateInBackground(db);
      // Wait for debounce timer
      await Future.delayed(const Duration(milliseconds: 350));
      expect(FirestoreDatabaseService.isInitialized, isFalse);
    });
  });
}
