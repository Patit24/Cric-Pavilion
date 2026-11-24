import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'database_persistence_service.dart';
import 'mock_database.dart';

/// Cloud Firestore Realtime Database Synchronization Service for CricPavilion.
/// Enables seamless instant scoring updates and tournament synchronization
/// across Mobile phones, Desktop web browsers, and spectator devices worldwide.
class FirestoreDatabaseService {
  /// Checks whether Firebase has been initialized in the current environment
  static bool get isFirebaseAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static FirebaseFirestore? get _firestore => isFirebaseAvailable ? FirebaseFirestore.instance : null;
  static FirebaseAuth? get _auth => isFirebaseAvailable ? FirebaseAuth.instance : null;

  static bool isInitialized = false;
  static bool isApplyingCloudUpdate = false;
  static DateTime? lastCloudSyncTime;
  static String lastSyncStatus = 'Not connected';
  static int cloudSyncCount = 0;

  static final List<StreamSubscription<dynamic>> _subscriptions = [];
  static Timer? _debouncePushTimer;

  // Collection names in Firestore
  static const String colMatches = 'matches';
  static const String colInnings = 'innings';
  static const String colDeliveries = 'deliveries';
  static const String colBattingScorecards = 'batting_scorecards';
  static const String colBowlingScorecards = 'bowling_scorecards';
  static const String colTournaments = 'tournaments';
  static const String colTeams = 'teams';
  static const String colPlayers = 'players';
  static const String colUsers = 'users';

  /// Initializes real-time Firestore listeners and performs initial sync.
  static Future<void> init(MockDatabase db) async {
    if (!isFirebaseAvailable || isInitialized) return;

    try {
      lastSyncStatus = 'Connecting to Cloud Firestore...';

      // 1. Ensure user authentication if a user is currently logged in locally
      if (db.currentUser != null) {
        await ensureFirebaseAuthForUser(db.currentUser);
      }

      // 2. Perform initial pull from Cloud Firestore to hydrate local state
      await _pullInitialCloudState(db);

      // 3. Push any local records that don't exist in Firestore yet (e.g. offline created matches)
      await _pushMissingLocalRecords(db);

      // 4. Start Real-time Stream Listeners on Firestore collections
      _setupRealtimeListeners(db);

      isInitialized = true;
      lastSyncStatus = 'Live connected (Firestore)';
      lastCloudSyncTime = DateTime.now();
      debugPrint('[FirestoreDatabaseService] Successfully connected to Cloud Firestore (cricpavilion-750c5)');
    } catch (e) {
      lastSyncStatus = 'Connection error: $e';
      debugPrint('[FirestoreDatabaseService] Initialization notice: $e');
    }
  }

  /// Cancels all active Firestore listeners
  static void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    _debouncePushTimer?.cancel();
    isInitialized = false;
  }

  /// Ensures Firebase Auth has an active session for the logged in user
  static Future<bool> ensureFirebaseAuthForUser(UserAccount? user) async {
    if (!isFirebaseAvailable || _auth == null) return false;

    if (_auth!.currentUser != null) {
      return true;
    }
    if (user == null) return false;

    try {
      final email = user.email.isNotEmpty
          ? user.email.trim()
          : 'user_${user.id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')}@cricpavilion.app';
      final password = user.passwordHash.isNotEmpty && user.passwordHash.length >= 6
          ? user.passwordHash
          : 'CricPavilion!2026';

      try {
        await _auth!.signInWithEmailAndPassword(email: email, password: password);
        return true;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
          // Provision account in Firebase Auth
          await _auth!.createUserWithEmailAndPassword(email: email, password: password);
          return true;
        }
      }
    } catch (e) {
      debugPrint('[FirestoreDatabaseService] FirebaseAuth bridge notice: $e');
    }
    return _auth?.currentUser != null;
  }

  /// Sanitizes map payload so fields with null values are removed or conform to Firestore rules.
  static Map<String, dynamic> _sanitizePayload(Map<String, dynamic> map) {
    final clean = Map<String, dynamic>.from(map);
    clean.removeWhere((key, value) => value == null);
    return clean;
  }

  // =========================================================================
  // REAL-TIME FIRESTORE LISTENERS
  // =========================================================================

  static void _setupRealtimeListeners(MockDatabase db) {
    if (!isFirebaseAvailable || _firestore == null) return;

    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();

    // 1. Matches Realtime Stream
    final matchSub = _firestore!.collection(colMatches).snapshots().listen((snapshot) {
      if (snapshot.docChanges.isEmpty) return;
      isApplyingCloudUpdate = true;
      try {
        bool changed = false;
        for (final change in snapshot.docChanges) {
          final data = change.doc.data();
          if (data == null) continue;
          final match = DatabasePersistenceService.matchFromMap(data);
          final idx = db.matches.indexWhere((m) => m.id == match.id);
          if (idx == -1) {
            db.matches.add(match);
            changed = true;
          } else {
            // Update existing match if cloud has updated status or score
            db.matches[idx] = match;
            changed = true;
          }
        }
        if (changed) {
          lastCloudSyncTime = DateTime.now();
          cloudSyncCount++;
          db.notifyListeners();
          DatabasePersistenceService.saveDatabase(db);
        }
      } catch (e) {
        debugPrint('[FirestoreDatabaseService] matches listener error: $e');
      } finally {
        isApplyingCloudUpdate = false;
      }
    }, onError: (err) {
      debugPrint('[FirestoreDatabaseService] matches stream error: $err');
    });
    _subscriptions.add(matchSub);

    // 2. Innings Realtime Stream
    final inningsSub = _firestore!.collection(colInnings).snapshots().listen((snapshot) {
      if (snapshot.docChanges.isEmpty) return;
      isApplyingCloudUpdate = true;
      try {
        bool changed = false;
        for (final change in snapshot.docChanges) {
          final data = change.doc.data();
          if (data == null) continue;
          final inn = DatabasePersistenceService.inningsFromMap(data);
          final idx = db.inningsList.indexWhere((i) => i.id == inn.id);
          if (idx == -1) {
            db.inningsList.add(inn);
            changed = true;
          } else {
            db.inningsList[idx] = inn;
            changed = true;
          }
        }
        if (changed) {
          lastCloudSyncTime = DateTime.now();
          db.notifyListeners();
          DatabasePersistenceService.saveDatabase(db);
        }
      } catch (e) {
        debugPrint('[FirestoreDatabaseService] innings listener error: $e');
      } finally {
        isApplyingCloudUpdate = false;
      }
    }, onError: (err) {
      debugPrint('[FirestoreDatabaseService] innings stream error: $err');
    });
    _subscriptions.add(inningsSub);

    // 3. Deliveries Realtime Stream (Ball-by-Ball)
    final deliverySub = _firestore!.collection(colDeliveries).snapshots().listen((snapshot) {
      if (snapshot.docChanges.isEmpty) return;
      isApplyingCloudUpdate = true;
      try {
        bool changed = false;
        final existingIds = db.deliveries.map((d) => d.id).toSet();
        for (final change in snapshot.docChanges) {
          final data = change.doc.data();
          if (data == null) continue;
          final del = DatabasePersistenceService.deliveryFromMap(data);
          if (!existingIds.contains(del.id)) {
            db.deliveries.add(del);
            existingIds.add(del.id);
            changed = true;
          } else {
            final idx = db.deliveries.indexWhere((d) => d.id == del.id);
            if (idx != -1 && db.deliveries[idx].isUndone != del.isUndone) {
              db.deliveries[idx] = del;
              changed = true;
            }
          }
        }
        if (changed) {
          // Keep deliveries sorted by sequence
          db.deliveries.sort((a, b) => a.deliverySequence.compareTo(b.deliverySequence));
          lastCloudSyncTime = DateTime.now();
          db.notifyListeners();
          DatabasePersistenceService.saveDatabase(db);
        }
      } catch (e) {
        debugPrint('[FirestoreDatabaseService] deliveries listener error: $e');
      } finally {
        isApplyingCloudUpdate = false;
      }
    }, onError: (err) {
      debugPrint('[FirestoreDatabaseService] deliveries stream error: $err');
    });
    _subscriptions.add(deliverySub);

    // 4. Batting Scorecards Stream
    final batSub = _firestore!.collection(colBattingScorecards).snapshots().listen((snapshot) {
      if (snapshot.docChanges.isEmpty) return;
      isApplyingCloudUpdate = true;
      try {
        bool changed = false;
        for (final change in snapshot.docChanges) {
          final data = change.doc.data();
          if (data == null) continue;
          final b = DatabasePersistenceService.battingScorecardFromMap(data);
          final idx = db.battingScorecards.indexWhere((existing) => existing.id == b.id);
          if (idx == -1) {
            db.battingScorecards.add(b);
            changed = true;
          } else {
            db.battingScorecards[idx] = b;
            changed = true;
          }
        }
        if (changed) {
          lastCloudSyncTime = DateTime.now();
          db.notifyListeners();
          DatabasePersistenceService.saveDatabase(db);
        }
      } catch (e) {
        debugPrint('[FirestoreDatabaseService] batting scorecards listener error: $e');
      } finally {
        isApplyingCloudUpdate = false;
      }
    }, onError: (err) {
      debugPrint('[FirestoreDatabaseService] batting scorecards stream error: $err');
    });
    _subscriptions.add(batSub);

    // 5. Bowling Scorecards Stream
    final bowlSub = _firestore!.collection(colBowlingScorecards).snapshots().listen((snapshot) {
      if (snapshot.docChanges.isEmpty) return;
      isApplyingCloudUpdate = true;
      try {
        bool changed = false;
        for (final change in snapshot.docChanges) {
          final data = change.doc.data();
          if (data == null) continue;
          final bw = DatabasePersistenceService.bowlingScorecardFromMap(data);
          final idx = db.bowlingScorecards.indexWhere((existing) => existing.id == bw.id);
          if (idx == -1) {
            db.bowlingScorecards.add(bw);
            changed = true;
          } else {
            db.bowlingScorecards[idx] = bw;
            changed = true;
          }
        }
        if (changed) {
          lastCloudSyncTime = DateTime.now();
          db.notifyListeners();
          DatabasePersistenceService.saveDatabase(db);
        }
      } catch (e) {
        debugPrint('[FirestoreDatabaseService] bowling scorecards listener error: $e');
      } finally {
        isApplyingCloudUpdate = false;
      }
    }, onError: (err) {
      debugPrint('[FirestoreDatabaseService] bowling scorecards stream error: $err');
    });
    _subscriptions.add(bowlSub);

    // 6. Tournaments Stream
    final tournSub = _firestore!.collection(colTournaments).snapshots().listen((snapshot) {
      if (snapshot.docChanges.isEmpty) return;
      isApplyingCloudUpdate = true;
      try {
        bool changed = false;
        for (final change in snapshot.docChanges) {
          final data = change.doc.data();
          if (data == null) continue;
          final t = DatabasePersistenceService.tournamentFromMap(data);
          final idx = db.tournaments.indexWhere((existing) => existing.id == t.id);
          if (idx == -1) {
            db.tournaments.add(t);
            changed = true;
          } else {
            db.tournaments[idx] = t;
            changed = true;
          }
        }
        if (changed) {
          db.notifyListeners();
          DatabasePersistenceService.saveDatabase(db);
        }
      } catch (e) {
        debugPrint('[FirestoreDatabaseService] tournaments listener error: $e');
      } finally {
        isApplyingCloudUpdate = false;
      }
    }, onError: (err) {
      debugPrint('[FirestoreDatabaseService] tournaments stream error: $err');
    });
    _subscriptions.add(tournSub);

    // 7. Teams Stream
    final teamSub = _firestore!.collection(colTeams).snapshots().listen((snapshot) {
      if (snapshot.docChanges.isEmpty) return;
      isApplyingCloudUpdate = true;
      try {
        bool changed = false;
        for (final change in snapshot.docChanges) {
          final data = change.doc.data();
          if (data == null) continue;
          final tm = DatabasePersistenceService.teamFromMap(data);
          final idx = db.teams.indexWhere((existing) => existing.id == tm.id);
          if (idx == -1) {
            db.teams.add(tm);
            changed = true;
          } else {
            db.teams[idx] = tm;
            changed = true;
          }
        }
        if (changed) {
          db.notifyListeners();
          DatabasePersistenceService.saveDatabase(db);
        }
      } catch (e) {
        debugPrint('[FirestoreDatabaseService] teams listener error: $e');
      } finally {
        isApplyingCloudUpdate = false;
      }
    }, onError: (err) {
      debugPrint('[FirestoreDatabaseService] teams stream error: $err');
    });
    _subscriptions.add(teamSub);

    // 8. Players Stream
    final playerSub = _firestore!.collection(colPlayers).snapshots().listen((snapshot) {
      if (snapshot.docChanges.isEmpty) return;
      isApplyingCloudUpdate = true;
      try {
        bool changed = false;
        for (final change in snapshot.docChanges) {
          final data = change.doc.data();
          if (data == null) continue;
          final p = DatabasePersistenceService.playerFromMap(data);
          final idx = db.players.indexWhere((existing) => existing.id == p.id);
          if (idx == -1) {
            db.players.add(p);
            changed = true;
          } else {
            db.players[idx] = p;
            changed = true;
          }
        }
        if (changed) {
          db.notifyListeners();
          DatabasePersistenceService.saveDatabase(db);
        }
      } catch (e) {
        debugPrint('[FirestoreDatabaseService] players listener error: $e');
      } finally {
        isApplyingCloudUpdate = false;
      }
    }, onError: (err) {
      debugPrint('[FirestoreDatabaseService] players stream error: $err');
    });
    _subscriptions.add(playerSub);
  }

  // =========================================================================
  // INITIAL PULL & SEED
  // =========================================================================

  static Future<void> _pullInitialCloudState(MockDatabase db) async {
    if (!isFirebaseAvailable || _firestore == null) return;

    isApplyingCloudUpdate = true;
    try {
      bool changed = false;

      // 1. Tournaments
      final tournSnap = await _firestore!.collection(colTournaments).get();
      for (final doc in tournSnap.docs) {
        final t = DatabasePersistenceService.tournamentFromMap(doc.data());
        final idx = db.tournaments.indexWhere((existing) => existing.id == t.id);
        if (idx == -1) {
          db.tournaments.add(t);
          changed = true;
        } else {
          db.tournaments[idx] = t;
        }
      }

      // 2. Teams
      final teamSnap = await _firestore!.collection(colTeams).get();
      for (final doc in teamSnap.docs) {
        final tm = DatabasePersistenceService.teamFromMap(doc.data());
        final idx = db.teams.indexWhere((existing) => existing.id == tm.id);
        if (idx == -1) {
          db.teams.add(tm);
          changed = true;
        } else {
          db.teams[idx] = tm;
        }
      }

      // 3. Players
      final playerSnap = await _firestore!.collection(colPlayers).get();
      for (final doc in playerSnap.docs) {
        final p = DatabasePersistenceService.playerFromMap(doc.data());
        final idx = db.players.indexWhere((existing) => existing.id == p.id);
        if (idx == -1) {
          db.players.add(p);
          changed = true;
        } else {
          db.players[idx] = p;
        }
      }

      // 4. Matches
      final matchSnap = await _firestore!.collection(colMatches).get();
      for (final doc in matchSnap.docs) {
        final m = DatabasePersistenceService.matchFromMap(doc.data());
        final idx = db.matches.indexWhere((existing) => existing.id == m.id);
        if (idx == -1) {
          db.matches.add(m);
          changed = true;
        } else {
          db.matches[idx] = m;
        }
      }

      // 5. Innings
      final inningsSnap = await _firestore!.collection(colInnings).get();
      for (final doc in inningsSnap.docs) {
        final inn = DatabasePersistenceService.inningsFromMap(doc.data());
        final idx = db.inningsList.indexWhere((existing) => existing.id == inn.id);
        if (idx == -1) {
          db.inningsList.add(inn);
          changed = true;
        } else {
          db.inningsList[idx] = inn;
        }
      }

      // 6. Deliveries
      final delivSnap = await _firestore!.collection(colDeliveries).get();
      final existingDelIds = db.deliveries.map((d) => d.id).toSet();
      for (final doc in delivSnap.docs) {
        final d = DatabasePersistenceService.deliveryFromMap(doc.data());
        if (!existingDelIds.contains(d.id)) {
          db.deliveries.add(d);
          existingDelIds.add(d.id);
          changed = true;
        }
      }
      db.deliveries.sort((a, b) => a.deliverySequence.compareTo(b.deliverySequence));

      // 7. Batting Scorecards
      final batSnap = await _firestore!.collection(colBattingScorecards).get();
      for (final doc in batSnap.docs) {
        final b = DatabasePersistenceService.battingScorecardFromMap(doc.data());
        final idx = db.battingScorecards.indexWhere((existing) => existing.id == b.id);
        if (idx == -1) {
          db.battingScorecards.add(b);
          changed = true;
        } else {
          db.battingScorecards[idx] = b;
        }
      }

      // 8. Bowling Scorecards
      final bowlSnap = await _firestore!.collection(colBowlingScorecards).get();
      for (final doc in bowlSnap.docs) {
        final bw = DatabasePersistenceService.bowlingScorecardFromMap(doc.data());
        final idx = db.bowlingScorecards.indexWhere((existing) => existing.id == bw.id);
        if (idx == -1) {
          db.bowlingScorecards.add(bw);
          changed = true;
        } else {
          db.bowlingScorecards[idx] = bw;
        }
      }

      if (changed) {
        db.notifyListeners();
        DatabasePersistenceService.saveDatabase(db);
      }
    } catch (e) {
      debugPrint('[FirestoreDatabaseService] pullInitialCloudState notice: $e');
    } finally {
      isApplyingCloudUpdate = false;
    }
  }

  /// Pushes any locally created tournaments, teams, players, or matches to Firestore
  /// so that if a match was created while offline or before connection, it becomes visible to all devices.
  static Future<void> _pushMissingLocalRecords(MockDatabase db) async {
    if (!isFirebaseAvailable || _firestore == null) return;

    final isAuth = await ensureFirebaseAuthForUser(db.currentUser);
    if (!isAuth) return;

    try {
      // Push Tournaments
      for (final t in db.tournaments) {
        await pushTournament(t);
      }
      // Push Teams
      for (final tm in db.teams) {
        await pushTeam(tm);
      }
      // Push Players
      for (final p in db.players) {
        await pushPlayer(p);
      }
      // Push Matches
      for (final m in db.matches) {
        await pushMatch(m);
      }
      // Push Innings
      for (final inn in db.inningsList) {
        await pushInnings(inn);
      }
      // Push Batting Scorecards
      for (final b in db.battingScorecards) {
        await pushBattingScorecard(b);
      }
      // Push Bowling Scorecards
      for (final bw in db.bowlingScorecards) {
        await pushBowlingScorecard(bw);
      }
      // Push Deliveries
      for (final d in db.deliveries) {
        await pushDelivery(d);
      }
    } catch (e) {
      debugPrint('[FirestoreDatabaseService] pushMissingLocalRecords notice: $e');
    }
  }

  // =========================================================================
  // DIRECT OUTBOUND WRITES (ATOMIC & REALTIME)
  // =========================================================================

  /// Pushes single Match to Firestore
  static Future<void> pushMatch(MatchModel match) async {
    if (!isFirebaseAvailable || _firestore == null) return;
    try {
      final isAuth = await ensureFirebaseAuthForUser(null);
      if (!isAuth) return;
      final payload = _sanitizePayload(DatabasePersistenceService.matchToMap(match));
      await _firestore!.collection(colMatches).doc(match.id).set(payload, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[FirestoreDatabaseService] pushMatch error: $e');
    }
  }

  /// Pushes single Innings to Firestore
  static Future<void> pushInnings(Innings innings) async {
    if (!isFirebaseAvailable || _firestore == null) return;
    try {
      final isAuth = await ensureFirebaseAuthForUser(null);
      if (!isAuth) return;
      final payload = _sanitizePayload(DatabasePersistenceService.inningsToMap(innings));
      await _firestore!.collection(colInnings).doc(innings.id).set(payload, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[FirestoreDatabaseService] pushInnings error: $e');
    }
  }

  /// Pushes single Delivery (ball-by-ball) to Firestore
  static Future<void> pushDelivery(Delivery delivery) async {
    if (!isFirebaseAvailable || _firestore == null) return;
    try {
      final isAuth = await ensureFirebaseAuthForUser(null);
      if (!isAuth) return;
      final payload = _sanitizePayload(DatabasePersistenceService.deliveryToMap(delivery));
      await _firestore!.collection(colDeliveries).doc(delivery.id).set(payload, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[FirestoreDatabaseService] pushDelivery error: $e');
    }
  }

  /// Pushes single BattingScorecard to Firestore
  static Future<void> pushBattingScorecard(BattingScorecard card) async {
    if (!isFirebaseAvailable || _firestore == null) return;
    try {
      final isAuth = await ensureFirebaseAuthForUser(null);
      if (!isAuth) return;
      final payload = _sanitizePayload(DatabasePersistenceService.battingScorecardToMap(card));
      await _firestore!.collection(colBattingScorecards).doc(card.id).set(payload, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[FirestoreDatabaseService] pushBattingScorecard error: $e');
    }
  }

  /// Pushes single BowlingScorecard to Firestore
  static Future<void> pushBowlingScorecard(BowlingScorecard card) async {
    if (!isFirebaseAvailable || _firestore == null) return;
    try {
      final isAuth = await ensureFirebaseAuthForUser(null);
      if (!isAuth) return;
      final payload = _sanitizePayload(DatabasePersistenceService.bowlingScorecardToMap(card));
      await _firestore!.collection(colBowlingScorecards).doc(card.id).set(payload, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[FirestoreDatabaseService] pushBowlingScorecard error: $e');
    }
  }

  /// Pushes single Tournament to Firestore
  static Future<void> pushTournament(Tournament tournament) async {
    if (!isFirebaseAvailable || _firestore == null) return;
    try {
      final isAuth = await ensureFirebaseAuthForUser(null);
      if (!isAuth) return;
      final payload = _sanitizePayload(DatabasePersistenceService.tournamentToMap(tournament));
      await _firestore!.collection(colTournaments).doc(tournament.id).set(payload, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[FirestoreDatabaseService] pushTournament error: $e');
    }
  }

  /// Pushes single Team to Firestore
  static Future<void> pushTeam(Team team) async {
    if (!isFirebaseAvailable || _firestore == null) return;
    try {
      final isAuth = await ensureFirebaseAuthForUser(null);
      if (!isAuth) return;
      final payload = _sanitizePayload(DatabasePersistenceService.teamToMap(team));
      await _firestore!.collection(colTeams).doc(team.id).set(payload, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[FirestoreDatabaseService] pushTeam error: $e');
    }
  }

  /// Pushes single Player to Firestore
  static Future<void> pushPlayer(Player player) async {
    if (!isFirebaseAvailable || _firestore == null) return;
    try {
      final isAuth = await ensureFirebaseAuthForUser(null);
      if (!isAuth) return;
      final payload = _sanitizePayload(DatabasePersistenceService.playerToMap(player));
      await _firestore!.collection(colPlayers).doc(player.id).set(payload, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[FirestoreDatabaseService] pushPlayer error: $e');
    }
  }

  /// Pushes authenticated user's profile to Firestore `/users/{firebaseUid}`
  /// so mobile verification status and contact info sync across all devices.
  static Future<void> pushUserProfile(UserAccount user) async {
    if (!isFirebaseAvailable || _firestore == null || _auth?.currentUser == null) return;
    try {
      final uid = _auth!.currentUser!.uid;
      final cleanEmail = user.email.trim().toLowerCase();
      if (cleanEmail.isEmpty || !cleanEmail.contains('@') || !cleanEmail.contains('.')) {
        return; // Satisfy firestore.rules isValidEmail check
      }
      final payload = _sanitizePayload(DatabasePersistenceService.userAccountToMap(user));
      payload['id'] = uid;
      payload['email'] = cleanEmail;
      if ((payload['fullName'] as String? ?? '').trim().isEmpty) {
        payload['fullName'] = 'Cricketer';
      }
      await _firestore!.collection(colUsers).doc(uid).set(payload, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[FirestoreDatabaseService] pushUserProfile error: $e');
    }
  }

  /// Fetches the authenticated user's profile from Firestore `/users/{firebaseUid}`
  /// and merges verification status & mobile number into MockDatabase.
  static Future<bool> fetchAndMergeCurrentUser(MockDatabase db) async {
    if (!isFirebaseAvailable || _firestore == null || _auth?.currentUser == null) return false;
    try {
      final uid = _auth!.currentUser!.uid;
      final doc = await _firestore!.collection(colUsers).doc(uid).get();
      if (!doc.exists || doc.data() == null) return false;

      final data = doc.data()!;
      final cloudEmail = (data['email'] as String? ?? '').trim().toLowerCase();
      final cloudMobile = (data['mobileNumber'] as String? ?? '').trim();
      final cloudVerified = data['isMobileVerified'] as bool? ?? false;
      final cloudName = (data['fullName'] as String? ?? '').trim();
      final cloudLinkedPlayerId = data['linkedPlayerId'] as String?;

      bool merged = false;
      if (db.currentUser != null) {
        if (cloudMobile.isNotEmpty && db.currentUser!.mobileNumber.isEmpty) {
          db.currentUser!.mobileNumber = cloudMobile;
          merged = true;
        }
        if (cloudVerified && !db.currentUser!.isMobileVerified) {
          db.currentUser!.isMobileVerified = true;
          merged = true;
        }
        if (cloudEmail.isNotEmpty && db.currentUser!.email.isEmpty) {
          db.currentUser!.email = cloudEmail;
          merged = true;
        }
        if (cloudName.isNotEmpty && (db.currentUser!.fullName.isEmpty || db.currentUser!.fullName == 'Cricketer')) {
          db.currentUser!.fullName = cloudName;
          merged = true;
        }
        if (cloudLinkedPlayerId != null && db.currentUser!.linkedPlayerId == null) {
          db.currentUser!.linkedPlayerId = cloudLinkedPlayerId;
          merged = true;
        }
      }

      if (merged) {
        db.notifyListeners();
        DatabasePersistenceService.saveDatabase(db);
      }
      return cloudVerified && cloudMobile.isNotEmpty;
    } catch (e) {
      debugPrint('[FirestoreDatabaseService] fetchAndMergeCurrentUser error: $e');
      return false;
    }
  }

  /// Immediate push for ball recording (delivery, innings, scorecards, match)
  static Future<void> pushLiveScoringEvent({
    required MatchModel match,
    required Innings innings,
    required Delivery delivery,
    required List<BattingScorecard> batCards,
    required List<BowlingScorecard> bowlCards,
  }) async {
    if (!isFirebaseAvailable || _firestore == null) return;
    try {
      final isAuth = await ensureFirebaseAuthForUser(null);
      if (!isAuth) return;

      final batch = _firestore!.batch();

      // 1. Delivery doc
      final delRef = _firestore!.collection(colDeliveries).doc(delivery.id);
      batch.set(delRef, _sanitizePayload(DatabasePersistenceService.deliveryToMap(delivery)), SetOptions(merge: true));

      // 2. Innings doc
      final innRef = _firestore!.collection(colInnings).doc(innings.id);
      batch.set(innRef, _sanitizePayload(DatabasePersistenceService.inningsToMap(innings)), SetOptions(merge: true));

      // 3. Match doc
      final matchRef = _firestore!.collection(colMatches).doc(match.id);
      batch.set(matchRef, _sanitizePayload(DatabasePersistenceService.matchToMap(match)), SetOptions(merge: true));

      // 4. Batting Scorecards
      for (final b in batCards) {
        final bRef = _firestore!.collection(colBattingScorecards).doc(b.id);
        batch.set(bRef, _sanitizePayload(DatabasePersistenceService.battingScorecardToMap(b)), SetOptions(merge: true));
      }

      // 5. Bowling Scorecards
      for (final bw in bowlCards) {
        final bwRef = _firestore!.collection(colBowlingScorecards).doc(bw.id);
        batch.set(bwRef, _sanitizePayload(DatabasePersistenceService.bowlingScorecardToMap(bw)), SetOptions(merge: true));
      }

      await batch.commit();
      lastCloudSyncTime = DateTime.now();
      cloudSyncCount++;
    } catch (e) {
      debugPrint('[FirestoreDatabaseService] pushLiveScoringEvent error: $e');
    }
  }

  /// Asynchronous debounced push of state to Cloud Firestore
  static void pushStateInBackground(MockDatabase db) {
    if (!isFirebaseAvailable || isApplyingCloudUpdate) return;

    _debouncePushTimer?.cancel();
    _debouncePushTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        final isAuth = await ensureFirebaseAuthForUser(db.currentUser);
        if (!isAuth) return;

        // Push matches
        for (final m in db.matches) {
          await pushMatch(m);
        }
        // Push active innings
        for (final inn in db.inningsList) {
          await pushInnings(inn);
        }
        // Push tournaments
        for (final t in db.tournaments) {
          await pushTournament(t);
        }
        // Push teams
        for (final tm in db.teams) {
          await pushTeam(tm);
        }
        // Push players
        for (final p in db.players) {
          await pushPlayer(p);
        }
      } catch (e) {
        debugPrint('[FirestoreDatabaseService] pushStateInBackground error: $e');
      }
    });
  }
}
