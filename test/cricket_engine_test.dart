import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:cricket_app/models/models.dart';
import 'package:cricket_app/services/cricket_rules_engine.dart';
import 'package:cricket_app/services/mock_database.dart';

void main() {
  setUpAll(() {
    // Override HttpOverrides for test environment
    HttpOverrides.global = null;
  });

  group('CricketRulesEngine Tests', () {
    test('formatOvers formats balls correctly', () {
      expect(CricketRulesEngine.formatOvers(0), '0.0');
      expect(CricketRulesEngine.formatOvers(1), '0.1');
      expect(CricketRulesEngine.formatOvers(6), '1.0');
      expect(CricketRulesEngine.formatOvers(86), '14.2');
      expect(CricketRulesEngine.formatOvers(120), '20.0');
    });

    test('Law 17.8 blocks same bowler from bowling consecutive overs', () {
      final deliveries = <Delivery>[];
      final result = CricketRulesEngine.validateBowler(
        bowlerId: 'pl_4',
        previousOverBowlerId: 'pl_4',
        deliveries: deliveries,
        inningsId: 'inn_1',
        maxOversPerBowler: 4,
      );

      expect(result.isEligible, isFalse);
      expect(result.reason, contains('Law 17.8: Cannot bowl consecutive overs'));
    });

    test('Bowler quota check enforces max 4 overs in T20', () {
      final deliveries = List.generate(
        24,
        (i) => Delivery(
          id: 'del_$i',
          inningsId: 'inn_1',
          matchId: 'match_1',
          overNumber: i ~/ 6,
          ballInOver: (i % 6) + 1,
          deliverySequence: i + 1,
          strikerId: 'pl_1',
          nonStrikerId: 'pl_2',
          bowlerId: 'pl_4',
          runsBatter: 1,
          isLegal: true,
          commentaryText: 'single',
          timestamp: DateTime.now(),
        ),
      );

      final result = CricketRulesEngine.validateBowler(
        bowlerId: 'pl_4',
        previousOverBowlerId: 'pl_5', // different from previous
        deliveries: deliveries,
        inningsId: 'inn_1',
        maxOversPerBowler: 4,
      );

      expect(result.isEligible, isFalse);
      expect(result.reason, contains('Max quota reached'));
    });

    test('getAvailableIncomingBatsmen excludes dismissed and crease players', () {
      final players = [
        Player(id: 'p1', fullName: 'P1', displayName: 'P1', role: PlayerRole.batsman, battingStyle: 'RHB', bowlingStyle: 'None', basePrice: 100, photoUrl: ''),
        Player(id: 'p2', fullName: 'P2', displayName: 'P2', role: PlayerRole.batsman, battingStyle: 'RHB', bowlingStyle: 'None', basePrice: 100, photoUrl: ''),
        Player(id: 'p3', fullName: 'P3', displayName: 'P3', role: PlayerRole.batsman, battingStyle: 'RHB', bowlingStyle: 'None', basePrice: 100, photoUrl: ''),
        Player(id: 'p4', fullName: 'P4', displayName: 'P4', role: PlayerRole.batsman, battingStyle: 'RHB', bowlingStyle: 'None', basePrice: 100, photoUrl: ''),
      ];

      final deliveries = [
        Delivery(
          id: 'del_1',
          inningsId: 'inn_1',
          matchId: 'm1',
          overNumber: 1,
          ballInOver: 1,
          deliverySequence: 1,
          strikerId: 'p1',
          nonStrikerId: 'p2',
          bowlerId: 'b1',
          isWicket: true,
          dismissedPlayerId: 'p1',
          commentaryText: 'OUT',
          timestamp: DateTime.now(),
        ),
      ];

      final available = CricketRulesEngine.getAvailableIncomingBatsmen(
        teamPlayers: players,
        deliveries: deliveries,
        inningsId: 'inn_1',
        currentStrikerId: 'p1',
        currentNonStrikerId: 'p2',
        dismissedPlayerId: 'p1',
      );

      // p1 is out, p2 is at crease -> only p3 and p4 available
      expect(available.map((p) => p.id).toList(), ['p3', 'p4']);
    });
  });

  group('MockDatabase State Management Tests', () {
    test('recordDelivery updates score, overs, and rotates strike on odd runs', () {
      final db = MockDatabase();
      final inn1 = db.inningsList.firstWhere((i) => i.id == 'inn_1');
      final initialRuns = inn1.totalRuns;
      final initialBalls = inn1.legalBalls;

      final strikerBefore = inn1.currentStrikerId;
      final nonStrikerBefore = inn1.currentNonStrikerId;

      // Score 1 run
      db.recordDelivery(inningsId: 'inn_1', runsBatter: 1);

      expect(inn1.totalRuns, initialRuns + 1);
      expect(inn1.legalBalls, initialBalls + 1);

      // Strike rotated: striker & non-striker swapped
      expect(inn1.currentStrikerId, nonStrikerBefore);
      expect(inn1.currentNonStrikerId, strikerBefore);
    });

    test('Wicket dismisses batter and brings in next batter', () {
      final db = MockDatabase();
      final inn1 = db.inningsList.firstWhere((i) => i.id == 'inn_1');
      final initialWickets = inn1.wickets;

      db.recordDelivery(
        inningsId: 'inn_1',
        runsBatter: 0,
        isWicket: true,
        dismissalType: DismissalType.bowled,
        dismissedPlayerId: inn1.currentStrikerId,
        nextBatterId: 'pl_5',
      );

      expect(inn1.wickets, initialWickets + 1);
      expect(inn1.currentStrikerId, 'pl_5');
    });

    test('Auction bidding increments current bid and tracks highest bidder', () {
      final db = MockDatabase();
      final initialBid = db.auction.currentBid ?? 450000;

      db.placeAuctionBid('team_kolkata', 50000);

      expect(db.auction.currentBid, initialBid + 50000);
      expect(db.auction.highBidderTeamId, 'team_kolkata');
    });

    test('Selling auction lot deducts franchise purse and increments squad', () {
      final db = MockDatabase();
      final buyerTeam = db.teams.firstWhere((t) => t.id == 'team_barasat');
      final initialPurse = buyerTeam.purseRemaining;
      final initialSquad = buyerTeam.squadCount;
      final winningBid = db.auction.currentBid!;

      db.sellCurrentLot();

      expect(buyerTeam.purseRemaining, initialPurse - winningBid);
      expect(buyerTeam.squadCount, initialSquad + 1);
    });

    test('Room Access Control: Spectator mode is locked by default and requires Room ID & Passcode', () {
      final db = MockDatabase();

      // Default state: Spectator mode (Locked)
      expect(db.isScoringUnlockedForMatch('match_1'), isFalse);
      expect(db.isAuctionUnlocked, isFalse);
      expect(db.isAuctionAdmin, isFalse);

      // Wrong passcode fails
      final wrongUnlock = db.unlockScoringRoom(
        matchId: 'match_1',
        roomId: 'ROOM-BPL-01',
        passcode: 'wrong_pass',
      );
      expect(wrongUnlock, isFalse);
      expect(db.isScoringUnlockedForMatch('match_1'), isFalse);

      // Correct passcode unlocks scoring for match_1
      final validUnlock = db.unlockScoringRoom(
        matchId: 'match_1',
        roomId: 'ROOM-BPL-01',
        passcode: '1234',
      );
      expect(validUnlock, isTrue);
      expect(db.isScoringUnlockedForMatch('match_1'), isTrue);

      // Lock scoring returns to spectator mode
      db.lockScoringRoom('match_1');
      expect(db.isScoringUnlockedForMatch('match_1'), isFalse);

      // Creating a room auto-authenticates creator
      final newRoom = db.createScoringRoom(
        matchId: 'match_2',
        roomId: 'ROOM-CUSTOM-99',
        passcode: '5678',
        createdBy: 'Tournament Admin',
      );
      expect(newRoom.id, 'ROOM-CUSTOM-99');
      expect(db.isScoringUnlockedForMatch('match_2'), isTrue);

      // Auction team PIN unlocks bidding
      final teamAuctionUnlock = db.unlockAuctionRoom(
        roomId: 'AUCTION-BPL',
        passcode: '1234',
      );
      expect(teamAuctionUnlock, isTrue);
      expect(db.isAuctionUnlocked, isTrue);
      expect(db.isAuctionAdmin, isFalse);

      // Auction admin PIN unlocks admin controls
      final adminAuctionUnlock = db.unlockAuctionRoom(
        roomId: 'AUCTION-BPL',
        passcode: 'admin123',
      );
      expect(adminAuctionUnlock, isTrue);
      expect(db.isAuctionUnlocked, isTrue);
      expect(db.isAuctionAdmin, isTrue);

      // Lock auction returns to spectator mode
      db.lockAuctionRoom();
      expect(db.isAuctionUnlocked, isFalse);
      expect(db.isAuctionAdmin, isFalse);
    });
  });
}
