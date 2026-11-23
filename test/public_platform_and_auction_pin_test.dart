import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cricket_app/models/models.dart';
import 'package:cricket_app/services/mock_database.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = null;
  });

  group('Public Cricket Platform & Auction ID & PIN Flow Tests', () {
    test('1. Public-First Access: Default state is unauthenticated Guest Spectator and clean slate', () {
      final dbClean = MockDatabase();

      // Guest viewer by default: no forced login, no role spoofing
      expect(dbClean.currentUser, isNull);
      expect(dbClean.currentRole, equals(AppUserRole.viewer));
      expect(dbClean.tournaments, isEmpty);

      // Now with tournament data
      final db = MockDatabase(loadDemoSeed: true);
      db.logoutUser(); // Ensure spectator mode

      expect(db.currentUser, isNull);
      expect(db.currentRole, equals(AppUserRole.viewer));
      expect(db.tournaments, isNotEmpty);
      expect(db.auctions, isNotEmpty);
      expect(db.matches, isNotEmpty);

      // Spectator CANNOT score matches
      final match = db.matches.first;
      expect(db.canScoreMatch(match.id), isFalse);

      // Spectator CANNOT spin lots
      final auction = db.auctions.first;
      expect(db.canSpinPlayer(auction.id), isFalse);
    });

    test('2. Auction PIN Validation: Correct ID & PIN succeeds', () {
      final db = MockDatabase(loadDemoSeed: true);
      final auction = db.auctions.first; // BPL 2026 Mega Auction

      // Valid Auction ID + PIN
      final result = db.validateAuctionJoinCredentials(
        auctionIdOrCode: auction.auctionCode,
        auctionPin: auction.auctionPin,
      );

      expect(result.isValid, isTrue);
      expect(result.auction, isNotNull);
      expect(result.auction!.id, equals(auction.id));
      expect(result.errorMessage, isNull);
    });

    test('3. Rate Limiting: 5 failed PIN attempts locks client for cooldown window', () {
      final db = MockDatabase(loadDemoSeed: true);
      final auction = db.auctions.first;

      // 4 incorrect attempts
      for (int i = 0; i < 4; i++) {
        final res = db.validateAuctionJoinCredentials(
          auctionIdOrCode: auction.auctionCode,
          auctionPin: '00000$i',
        );
        expect(res.isValid, isFalse);
      }

      // 5th incorrect attempt -> triggers rate limit lockout
      final fifth = db.validateAuctionJoinCredentials(
        auctionIdOrCode: auction.auctionCode,
        auctionPin: '999999',
      );
      expect(fifth.isValid, isFalse);
      expect(fifth.errorMessage, contains('lockout'));

      // 6th attempt even with correct PIN is immediately blocked by lockout
      final blocked = db.validateAuctionJoinCredentials(
        auctionIdOrCode: auction.auctionCode,
        auctionPin: auction.auctionPin,
      );
      expect(blocked.isValid, isFalse);
      expect(blocked.errorMessage, contains('lockout'));
    });

    test('4. Franchise Joining: Automatic entry registers franchise team when logged in', () {
      final db = MockDatabase(loadDemoSeed: true);
      final auction = db.auctions.first;

      // User signs in first
      final regSuccess = db.registerUser(
        fullName: 'Subhasis Roy',
        email: 'subhasis@strikers.com',
        mobileNumber: '9876543210',
        password: 'password123',
      );
      expect(regSuccess, isTrue);

      // Ensure joining is enabled and mode is automatic
      auction.isJoiningEnabled = true;
      auction.joiningMode = AuctionJoiningMode.automatic;

      final initialTeamsCount = db.teams.where((t) => t.tournamentId == auction.tournamentId).length;

      // Submit new franchise registration
      final regResult = db.submitTeamOwnerRegistration(
        auctionId: auction.id,
        teamName: 'Sundarbans Strikers',
        teamShortName: 'SS',
        primaryColor: const Color(0xFF00F5A0),
        logoUrl: 'https://images.unsplash.com/photo-1589487391730-58f20eb2c308?w=120',
      );

      expect(regResult['success'], isTrue);
      expect(regResult['mode'], equals('automatic'));
      final team = regResult['team'] as Team;

      // Verify team was created and linked to the tournament
      final updatedTeams = db.teams.where((t) => t.tournamentId == auction.tournamentId).toList();
      expect(updatedTeams.length, equals(initialTeamsCount + 1));
      expect(updatedTeams.any((t) => t.name == 'Sundarbans Strikers'), isTrue);

      // Verify franchise user account has owned team ID
      expect(db.currentUser!.ownedTeamIds, contains(team.id));
    });

    test('5. Franchise Joining: Host Approval queue and approval lifecycle', () {
      final db = MockDatabase(loadDemoSeed: true);
      final auction = db.auctions.first;

      // User signs in
      db.registerUser(
        fullName: 'Anil Sengupta',
        email: 'anil@hawks.com',
        mobileNumber: '9830112233',
        password: 'password123',
      );

      // Set joining mode to hostApproval
      auction.joiningMode = AuctionJoiningMode.hostApproval;

      final initialPendingCount = auction.pendingRegistrations.length;

      // Submit registration
      final regResult = db.submitTeamOwnerRegistration(
        auctionId: auction.id,
        teamName: 'Howrah Hawks',
        teamShortName: 'HH',
        primaryColor: const Color(0xFF00D9F5),
        logoUrl: 'https://images.unsplash.com/photo-1589487391730-58f20eb2c308?w=120',
      );

      expect(regResult['success'], isTrue);
      expect(regResult['mode'], equals('hostApproval'));
      final pending = regResult['registration'] as PendingTeamRegistration;
      expect(auction.pendingRegistrations.length, equals(initialPendingCount + 1));

      // Host approves registration
      db.approveTeamRegistration(auction.id, pending.id);

      // Check team was added to tournament
      expect(db.teams.any((t) => t.name == 'Howrah Hawks'), isTrue);
      // Check registration marked approved
      final regItem = auction.pendingRegistrations.firstWhere((r) => r.id == pending.id);
      expect(regItem.isApproved, isTrue);
    });

    test('6. Host Controls: PIN regeneration and Joining Toggle', () {
      final db = MockDatabase(loadDemoSeed: true);
      final auction = db.auctions.first;
      final oldPin = auction.auctionPin;

      // Regenerate PIN
      final newPin = db.regenerateAuctionPin(auction.id);
      expect(newPin.length, equals(6));
      expect(auction.auctionPin, equals(newPin));
      expect(newPin, isNot(equals(oldPin)));

      // Toggle joining off
      db.toggleAuctionJoining(auction.id, false);
      expect(auction.isJoiningEnabled, isFalse);

      // Attempting to validate with new PIN when disabled fails
      final res = db.validateAuctionJoinCredentials(
        auctionIdOrCode: auction.auctionCode,
        auctionPin: newPin,
      );
      expect(res.isValid, isFalse);
      expect(res.errorMessage, contains('closed or paused'));
    });

    test('7. Scorer & Conductor Permission Gating', () {
      final db = MockDatabase(loadDemoSeed: true);
      db.logoutUser();
      final match = db.matches.first;
      final auction = db.auctions.first;

      // Unauthenticated -> cannot score or spin
      expect(db.canScoreMatch(match.id), isFalse);
      expect(db.canSpinPlayer(auction.id), isFalse);

      // Login as Scorer
      db.loginUser(emailOrMobile: 'scorer@cricpavilion.com', password: 'scorer123');
      expect(db.currentUser, isNotNull);
      expect(db.canScoreMatch(match.id), isTrue);

      // Scorer cannot spin auction gavel
      expect(db.canSpinPlayer(auction.id), isFalse);

      // Logout and login as Auctioneer
      db.logoutUser();
      db.loginUser(emailOrMobile: 'auctioneer@cricpavilion.com', password: 'gavel123');
      expect(db.canSpinPlayer(auction.id), isTrue);
    });

    test('8. Organizer-Controlled Player Management: Instant Direct Add', () {
      final db = MockDatabase(loadDemoSeed: true);
      final tournament = db.tournaments.first;
      final initialPlayerCount = db.players.length;

      final newPlayer = db.addPlayerDirectly(
        tournamentId: tournament.id,
        fullName: 'Soumya Sarkar',
        mobileNumber: '9830554433',
        role: PlayerRole.allRounder,
        battingStyle: 'Left Hand Bat',
        bowlingStyle: 'Right Arm Medium',
        basePrice: 500000,
      );

      expect(newPlayer.id, isNotEmpty);
      expect(newPlayer.fullName, equals('Soumya Sarkar'));
      expect(db.players.length, equals(initialPlayerCount + 1));
    });
  });
}
