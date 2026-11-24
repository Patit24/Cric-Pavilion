import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'mock_database.dart';

/// Permanent disk persistence service for Cricpavilion.
/// Automatically stores all matches, scorecards, deliveries, users, teams,
/// tournaments, and permanent player profiles in device storage / browser local storage.
class DatabasePersistenceService {
  static const String _keyHasPersistedData = 'cricpavilion_persisted_active';
  static const String _keyUsers = 'cricpavilion_db_users';
  static const String _keyCurrentUserId = 'cricpavilion_db_current_user_id';
  static const String _keyMatches = 'cricpavilion_db_matches';
  static const String _keyTournaments = 'cricpavilion_db_tournaments';
  static const String _keyTeams = 'cricpavilion_db_teams';
  static const String _keyPlayers = 'cricpavilion_db_players';
  static const String _keyInnings = 'cricpavilion_db_innings';
  static const String _keyDeliveries = 'cricpavilion_db_deliveries';
  static const String _keyBattingScorecards = 'cricpavilion_db_batting_scorecards';
  static const String _keyBowlingScorecards = 'cricpavilion_db_bowling_scorecards';
  static const String _keyAuditLogs = 'cricpavilion_db_audit_logs';

  static bool isPersistenceEnabled = false;
  static bool isPersisting = false;

  /// Saves the complete state of MockDatabase to permanent storage.
  static Future<void> saveDatabase(MockDatabase db) async {
    if (!isPersistenceEnabled) return;
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Users
      final usersJson = jsonEncode(db.users.map((u) => _userAccountToMap(u)).toList());
      await prefs.setString(_keyUsers, usersJson);

      // Current User ID
      if (db.currentUser != null) {
        await prefs.setString(_keyCurrentUserId, db.currentUser!.id);
      } else {
        await prefs.remove(_keyCurrentUserId);
      }

      // 2. Matches
      final matchesJson = jsonEncode(db.matches.map((m) => _matchToMap(m)).toList());
      await prefs.setString(_keyMatches, matchesJson);

      // 3. Tournaments
      final tournamentsJson = jsonEncode(db.tournaments.map((t) => _tournamentToMap(t)).toList());
      await prefs.setString(_keyTournaments, tournamentsJson);

      // 4. Teams
      final teamsJson = jsonEncode(db.teams.map((t) => _teamToMap(t)).toList());
      await prefs.setString(_keyTeams, teamsJson);

      // 5. Players
      final playersJson = jsonEncode(db.players.map((p) => _playerToMap(p)).toList());
      await prefs.setString(_keyPlayers, playersJson);

      // 6. Innings
      final inningsJson = jsonEncode(db.inningsList.map((i) => _inningsToMap(i)).toList());
      await prefs.setString(_keyInnings, inningsJson);

      // 7. Deliveries
      final deliveriesJson = jsonEncode(db.deliveries.map((d) => _deliveryToMap(d)).toList());
      await prefs.setString(_keyDeliveries, deliveriesJson);

      // 8. Batting Scorecards
      final battingJson = jsonEncode(db.battingScorecards.map((b) => _battingScorecardToMap(b)).toList());
      await prefs.setString(_keyBattingScorecards, battingJson);

      // 9. Bowling Scorecards
      final bowlingJson = jsonEncode(db.bowlingScorecards.map((bw) => _bowlingScorecardToMap(bw)).toList());
      await prefs.setString(_keyBowlingScorecards, bowlingJson);

      // 10. Audit Logs
      final auditJson = jsonEncode(db.auditLogs.map((a) => _auditLogToMap(a)).toList());
      await prefs.setString(_keyAuditLogs, auditJson);

      // Mark that valid persisted data exists
      await prefs.setBool(_keyHasPersistedData, true);
    } catch (e) {
      if (!e.toString().contains('MissingPluginException')) {
        debugPrint('DatabasePersistenceService save error: $e');
      }
    }
  }

  /// Loads saved state from permanent storage into MockDatabase.
  /// Returns true if saved data was found and restored; false otherwise.
  static Future<bool> loadDatabase(MockDatabase db) async {
    isPersistenceEnabled = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasData = prefs.getBool(_keyHasPersistedData) ?? false;
      if (!hasData) return false;

      // 1. Users
      final usersStr = prefs.getString(_keyUsers);
      if (usersStr != null && usersStr.isNotEmpty) {
        final List<dynamic> list = jsonDecode(usersStr);
        db.users = list.map((item) => _userAccountFromMap(item as Map<String, dynamic>)).toList();
      }

      // Current User
      final currentUserId = prefs.getString(_keyCurrentUserId);
      if (currentUserId != null && currentUserId.isNotEmpty) {
        db.currentUser = db.users.where((u) => u.id == currentUserId).firstOrNull;
      }

      // 2. Matches
      final matchesStr = prefs.getString(_keyMatches);
      if (matchesStr != null && matchesStr.isNotEmpty) {
        final List<dynamic> list = jsonDecode(matchesStr);
        db.matches = list.map((item) => _matchFromMap(item as Map<String, dynamic>)).toList();
      }

      // 3. Tournaments
      final tournsStr = prefs.getString(_keyTournaments);
      if (tournsStr != null && tournsStr.isNotEmpty) {
        final List<dynamic> list = jsonDecode(tournsStr);
        db.tournaments = list.map((item) => _tournamentFromMap(item as Map<String, dynamic>)).toList();
      }

      // 4. Teams
      final teamsStr = prefs.getString(_keyTeams);
      if (teamsStr != null && teamsStr.isNotEmpty) {
        final List<dynamic> list = jsonDecode(teamsStr);
        db.teams = list.map((item) => _teamFromMap(item as Map<String, dynamic>)).toList();
      }

      // 5. Players
      final playersStr = prefs.getString(_keyPlayers);
      if (playersStr != null && playersStr.isNotEmpty) {
        final List<dynamic> list = jsonDecode(playersStr);
        db.players = list.map((item) => _playerFromMap(item as Map<String, dynamic>)).toList();
      }

      // 6. Innings
      final inningsStr = prefs.getString(_keyInnings);
      if (inningsStr != null && inningsStr.isNotEmpty) {
        final List<dynamic> list = jsonDecode(inningsStr);
        db.inningsList = list.map((item) => _inningsFromMap(item as Map<String, dynamic>)).toList();
      }

      // 7. Deliveries
      final deliveriesStr = prefs.getString(_keyDeliveries);
      if (deliveriesStr != null && deliveriesStr.isNotEmpty) {
        final List<dynamic> list = jsonDecode(deliveriesStr);
        db.deliveries = list.map((item) => _deliveryFromMap(item as Map<String, dynamic>)).toList();
      }

      // 8. Batting Scorecards
      final battingStr = prefs.getString(_keyBattingScorecards);
      if (battingStr != null && battingStr.isNotEmpty) {
        final List<dynamic> list = jsonDecode(battingStr);
        db.battingScorecards = list.map((item) => _battingScorecardFromMap(item as Map<String, dynamic>)).toList();
      }

      // 9. Bowling Scorecards
      final bowlingStr = prefs.getString(_keyBowlingScorecards);
      if (bowlingStr != null && bowlingStr.isNotEmpty) {
        final List<dynamic> list = jsonDecode(bowlingStr);
        db.bowlingScorecards = list.map((item) => _bowlingScorecardFromMap(item as Map<String, dynamic>)).toList();
      }

      // 10. Audit Logs
      final auditStr = prefs.getString(_keyAuditLogs);
      if (auditStr != null && auditStr.isNotEmpty) {
        final List<dynamic> list = jsonDecode(auditStr);
        db.auditLogs.clear();
        db.auditLogs.addAll(list.map((item) => _auditLogFromMap(item as Map<String, dynamic>)));
      }

      return true;
    } catch (e) {
      debugPrint('DatabasePersistenceService load error: $e');
      return false;
    }
  }

  /// Clears all permanently saved database entries
  static Future<void> clearDatabase() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyHasPersistedData);
      await prefs.remove(_keyUsers);
      await prefs.remove(_keyCurrentUserId);
      await prefs.remove(_keyMatches);
      await prefs.remove(_keyTournaments);
      await prefs.remove(_keyTeams);
      await prefs.remove(_keyPlayers);
      await prefs.remove(_keyInnings);
      await prefs.remove(_keyDeliveries);
      await prefs.remove(_keyBattingScorecards);
      await prefs.remove(_keyBowlingScorecards);
      await prefs.remove(_keyAuditLogs);
    } catch (e) {
      debugPrint('DatabasePersistenceService clear error: $e');
    }
  }

  /// Exports entire MockDatabase state as a serializable JSON-compatible Map.
  static Map<String, dynamic> exportDatabaseToMap(MockDatabase db) {
    return {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'users': db.users.map((u) => _userAccountToMap(u)).toList(),
      'matches': db.matches.map((m) => _matchToMap(m)).toList(),
      'tournaments': db.tournaments.map((t) => _tournamentToMap(t)).toList(),
      'teams': db.teams.map((t) => _teamToMap(t)).toList(),
      'players': db.players.map((p) => _playerToMap(p)).toList(),
      'innings': db.inningsList.map((i) => _inningsToMap(i)).toList(),
      'deliveries': db.deliveries.map((d) => _deliveryToMap(d)).toList(),
      'battingScorecards': db.battingScorecards.map((b) => _battingScorecardToMap(b)).toList(),
      'bowlingScorecards': db.bowlingScorecards.map((bw) => _bowlingScorecardToMap(bw)).toList(),
      'auditLogs': db.auditLogs.map((a) => _auditLogToMap(a)).toList(),
    };
  }

  /// Exports entire MockDatabase state as a formatted JSON String.
  static String exportDatabaseToJson(MockDatabase db) {
    return jsonEncode(exportDatabaseToMap(db));
  }

  /// Intelligently merges an incoming database payload into MockDatabase.
  /// Deduplicates items by unique ID and persists the merged state.
  static bool mergeMapIntoDatabase(MockDatabase db, Map<String, dynamic> data) {
    bool hasChanges = false;
    try {
      // 1. Users
      if (data['users'] is List) {
        for (final item in data['users'] as List) {
          if (item is Map<String, dynamic>) {
            final u = _userAccountFromMap(item);
            final idx = db.users.indexWhere((existing) => existing.id == u.id);
            if (idx == -1) {
              db.users.add(u);
              hasChanges = true;
            }
          }
        }
      }

      // 2. Tournaments
      if (data['tournaments'] is List) {
        for (final item in data['tournaments'] as List) {
          if (item is Map<String, dynamic>) {
            final t = _tournamentFromMap(item);
            final idx = db.tournaments.indexWhere((existing) => existing.id == t.id);
            if (idx == -1) {
              db.tournaments.add(t);
              hasChanges = true;
            } else {
              db.tournaments[idx] = t;
              hasChanges = true;
            }
          }
        }
      }

      // 3. Teams
      if (data['teams'] is List) {
        for (final item in data['teams'] as List) {
          if (item is Map<String, dynamic>) {
            final tm = _teamFromMap(item);
            final idx = db.teams.indexWhere((existing) => existing.id == tm.id);
            if (idx == -1) {
              db.teams.add(tm);
              hasChanges = true;
            }
          }
        }
      }

      // 4. Players
      if (data['players'] is List) {
        for (final item in data['players'] as List) {
          if (item is Map<String, dynamic>) {
            final p = _playerFromMap(item);
            final idx = db.players.indexWhere((existing) => existing.id == p.id);
            if (idx == -1) {
              db.players.add(p);
              hasChanges = true;
            }
          }
        }
      }

      // 5. Matches
      if (data['matches'] is List) {
        for (final item in data['matches'] as List) {
          if (item is Map<String, dynamic>) {
            final m = _matchFromMap(item);
            final idx = db.matches.indexWhere((existing) => existing.id == m.id);
            if (idx == -1) {
              db.matches.add(m);
              hasChanges = true;
            } else {
              db.matches[idx] = m;
              hasChanges = true;
            }
          }
        }
      }

      // 6. Innings
      if (data['innings'] is List) {
        for (final item in data['innings'] as List) {
          if (item is Map<String, dynamic>) {
            final inn = _inningsFromMap(item);
            final idx = db.inningsList.indexWhere((existing) => existing.id == inn.id);
            if (idx == -1) {
              db.inningsList.add(inn);
              hasChanges = true;
            } else {
              db.inningsList[idx] = inn;
              hasChanges = true;
            }
          }
        }
      }

      // 7. Deliveries
      if (data['deliveries'] is List) {
        final existingDeliveryIds = db.deliveries.map((d) => d.id).toSet();
        for (final item in data['deliveries'] as List) {
          if (item is Map<String, dynamic>) {
            final d = _deliveryFromMap(item);
            if (!existingDeliveryIds.contains(d.id)) {
              db.deliveries.add(d);
              existingDeliveryIds.add(d.id);
              hasChanges = true;
            }
          }
        }
      }

      // 8. Batting Scorecards
      if (data['battingScorecards'] is List) {
        for (final item in data['battingScorecards'] as List) {
          if (item is Map<String, dynamic>) {
            final b = _battingScorecardFromMap(item);
            final idx = db.battingScorecards.indexWhere((existing) => existing.id == b.id);
            if (idx == -1) {
              db.battingScorecards.add(b);
              hasChanges = true;
            } else {
              db.battingScorecards[idx] = b;
              hasChanges = true;
            }
          }
        }
      }

      // 9. Bowling Scorecards
      if (data['bowlingScorecards'] is List) {
        for (final item in data['bowlingScorecards'] as List) {
          if (item is Map<String, dynamic>) {
            final bw = _bowlingScorecardFromMap(item);
            final idx = db.bowlingScorecards.indexWhere((existing) => existing.id == bw.id);
            if (idx == -1) {
              db.bowlingScorecards.add(bw);
              hasChanges = true;
            } else {
              db.bowlingScorecards[idx] = bw;
              hasChanges = true;
            }
          }
        }
      }

      // 10. Audit Logs
      if (data['auditLogs'] is List) {
        final existingAuditIds = db.auditLogs.map((a) => a.id).toSet();
        for (final item in data['auditLogs'] as List) {
          if (item is Map<String, dynamic>) {
            final a = _auditLogFromMap(item);
            if (!existingAuditIds.contains(a.id)) {
              db.auditLogs.add(a);
              existingAuditIds.add(a.id);
              hasChanges = true;
            }
          }
        }
      }

      if (hasChanges) {
        saveDatabase(db);
      }
    } catch (e) {
      debugPrint('DatabasePersistenceService merge error: $e');
    }
    return hasChanges;
  }

  // =========================================================================
  // SERIALIZERS & DESERIALIZERS
  // =========================================================================

  static Map<String, dynamic> _userAccountToMap(UserAccount u) => {
        'id': u.id,
        'fullName': u.fullName,
        'email': u.email,
        'mobileNumber': u.mobileNumber,
        'passwordHash': u.passwordHash,
        'createdAt': u.createdAt.toIso8601String(),
        'isMobileVerified': u.isMobileVerified,
        'linkedPlayerId': u.linkedPlayerId,
        'isGoogleAuthEnabled': u.isGoogleAuthEnabled,
        'googleAuthSecret': u.googleAuthSecret,
        'googleAuthRecoveryCodes': u.googleAuthRecoveryCodes,
        'googleAuthEnabledAt': u.googleAuthEnabledAt?.toIso8601String(),
        'isGoogleOAuthUser': u.isGoogleOAuthUser,
        'ownedTeamIds': u.ownedTeamIds,
        'conductorAuctionIds': u.conductorAuctionIds,
        'scorerMatchIds': u.scorerMatchIds,
        'tournamentRoles': u.tournamentRoles.map((k, v) => MapEntry(k, v.name)),
      };

  static UserAccount _userAccountFromMap(Map<String, dynamic> m) {
    final rolesMap = <String, AppUserRole>{};
    if (m['tournamentRoles'] != null) {
      final rawRoles = m['tournamentRoles'] as Map<String, dynamic>;
      rawRoles.forEach((k, v) {
        final role = AppUserRole.values.where((r) => r.name == v).firstOrNull;
        if (role != null) rolesMap[k] = role;
      });
    }

    return UserAccount(
      id: m['id'] as String,
      fullName: m['fullName'] as String? ?? 'User',
      email: m['email'] as String? ?? '',
      mobileNumber: m['mobileNumber'] as String? ?? '',
      passwordHash: m['passwordHash'] as String? ?? '',
      createdAt: m['createdAt'] != null ? DateTime.tryParse(m['createdAt'] as String) ?? DateTime.now() : DateTime.now(),
      isMobileVerified: m['isMobileVerified'] as bool? ?? false,
      linkedPlayerId: m['linkedPlayerId'] as String?,
      isGoogleAuthEnabled: m['isGoogleAuthEnabled'] as bool? ?? false,
      googleAuthSecret: m['googleAuthSecret'] as String?,
      googleAuthRecoveryCodes: (m['googleAuthRecoveryCodes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      googleAuthEnabledAt: m['googleAuthEnabledAt'] != null ? DateTime.tryParse(m['googleAuthEnabledAt'] as String) : null,
      isGoogleOAuthUser: m['isGoogleOAuthUser'] as bool? ?? false,
      ownedTeamIds: (m['ownedTeamIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      conductorAuctionIds: (m['conductorAuctionIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      scorerMatchIds: (m['scorerMatchIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      tournamentRoles: rolesMap,
    );
  }

  static Map<String, dynamic> _matchToMap(MatchModel m) => {
        'id': m.id,
        'tournamentId': m.tournamentId,
        'stage': m.stage,
        'teamAId': m.teamAId,
        'teamBId': m.teamBId,
        'venue': m.venue,
        'dateTime': m.dateTime.toIso8601String(),
        'overs': m.overs,
        'status': m.status.name,
        'tossWonBy': m.tossWonBy,
        'tossDecision': m.tossDecision,
        'battingFirstId': m.battingFirstId,
        'winnerId': m.winnerId,
        'winMargin': m.winMargin,
        'currentInningsNumber': m.currentInningsNumber,
        'playingXIA': m.playingXIA,
        'playingXIB': m.playingXIB,
        'captainAId': m.captainAId,
        'captainBId': m.captainBId,
        'keeperAId': m.keeperAId,
        'keeperBId': m.keeperBId,
        'playerOfTheMatchId': m.playerOfTheMatchId,
        'playerOfTheMatchName': m.playerOfTheMatchName,
        'isLocked': m.isLocked,
      };

  static MatchModel _matchFromMap(Map<String, dynamic> m) {
    final status = MatchStatus.values.where((s) => s.name == m['status']).firstOrNull ?? MatchStatus.scheduled;

    return MatchModel(
      id: m['id'] as String,
      tournamentId: m['tournamentId'] as String? ?? 'standalone',
      stage: m['stage'] as String? ?? 'Match',
      teamAId: m['teamAId'] as String? ?? '',
      teamBId: m['teamBId'] as String? ?? '',
      venue: m['venue'] as String? ?? 'Ground',
      dateTime: m['dateTime'] != null ? DateTime.tryParse(m['dateTime'] as String) ?? DateTime.now() : DateTime.now(),
      overs: m['overs'] as int? ?? 20,
      status: status,
      tossWonBy: m['tossWonBy'] as String?,
      tossDecision: m['tossDecision'] as String?,
      battingFirstId: m['battingFirstId'] as String?,
      winnerId: m['winnerId'] as String?,
      winMargin: m['winMargin'] as String?,
      currentInningsNumber: m['currentInningsNumber'] as int? ?? 1,
      playingXIA: (m['playingXIA'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      playingXIB: (m['playingXIB'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      captainAId: m['captainAId'] as String?,
      captainBId: m['captainBId'] as String?,
      keeperAId: m['keeperAId'] as String?,
      keeperBId: m['keeperBId'] as String?,
      playerOfTheMatchId: m['playerOfTheMatchId'] as String?,
      playerOfTheMatchName: m['playerOfTheMatchName'] as String?,
      isLocked: m['isLocked'] as bool? ?? false,
    );
  }

  static Map<String, dynamic> _tournamentToMap(Tournament t) => {
        'id': t.id,
        'name': t.name,
        'shortName': t.shortName,
        'location': t.location,
        'startDate': t.startDate,
        'endDate': t.endDate,
        'overs': t.overs,
        'totalTeams': t.totalTeams,
        'status': t.status,
        'bannerUrl': t.bannerUrl,
        'roomId': t.roomId,
        'passcode': t.passcode,
        'createdBy': t.createdBy,
      };

  static Tournament _tournamentFromMap(Map<String, dynamic> m) => Tournament(
        id: m['id'] as String,
        name: m['name'] as String? ?? 'Tournament',
        shortName: m['shortName'] as String? ?? 'TRN',
        location: m['location'] as String? ?? 'Ground',
        startDate: m['startDate'] as String? ?? '2026-01-01',
        endDate: m['endDate'] as String? ?? '2026-01-01',
        overs: m['overs'] as int? ?? 20,
        totalTeams: m['totalTeams'] as int? ?? 8,
        status: m['status'] as String? ?? 'draft',
        bannerUrl: m['bannerUrl'] as String? ?? '',
        roomId: m['roomId'] as String? ?? '',
        passcode: m['passcode'] as String? ?? '1234',
        createdBy: m['createdBy'] as String? ?? 'Official Board',
      );

  static Map<String, dynamic> _teamToMap(Team t) => {
        'id': t.id,
        'tournamentId': t.tournamentId,
        'name': t.name,
        'shortName': t.shortName,
        'uniqueTeamCode': t.uniqueTeamCode,
        'passcode': t.passcode,
        'ownerMobileNumber': t.ownerMobileNumber,
        'ownerName': t.ownerName,
        'primaryColor': t.primaryColor.toARGB32(),
        'logoUrl': t.logoUrl,
        'purseRemaining': t.purseRemaining,
        'maxPurse': t.maxPurse,
        'squadCount': t.squadCount,
        'minSquadRequirement': t.minSquadRequirement,
        'maxSquadLimit': t.maxSquadLimit,
        'overseasCount': t.overseasCount,
      };

  static Team _teamFromMap(Map<String, dynamic> m) {
    final colorInt = m['primaryColor'] as int? ?? 0xFF009270;
    return Team(
      id: m['id'] as String,
      tournamentId: m['tournamentId'] as String? ?? '',
      name: m['name'] as String? ?? 'Team',
      shortName: m['shortName'] as String? ?? 'TM',
      uniqueTeamCode: m['uniqueTeamCode'] as String? ?? '',
      passcode: m['passcode'] as String? ?? '1234',
      ownerMobileNumber: m['ownerMobileNumber'] as String? ?? '',
      ownerName: m['ownerName'] as String? ?? '',
      primaryColor: Color(colorInt),
      logoUrl: m['logoUrl'] as String? ?? '',
      purseRemaining: m['purseRemaining'] as int? ?? 10000000,
      maxPurse: m['maxPurse'] as int? ?? 10000000,
      squadCount: m['squadCount'] as int? ?? 0,
      minSquadRequirement: m['minSquadRequirement'] as int? ?? 15,
      maxSquadLimit: m['maxSquadLimit'] as int? ?? 18,
      overseasCount: m['overseasCount'] as int? ?? 0,
    );
  }

  static Map<String, dynamic> _playerToMap(Player p) => {
        'id': p.id,
        'permanentPlayerCode': p.permanentPlayerCode,
        'tournamentId': p.tournamentId,
        'fullName': p.fullName,
        'displayName': p.displayName,
        'mobileNumber': p.mobileNumber,
        'age': p.age,
        'dateOfBirth': p.dateOfBirth,
        'city': p.city,
        'role': p.role.name,
        'battingStyle': p.battingStyle,
        'bowlingStyle': p.bowlingStyle,
        'experienceYears': p.experienceYears,
        'category': p.category,
        'basePrice': p.basePrice,
        'photoUrl': p.photoUrl,
        'registrationStatus': p.registrationStatus.name,
        'auctionStatus': p.auctionStatus.name,
        'teamId': p.teamId,
        'soldPrice': p.soldPrice,
        'soldRound': p.soldRound,
        'soldTimestamp': p.soldTimestamp?.toIso8601String(),
        'isOverseas': p.isOverseas,
        'runs': p.runs,
        'wickets': p.wickets,
        'matches': p.matches,
        'registeredAt': p.registeredAt?.toIso8601String(),
        'registeredByOrganizerId': p.registeredByOrganizerId,
        'isMobileVerified': p.isMobileVerified,
        'teamHistory': p.teamHistory
            .map((th) => {
                  'teamId': th.teamId,
                  'teamName': th.teamName,
                  'tournamentId': th.tournamentId,
                  'tournamentName': th.tournamentName,
                  'year': th.year,
                  'joinedAt': th.joinedAt.toIso8601String(),
                  'leftAt': th.leftAt?.toIso8601String(),
                })
            .toList(),
      };

  static Player _playerFromMap(Map<String, dynamic> m) {
    final role = PlayerRole.values.where((r) => r.name == m['role']).firstOrNull ?? PlayerRole.batsman;
    final regStatus = PlayerRegistrationStatus.values.where((s) => s.name == m['registrationStatus']).firstOrNull ?? PlayerRegistrationStatus.approved;
    final aucStatus = PlayerAuctionStatus.values.where((s) => s.name == m['auctionStatus']).firstOrNull ?? PlayerAuctionStatus.available;

    final List<PlayerTeamHistory> history = [];
    if (m['teamHistory'] != null) {
      final List<dynamic> rawList = m['teamHistory'];
      for (final item in rawList) {
        final hm = item as Map<String, dynamic>;
        history.add(PlayerTeamHistory(
          teamId: hm['teamId'] as String? ?? '',
          teamName: hm['teamName'] as String? ?? 'Team',
          tournamentId: hm['tournamentId'] as String?,
          tournamentName: hm['tournamentName'] as String?,
          year: hm['year'] as int? ?? DateTime.now().year,
          joinedAt: hm['joinedAt'] != null ? DateTime.tryParse(hm['joinedAt'] as String) ?? DateTime.now() : DateTime.now(),
          leftAt: hm['leftAt'] != null ? DateTime.tryParse(hm['leftAt'] as String) : null,
        ));
      }
    }

    return Player(
      id: m['id'] as String,
      permanentPlayerCode: m['permanentPlayerCode'] as String?,
      tournamentId: m['tournamentId'] as String? ?? '',
      fullName: m['fullName'] as String? ?? 'Player',
      displayName: m['displayName'] as String? ?? 'Player',
      mobileNumber: m['mobileNumber'] as String? ?? '',
      age: m['age'] as int? ?? 24,
      dateOfBirth: m['dateOfBirth'] as String? ?? '2000-01-01',
      city: m['city'] as String? ?? 'Kolkata',
      role: role,
      battingStyle: m['battingStyle'] as String? ?? 'Right Hand Bat',
      bowlingStyle: m['bowlingStyle'] as String? ?? 'Right Arm Medium',
      experienceYears: m['experienceYears'] as int? ?? 3,
      category: m['category'] as String? ?? 'Batsman',
      basePrice: m['basePrice'] as int? ?? 500,
      photoUrl: m['photoUrl'] as String? ?? 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=256',
      registrationStatus: regStatus,
      auctionStatus: aucStatus,
      teamId: m['teamId'] as String?,
      soldPrice: m['soldPrice'] as int?,
      soldRound: m['soldRound'] as int?,
      soldTimestamp: m['soldTimestamp'] != null ? DateTime.tryParse(m['soldTimestamp'] as String) : null,
      isOverseas: m['isOverseas'] as bool? ?? false,
      runs: m['runs'] as int? ?? 0,
      wickets: m['wickets'] as int? ?? 0,
      matches: m['matches'] as int? ?? 0,
      registeredAt: m['registeredAt'] != null ? DateTime.tryParse(m['registeredAt'] as String) : null,
      registeredByOrganizerId: m['registeredByOrganizerId'] as String?,
      isMobileVerified: m['isMobileVerified'] as bool? ?? false,
      teamHistory: history,
    );
  }

  static Map<String, dynamic> _inningsToMap(Innings i) => {
        'id': i.id,
        'matchId': i.matchId,
        'inningsNumber': i.inningsNumber,
        'battingTeamId': i.battingTeamId,
        'bowlingTeamId': i.bowlingTeamId,
        'totalRuns': i.totalRuns,
        'wickets': i.wickets,
        'legalBalls': i.legalBalls,
        'oversStr': i.oversStr,
        'extrasWides': i.extrasWides,
        'extrasNoBalls': i.extrasNoBalls,
        'extrasByes': i.extrasByes,
        'extrasLegByes': i.extrasLegByes,
        'totalExtras': i.totalExtras,
        'isCompleted': i.isCompleted,
        'currentStrikerId': i.currentStrikerId,
        'currentNonStrikerId': i.currentNonStrikerId,
        'currentBowlerId': i.currentBowlerId,
        'targetRuns': i.targetRuns,
      };

  static Innings _inningsFromMap(Map<String, dynamic> m) => Innings(
        id: m['id'] as String,
        matchId: m['matchId'] as String? ?? '',
        inningsNumber: m['inningsNumber'] as int? ?? 1,
        battingTeamId: m['battingTeamId'] as String? ?? '',
        bowlingTeamId: m['bowlingTeamId'] as String? ?? '',
        totalRuns: m['totalRuns'] as int? ?? 0,
        wickets: m['wickets'] as int? ?? 0,
        legalBalls: m['legalBalls'] as int? ?? 0,
        oversStr: m['oversStr'] as String? ?? '0.0',
        extrasWides: m['extrasWides'] as int? ?? 0,
        extrasNoBalls: m['extrasNoBalls'] as int? ?? 0,
        extrasByes: m['extrasByes'] as int? ?? 0,
        extrasLegByes: m['extrasLegByes'] as int? ?? 0,
        totalExtras: m['totalExtras'] as int? ?? 0,
        isCompleted: m['isCompleted'] as bool? ?? false,
        currentStrikerId: m['currentStrikerId'] as String?,
        currentNonStrikerId: m['currentNonStrikerId'] as String?,
        currentBowlerId: m['currentBowlerId'] as String?,
        targetRuns: m['targetRuns'] as int?,
      );

  static Map<String, dynamic> _deliveryToMap(Delivery d) => {
        'id': d.id,
        'inningsId': d.inningsId,
        'matchId': d.matchId,
        'overNumber': d.overNumber,
        'ballInOver': d.ballInOver,
        'deliverySequence': d.deliverySequence,
        'strikerId': d.strikerId,
        'nonStrikerId': d.nonStrikerId,
        'bowlerId': d.bowlerId,
        'runsBatter': d.runsBatter,
        'extrasRuns': d.extrasRuns,
        'isLegal': d.isLegal,
        'isWicket': d.isWicket,
        'extrasType': d.extrasType.name,
        'dismissalType': d.dismissalType?.name,
        'dismissedPlayerId': d.dismissedPlayerId,
        'fielderId': d.fielderId,
        'commentaryText': d.commentaryText,
        'timestamp': d.timestamp.toIso8601String(),
        'isUndone': d.isUndone,
      };

  static Delivery _deliveryFromMap(Map<String, dynamic> m) {
    final extrasType = ExtrasType.values.where((e) => e.name == m['extrasType']).firstOrNull ?? ExtrasType.none;
    final dismissalType = DismissalType.values.where((d) => d.name == m['dismissalType']).firstOrNull;

    return Delivery(
      id: m['id'] as String,
      inningsId: m['inningsId'] as String? ?? '',
      matchId: m['matchId'] as String? ?? '',
      overNumber: m['overNumber'] as int? ?? 0,
      ballInOver: m['ballInOver'] as int? ?? 1,
      deliverySequence: m['deliverySequence'] as int? ?? 1,
      strikerId: m['strikerId'] as String? ?? '',
      nonStrikerId: m['nonStrikerId'] as String? ?? '',
      bowlerId: m['bowlerId'] as String? ?? '',
      runsBatter: m['runsBatter'] as int? ?? 0,
      extrasRuns: m['extrasRuns'] as int? ?? 0,
      isLegal: m['isLegal'] as bool? ?? true,
      isWicket: m['isWicket'] as bool? ?? false,
      extrasType: extrasType,
      dismissalType: dismissalType,
      dismissedPlayerId: m['dismissedPlayerId'] as String?,
      fielderId: m['fielderId'] as String?,
      commentaryText: m['commentaryText'] as String? ?? '',
      timestamp: m['timestamp'] != null ? DateTime.tryParse(m['timestamp'] as String) ?? DateTime.now() : DateTime.now(),
      isUndone: m['isUndone'] as bool? ?? false,
    );
  }

  static Map<String, dynamic> _battingScorecardToMap(BattingScorecard b) => {
        'id': b.id,
        'inningsId': b.inningsId,
        'matchId': b.matchId,
        'playerId': b.playerId,
        'playerName': b.playerName,
        'runs': b.runs,
        'balls': b.balls,
        'fours': b.fours,
        'sixes': b.sixes,
        'strikeRate': b.strikeRate,
        'dismissalText': b.dismissalText,
        'isOut': b.isOut,
      };

  static BattingScorecard _battingScorecardFromMap(Map<String, dynamic> m) => BattingScorecard(
        id: m['id'] as String,
        inningsId: m['inningsId'] as String? ?? '',
        matchId: m['matchId'] as String? ?? '',
        playerId: m['playerId'] as String? ?? '',
        playerName: m['playerName'] as String? ?? 'Batter',
        runs: m['runs'] as int? ?? 0,
        balls: m['balls'] as int? ?? 0,
        fours: m['fours'] as int? ?? 0,
        sixes: m['sixes'] as int? ?? 0,
        strikeRate: (m['strikeRate'] as num?)?.toDouble() ?? 0.0,
        dismissalText: m['dismissalText'] as String? ?? 'not out',
        isOut: m['isOut'] as bool? ?? false,
      );

  static Map<String, dynamic> _bowlingScorecardToMap(BowlingScorecard bw) => {
        'id': bw.id,
        'inningsId': bw.inningsId,
        'matchId': bw.matchId,
        'playerId': bw.playerId,
        'playerName': bw.playerName,
        'oversStr': bw.oversStr,
        'legalBalls': bw.legalBalls,
        'maidens': bw.maidens,
        'runsConceded': bw.runsConceded,
        'wickets': bw.wickets,
        'dots': bw.dots,
        'economy': bw.economy,
      };

  static BowlingScorecard _bowlingScorecardFromMap(Map<String, dynamic> m) => BowlingScorecard(
        id: m['id'] as String,
        inningsId: m['inningsId'] as String? ?? '',
        matchId: m['matchId'] as String? ?? '',
        playerId: m['playerId'] as String? ?? '',
        playerName: m['playerName'] as String? ?? 'Bowler',
        oversStr: m['oversStr'] as String? ?? '0.0',
        legalBalls: m['legalBalls'] as int? ?? 0,
        maidens: m['maidens'] as int? ?? 0,
        runsConceded: m['runsConceded'] as int? ?? 0,
        wickets: m['wickets'] as int? ?? 0,
        dots: m['dots'] as int? ?? 0,
        economy: (m['economy'] as num?)?.toDouble() ?? 0.0,
      );

  static Map<String, dynamic> _auditLogToMap(AuditLog a) => {
        'id': a.id,
        'timestamp': a.timestamp.toIso8601String(),
        'category': a.category,
        'action': a.action,
        'details': a.details,
        'performedBy': a.performedBy,
        'tournamentId': a.tournamentId,
        'auctionId': a.auctionId,
        'role': a.role,
      };

  static AuditLog _auditLogFromMap(Map<String, dynamic> m) => AuditLog(
        id: m['id'] as String,
        timestamp: m['timestamp'] != null ? DateTime.tryParse(m['timestamp'] as String) ?? DateTime.now() : DateTime.now(),
        category: m['category'] as String? ?? '',
        action: m['action'] as String? ?? '',
        details: m['details'] as String? ?? '',
        performedBy: m['performedBy'] as String? ?? '',
        tournamentId: m['tournamentId'] as String? ?? '',
        auctionId: m['auctionId'] as String? ?? '',
        role: m['role'] as String? ?? '',
      );
}
