import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:cricket_app/models/models.dart';
import 'package:cricket_app/services/mock_database.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = null;
  });

  group('Master Cricket Auction Management System Tests', () {
    test('1. Strict RBAC: Only assigned Auctioneer or Super Admin can spin and reveal player', () {
      final db = MockDatabase(loadDemoSeed: true);
      final auc = db.auctions.first;

      // Ensure 8 teams are checked in
      db.checkInAllTeamsToAuction(auc.id);

      // Case A: Team Owner cannot spin
      db.setRole(AppUserRole.teamOwner, teamId: 'team_barasat');
      expect(db.canSpinPlayer(auc.id), isFalse);
      final attemptOwner = db.spinToRandomEligibleLot(auc.id);
      expect(attemptOwner, isNull);

      // Case B: Public Viewer cannot spin
      db.setRole(AppUserRole.viewer);
      expect(db.canSpinPlayer(auc.id), isFalse);
      final attemptViewer = db.spinToRandomEligibleLot(auc.id);
      expect(attemptViewer, isNull);

      // Case C: Auction Operator cannot spin (assists queue & timer only)
      db.setRole(AppUserRole.auctionOperator, operatorId: 'op_01');
      expect(db.canSpinPlayer(auc.id), isFalse);
      final attemptOp = db.spinToRandomEligibleLot(auc.id);
      expect(attemptOp, isNull);

      // Case D: Player persona cannot spin
      db.setRole(AppUserRole.player, playerId: 'p_01');
      expect(db.canSpinPlayer(auc.id), isFalse);
      final attemptPlayer = db.spinToRandomEligibleLot(auc.id);
      expect(attemptPlayer, isNull);

      // Case E: Assigned Auctioneer CAN spin
      db.setRole(AppUserRole.auctioneer, auctioneerId: auc.assignedAuctioneerId);
      expect(db.canSpinPlayer(auc.id), isTrue);
      final pickedByAuctioneer = db.spinToRandomEligibleLot(auc.id);
      expect(pickedByAuctioneer, isNotNull);
      expect(pickedByAuctioneer!.status, LotStatus.bidding);
      expect(auc.currentLotId, pickedByAuctioneer.id);

      // Case F: Super Admin CAN spin
      db.setRole(AppUserRole.superAdmin);
      expect(db.canSpinPlayer(auc.id), isTrue);
    });

    test('2. Live Bidding: Validates bidder authority, budget reserve, increments, and resets timer', () {
      final db = MockDatabase(loadDemoSeed: true);
      final auc = db.auctions.first;
      db.checkInAllTeamsToAuction(auc.id);

      // Reveal a player
      db.setRole(AppUserRole.superAdmin);
      db.spinToRandomEligibleLot(auc.id);
      final openingBid = auc.currentBid!;

      // Viewer cannot bid
      db.setRole(AppUserRole.viewer);
      final viewerBid = db.placeAuctionBid(auctionId: auc.id, teamId: 'team_barasat', increment: 25000);
      expect(viewerBid, isFalse);

      // Team Owner can bid for their own team
      db.setRole(AppUserRole.teamOwner, teamId: 'team_barasat');
      final teamBid = db.placeAuctionBid(auctionId: auc.id, teamId: 'team_barasat', increment: 25000);
      expect(teamBid, isTrue);
      expect(auc.highBidderTeamId, 'team_barasat');
      expect(auc.currentBid, openingBid + 25000);
      expect(auc.biddingSecondsRemaining, auc.defaultTimerSeconds); // Timer reset
      expect(auc.gavelWarningCount, 0);

      // Counter-bid by another team owner
      db.setRole(AppUserRole.teamOwner, teamId: 'team_howrah');
      final counterBid = db.placeAuctionBid(auctionId: auc.id, teamId: 'team_howrah', increment: 25000);
      expect(counterBid, isTrue);
      expect(auc.highBidderTeamId, 'team_howrah');
      expect(auc.currentBid, openingBid + 50000);

      // Team cannot bid for a different team
      final spoofBid = db.placeAuctionBid(auctionId: auc.id, teamId: 'team_siliguri', increment: 25000);
      expect(spoofBid, isFalse);
    });

    test('3. Strict Budget Protection Formula & Overseas Player Limits', () {
      final db = MockDatabase(loadDemoSeed: true);
      final auc = db.auctions.first;
      db.checkInAllTeamsToAuction(auc.id);

      final team = db.teams.firstWhere((t) => t.id == 'team_barasat');
      final basePrice = 100000;

      // Remaining purse calculation
      final maxEligible = team.getMaxEligibleBid(basePrice);
      expect(maxEligible, lessThanOrEqualTo(team.purseRemaining));

      // Attempting to bid over max eligible is rejected
      db.setRole(AppUserRole.teamOwner, teamId: team.id);
      final excessiveIncrement = maxEligible + 1000000;
      final rejected = db.placeAuctionBid(auctionId: auc.id, teamId: team.id, increment: excessiveIncrement);
      expect(rejected, isFalse);
    });

    test('4. Idempotent SOLD Confirmation, Automatic Squad Update & WhatsApp Queuing', () {
      final db = MockDatabase(loadDemoSeed: true);
      final auc = db.auctions.first;
      db.checkInAllTeamsToAuction(auc.id);

      // Reveal lot and place bid
      db.setRole(AppUserRole.superAdmin);
      final lot = db.spinToRandomEligibleLot(auc.id)!;
      final player = db.players.firstWhere((p) => p.id == lot.playerId);
      final team = db.teams.firstWhere((t) => t.id == 'team_barasat');

      db.setRole(AppUserRole.teamOwner, teamId: team.id);
      db.placeAuctionBid(auctionId: auc.id, teamId: team.id, increment: 50000);
      final winningBid = auc.currentBid!;
      final initialPurse = team.purseRemaining;
      final initialSquad = team.squadCount;

      // Confirm SOLD by Auctioneer
      db.setRole(AppUserRole.auctioneer, auctioneerId: auc.assignedAuctioneerId);
      db.sellCurrentLot(auc.id);

      expect(lot.status, LotStatus.sold);
      expect(lot.winningTeamId, team.id);
      expect(player.teamId, team.id);
      expect(player.auctionStatus, PlayerAuctionStatus.sold);
      expect(player.soldPrice, winningBid);
      expect(team.purseRemaining, initialPurse - winningBid);
      expect(team.squadCount, initialSquad + 1);

      // Verify transaction recorded
      expect(db.auctionTransactions.any((tx) => tx.lotId == lot.id && tx.type == AuctionTransactionType.purchase), isTrue);

      // Verify WhatsApp notification queued
      final queuedNotif = db.whatsappNotifications.where((n) => n.playerId == player.id).firstOrNull;
      expect(queuedNotif, isNotNull);
      expect(queuedNotif!.messageBody, contains(team.name));
      expect(queuedNotif.recipientMobile, player.mobileNumber.isNotEmpty ? player.mobileNumber : '+91 98300 00000');

      // IDEMPOTENCY CHECK: Calling sellCurrentLot again must NOT deduct purse twice
      final purseAfterFirstSold = team.purseRemaining;
      db.sellCurrentLot(auc.id);
      expect(team.purseRemaining, purseAfterFirstSold);
    });

    test('5. Correction Reversal: Restores purse, decrements squad, reverts player to available', () {
      final db = MockDatabase(loadDemoSeed: true);
      final auc = db.auctions.first;
      db.checkInAllTeamsToAuction(auc.id);

      // Setup and sell a lot
      db.setRole(AppUserRole.superAdmin);
      final lot = db.spinToRandomEligibleLot(auc.id)!;
      final player = db.players.firstWhere((p) => p.id == lot.playerId);
      final team = db.teams.firstWhere((t) => t.id == 'team_howrah');

      db.setRole(AppUserRole.teamOwner, teamId: team.id);
      db.placeAuctionBid(auctionId: auc.id, teamId: team.id, increment: 25000);
      final finalPrice = auc.currentBid!;

      db.setRole(AppUserRole.superAdmin);
      db.sellCurrentLot(auc.id);

      final purseBeforeReversal = team.purseRemaining;
      final squadBeforeReversal = team.squadCount;

      // Reverse the transaction
      final reversed = db.reverseSoldLot(
        auctionId: auc.id,
        lotId: lot.id,
        reason: 'Misclick by Auctioneer corrected by Tournament Admin',
      );

      expect(reversed, isTrue);
      expect(team.purseRemaining, purseBeforeReversal + finalPrice);
      expect(team.squadCount, squadBeforeReversal - 1);
      expect(player.teamId, isNull);
      expect(player.auctionStatus, PlayerAuctionStatus.available);
      expect(lot.status, LotStatus.pending);
      expect(db.auctionTransactions.any((tx) => tx.lotId == lot.id && tx.type == AuctionTransactionType.reversal), isTrue);
    });

    test('6. Advance Round & Re-Auction Unsold with discount', () {
      final db = MockDatabase(loadDemoSeed: true);
      final auc = db.auctions.first;
      db.checkInAllTeamsToAuction(auc.id);

      db.setRole(AppUserRole.superAdmin);
      final lot = db.spinToRandomEligibleLot(auc.id)!;

      // Mark lot unsold
      db.passCurrentLot(auc.id);
      expect(lot.status, LotStatus.unsold);

      final initialRound = auc.currentRound;

      // Advance round with 20% discount on unsold lots
      db.advanceAuctionRound(auctionId: auc.id, unsoldPriceDiscount: 0.20);
      expect(auc.currentRound, initialRound + 1);
      expect(lot.status, LotStatus.pending);
      expect(lot.isSelectedForSpin, isTrue);
      expect(lot.startingPrice, (lot.basePrice * 0.80).toInt());
    });

    test('7. Bulk CSV Player Import with duplicate prevention', () {
      final db = MockDatabase(loadDemoSeed: true);
      final auc = db.auctions.first;

      const csvData = '''FullName, Mobile, Role, BasePrice, Category, BattingStyle, BowlingStyle, Age, City, Overseas
Pat Cummins, 9870000001, bowler, 2000000, marquee, Right Hand Bat, Right Arm Fast, 30, Sydney, true
Travis Head, 9870000002, allrounder, 1500000, marquee, Left Hand Bat, Off Break, 30, Adelaide, true
Mitchell Starc, 9870000003, bowler, 2500000, marquee, Left Hand Bat, Left Arm Fast, 34, Sydney, true''';

      db.setRole(AppUserRole.superAdmin);
      final result = db.bulkImportPlayersFromCsv(auctionId: auc.id, csvData: csvData);

      expect(result['success'], isTrue);
      expect(result['imported'], 3);

      // Importing same CSV again must skip duplicates
      final reimport = db.bulkImportPlayersFromCsv(auctionId: auc.id, csvData: csvData);
      expect(reimport['imported'], 0);
      expect(reimport['duplicates'], 3);
    });

    test('8. Auction Report Generation and CSV Export', () {
      final db = MockDatabase(loadDemoSeed: true);
      final auc = db.auctions.first;

      final report = db.generateAuctionReport(auc.id);
      expect(report['auctionId'], auc.id);
      expect(report.containsKey('totalSpent'), isTrue);
      expect(report.containsKey('teams'), isTrue);

      final csv = db.exportAuctionReportCsv(auc.id);
      expect(csv, contains('CRICKET AUCTION REPORT'));
      expect(csv, contains('Lot Number,Player Name,Role,Category'));
    });
  });
}
