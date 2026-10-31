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

      // In BPL auction, all 8 teams are checked in by default
      final success = db.placeAuctionBid(
        auctionId: db.auction.id,
        teamId: 'team_kolkata',
        increment: 50000,
      );

      expect(success, isTrue);
      expect(db.auction.currentBid, initialBid + 50000);
      expect(db.auction.highBidderTeamId, 'team_kolkata');
    });

    test('Host is NOT allowed to bid, and auction blocks bidding if 8 teams not entered', () {
      final db = MockDatabase();

      // PSL has only 4 teams checked in initially
      final psl = db.auctions.firstWhere((a) => a.id == 'auc_psl_2026');
      expect(psl.isReadyToStart, isFalse);

      // Bidding should fail because 8 teams haven't entered
      final bidBefore8 = db.placeAuctionBid(
        auctionId: psl.id,
        teamId: 'team_barasat',
        increment: 50000,
      );
      expect(bidBefore8, isFalse);

      // Check in all 8 teams
      db.checkInAllTeamsToAuction(psl.id);
      expect(psl.isReadyToStart, isTrue);

      // If user logs in as Host (admin), host is blocked from bidding!
      db.enterAuctionAsHost(auctionId: psl.id, adminPasscode: 'admin123');
      expect(db.isAuctionAdmin, isTrue);
      final hostBid = db.placeAuctionBid(
        auctionId: psl.id,
        teamId: 'team_barasat',
        increment: 50000,
      );
      expect(hostBid, isFalse); // Host cannot bid!

      // Team owner logs in -> can bid!
      final ownerEnter = db.enterAuctionAsTeamOwner(
        auctionId: psl.id,
        teamCode: 'TEAM-BBL-01',
        passcode: '1234',
      );
      expect(ownerEnter, isTrue);
      expect(db.isAuctionAdmin, isFalse);
      expect(db.authenticatedTeamId, 'team_barasat');

      final ownerBid = db.placeAuctionBid(
        auctionId: psl.id,
        teamId: 'team_barasat',
        increment: 50000,
      );
      expect(ownerBid, isTrue);
    });

    test('Create Tournament provisions 8 franchise teams, room ID, and linked auction', () {
      final db = MockDatabase();

      final tourn = db.createTournament(
        name: 'Super Cup 2026',
        shortName: 'SC 2026',
        location: 'Wankhede Stadium',
        overs: 20,
        roomId: 'TOURN-SC-2026',
        passcode: '9999',
        createAuction: true,
      );

      expect(tourn.roomId, 'TOURN-SC-2026');
      expect(tourn.passcode, '9999');

      // Check that 8 teams were created for this tournament
      final tournTeams = db.teams.where((t) => t.tournamentId == tourn.id).toList();
      expect(tournTeams.length, 8);
      for (final t in tournTeams) {
        expect(t.uniqueTeamCode, startsWith('TEAM-SC2026'));
        expect(t.minSquadRequirement, 15);
      }

      // Check that linked auction was created
      final linkedAuction = db.auctions.where((a) => a.tournamentId == tourn.id).firstOrNull;
      expect(linkedAuction, isNotNull);
      expect(linkedAuction!.requiredTeamsCount, 8);
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

    test('Host Manual Starting Price & Floor Gavel Warnings', () {
      final db = MockDatabase();
      final auc = db.getAuction('auc_bpl_2026');
      db.checkInAllTeamsToAuction(auc.id);

      // Verify initial floor status is open
      expect(auc.floorStatus, FloorStatus.open);

      // Host sets manual starting price
      final lot = db.auctionLots.firstWhere((l) => l.auctionId == auc.id && l.id == auc.currentLotId);
      db.setLotStartingPrice(auc.id, lot.id, 2500000);
      expect(lot.startingPrice, 2500000);
      expect(auc.currentBid, 2500000);

      // Host triggers countdown warnings
      db.setFloorStatus(auc.id, FloorStatus.goingOnce);
      expect(auc.floorStatus, FloorStatus.goingOnce);

      db.setFloorStatus(auc.id, FloorStatus.goingTwice);
      expect(auc.floorStatus, FloorStatus.goingTwice);

      // Counter-bid from team owner resets warning to open
      final team = db.teams.first;
      final bidSuccess = db.placeAuctionBid(
        teamId: team.id,
        increment: 500000,
        auctionId: auc.id,
      );
      expect(bidSuccess, isTrue);
      expect(auc.floorStatus, FloorStatus.open);
      expect(auc.currentBid, 3000000);
      expect(auc.highBidderTeamId, team.id);

      // Fair warning and gavel sell
      db.setFloorStatus(auc.id, FloorStatus.fairWarning);
      expect(auc.floorStatus, FloorStatus.fairWarning);

      db.setFloorStatus(auc.id, FloorStatus.sold);
      expect(lot.status, LotStatus.sold);
      expect(lot.winningTeamId, team.id);
    });

    test('Host Spin Pool Management and Unsold Re-Auctioning', () {
      final db = MockDatabase();
      final auc = db.getAuction('auc_bpl_2026');

      // Test deselect all and select all
      db.selectAllLotsForSpin(auc.id, false);
      final unselected = db.auctionLots.where((l) => l.auctionId == auc.id && l.status == LotStatus.pending && !l.isSelectedForSpin);
      expect(unselected.isNotEmpty, isTrue);

      db.selectAllLotsForSpin(auc.id, true);
      final allSelected = db.auctionLots.where((l) => l.auctionId == auc.id && l.status == LotStatus.pending && l.isSelectedForSpin);
      expect(allSelected.isNotEmpty, isTrue);

      // Spin picks random eligible lot
      final picked = db.spinToRandomEligibleLot(auc.id);
      expect(picked, isNotNull);
      expect(picked!.status, LotStatus.bidding);
      expect(auc.currentLotId, picked.id);

      // Pass lot as unsold
      db.setFloorStatus(auc.id, FloorStatus.unsold);
      expect(picked.status, LotStatus.unsold);

      // Re-auction unsold lots resets them to pending with discounted starting price
      db.reAuctionUnsoldLots(auc.id, 0.75);
      expect(picked.status, anyOf(LotStatus.pending, LotStatus.bidding));
      expect(picked.startingPrice, (picked.basePrice * 0.75).toInt());
    });
  });
}
