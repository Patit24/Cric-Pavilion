import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:cricket_app/models/models.dart';
import 'package:cricket_app/services/mock_database.dart';
import 'package:cricket_app/services/database_persistence_service.dart';

void main() {
  group('Multi-Device Central Sync & Mandatory Login Scoring Tests', () {
    late MockDatabase dbMobile;
    late MockDatabase dbDesktop;

    setUp(() {
      dbMobile = MockDatabase(loadDemoSeed: false);
      dbDesktop = MockDatabase(loadDemoSeed: false);
      DatabasePersistenceService.isPersistenceEnabled = false;
    });

    test('1. Mandatory Login: Unauthenticated guests cannot score standalone/friendly matches', () {
      // Create a standalone match
      final p1 = dbMobile.registerPermanentPlayer(fullName: 'Player 1', mobileNumber: '9111111111');
      final p2 = dbMobile.registerPermanentPlayer(fullName: 'Player 2', mobileNumber: '9111111112');
      final match = dbMobile.createDirectMatch(
        matchName: 'Guest Match Check',
        teamAName: 'Team A',
        teamBName: 'Team B',
        overs: 5,
        venue: 'Eden Gardens',
        playingXIA: [p1.id],
        playingXIB: [p2.id],
      );

      // Verify unauthenticated by default
      expect(dbMobile.isAuthenticated, isFalse);

      // Unauthenticated user MUST NOT have scoring unlocked
      expect(dbMobile.isScoringUnlockedForMatch(match.id), isFalse);
      expect(dbMobile.canScoreMatch(match.id), isFalse);

      // Log in a valid user
      final success = dbMobile.registerUser(
        fullName: 'Official Scorer',
        email: 'scorer@cricpavilion.com',
        mobileNumber: '9111111113',
        password: 'password123',
      );
      expect(success, isTrue);
      expect(dbMobile.isAuthenticated, isTrue);
      expect(dbMobile.currentUser?.fullName, 'Official Scorer');

      // Authenticated user now has scoring unlocked for the friendly match
      expect(dbMobile.isScoringUnlockedForMatch(match.id), isTrue);
      expect(dbMobile.canScoreMatch(match.id), isTrue);
    });

    test('2. Multi-Device Sync: Mobile-scored match transfers and merges seamlessly into Desktop', () {
      // 1. Mobile user logs in and scores a friendly match
      final registered = dbMobile.registerUser(
        fullName: 'Mobile Scorer',
        email: 'mobile@cricpavilion.com',
        mobileNumber: '9222222221',
        password: 'password123',
      );
      expect(registered, isTrue);
      final p1 = dbMobile.registerPermanentPlayer(fullName: 'Kohli', mobileNumber: '9222222222', role: PlayerRole.batsman);
      final p2 = dbMobile.registerPermanentPlayer(fullName: 'Rohit', mobileNumber: '9222222223', role: PlayerRole.batsman);
      final p3 = dbMobile.registerPermanentPlayer(fullName: 'Bumrah', mobileNumber: '9222222224', role: PlayerRole.bowler);

      final match = dbMobile.createDirectMatch(
        matchName: 'Mobile Derby 2026',
        teamAName: 'Red Challengers',
        teamBName: 'Blue Titans',
        overs: 2,
        venue: 'Chinnaswamy Stadium',
        playingXIA: [p1.id, p2.id],
        playingXIB: [p3.id],
        strikerId: p1.id,
        nonStrikerId: p2.id,
        bowlerId: p3.id,
      );

      final inn1 = dbMobile.inningsList.firstWhere((i) => i.matchId == match.id);
      dbMobile.recordDelivery(inningsId: inn1.id, runsBatter: 4); // 4 runs
      dbMobile.recordDelivery(inningsId: inn1.id, runsBatter: 6); // 6 runs

      expect(dbMobile.matches.length, 1);
      expect(dbMobile.deliveries.length, 2);
      expect(inn1.totalRuns, 10);

      // 2. Desktop currently has 0 matches
      expect(dbDesktop.matches.length, 0);
      expect(dbDesktop.deliveries.length, 0);

      // 3. Export Mobile DB to payload (simulating POST /api/sync)
      final mobileExportMap = DatabasePersistenceService.exportDatabaseToMap(dbMobile);
      final jsonPayload = jsonEncode(mobileExportMap);

      // Verify JSON serialization is intact
      final decodedPayload = jsonDecode(jsonPayload) as Map<String, dynamic>;
      expect(decodedPayload['matches'], isNotEmpty);
      expect(decodedPayload['deliveries'].length, 2);

      // 4. Desktop synchronizes and merges Mobile payload
      final merged = DatabasePersistenceService.mergeMapIntoDatabase(dbDesktop, decodedPayload);
      expect(merged, isTrue);

      // 5. Desktop now reflects the exact match, teams, players, deliveries, and scorecards!
      expect(dbDesktop.matches.length, 1);
      expect(dbDesktop.matches.first.id, match.id);
      expect(dbDesktop.matches.first.stage, 'Mobile Derby 2026');
      expect(dbDesktop.deliveries.length, 2);

      final desktopInn1 = dbDesktop.inningsList.firstWhere((i) => i.matchId == match.id);
      expect(desktopInn1.totalRuns, 10);

      final desktopBatting = dbDesktop.battingScorecards.firstWhere((b) => b.playerId == p1.id);
      expect(desktopBatting.runs, 10);
      expect(desktopBatting.fours, 1);
      expect(desktopBatting.sixes, 1);
    });

    test('3. Multi-Device Sync: Re-syncing does not duplicate deliveries or scorecards', () {
      final p1 = dbMobile.registerPermanentPlayer(fullName: 'Batter', mobileNumber: '9333333331');
      final p2 = dbMobile.registerPermanentPlayer(fullName: 'Bowler', mobileNumber: '9333333332');
      final match = dbMobile.createDirectMatch(
        matchName: 'Deduplication Test',
        teamAName: 'Team 1',
        teamBName: 'Team 2',
        overs: 1,
        venue: 'Eden Gardens',
        playingXIA: [p1.id],
        playingXIB: [p2.id],
        strikerId: p1.id,
        nonStrikerId: p1.id,
        bowlerId: p2.id,
      );

      final inn1 = dbMobile.inningsList.firstWhere((i) => i.matchId == match.id);
      dbMobile.recordDelivery(inningsId: inn1.id, runsBatter: 1);

      final export1 = DatabasePersistenceService.exportDatabaseToMap(dbMobile);
      DatabasePersistenceService.mergeMapIntoDatabase(dbDesktop, export1);
      expect(dbDesktop.deliveries.length, 1);

      // Second sync with identical data
      final export2 = DatabasePersistenceService.exportDatabaseToMap(dbMobile);
      DatabasePersistenceService.mergeMapIntoDatabase(dbDesktop, export2);
      expect(dbDesktop.deliveries.length, 1, reason: 'Duplicate deliveries must be ignored');
      expect(dbDesktop.matches.length, 1);
    });
  });
}
