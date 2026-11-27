import 'dart:math';
import 'package:flutter/material.dart';
import '../models/models.dart';
import 'cricket_rules_engine.dart';
import 'totp_service.dart';
import 'database_persistence_service.dart';
import 'server_sync_service.dart';
import 'firestore_database_service.dart';
import 'google_auth_service.dart';

class MockDatabase extends ChangeNotifier {
  bool _persistScheduled = false;

  void _scheduleAutoPersist() {
    if (_persistScheduled) return;
    _persistScheduled = true;
    Future.microtask(() async {
      _persistScheduled = false;
      await DatabasePersistenceService.saveDatabase(this);
      ServerSyncService.pushInBackground(this);
      FirestoreDatabaseService.pushStateInBackground(this);
    });
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
    _scheduleAutoPersist();
  }

  /// Explicitly persists current database state to permanent storage immediately
  Future<void> persistState() async {
    await DatabasePersistenceService.saveDatabase(this);
    ServerSyncService.pushInBackground(this);
    FirestoreDatabaseService.pushStateInBackground(this);
  }

  /// Hydrates database from permanent storage if saved data exists
  Future<void> initPersistence() async {
    final loaded = await DatabasePersistenceService.loadDatabase(this);
    if (!loaded) {
      await DatabasePersistenceService.saveDatabase(this);
    }
    // Attempt automatic sync with central server
    try {
      await ServerSyncService.syncWithServer(this);
      ServerSyncService.startAutoSyncPolling(this);
    } catch (_) {}

    // Initialize real-time Cloud Firestore synchronization
    try {
      await FirestoreDatabaseService.init(this);
    } catch (e) {
      debugPrint('FirestoreDatabaseService init notice: $e');
    }

    super.notifyListeners();
  }

  late List<Tournament> tournaments;
  static final Tournament _emptyTournament = Tournament(
    id: 'empty_tourn',
    name: 'No Tournament Created',
    shortName: 'NONE',
    location: 'Cricket Ground',
    startDate: '2026-01-01',
    endDate: '2026-01-01',
    overs: 20,
    totalTeams: 0,
    status: 'draft',
    bannerUrl: 'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?w=1200',
  );
  Tournament get tournament => tournaments.isNotEmpty ? tournaments.first : _emptyTournament;

  late List<Team> teams;
  late List<Player> players;
  late List<MatchModel> matches;
  late List<Innings> inningsList;
  late List<Delivery> deliveries;
  late List<BattingScorecard> battingScorecards;
  late List<BowlingScorecard> bowlingScorecards;
  late List<TournamentStanding> tournamentStandings;

  late List<Auction> auctions;
  static final Auction _emptyAuction = Auction(
    id: 'empty_auc',
    tournamentId: 'empty_tourn',
    title: 'No Active Auction',
    status: AuctionStatus.draft,
    totalLots: 0,
    completedLots: 0,
    adminPasscode: 'admin123',
    minBidIncrement: 25000,
    maxPursePerTeam: 10000000,
    requiredTeamsCount: 8,
  );
  Auction get auction => auctions.isNotEmpty ? auctions.first : _emptyAuction;
  late List<AuctionLot> auctionLots;
  late List<AuctionBid> auctionBids;
  late List<AuctionTransaction> auctionTransactions;
  late List<WhatsAppNotification> whatsappNotifications;

  String? authenticatedAuctioneerId;
  String? authenticatedOperatorId;
  String? authenticatedPlayerId;

  static final Team emptyTeam = Team(
    id: 'empty_team',
    tournamentId: '',
    name: 'Team',
    shortName: 'TM',
    primaryColor: const Color(0xFF009270),
    logoUrl: 'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?w=128',
    uniqueTeamCode: 'TEAM-00',
    passcode: '0000',
    purseRemaining: 0,
    maxPurse: 0,
    squadCount: 0,
    minSquadRequirement: 11,
    maxSquadLimit: 15,
  );

  static final MatchModel emptyMatch = MatchModel(
    id: 'empty_match',
    tournamentId: '',
    teamAId: '',
    teamBId: '',
    stage: 'Fixture',
    venue: 'Ground',
    dateTime: DateTime(2026, 1, 1),
    overs: 20,
    status: MatchStatus.scheduled,
  );

  Team? getTeam(String? id) => teams.where((t) => t.id == id).firstOrNull;
  Player? getPlayer(String? id) => players.where((p) => p.id == id).firstOrNull;
  MatchModel? getMatch(String? id) => matches.where((m) => m.id == id).firstOrNull;
  Tournament? getTournament(String? id) => tournaments.where((t) => t.id == id).firstOrNull;
  AuctionLot? getLot(String? id) => auctionLots.where((l) => l.id == id).firstOrNull;

  late List<ScoringRoom> scoringRooms;
  late List<AuctionRoom> auctionRooms;
  final Set<String> createdTournamentIds = {};
  final Set<String> authenticatedTournamentIds = {};
  final Set<String> createdAuctionIds = {};
  final Set<String> authenticatedAuctionAdminIds = {};
  final Set<String> authenticatedScoringMatchIds = {};
  bool isAuctionUnlocked = false;
  bool isAuctionAdmin = false;
  String? currentAuctionRoomId;
  String? authenticatedTeamId;
  bool isDemoDataLoaded = false;

  /// Clears all demo tournaments, demo auctions, and fake matches so user has a 100% clean slate!
  void clearAllDemoData() {
    tournaments = [];
    teams = [];
    players = [];
    matches = [];
    inningsList = [];
    deliveries = [];
    battingScorecards = [];
    bowlingScorecards = [];
    tournamentStandings = [];
    auctions = [];
    auctionLots = [];
    auctionBids = [];
    auctionTransactions = [];
    whatsappNotifications = [];
    scoringRooms = [];
    auctionRooms = [];
    users = [];
    currentUser = null;
    _activeOverrideRole = null;
    _failedPinAttempts.clear();
    _pinLockoutUntil.clear();
    createdTournamentIds.clear();
    authenticatedTournamentIds.clear();
    createdAuctionIds.clear();
    authenticatedAuctionAdminIds.clear();
    authenticatedScoringMatchIds.clear();
    isDemoDataLoaded = false;
    isAuctionUnlocked = false;
    isAuctionAdmin = false;
    currentAuctionRoomId = null;
    authenticatedTeamId = null;
    authenticatedAuctioneerId = null;
    authenticatedOperatorId = null;
    authenticatedPlayerId = null;
    notifyListeners();
  }

  /// Permanently removes all demo tournaments, demo auctions, fake demo matches,
  /// seeded demo users, and demo players from memory and device storage.
  void purgeAllDemoData() {
    tournaments.removeWhere((t) => t.id == 'tourn_bpl_2026' || t.id == 'tourn_psl_2026' || t.id.startsWith('empty_'));
    teams.removeWhere((t) => t.id.startsWith('team_bpl_') || t.id == 'empty_team');
    players.removeWhere((p) => p.id.startsWith('pl_bpl_') || p.permanentPlayerCode == 'PLY-BPL-0001');
    matches.removeWhere((m) => m.id.startsWith('match_bpl_') || m.id == 'match_001' || m.id == 'empty_match');
    inningsList.removeWhere((i) => i.id.startsWith('inn_bpl_') || i.id.startsWith('inn_001') || i.matchId == 'match_001');
    deliveries.removeWhere((d) => d.id.startsWith('del_bpl_') || d.matchId == 'match_001');
    battingScorecards.removeWhere((b) => b.id.startsWith('bat_bpl_') || b.matchId == 'match_001');
    bowlingScorecards.removeWhere((bw) => bw.id.startsWith('bowl_bpl_') || bw.matchId == 'match_001');
    auctions.removeWhere((a) => a.id == 'auc_bpl_2026' || a.id == 'empty_auc');
    auctionLots.removeWhere((l) => l.auctionId == 'auc_bpl_2026' || l.id.startsWith('lot_bpl_'));
    auctionBids.clear();
    tournamentStandings.clear();
    users.removeWhere((u) => u.email.endsWith('@cricpavilion.com') || u.id.startsWith('user_admin_') || u.id.startsWith('user_auctioneer_') || u.id.startsWith('user_owner_') || u.id.startsWith('user_scorer_') || u.id.startsWith('user_player_') || u.id.startsWith('user_gauth_'));
    if (currentUser?.email.endsWith('@cricpavilion.com') == true) {
      currentUser = null;
      _activeOverrideRole = null;
    }
    isDemoDataLoaded = false;
    persistState();
    notifyListeners();
  }

  /// Reloads sample demo tournament (BPL 2026) for testing and inspection
  void reloadDemoData() {
    _initializeSeedData();
    isDemoDataLoaded = true;
    notifyListeners();
  }

  // =========================================================================
  // UNIFIED AUTHENTICATION & MULTI-ROLE USER STATE (PUBLIC-FIRST ARCHITECTURE)
  // =========================================================================
  List<UserAccount> users = [];
  UserAccount? currentUser;
  AppUserRole? _activeOverrideRole;
  final List<AuditLog> auditLogs = [];

  bool get isAuthenticated => currentUser != null;

  /// Returns the Player profile associated with the currently authenticated user.
  Player? get currentPlayer {
    if (currentUser == null) return null;

    // 1. Direct linkedPlayerId match
    if (currentUser!.linkedPlayerId != null && currentUser!.linkedPlayerId!.isNotEmpty) {
      final p = players.where((p) => p.id == currentUser!.linkedPlayerId).firstOrNull;
      if (p != null) return p;
    }

    // 2. Match by normalized mobile number
    if (currentUser!.mobileNumber.isNotEmpty) {
      final norm = normalizeMobile(currentUser!.mobileNumber);
      if (norm.isNotEmpty) {
        final byMobile = players.where((p) => normalizeMobile(p.mobileNumber) == norm).firstOrNull;
        if (byMobile != null) {
          currentUser!.linkedPlayerId = byMobile.id;
          return byMobile;
        }
      }
    }

    // 3. Match by full name
    final cleanName = currentUser!.fullName.trim().toLowerCase();
    if (cleanName.isNotEmpty) {
      final byName = players.where((p) => p.fullName.trim().toLowerCase() == cleanName).firstOrNull;
      if (byName != null) {
        currentUser!.linkedPlayerId = byName.id;
        return byName;
      }
    }

    // 4. Auto-provision permanent player profile for the authenticated user
    final newP = registerPermanentPlayer(
      fullName: currentUser!.fullName,
      mobileNumber: currentUser!.mobileNumber,
      role: PlayerRole.allRounder,
    );
    currentUser!.linkedPlayerId = newP.id;
    return newP;
  }

  AppUserRole get currentRole {
    if (_activeOverrideRole != null) return _activeOverrideRole!;
    if (currentUser == null) return AppUserRole.viewer; // Public-first default!
    if (currentUser!.tournamentRoles.values.contains(AppUserRole.superAdmin)) {
      return AppUserRole.superAdmin;
    }
    if (currentUser!.tournamentRoles.values.contains(AppUserRole.tournamentAdmin)) {
      return AppUserRole.tournamentAdmin;
    }
    if (currentUser!.conductorAuctionIds.isNotEmpty) {
      return AppUserRole.auctioneer;
    }
    if (currentUser!.ownedTeamIds.isNotEmpty) {
      return AppUserRole.teamOwner;
    }
    if (currentUser!.scorerMatchIds.isNotEmpty) {
      return AppUserRole.scorer;
    }
    return AppUserRole.viewer;
  }

  bool registerUser({
    required String fullName,
    required String email,
    required String mobileNumber,
    required String password,
  }) {
    final cleanEmail = email.trim().toLowerCase();
    final cleanMobile = mobileNumber.trim();
    if (users.any((u) => u.email.toLowerCase() == cleanEmail)) {
      return false;
    }

    final newUser = UserAccount(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      fullName: fullName.trim(),
      email: cleanEmail,
      mobileNumber: cleanMobile,
      passwordHash: password,
      createdAt: DateTime.now(),
    );
    // Auto-link to existing player if valid mobile matches
    final normMobile = normalizeMobile(cleanMobile);
    if (normMobile.isNotEmpty) {
      final byMobile = players.where((p) => normalizeMobile(p.mobileNumber) == normMobile).firstOrNull;
      if (byMobile != null) {
        newUser.linkedPlayerId = byMobile.id;
      }
    }

    users.add(newUser);
    currentUser = newUser;
    _activeOverrideRole = null;

    logAudit(
      category: 'auth',
      action: 'USER_REGISTERED',
      details: 'New account registered: ${newUser.fullName} ($cleanEmail)',
      performedBy: newUser.fullName,
    );
    notifyListeners();
    return true;
  }

  /// Map of pending 6-digit OTPs by 10-digit normalized mobile number
  final Map<String, String> _pendingMobileOtps = {};
  final Map<String, DateTime> _otpExpiresAt = {};

  /// Find user by email or mobile number
  UserAccount? findUser(String emailOrMobile) {
    final query = emailOrMobile.trim().toLowerCase();
    final cleanMobile = normalizeMobile(emailOrMobile);
    return users.where((u) =>
      u.email.toLowerCase() == query ||
      (cleanMobile.isNotEmpty && normalizeMobile(u.mobileNumber) == cleanMobile)
    ).firstOrNull;
  }

  /// Checks whether a user with this email or mobile has already saved and verified their mobile number
  bool hasSavedAndVerifiedMobile(String emailOrMobile) {
    final user = findUser(emailOrMobile);
    if (user == null) return false;
    return user.hasVerifiedMobile;
  }

  /// Generates and stores a 6-digit OTP for the given mobile number (expires in 5 minutes)
  String sendMobileOtp(String mobileNumber) {
    final norm = normalizeMobile(mobileNumber);
    final rand = Random();
    final otp = (rand.nextInt(900000) + 100000).toString();
    _pendingMobileOtps[norm] = otp;
    _otpExpiresAt[norm] = DateTime.now().add(const Duration(minutes: 5));

    logAudit(
      category: 'auth',
      action: 'OTP_SENT',
      details: 'Sent 6-digit verification OTP $otp to +91 $norm',
      performedBy: currentUser?.fullName ?? 'System',
    );
    notifyListeners();
    return otp;
  }

  /// Returns the pending OTP for testing/verification
  String? getPendingOtp(String mobileNumber) {
    final norm = normalizeMobile(mobileNumber);
    return _pendingMobileOtps[norm];
  }

  /// Checks if credentials are valid without completing login
  bool checkCredentials(String emailOrMobile, String password) {
    final user = findUser(emailOrMobile);
    return user != null && user.passwordHash == password;
  }

  /// Checks if Google Authenticator 2FA is enabled and active for user
  bool is2faRequired(String emailOrMobile) {
    final user = findUser(emailOrMobile);
    return user != null && user.isGoogleAuthEnabled && (user.googleAuthSecret != null && user.googleAuthSecret!.isNotEmpty);
  }

  bool loginUser({
    required String emailOrMobile,
    required String password,
    bool bypass2faCheck = false,
  }) {
    final user = findUser(emailOrMobile);

    if (user == null || user.passwordHash != password) {
      return false;
    }

    if (!bypass2faCheck && user.isGoogleAuthEnabled && (user.googleAuthSecret?.isNotEmpty ?? false)) {
      // 2-Factor Authentication required: Must verify with Google Authenticator code
      return false;
    }

    _finalizeUserLogin(user, loginMethod: 'Email/Password');
    return true;
  }

  /// Verifies a 6-digit TOTP code or recovery code and logs in the user
  bool verifyAndLoginWithGoogleAuth({
    required String emailOrMobile,
    required String code,
  }) {
    final user = findUser(emailOrMobile);
    if (user == null || !user.isGoogleAuthEnabled || user.googleAuthSecret == null) {
      return false;
    }

    final cleanCode = code.replaceAll(' ', '').trim();

    // Check TOTP RFC 6238 code
    bool isTotpValid = TotpService.verifyTotpCode(
      secret: user.googleAuthSecret!,
      code: cleanCode,
    );

    // If not TOTP code, check if it's one of the recovery codes
    bool isRecoveryCode = false;
    if (!isTotpValid && user.googleAuthRecoveryCodes.isNotEmpty) {
      final idx = user.googleAuthRecoveryCodes.indexOf(cleanCode);
      if (idx != -1) {
        isTotpValid = true;
        isRecoveryCode = true;
        user.googleAuthRecoveryCodes.removeAt(idx); // Single-use recovery code
      }
    }

    if (!isTotpValid) {
      logAudit(
        category: 'auth',
        action: 'GOOGLE_AUTH_FAILED',
        details: 'Failed 2FA verification attempt for ${user.email}',
        performedBy: user.fullName,
      );
      return false;
    }

    // Complete login
    _finalizeUserLogin(user, loginMethod: isRecoveryCode ? 'Google Auth Recovery Code' : 'Google Authenticator TOTP');
    return true;
  }

  void _finalizeUserLogin(UserAccount user, {String loginMethod = 'Password'}) {
    currentUser = user;
    _activeOverrideRole = null;

    if (user.linkedPlayerId == null && user.mobileNumber.isNotEmpty) {
      final normMobile = normalizeMobile(user.mobileNumber);
      if (normMobile.isNotEmpty) {
        final byMobile = players.where((p) => normalizeMobile(p.mobileNumber) == normMobile).firstOrNull;
        if (byMobile != null) {
          user.linkedPlayerId = byMobile.id;
        }
      }
    }

    if (user.ownedTeamIds.isNotEmpty) {
      authenticatedTeamId = user.ownedTeamIds.first;
    }

    logAudit(
      category: 'auth',
      action: 'USER_LOGGED_IN',
      details: 'User logged in via $loginMethod: ${user.fullName} (${user.email})',
      performedBy: user.fullName,
    );

    // Bridge with Firebase Auth for Firestore security rules write permission
    FirestoreDatabaseService.ensureFirebaseAuthForUser(user);
    DatabasePersistenceService.saveCurrentUserSession(this);

    notifyListeners();
  }

  /// Generates a new Base32 secret for setup
  String generateGoogleAuthSecret() {
    return TotpService.generateSecret(length: 20);
  }

  /// Verifies confirmation code and enables Google Authenticator 2FA for user
  bool enableGoogleAuthenticator({
    required String userId,
    required String secret,
    required String verificationCode,
  }) {
    final user = users.where((u) => u.id == userId).firstOrNull;
    if (user == null) return false;

    final isValid = TotpService.verifyTotpCode(secret: secret, code: verificationCode);
    if (!isValid) return false;

    user.isGoogleAuthEnabled = true;
    user.googleAuthSecret = secret;
    user.googleAuthRecoveryCodes = TotpService.generateRecoveryCodes(count: 6);
    user.googleAuthEnabledAt = DateTime.now();

    logAudit(
      category: 'auth',
      action: 'GOOGLE_AUTH_ENABLED',
      details: 'Google Authenticator 2FA enabled for ${user.fullName} (${user.email})',
      performedBy: user.fullName,
    );
    notifyListeners();
    return true;
  }

  /// Disables Google Authenticator 2FA
  void disableGoogleAuthenticator(String userId) {
    final user = users.where((u) => u.id == userId).firstOrNull;
    if (user == null) return;

    user.isGoogleAuthEnabled = false;
    user.googleAuthSecret = null;
    user.googleAuthRecoveryCodes.clear();
    user.googleAuthEnabledAt = null;

    logAudit(
      category: 'auth',
      action: 'GOOGLE_AUTH_DISABLED',
      details: 'Google Authenticator 2FA disabled for ${user.fullName} (${user.email})',
      performedBy: user.fullName,
    );
    notifyListeners();
  }

  /// One-tap / OAuth "Sign in with Google"
  UserAccount signInWithGoogle({
    required String email,
    required String displayName,
    String? photoUrl,
  }) {
    final cleanEmail = email.trim().toLowerCase();
    var user = users.where((u) => u.email.toLowerCase() == cleanEmail).firstOrNull;

    if (user == null) {
      // Auto-provision user account from Google profile
      user = UserAccount(
        id: 'usr_g_${DateTime.now().millisecondsSinceEpoch}',
        fullName: displayName.trim().isNotEmpty ? displayName.trim() : 'Google User',
        email: cleanEmail,
        mobileNumber: '',
        passwordHash: 'oauth_${DateTime.now().millisecondsSinceEpoch}',
        createdAt: DateTime.now(),
        isGoogleOAuthUser: true,
      );
      users.add(user);
    } else {
      user.isGoogleOAuthUser = true;
    }

    _finalizeUserLogin(user, loginMethod: 'Google Sign-In (OAuth)');
    return user;
  }

  /// Logs in an existing user via verified mobile number OTP,
  /// or provisions a new account if this is a first-time mobile user.
  UserAccount loginWithVerifiedMobile({
    required String mobileNumber,
    String? email,
    String? fullName,
  }) {
    final norm = normalizeMobile(mobileNumber);
    final cleanEmail = (email ?? '').trim().toLowerCase();

    var user = users.where((u) => normalizeMobile(u.mobileNumber) == norm && norm.isNotEmpty).firstOrNull;
    if (user == null && cleanEmail.isNotEmpty) {
      user = users.where((u) => u.email.toLowerCase() == cleanEmail).firstOrNull;
    }

    if (user == null) {
      user = UserAccount(
        id: 'usr_m_${DateTime.now().millisecondsSinceEpoch}',
        fullName: (fullName ?? '').trim().isNotEmpty ? fullName!.trim() : 'Cricketer',
        email: cleanEmail,
        mobileNumber: norm,
        passwordHash: 'otp_${DateTime.now().millisecondsSinceEpoch}',
        createdAt: DateTime.now(),
        isMobileVerified: true,
      );
      users.add(user);
    } else {
      user.mobileNumber = norm;
      user.isMobileVerified = true;
      if (cleanEmail.isNotEmpty && user.email.trim().isEmpty) {
        user.email = cleanEmail;
      }
      if ((fullName ?? '').trim().isNotEmpty && (user.fullName.isEmpty || user.fullName == 'Cricketer')) {
        user.fullName = fullName!.trim();
      }
    }

    // Link or auto-create permanent player profile
    var existingPlayer = players.where((p) => normalizeMobile(p.mobileNumber) == norm).firstOrNull;
    if (existingPlayer != null) {
      user.linkedPlayerId = existingPlayer.id;
      existingPlayer.isMobileVerified = true;
    } else if (user.fullName.isNotEmpty && user.fullName != 'Cricketer') {
      final newPlayer = registerPermanentPlayer(
        fullName: user.fullName,
        mobileNumber: norm,
        role: PlayerRole.allRounder,
      );
      user.linkedPlayerId = newPlayer.id;
    }

    _finalizeUserLogin(user, loginMethod: 'Mobile OTP');
    if (user.isProfileComplete) {
      FirestoreDatabaseService.pushUserProfile(user);
    }
    return user;
  }

  /// Completes Gmail/email and Full Name for first-time mobile-login users.
  bool completeFirstTimeEmailAndName({
    required String email,
    required String fullName,
  }) {
    if (currentUser == null) return false;
    final cleanEmail = email.trim().toLowerCase();
    final cleanName = fullName.trim();
    if (!cleanEmail.contains('@') || !cleanEmail.contains('.') || cleanName.isEmpty) {
      return false;
    }

    // Check if another account already exists with this email and merge if unverified, else block duplicate
    final existingWithEmail = users.where((u) => u.email.toLowerCase() == cleanEmail && u.id != currentUser!.id).firstOrNull;
    if (existingWithEmail != null) {
      // Link mobile to that existing account if they are the same person logging in
      existingWithEmail.mobileNumber = currentUser!.mobileNumber;
      existingWithEmail.isMobileVerified = currentUser!.isMobileVerified;
      if (existingWithEmail.fullName.isEmpty || existingWithEmail.fullName == 'Cricketer') {
        existingWithEmail.fullName = cleanName;
      }
      users.removeWhere((u) => u.id == currentUser!.id);
      currentUser = existingWithEmail;
    } else {
      currentUser!.email = cleanEmail;
      currentUser!.fullName = cleanName;
      final u = users.where((usr) => usr.id == currentUser!.id).firstOrNull;
      if (u != null) {
        u.email = cleanEmail;
        u.fullName = cleanName;
      }
    }

    // Ensure linked player has updated name
    final norm = normalizeMobile(currentUser!.mobileNumber);
    if (norm.isNotEmpty) {
      var existingPlayer = players.where((p) => normalizeMobile(p.mobileNumber) == norm).firstOrNull;
      if (existingPlayer == null) {
        final newPlayer = registerPermanentPlayer(
          fullName: currentUser!.fullName,
          mobileNumber: norm,
          role: PlayerRole.allRounder,
        );
        currentUser!.linkedPlayerId = newPlayer.id;
      } else {
        currentUser!.linkedPlayerId = existingPlayer.id;
        existingPlayer.isMobileVerified = true;
      }
    }

    logAudit(
      category: 'auth',
      action: 'PROFILE_COMPLETED',
      details: 'First-time Gmail & mobile setup completed for ${currentUser!.fullName} ($cleanEmail)',
      performedBy: currentUser!.fullName,
    );
    FirestoreDatabaseService.pushUserProfile(currentUser!);
    DatabasePersistenceService.saveCurrentUserSession(this);
    notifyListeners();
    return true;
  }

  void logoutUser() {
    final prevName = currentUser?.fullName ?? 'Anonymous';
    currentUser = null;
    _activeOverrideRole = null;
    authenticatedTeamId = null;
    authenticatedAuctioneerId = null;
    isAuctionAdmin = false;
    isAuctionUnlocked = false;

    if (FirestoreDatabaseService.isFirebaseAvailable) {
      GoogleAuthService.signOut();
    }
    DatabasePersistenceService.saveCurrentUserSession(this);

    logAudit(
      category: 'auth',
      action: 'USER_LOGGED_OUT',
      details: 'User logged out: $prevName',
      performedBy: prevName,
    );
    notifyListeners();
  }

  /// Google Play User Data Compliance: Permanent user account & personal data deletion
  void deleteUserAccount(String userId) {
    users.removeWhere((u) => u.id == userId);
    if (currentUser?.id == userId) {
      logoutUser();
    }
    logAudit(
      category: 'auth',
      action: 'USER_ACCOUNT_DELETED',
      details: 'User account and personal data permanently deleted: $userId',
      performedBy: userId,
    );
    notifyListeners();
  }

  void setRole(AppUserRole role, {String? teamId, String? auctioneerId, String? operatorId, String? playerId}) {
    _activeOverrideRole = role;
    if (role == AppUserRole.superAdmin) {
      isAuctionAdmin = true;
      isAuctionUnlocked = true;
      authenticatedTeamId = null;
    } else if (role == AppUserRole.tournamentAdmin || role == AppUserRole.auctionAdmin) {
      isAuctionAdmin = true;
      isAuctionUnlocked = true;
      authenticatedTeamId = null;
    } else if (role == AppUserRole.auctioneer) {
      isAuctionAdmin = true;
      isAuctionUnlocked = true;
      authenticatedTeamId = null;
      authenticatedAuctioneerId = auctioneerId ?? 'auctioneer_01';
    } else if (role == AppUserRole.auctionOperator) {
      isAuctionAdmin = false;
      isAuctionUnlocked = true;
      authenticatedTeamId = null;
      authenticatedOperatorId = operatorId ?? 'operator_01';
    } else if (role == AppUserRole.teamOwner) {
      isAuctionAdmin = false;
      isAuctionUnlocked = true;
      if (teamId != null) {
        authenticatedTeamId = teamId;
      } else if (authenticatedTeamId == null && teams.isNotEmpty) {
        authenticatedTeamId = teams.first.id;
      }
    } else if (role == AppUserRole.player) {
      isAuctionAdmin = false;
      isAuctionUnlocked = false;
      authenticatedTeamId = null;
      authenticatedPlayerId = playerId ?? (players.isNotEmpty ? players.first.id : null);
    } else if (role == AppUserRole.scorer) {
      isAuctionAdmin = false;
    } else if (role == AppUserRole.viewer) {
      isAuctionAdmin = false;
      isAuctionUnlocked = false;
      authenticatedTeamId = null;
    }
    logAudit(
      category: 'system',
      action: 'ROLE_SWITCHED',
      details: 'Switched persona to ${role.displayName}',
      performedBy: role.displayName,
    );
    notifyListeners();
  }

  bool get canManageTournaments => currentRole == AppUserRole.superAdmin || currentRole == AppUserRole.tournamentAdmin;
  bool get canManageAuction => currentRole == AppUserRole.superAdmin || currentRole == AppUserRole.auctionAdmin;
  bool get canScoreMatches => currentRole == AppUserRole.superAdmin || currentRole == AppUserRole.scorer;
  bool get isTeamOwner => currentRole == AppUserRole.teamOwner;
  bool get isAuctioneer => currentRole == AppUserRole.auctioneer;
  bool get isAuctionOperator => currentRole == AppUserRole.auctionOperator;
  bool get isPlayerPersona => currentRole == AppUserRole.player;
  bool get isViewer => currentRole == AppUserRole.viewer;

  /// Strict RBAC rule: ONLY the assigned Auctioneer (or Super Admin / Host) can spin & reveal next player!
  bool canSpinPlayer(String auctionId) {
    if (currentRole == AppUserRole.superAdmin) return true;
    final auc = getAuction(auctionId);
    if (currentUser != null) {
      if (currentUser!.isHostOf(auc.tournamentId)) return true;
      if (currentUser!.isConductorOf(auctionId)) return true;
    }
    if (currentRole == AppUserRole.auctioneer) {
      if (authenticatedAuctioneerId != null &&
          authenticatedAuctioneerId!.isNotEmpty &&
          auc.assignedAuctioneerId.isNotEmpty &&
          authenticatedAuctioneerId != auc.assignedAuctioneerId) {
        return false;
      }
      return true;
    }
    return false;
  }

  bool canStartBidding(String auctionId) {
    if (currentRole == AppUserRole.superAdmin) return true;
    final auc = getAuction(auctionId);
    if (currentUser != null) {
      if (currentUser!.isHostOf(auc.tournamentId) || currentUser!.isConductorOf(auctionId)) {
        return true;
      }
    }
    return currentRole == AppUserRole.auctioneer;
  }

  bool canPlaceBid(String auctionId, String teamId) {
    if (currentRole == AppUserRole.superAdmin) return true;
    if (currentUser != null && currentUser!.ownedTeamIds.contains(teamId)) {
      return true;
    }
    if (currentRole == AppUserRole.teamOwner) {
      return authenticatedTeamId == teamId;
    }
    return false;
  }

  bool canScoreMatch(String matchId) {
    if (currentRole == AppUserRole.superAdmin) return true;
    final match = getMatch(matchId);
    if (match == null) return false;
    if (currentUser != null) {
      if (currentUser!.isHostOf(match.tournamentId)) return true;
      if (currentUser!.isScorerOf(matchId)) return true;
    }
    if (isScoringUnlockedForMatch(matchId)) return true;
    return currentRole == AppUserRole.scorer;
  }

  bool canManageTimer(String auctionId) {
    if (currentRole == AppUserRole.superAdmin) return true;
    final auc = getAuction(auctionId);
    if (currentUser != null && (currentUser!.isHostOf(auc.tournamentId) || currentUser!.isConductorOf(auctionId))) {
      return true;
    }
    return currentRole == AppUserRole.auctioneer ||
        currentRole == AppUserRole.auctionOperator ||
        currentRole == AppUserRole.auctionAdmin;
  }

  bool canConfirmOutcome(String auctionId) {
    if (currentRole == AppUserRole.superAdmin) return true;
    final auc = getAuction(auctionId);
    if (currentUser != null && (currentUser!.isHostOf(auc.tournamentId) || currentUser!.isConductorOf(auctionId))) {
      return true;
    }
    return currentRole == AppUserRole.auctioneer;
  }

  bool canConfigureAuction(String auctionId) {
    if (currentRole == AppUserRole.superAdmin) return true;
    final auc = getAuction(auctionId);
    if (currentUser != null && currentUser!.isHostOf(auc.tournamentId)) {
      return true;
    }
    return currentRole == AppUserRole.tournamentAdmin ||
        currentRole == AppUserRole.auctionAdmin;
  }

  bool canManagePlayers(String auctionId) {
    if (currentRole == AppUserRole.superAdmin) return true;
    final auc = getAuction(auctionId);
    if (currentUser != null && currentUser!.isHostOf(auc.tournamentId)) {
      return true;
    }
    return currentRole == AppUserRole.tournamentAdmin ||
        currentRole == AppUserRole.auctionAdmin;
  }

  void logAudit({
    required String category,
    required String action,
    required String details,
    String? performedBy,
    String tournamentId = '',
    String auctionId = '',
    String role = '',
  }) {
    auditLogs.insert(
      0,
      AuditLog(
        id: 'audit_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}',
        timestamp: DateTime.now(),
        category: category,
        action: action,
        details: details,
        performedBy: performedBy ?? currentRole.displayName,
        tournamentId: tournamentId,
        auctionId: auctionId,
        role: role.isNotEmpty ? role : currentRole.shortDisplayName,
      ),
    );
  }

  Team? get currentAuthenticatedTeam =>
      authenticatedTeamId != null ? teams.where((t) => t.id == authenticatedTeamId).firstOrNull : null;

  MockDatabase({bool loadDemoSeed = false}) {
    if (loadDemoSeed) {
      _activeOverrideRole = AppUserRole.superAdmin;
      isAuctionAdmin = false;
      isAuctionUnlocked = false;
      _initializeSeedData();
      isDemoDataLoaded = true;
    } else {
      _activeOverrideRole = null;
      clearAllDemoData();
    }
  }

  void _initializeSeedData() {
    users = [
      UserAccount(
        id: 'user_admin_01',
        fullName: 'Rahul Sharma (Tournament Host)',
        email: 'admin@cricpavilion.com',
        mobileNumber: '9876543210',
        passwordHash: 'admin123',
        isMobileVerified: true,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        tournamentRoles: {
          'tourn_bpl_2026': AppUserRole.tournamentAdmin,
          'tourn_psl_2026': AppUserRole.tournamentAdmin,
        },
      ),
      UserAccount(
        id: 'user_auctioneer_01',
        fullName: 'Amit Verma (Gavel Master)',
        email: 'auctioneer@cricpavilion.com',
        mobileNumber: '9876543211',
        passwordHash: 'gavel123',
        isMobileVerified: true,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        conductorAuctionIds: ['auc_bpl_2026', 'auc_psl_2026'],
      ),
      UserAccount(
        id: 'user_owner_01',
        fullName: 'Sourav Ganguly (Franchise Owner)',
        email: 'owner1@cricpavilion.com',
        mobileNumber: '9876543212',
        passwordHash: 'owner123',
        isMobileVerified: true,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        ownedTeamIds: ['team_barasat'],
        tournamentRoles: {'tourn_bpl_2026': AppUserRole.teamOwner},
      ),
      UserAccount(
        id: 'user_scorer_01',
        fullName: 'Sunil Gavaskar (Match Scorer)',
        email: 'scorer@cricpavilion.com',
        mobileNumber: '9876543213',
        passwordHash: 'scorer123',
        isMobileVerified: true,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        scorerMatchIds: ['match_1', 'match_2'],
      ),
      UserAccount(
        id: 'user_gauth_01',
        fullName: 'Vikram Malhotra (2FA Protected)',
        email: 'gauth@cricpavilion.com',
        mobileNumber: '9876543214',
        passwordHash: 'gauth123',
        isMobileVerified: true,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        isGoogleAuthEnabled: true,
        googleAuthSecret: 'JBSWY3DPEHPK3PXP',
        googleAuthRecoveryCodes: ['1234-5678', '8765-4321', '9988-7766'],
        googleAuthEnabledAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      UserAccount(
        id: 'user_first_time_01',
        fullName: 'New Player (First-Time User)',
        email: 'newuser@cricpavilion.com',
        mobileNumber: '',
        passwordHash: 'new123',
        isMobileVerified: false,
        createdAt: DateTime.now(),
      ),
    ];

    tournaments = [
      Tournament(
        id: 'tourn_bpl_2026',
        name: 'Bengal Premier League 2026',
        shortName: 'BPL 2026',
        location: 'Eden Gardens, Kolkata',
        startDate: '2026-11-01',
        endDate: '2026-11-28',
        overs: 20,
        totalTeams: 8,
        status: 'active',
        bannerUrl: 'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?w=1200',
        roomId: 'TOURN-BPL-2026',
        passcode: '1234',
      ),
      Tournament(
        id: 'tourn_psl_2026',
        name: 'Premier Super League 2026',
        shortName: 'PSL 2026',
        location: 'Gaddafi Stadium, Lahore',
        startDate: '2026-12-01',
        endDate: '2026-12-25',
        overs: 20,
        totalTeams: 8,
        status: 'active',
        bannerUrl: 'https://images.unsplash.com/photo-1517649763962-0c623266ddc0?w=1200',
        roomId: 'TOURN-PSL-2026',
        passcode: '1234',
      ),
      Tournament(
        id: 'tourn_ipl_2026',
        name: 'Indian Premier League 2026',
        shortName: 'IPL 2026',
        location: 'Wankhede Stadium, Mumbai',
        startDate: '2027-03-20',
        endDate: '2027-05-25',
        overs: 20,
        totalTeams: 8,
        status: 'scheduled',
        bannerUrl: 'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=1200',
        roomId: 'TOURN-IPL-2026',
        passcode: '1234',
      ),
    ];

    teams = [
      Team(
        id: 'team_barasat',
        tournamentId: 'tourn_bpl_2026',
        name: 'Barasat Blasters',
        shortName: 'BBL',
        uniqueTeamCode: 'TEAM-BBL-01',
        passcode: '1234',
        primaryColor: const Color(0xFF059669), // Emerald
        logoUrl: 'https://images.unsplash.com/photo-1589487391730-58f20eb2c308?w=120',
        purseRemaining: 8500000,
        maxPurse: 10000000,
        squadCount: 11,
        minSquadRequirement: 15,
        maxSquadLimit: 18,
      ),
      Team(
        id: 'team_kolkata',
        tournamentId: 'tourn_bpl_2026',
        name: 'Kolkata Kings',
        shortName: 'KK',
        uniqueTeamCode: 'TEAM-KK-02',
        passcode: '1234',
        primaryColor: const Color(0xFF7C3AED), // Purple
        logoUrl: 'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=120',
        purseRemaining: 7250000,
        maxPurse: 10000000,
        squadCount: 10,
        minSquadRequirement: 15,
        maxSquadLimit: 18,
      ),
      Team(
        id: 'team_howrah',
        tournamentId: 'tourn_bpl_2026',
        name: 'Howrah Hurricanes',
        shortName: 'HH',
        uniqueTeamCode: 'TEAM-HH-03',
        passcode: '1234',
        primaryColor: const Color(0xFF0284C7), // Sky Blue
        logoUrl: 'https://images.unsplash.com/photo-1517649763962-0c623266ddc0?w=120',
        purseRemaining: 6500000,
        maxPurse: 10000000,
        squadCount: 9,
        minSquadRequirement: 15,
        maxSquadLimit: 18,
      ),
      Team(
        id: 'team_hooghly',
        tournamentId: 'tourn_bpl_2026',
        name: 'Hooghly Heroes',
        shortName: 'HOH',
        uniqueTeamCode: 'TEAM-HOH-04',
        passcode: '1234',
        primaryColor: const Color(0xFFD97706), // Amber
        logoUrl: 'https://images.unsplash.com/photo-1579952363873-27f3bade9f55?w=120',
        purseRemaining: 9000000,
        maxPurse: 10000000,
        squadCount: 11,
        minSquadRequirement: 15,
        maxSquadLimit: 18,
      ),
      Team(
        id: 'team_siliguri',
        tournamentId: 'tourn_bpl_2026',
        name: 'Siliguri Strikers',
        shortName: 'SS',
        uniqueTeamCode: 'TEAM-SS-05',
        passcode: '1234',
        primaryColor: const Color(0xFFE11D48), // Rose
        logoUrl: 'https://images.unsplash.com/photo-1521412644187-c49fa049e84d?w=120',
        purseRemaining: 8800000,
        maxPurse: 10000000,
        squadCount: 10,
        minSquadRequirement: 15,
        maxSquadLimit: 18,
      ),
      Team(
        id: 'team_durgapur',
        tournamentId: 'tourn_bpl_2026',
        name: 'Durgapur Dynamos',
        shortName: 'DD',
        uniqueTeamCode: 'TEAM-DD-06',
        passcode: '1234',
        primaryColor: const Color(0xFF2563EB), // Blue
        logoUrl: 'https://images.unsplash.com/photo-1533443740262-9442254f99c2?w=120',
        purseRemaining: 7600000,
        maxPurse: 10000000,
        squadCount: 9,
        minSquadRequirement: 15,
        maxSquadLimit: 18,
      ),
      Team(
        id: 'team_midnapore',
        tournamentId: 'tourn_bpl_2026',
        name: 'Midnapore Mavericks',
        shortName: 'MM',
        uniqueTeamCode: 'TEAM-MM-07',
        passcode: '1234',
        primaryColor: const Color(0xFF9333EA), // Violet
        logoUrl: 'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=120',
        purseRemaining: 8200000,
        maxPurse: 10000000,
        squadCount: 8,
        minSquadRequirement: 15,
        maxSquadLimit: 18,
      ),
      Team(
        id: 'team_malda',
        tournamentId: 'tourn_bpl_2026',
        name: 'Malda Monarchs',
        shortName: 'MLM',
        uniqueTeamCode: 'TEAM-MLM-08',
        passcode: '1234',
        primaryColor: const Color(0xFF0D9488), // Teal
        logoUrl: 'https://images.unsplash.com/photo-1579952363873-27f3bade9f55?w=120',
        purseRemaining: 8000000,
        maxPurse: 10000000,
        squadCount: 8,
        minSquadRequirement: 15,
        maxSquadLimit: 18,
      ),

      // ==========================================
      // PSL 2026 FRANCHISE TEAMS (Fresh: 0 Squad, 100% Full Purse)
      // ==========================================
      Team(
        id: 'team_psl_lahore',
        tournamentId: 'tourn_psl_2026',
        name: 'Lahore Qalandars',
        shortName: 'LQ',
        uniqueTeamCode: 'TEAM-LQ-01',
        passcode: '1234',
        primaryColor: const Color(0xFF16A34A), // Green
        logoUrl: 'https://images.unsplash.com/photo-1589487391730-58f20eb2c308?w=120',
        purseRemaining: 10000000,
        maxPurse: 10000000,
        squadCount: 0,
        minSquadRequirement: 15,
        maxSquadLimit: 18,
      ),
      Team(
        id: 'team_psl_karachi',
        tournamentId: 'tourn_psl_2026',
        name: 'Karachi Kings',
        shortName: 'KK',
        uniqueTeamCode: 'TEAM-KK-02',
        passcode: '1234',
        primaryColor: const Color(0xFF2563EB), // Blue
        logoUrl: 'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=120',
        purseRemaining: 10000000,
        maxPurse: 10000000,
        squadCount: 0,
        minSquadRequirement: 15,
        maxSquadLimit: 18,
      ),
      Team(
        id: 'team_psl_islamabad',
        tournamentId: 'tourn_psl_2026',
        name: 'Islamabad United',
        shortName: 'IU',
        uniqueTeamCode: 'TEAM-IU-03',
        passcode: '1234',
        primaryColor: const Color(0xFFDC2626), // Red
        logoUrl: 'https://images.unsplash.com/photo-1517649763962-0c623266ddc0?w=120',
        purseRemaining: 10000000,
        maxPurse: 10000000,
        squadCount: 0,
        minSquadRequirement: 15,
        maxSquadLimit: 18,
      ),
      Team(
        id: 'team_psl_peshawar',
        tournamentId: 'tourn_psl_2026',
        name: 'Peshawar Zalmi',
        shortName: 'PZ',
        uniqueTeamCode: 'TEAM-PZ-04',
        passcode: '1234',
        primaryColor: const Color(0xFFD97706), // Amber
        logoUrl: 'https://images.unsplash.com/photo-1579952363873-27f3bade9f55?w=120',
        purseRemaining: 10000000,
        maxPurse: 10000000,
        squadCount: 0,
        minSquadRequirement: 15,
        maxSquadLimit: 18,
      ),
      Team(
        id: 'team_psl_quetta',
        tournamentId: 'tourn_psl_2026',
        name: 'Quetta Gladiators',
        shortName: 'QG',
        uniqueTeamCode: 'TEAM-QG-05',
        passcode: '1234',
        primaryColor: const Color(0xFF7C3AED), // Purple
        logoUrl: 'https://images.unsplash.com/photo-1521412644187-c49fa049e84d?w=120',
        purseRemaining: 10000000,
        maxPurse: 10000000,
        squadCount: 0,
        minSquadRequirement: 15,
        maxSquadLimit: 18,
      ),
      Team(
        id: 'team_psl_multan',
        tournamentId: 'tourn_psl_2026',
        name: 'Multan Sultans',
        shortName: 'MS',
        uniqueTeamCode: 'TEAM-MS-06',
        passcode: '1234',
        primaryColor: const Color(0xFF059669), // Emerald
        logoUrl: 'https://images.unsplash.com/photo-1533443740262-9442254f99c2?w=120',
        purseRemaining: 10000000,
        maxPurse: 10000000,
        squadCount: 0,
        minSquadRequirement: 15,
        maxSquadLimit: 18,
      ),
      Team(
        id: 'team_psl_rawalpindi',
        tournamentId: 'tourn_psl_2026',
        name: 'Rawalpindi Riders',
        shortName: 'RR',
        uniqueTeamCode: 'TEAM-RR-07',
        passcode: '1234',
        primaryColor: const Color(0xFF0D9488), // Teal
        logoUrl: 'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=120',
        purseRemaining: 10000000,
        maxPurse: 10000000,
        squadCount: 0,
        minSquadRequirement: 15,
        maxSquadLimit: 18,
      ),
      Team(
        id: 'team_psl_sialkot',
        tournamentId: 'tourn_psl_2026',
        name: 'Sialkot Stallions',
        shortName: 'SS',
        uniqueTeamCode: 'TEAM-SS-08',
        passcode: '1234',
        primaryColor: const Color(0xFF4F46E5), // Indigo
        logoUrl: 'https://images.unsplash.com/photo-1579952363873-27f3bade9f55?w=120',
        purseRemaining: 10000000,
        maxPurse: 10000000,
        squadCount: 0,
        minSquadRequirement: 15,
        maxSquadLimit: 18,
      ),

      // ==========================================
      // IPL 2026 FRANCHISE TEAMS (Fresh: 0 Squad, 100% Full Purse)
      // ==========================================
      Team(
        id: 'team_ipl_csk',
        tournamentId: 'tourn_ipl_2026',
        name: 'Chennai Super Kings',
        shortName: 'CSK',
        uniqueTeamCode: 'TEAM-CSK-01',
        passcode: '1234',
        primaryColor: const Color(0xFFEAB308), // Yellow
        logoUrl: 'https://images.unsplash.com/photo-1589487391730-58f20eb2c308?w=120',
        purseRemaining: 15000000,
        maxPurse: 15000000,
        squadCount: 0,
        minSquadRequirement: 15,
        maxSquadLimit: 18,
      ),
      Team(
        id: 'team_ipl_mi',
        tournamentId: 'tourn_ipl_2026',
        name: 'Mumbai Indians',
        shortName: 'MI',
        uniqueTeamCode: 'TEAM-MI-02',
        passcode: '1234',
        primaryColor: const Color(0xFF2563EB), // Blue
        logoUrl: 'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=120',
        purseRemaining: 15000000,
        maxPurse: 15000000,
        squadCount: 0,
        minSquadRequirement: 15,
        maxSquadLimit: 18,
      ),
      Team(
        id: 'team_ipl_rcb',
        tournamentId: 'tourn_ipl_2026',
        name: 'Royal Challengers Bengaluru',
        shortName: 'RCB',
        uniqueTeamCode: 'TEAM-RCB-03',
        passcode: '1234',
        primaryColor: const Color(0xFFDC2626), // Red
        logoUrl: 'https://images.unsplash.com/photo-1517649763962-0c623266ddc0?w=120',
        purseRemaining: 15000000,
        maxPurse: 15000000,
        squadCount: 0,
        minSquadRequirement: 15,
        maxSquadLimit: 18,
      ),
      Team(
        id: 'team_ipl_kkr',
        tournamentId: 'tourn_ipl_2026',
        name: 'Kolkata Knight Riders',
        shortName: 'KKR',
        uniqueTeamCode: 'TEAM-KKR-04',
        passcode: '1234',
        primaryColor: const Color(0xFF7C3AED), // Purple
        logoUrl: 'https://images.unsplash.com/photo-1579952363873-27f3bade9f55?w=120',
        purseRemaining: 15000000,
        maxPurse: 15000000,
        squadCount: 0,
        minSquadRequirement: 15,
        maxSquadLimit: 18,
      ),
      Team(
        id: 'team_ipl_gt',
        tournamentId: 'tourn_ipl_2026',
        name: 'Gujarat Titans',
        shortName: 'GT',
        uniqueTeamCode: 'TEAM-GT-05',
        passcode: '1234',
        primaryColor: const Color(0xFF0D9488), // Teal
        logoUrl: 'https://images.unsplash.com/photo-1521412644187-c49fa049e84d?w=120',
        purseRemaining: 15000000,
        maxPurse: 15000000,
        squadCount: 0,
        minSquadRequirement: 15,
        maxSquadLimit: 18,
      ),
      Team(
        id: 'team_ipl_rr',
        tournamentId: 'tourn_ipl_2026',
        name: 'Rajasthan Royals',
        shortName: 'RR',
        uniqueTeamCode: 'TEAM-RR-06',
        passcode: '1234',
        primaryColor: const Color(0xFFEC4899), // Pink
        logoUrl: 'https://images.unsplash.com/photo-1533443740262-9442254f99c2?w=120',
        purseRemaining: 15000000,
        maxPurse: 15000000,
        squadCount: 0,
        minSquadRequirement: 15,
        maxSquadLimit: 18,
      ),
      Team(
        id: 'team_ipl_srh',
        tournamentId: 'tourn_ipl_2026',
        name: 'Sunrisers Hyderabad',
        shortName: 'SRH',
        uniqueTeamCode: 'TEAM-SRH-07',
        passcode: '1234',
        primaryColor: const Color(0xFFEA580C), // Orange
        logoUrl: 'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=120',
        purseRemaining: 15000000,
        maxPurse: 15000000,
        squadCount: 0,
        minSquadRequirement: 15,
        maxSquadLimit: 18,
      ),
      Team(
        id: 'team_ipl_dc',
        tournamentId: 'tourn_ipl_2026',
        name: 'Delhi Capitals',
        shortName: 'DC',
        uniqueTeamCode: 'TEAM-DC-08',
        passcode: '1234',
        primaryColor: const Color(0xFF0284C7), // Sky Blue
        logoUrl: 'https://images.unsplash.com/photo-1579952363873-27f3bade9f55?w=120',
        purseRemaining: 15000000,
        maxPurse: 15000000,
        squadCount: 0,
        minSquadRequirement: 15,
        maxSquadLimit: 18,
      ),
    ];

    players = [
      Player(
        id: 'pl_1',
        fullName: 'Rahul Das',
        displayName: 'Rahul Das',
        role: PlayerRole.batsman,
        battingStyle: 'Right Hand Bat',
        bowlingStyle: 'Right Arm Off Break',
        basePrice: 500000,
        photoUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=256',
        teamId: 'team_barasat',
        runs: 248,
        wickets: 2,
        matches: 4,
      ),
      Player(
        id: 'pl_2',
        fullName: 'Suman Biswas',
        displayName: 'Suman Biswas',
        role: PlayerRole.wicketKeeper,
        battingStyle: 'Right Hand Bat',
        bowlingStyle: 'None',
        basePrice: 350000,
        photoUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=256',
        teamId: 'team_barasat',
        runs: 142,
        wickets: 0,
        matches: 4,
      ),
      Player(
        id: 'pl_3',
        fullName: 'Subham Dey',
        displayName: 'Subham Dey',
        role: PlayerRole.batsman,
        battingStyle: 'Right Hand Bat',
        bowlingStyle: 'Right Arm Leg Break',
        basePrice: 600000,
        photoUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=256',
        teamId: 'team_barasat',
        runs: 310,
        wickets: 4,
        matches: 4,
      ),
      Player(
        id: 'pl_4',
        fullName: 'Debayan Paul',
        displayName: 'Debayan Paul',
        role: PlayerRole.bowler,
        battingStyle: 'Right Hand Bat',
        bowlingStyle: 'Right Arm Medium',
        basePrice: 400000,
        photoUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=256',
        teamId: 'team_kolkata',
        runs: 38,
        wickets: 9,
        matches: 4,
      ),
      Player(
        id: 'pl_5',
        fullName: 'Tanmoy Das',
        displayName: 'Tanmoy Das',
        role: PlayerRole.bowler,
        battingStyle: 'Left Hand Bat',
        bowlingStyle: 'Right Arm Fast',
        basePrice: 550000,
        photoUrl: 'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=256',
        teamId: 'team_barasat',
        runs: 18,
        wickets: 11,
        matches: 4,
      ),
      Player(
        id: 'pl_6',
        fullName: 'Manoj Tiwary',
        displayName: 'Manoj Tiwary',
        role: PlayerRole.batsman,
        battingStyle: 'Right Hand Bat',
        bowlingStyle: 'Right Arm Leg Break',
        basePrice: 800000,
        photoUrl: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=256',
        teamId: 'team_howrah',
        runs: 285,
        wickets: 3,
        matches: 4,
      ),
      Player(
        id: 'pl_7',
        fullName: 'Akash Deep',
        displayName: 'Akash Deep',
        role: PlayerRole.bowler,
        battingStyle: 'Right Hand Bat',
        bowlingStyle: 'Right Arm Fast Medium',
        basePrice: 750000,
        photoUrl: 'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=256',
        teamId: 'team_howrah',
        runs: 45,
        wickets: 10,
        matches: 4,
      ),
      Player(
        id: 'pl_8',
        fullName: 'Wriddhiman Saha',
        displayName: 'W. Saha',
        role: PlayerRole.wicketKeeper,
        battingStyle: 'Right Hand Bat',
        bowlingStyle: 'None',
        basePrice: 900000,
        photoUrl: 'https://images.unsplash.com/photo-1501196354995-cbb51c65aaea?w=256',
        teamId: 'team_kolkata',
        runs: 215,
        wickets: 0,
        matches: 4,
      ),
      Player(
        id: 'pl_9',
        fullName: 'Shahbaz Ahmed',
        displayName: 'Shahbaz Ahmed',
        role: PlayerRole.allRounder,
        battingStyle: 'Left Hand Bat',
        bowlingStyle: 'Slow Left Arm Orthodox',
        basePrice: 700000,
        photoUrl: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=256',
        teamId: 'team_kolkata',
        runs: 168,
        wickets: 8,
        matches: 4,
      ),
      Player(
        id: 'pl_10',
        fullName: 'Anustup Majumdar',
        displayName: 'A. Majumdar',
        role: PlayerRole.batsman,
        battingStyle: 'Right Hand Bat',
        bowlingStyle: 'Right Arm Leg Break',
        basePrice: 500000,
        photoUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=256',
        teamId: 'team_hooghly',
        runs: 195,
        wickets: 2,
        matches: 3,
      ),
      Player(
        id: 'pl_11',
        fullName: 'Ishan Porel',
        displayName: 'Ishan Porel',
        role: PlayerRole.bowler,
        battingStyle: 'Right Hand Bat',
        bowlingStyle: 'Right Arm Fast',
        basePrice: 650000,
        photoUrl: 'https://images.unsplash.com/photo-1508214751196-bcfd4ca60f91?w=256',
        teamId: 'team_hooghly',
        runs: 12,
        wickets: 9,
        matches: 3,
      ),

      // ==========================================
      // PSL 2026 AUCTION PLAYERS (Unassigned: teamId is null)
      // ==========================================
      Player(
        id: 'pl_psl_1',
        fullName: 'Babar Azam',
        displayName: 'Babar Azam',
        role: PlayerRole.batsman,
        battingStyle: 'Right Hand Bat',
        bowlingStyle: 'Right Arm Off Break',
        basePrice: 1000000,
        photoUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=256',
        teamId: null,
      ),
      Player(
        id: 'pl_psl_2',
        fullName: 'Shaheen Afridi',
        displayName: 'Shaheen Afridi',
        role: PlayerRole.bowler,
        battingStyle: 'Left Hand Bat',
        bowlingStyle: 'Left Arm Fast',
        basePrice: 900000,
        photoUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=256',
        teamId: null,
      ),
      Player(
        id: 'pl_psl_3',
        fullName: 'Mohammad Rizwan',
        displayName: 'Mohammad Rizwan',
        role: PlayerRole.wicketKeeper,
        battingStyle: 'Right Hand Bat',
        bowlingStyle: 'None',
        basePrice: 850000,
        photoUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=256',
        teamId: null,
      ),
      Player(
        id: 'pl_psl_4',
        fullName: 'Fakhar Zaman',
        displayName: 'Fakhar Zaman',
        role: PlayerRole.batsman,
        battingStyle: 'Left Hand Bat',
        bowlingStyle: 'Slow Left Arm',
        basePrice: 600000,
        photoUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=256',
        teamId: null,
      ),
      Player(
        id: 'pl_psl_5',
        fullName: 'Shadab Khan',
        displayName: 'Shadab Khan',
        role: PlayerRole.allRounder,
        battingStyle: 'Right Hand Bat',
        bowlingStyle: 'Right Arm Leg Break',
        basePrice: 750000,
        photoUrl: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=256',
        teamId: null,
      ),
      Player(
        id: 'pl_psl_6',
        fullName: 'Haris Rauf',
        displayName: 'Haris Rauf',
        role: PlayerRole.bowler,
        battingStyle: 'Right Hand Bat',
        bowlingStyle: 'Right Arm Fast',
        basePrice: 700000,
        photoUrl: 'https://images.unsplash.com/photo-1508214751196-bcfd4ca60f91?w=256',
        teamId: null,
      ),
      Player(
        id: 'pl_psl_7',
        fullName: 'Naseem Shah',
        displayName: 'Naseem Shah',
        role: PlayerRole.bowler,
        battingStyle: 'Right Hand Bat',
        bowlingStyle: 'Right Arm Fast',
        basePrice: 650000,
        photoUrl: 'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=256',
        teamId: null,
      ),
      Player(
        id: 'pl_psl_8',
        fullName: 'Saim Ayub',
        displayName: 'Saim Ayub',
        role: PlayerRole.batsman,
        battingStyle: 'Left Hand Bat',
        bowlingStyle: 'Right Arm Off Break',
        basePrice: 500000,
        photoUrl: 'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=256',
        teamId: null,
      ),
      Player(
        id: 'pl_psl_9',
        fullName: 'Iftikhar Ahmed',
        displayName: 'Iftikhar Ahmed',
        role: PlayerRole.allRounder,
        battingStyle: 'Right Hand Bat',
        bowlingStyle: 'Right Arm Off Break',
        basePrice: 450000,
        photoUrl: 'https://images.unsplash.com/photo-1501196354995-cbb51c65aaea?w=256',
        teamId: null,
      ),
      Player(
        id: 'pl_psl_10',
        fullName: 'Imad Wasim',
        displayName: 'Imad Wasim',
        role: PlayerRole.allRounder,
        battingStyle: 'Left Hand Bat',
        bowlingStyle: 'Slow Left Arm',
        basePrice: 550000,
        photoUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=256',
        teamId: null,
      ),

      // ==========================================
      // IPL 2026 AUCTION PLAYERS (Unassigned: teamId is null)
      // ==========================================
      Player(
        id: 'pl_ipl_1',
        fullName: 'Virat Kohli',
        displayName: 'Virat Kohli',
        role: PlayerRole.batsman,
        battingStyle: 'Right Hand Bat',
        bowlingStyle: 'Right Arm Medium',
        basePrice: 2000000,
        photoUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=256',
        teamId: null,
      ),
      Player(
        id: 'pl_ipl_2',
        fullName: 'Rohit Sharma',
        displayName: 'Rohit Sharma',
        role: PlayerRole.batsman,
        battingStyle: 'Right Hand Bat',
        bowlingStyle: 'Right Arm Off Break',
        basePrice: 1800000,
        photoUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=256',
        teamId: null,
      ),
      Player(
        id: 'pl_ipl_3',
        fullName: 'MS Dhoni',
        displayName: 'MS Dhoni',
        role: PlayerRole.wicketKeeper,
        battingStyle: 'Right Hand Bat',
        bowlingStyle: 'Right Arm Medium',
        basePrice: 1500000,
        photoUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=256',
        teamId: null,
      ),
      Player(
        id: 'pl_ipl_4',
        fullName: 'Jasprit Bumrah',
        displayName: 'Jasprit Bumrah',
        role: PlayerRole.bowler,
        battingStyle: 'Right Hand Bat',
        bowlingStyle: 'Right Arm Fast',
        basePrice: 1800000,
        photoUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=256',
        teamId: null,
      ),
      Player(
        id: 'pl_ipl_5',
        fullName: 'Hardik Pandya',
        displayName: 'Hardik Pandya',
        role: PlayerRole.allRounder,
        battingStyle: 'Right Hand Bat',
        bowlingStyle: 'Right Arm Fast Medium',
        basePrice: 1500000,
        photoUrl: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=256',
        teamId: null,
      ),
      Player(
        id: 'pl_ipl_6',
        fullName: 'Suryakumar Yadav',
        displayName: 'Suryakumar Yadav',
        role: PlayerRole.batsman,
        battingStyle: 'Right Hand Bat',
        bowlingStyle: 'Right Arm Off Break',
        basePrice: 1400000,
        photoUrl: 'https://images.unsplash.com/photo-1508214751196-bcfd4ca60f91?w=256',
        teamId: null,
      ),
      Player(
        id: 'pl_ipl_7',
        fullName: 'Shubman Gill',
        displayName: 'Shubman Gill',
        role: PlayerRole.batsman,
        battingStyle: 'Right Hand Bat',
        bowlingStyle: 'Right Arm Off Break',
        basePrice: 1200000,
        photoUrl: 'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=256',
        teamId: null,
      ),
      Player(
        id: 'pl_ipl_8',
        fullName: 'Ravindra Jadeja',
        displayName: 'Ravindra Jadeja',
        role: PlayerRole.allRounder,
        battingStyle: 'Left Hand Bat',
        bowlingStyle: 'Slow Left Arm Orthodox',
        basePrice: 1300000,
        photoUrl: 'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=256',
        teamId: null,
      ),
      Player(
        id: 'pl_ipl_9',
        fullName: 'Rishabh Pant',
        displayName: 'Rishabh Pant',
        role: PlayerRole.wicketKeeper,
        battingStyle: 'Left Hand Bat',
        bowlingStyle: 'None',
        basePrice: 1200000,
        photoUrl: 'https://images.unsplash.com/photo-1501196354995-cbb51c65aaea?w=256',
        teamId: null,
      ),
      Player(
        id: 'pl_ipl_10',
        fullName: 'KL Rahul',
        displayName: 'KL Rahul',
        role: PlayerRole.batsman,
        battingStyle: 'Right Hand Bat',
        bowlingStyle: 'None',
        basePrice: 1100000,
        photoUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=256',
        teamId: null,
      ),
    ];

    matches = [
      // 1. LIVE MATCH
      MatchModel(
        id: 'match_1',
        tournamentId: 'tourn_bpl_2026',
        stage: 'League Match 1',
        teamAId: 'team_barasat',
        teamBId: 'team_kolkata',
        venue: 'Eden Gardens, Kolkata',
        dateTime: DateTime.now().subtract(const Duration(hours: 1)),
        overs: 20,
        status: MatchStatus.live,
        tossWonBy: 'team_kolkata',
        tossDecision: 'bowl',
        battingFirstId: 'team_barasat',
        currentInningsNumber: 1,
      ),
      // 2. PAST COMPLETED MATCH
      MatchModel(
        id: 'match_past_1',
        tournamentId: 'tourn_bpl_2026',
        stage: 'Opening League Fixture',
        teamAId: 'team_barasat',
        teamBId: 'team_howrah',
        venue: 'Eden Gardens, Kolkata',
        dateTime: DateTime.now().subtract(const Duration(days: 1)),
        overs: 20,
        status: MatchStatus.completed,
        tossWonBy: 'team_howrah',
        tossDecision: 'bowl',
        battingFirstId: 'team_barasat',
        winnerId: 'team_barasat',
        winMargin: '24 runs',
        currentInningsNumber: 2,
      ),
      // 3. UPCOMING SCHEDULED MATCH 2
      MatchModel(
        id: 'match_2',
        tournamentId: 'tourn_bpl_2026',
        stage: 'League Match 2',
        teamAId: 'team_howrah',
        teamBId: 'team_kolkata',
        venue: 'Eden Gardens, Kolkata',
        dateTime: DateTime.now().add(const Duration(days: 1)),
        overs: 20,
        status: MatchStatus.scheduled,
        currentInningsNumber: 1,
      ),
      // 4. UPCOMING SCHEDULED MATCH 3
      MatchModel(
        id: 'match_3',
        tournamentId: 'tourn_bpl_2026',
        stage: 'League Match 3',
        teamAId: 'team_hooghly',
        teamBId: 'team_barasat',
        venue: 'Salt Lake Stadium, Kolkata',
        dateTime: DateTime.now().add(const Duration(days: 2)),
        overs: 20,
        status: MatchStatus.scheduled,
        currentInningsNumber: 1,
      ),
    ];

    inningsList = [
      // Innings for match_1 (Live)
      Innings(
        id: 'inn_1',
        matchId: 'match_1',
        inningsNumber: 1,
        battingTeamId: 'team_barasat',
        bowlingTeamId: 'team_kolkata',
        totalRuns: 142,
        wickets: 2,
        legalBalls: 86,
        oversStr: '14.2',
        extrasWides: 4,
        extrasNoBalls: 1,
        extrasByes: 2,
        extrasLegByes: 1,
        totalExtras: 8,
        isCompleted: false,
        currentStrikerId: 'pl_3', // Subham Dey
        currentNonStrikerId: 'pl_1', // Rahul Das
        currentBowlerId: 'pl_4', // Debayan Paul
      ),
      // Innings for match_past_1 (Innings 1)
      Innings(
        id: 'inn_past_1',
        matchId: 'match_past_1',
        inningsNumber: 1,
        battingTeamId: 'team_barasat',
        bowlingTeamId: 'team_howrah',
        totalRuns: 172,
        wickets: 5,
        legalBalls: 120,
        oversStr: '20.0',
        extrasWides: 6,
        extrasNoBalls: 2,
        totalExtras: 8,
        isCompleted: true,
      ),
      // Innings for match_past_1 (Innings 2 - Chased 173)
      Innings(
        id: 'inn_past_2',
        matchId: 'match_past_1',
        inningsNumber: 2,
        battingTeamId: 'team_howrah',
        bowlingTeamId: 'team_barasat',
        totalRuns: 148,
        wickets: 8,
        legalBalls: 120,
        oversStr: '20.0',
        extrasWides: 4,
        extrasNoBalls: 1,
        totalExtras: 5,
        isCompleted: true,
        targetRuns: 173,
      ),
    ];

    deliveries = [
      Delivery(
        id: 'del_1',
        inningsId: 'inn_1',
        matchId: 'match_1',
        overNumber: 14,
        ballInOver: 1,
        deliverySequence: 85,
        strikerId: 'pl_1',
        nonStrikerId: 'pl_3',
        bowlerId: 'pl_4',
        runsBatter: 1,
        extrasRuns: 0,
        isLegal: true,
        commentaryText: 'Debayan Paul bowls full on off, pushed to mid-off for a single.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
      ),
      Delivery(
        id: 'del_2',
        inningsId: 'inn_1',
        matchId: 'match_1',
        overNumber: 14,
        ballInOver: 2,
        deliverySequence: 86,
        strikerId: 'pl_3',
        nonStrikerId: 'pl_1',
        bowlerId: 'pl_4',
        runsBatter: 4,
        extrasRuns: 0,
        isLegal: true,
        commentaryText: 'FOUR! Slashed through backward point with blistering timing to the fence!',
        timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
      ),
    ];

    battingScorecards = [
      // Live match cards
      BattingScorecard(
        id: 'bat_1',
        inningsId: 'inn_1',
        matchId: 'match_1',
        playerId: 'pl_3',
        playerName: 'Subham Dey',
        runs: 62,
        balls: 38,
        fours: 6,
        sixes: 2,
        strikeRate: 163.2,
        dismissalText: 'not out',
        isOut: false,
      ),
      BattingScorecard(
        id: 'bat_2',
        inningsId: 'inn_1',
        matchId: 'match_1',
        playerId: 'pl_1',
        playerName: 'Rahul Das',
        runs: 45,
        balls: 31,
        fours: 4,
        sixes: 1,
        strikeRate: 145.2,
        dismissalText: 'not out',
        isOut: false,
      ),
      BattingScorecard(
        id: 'bat_3',
        inningsId: 'inn_1',
        matchId: 'match_1',
        playerId: 'pl_2',
        playerName: 'Suman Biswas',
        runs: 27,
        balls: 17,
        fours: 3,
        sixes: 1,
        strikeRate: 158.8,
        dismissalText: 'c W. Saha b Debayan Paul',
        isOut: true,
      ),
      // Past match cards (Innings 1)
      BattingScorecard(
        id: 'bat_past_1',
        inningsId: 'inn_past_1',
        matchId: 'match_past_1',
        playerId: 'pl_1',
        playerName: 'Rahul Das',
        runs: 68,
        balls: 42,
        fours: 7,
        sixes: 3,
        strikeRate: 161.9,
        dismissalText: 'c Manoj Tiwary b Akash Deep',
        isOut: true,
      ),
      BattingScorecard(
        id: 'bat_past_2',
        inningsId: 'inn_past_1',
        matchId: 'match_past_1',
        playerId: 'pl_3',
        playerName: 'Subham Dey',
        runs: 44,
        balls: 31,
        fours: 4,
        sixes: 1,
        strikeRate: 141.9,
        dismissalText: 'b Shahbaz Ahmed',
        isOut: true,
      ),
      // Past match cards (Innings 2)
      BattingScorecard(
        id: 'bat_past_3',
        inningsId: 'inn_past_2',
        matchId: 'match_past_1',
        playerId: 'pl_6',
        playerName: 'Manoj Tiwary',
        runs: 52,
        balls: 36,
        fours: 5,
        sixes: 2,
        strikeRate: 144.4,
        dismissalText: 'c Suman Biswas b Tanmoy Das',
        isOut: true,
      ),
    ];

    bowlingScorecards = [
      // Live match bowler
      BowlingScorecard(
        id: 'bowl_1',
        inningsId: 'inn_1',
        matchId: 'match_1',
        playerId: 'pl_4',
        playerName: 'Debayan Paul',
        oversStr: '2.4',
        legalBalls: 16,
        maidens: 0,
        runsConceded: 24,
        wickets: 1,
        dots: 7,
        economy: 9.0,
      ),
      // Past match bowlers
      BowlingScorecard(
        id: 'bowl_past_1',
        inningsId: 'inn_past_1',
        matchId: 'match_past_1',
        playerId: 'pl_7',
        playerName: 'Akash Deep',
        oversStr: '4.0',
        legalBalls: 24,
        maidens: 0,
        runsConceded: 32,
        wickets: 2,
        dots: 11,
        economy: 8.0,
      ),
      BowlingScorecard(
        id: 'bowl_past_2',
        inningsId: 'inn_past_2',
        matchId: 'match_past_1',
        playerId: 'pl_5',
        playerName: 'Tanmoy Das',
        oversStr: '4.0',
        legalBalls: 24,
        maidens: 0,
        runsConceded: 28,
        wickets: 3,
        dots: 13,
        economy: 7.0,
      ),
    ];

    tournamentStandings = [
      TournamentStanding(
        teamId: 'team_barasat',
        teamName: 'Barasat Blasters',
        teamShortName: 'BBL',
        teamLogoUrl: 'https://images.unsplash.com/photo-1589487391730-58f20eb2c308?w=96',
        matchesPlayed: 1,
        won: 1,
        lost: 0,
        points: 2,
        netRunRate: 1.200,
      ),
      TournamentStanding(
        teamId: 'team_kolkata',
        teamName: 'Kolkata Kings',
        teamShortName: 'KK',
        teamLogoUrl: 'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=96',
        matchesPlayed: 0,
        won: 0,
        lost: 0,
        points: 0,
        netRunRate: 0.000,
      ),
      TournamentStanding(
        teamId: 'team_hooghly',
        teamName: 'Hooghly Heroes',
        teamShortName: 'HOH',
        teamLogoUrl: 'https://images.unsplash.com/photo-1579952363873-27f3bade9f55?w=96',
        matchesPlayed: 0,
        won: 0,
        lost: 0,
        points: 0,
        netRunRate: 0.000,
      ),
      TournamentStanding(
        teamId: 'team_howrah',
        teamName: 'Howrah Hurricanes',
        teamShortName: 'HH',
        teamLogoUrl: 'https://images.unsplash.com/photo-1517649763962-0c623266ddc0?w=96',
        matchesPlayed: 1,
        won: 0,
        lost: 1,
        points: 0,
        netRunRate: -1.200,
      ),
    ];

    // AUCTION SEED DATA
    auctions = [
      Auction(
        id: 'auc_bpl_2026',
        tournamentId: 'tourn_bpl_2026',
        title: 'BPL 2026 Franchise Mega Auction',
        auctionCode: 'BPL2026-7842',
        auctionPin: '583921',
        isJoiningEnabled: true,
        joiningMode: AuctionJoiningMode.automatic,
        status: AuctionStatus.live,
        currentLotId: 'lot_6',
        currentBid: 450000,
        highBidderTeamId: 'team_barasat',
        totalLots: 8,
        completedLots: 5,
        adminPasscode: 'admin123',
        minBidIncrement: 25000,
        maxPursePerTeam: 10000000,
        requiredTeamsCount: 8,
        joinedTeamIds: {
          'team_barasat',
          'team_kolkata',
          'team_howrah',
          'team_hooghly',
          'team_siliguri',
          'team_durgapur',
          'team_midnapore',
          'team_malda',
        },
      ),
      Auction(
        id: 'auc_psl_2026',
        tournamentId: 'tourn_psl_2026',
        title: 'PSL 2026 Player Draft & Auction',
        auctionCode: 'PSL2026-3490',
        auctionPin: '123456',
        isJoiningEnabled: true,
        joiningMode: AuctionJoiningMode.hostApproval,
        status: AuctionStatus.live,
        currentLotId: 'lot_psl_1',
        currentBid: 1000000,
        highBidderTeamId: null,
        totalLots: 10,
        completedLots: 0,
        adminPasscode: 'admin123',
        minBidIncrement: 50000,
        maxPursePerTeam: 10000000,
        requiredTeamsCount: 8,
        joinedTeamIds: {}, // Fresh 8-team waiting lobby!
      ),
      Auction(
        id: 'auc_ipl_2026',
        tournamentId: 'tourn_ipl_2026',
        title: 'IPL 2026 Mini Auction',
        auctionCode: 'IPL2026-9021',
        auctionPin: '654321',
        isJoiningEnabled: true,
        joiningMode: AuctionJoiningMode.automatic,
        status: AuctionStatus.preview,
        currentLotId: 'lot_ipl_1',
        currentBid: 2000000,
        highBidderTeamId: null,
        totalLots: 10,
        completedLots: 0,
        adminPasscode: 'admin123',
        minBidIncrement: 100000,
        maxPursePerTeam: 15000000,
        requiredTeamsCount: 8,
        joinedTeamIds: {},
      ),
    ];

    auctionLots = [
      AuctionLot(
        id: 'lot_1',
        auctionId: 'auc_bpl_2026',
        lotNumber: 1,
        playerId: 'pl_1',
        category: 'marquee',
        basePrice: 500000,
        currentBid: 950000,
        winningTeamId: 'team_barasat',
        status: LotStatus.sold,
      ),
      AuctionLot(
        id: 'lot_2',
        auctionId: 'auc_bpl_2026',
        lotNumber: 2,
        playerId: 'pl_3',
        category: 'marquee',
        basePrice: 600000,
        currentBid: 1200000,
        winningTeamId: 'team_barasat',
        status: LotStatus.sold,
      ),
      AuctionLot(
        id: 'lot_3',
        auctionId: 'auc_bpl_2026',
        lotNumber: 3,
        playerId: 'pl_4',
        category: 'bowler',
        basePrice: 400000,
        currentBid: 850000,
        winningTeamId: 'team_kolkata',
        status: LotStatus.sold,
      ),
      AuctionLot(
        id: 'lot_4',
        auctionId: 'auc_bpl_2026',
        lotNumber: 4,
        playerId: 'pl_6',
        category: 'marquee',
        basePrice: 800000,
        currentBid: 1450000,
        winningTeamId: 'team_howrah',
        status: LotStatus.sold,
      ),
      AuctionLot(
        id: 'lot_5',
        auctionId: 'auc_bpl_2026',
        lotNumber: 5,
        playerId: 'pl_7',
        category: 'bowler',
        basePrice: 750000,
        currentBid: 1100000,
        winningTeamId: 'team_howrah',
        status: LotStatus.sold,
      ),
      AuctionLot(
        id: 'lot_6',
        auctionId: 'auc_bpl_2026',
        lotNumber: 6,
        playerId: 'pl_10', // Anustup Majumdar
        category: 'batsman',
        basePrice: 300000,
        currentBid: 450000,
        winningTeamId: 'team_barasat',
        status: LotStatus.bidding,
      ),
      AuctionLot(
        id: 'lot_7',
        auctionId: 'auc_bpl_2026',
        lotNumber: 7,
        playerId: 'pl_9', // Shahbaz Ahmed
        category: 'all_rounder',
        basePrice: 500000,
        status: LotStatus.pending,
      ),
      AuctionLot(
        id: 'lot_8',
        auctionId: 'auc_bpl_2026',
        lotNumber: 8,
        playerId: 'pl_11', // Ishan Porel
        category: 'bowler',
        basePrice: 450000,
        status: LotStatus.pending,
      ),

      // ==========================================
      // PSL 2026 AUCTION LOTS (Fresh: 0 sold, all pending/bidding)
      // ==========================================
      AuctionLot(
        id: 'lot_psl_1',
        auctionId: 'auc_psl_2026',
        lotNumber: 1,
        playerId: 'pl_psl_1', // Babar Azam
        category: 'marquee',
        basePrice: 1000000,
        currentBid: 1000000,
        status: LotStatus.bidding,
      ),
      AuctionLot(
        id: 'lot_psl_2',
        auctionId: 'auc_psl_2026',
        lotNumber: 2,
        playerId: 'pl_psl_2', // Shaheen Afridi
        category: 'marquee',
        basePrice: 900000,
        status: LotStatus.pending,
      ),
      AuctionLot(
        id: 'lot_psl_3',
        auctionId: 'auc_psl_2026',
        lotNumber: 3,
        playerId: 'pl_psl_3', // Mohammad Rizwan
        category: 'wicket_keeper',
        basePrice: 850000,
        status: LotStatus.pending,
      ),
      AuctionLot(
        id: 'lot_psl_4',
        auctionId: 'auc_psl_2026',
        lotNumber: 4,
        playerId: 'pl_psl_4', // Fakhar Zaman
        category: 'batsman',
        basePrice: 600000,
        status: LotStatus.pending,
      ),
      AuctionLot(
        id: 'lot_psl_5',
        auctionId: 'auc_psl_2026',
        lotNumber: 5,
        playerId: 'pl_psl_5', // Shadab Khan
        category: 'all_rounder',
        basePrice: 750000,
        status: LotStatus.pending,
      ),
      AuctionLot(
        id: 'lot_psl_6',
        auctionId: 'auc_psl_2026',
        lotNumber: 6,
        playerId: 'pl_psl_6', // Haris Rauf
        category: 'bowler',
        basePrice: 700000,
        status: LotStatus.pending,
      ),
      AuctionLot(
        id: 'lot_psl_7',
        auctionId: 'auc_psl_2026',
        lotNumber: 7,
        playerId: 'pl_psl_7', // Naseem Shah
        category: 'bowler',
        basePrice: 650000,
        status: LotStatus.pending,
      ),
      AuctionLot(
        id: 'lot_psl_8',
        auctionId: 'auc_psl_2026',
        lotNumber: 8,
        playerId: 'pl_psl_8', // Saim Ayub
        category: 'batsman',
        basePrice: 500000,
        status: LotStatus.pending,
      ),
      AuctionLot(
        id: 'lot_psl_9',
        auctionId: 'auc_psl_2026',
        lotNumber: 9,
        playerId: 'pl_psl_9', // Iftikhar Ahmed
        category: 'all_rounder',
        basePrice: 450000,
        status: LotStatus.pending,
      ),
      AuctionLot(
        id: 'lot_psl_10',
        auctionId: 'auc_psl_2026',
        lotNumber: 10,
        playerId: 'pl_psl_10', // Imad Wasim
        category: 'all_rounder',
        basePrice: 550000,
        status: LotStatus.pending,
      ),

      // ==========================================
      // IPL 2026 AUCTION LOTS (Fresh)
      // ==========================================
      AuctionLot(
        id: 'lot_ipl_1',
        auctionId: 'auc_ipl_2026',
        lotNumber: 1,
        playerId: 'pl_ipl_1', // Virat Kohli
        category: 'marquee',
        basePrice: 2000000,
        currentBid: 2000000,
        status: LotStatus.bidding,
      ),
      AuctionLot(
        id: 'lot_ipl_2',
        auctionId: 'auc_ipl_2026',
        lotNumber: 2,
        playerId: 'pl_ipl_2', // Rohit Sharma
        category: 'marquee',
        basePrice: 1800000,
        status: LotStatus.pending,
      ),
      AuctionLot(
        id: 'lot_ipl_3',
        auctionId: 'auc_ipl_2026',
        lotNumber: 3,
        playerId: 'pl_ipl_3', // MS Dhoni
        category: 'wicket_keeper',
        basePrice: 1500000,
        status: LotStatus.pending,
      ),
      AuctionLot(
        id: 'lot_ipl_4',
        auctionId: 'auc_ipl_2026',
        lotNumber: 4,
        playerId: 'pl_ipl_4', // Jasprit Bumrah
        category: 'bowler',
        basePrice: 1800000,
        status: LotStatus.pending,
      ),
      AuctionLot(
        id: 'lot_ipl_5',
        auctionId: 'auc_ipl_2026',
        lotNumber: 5,
        playerId: 'pl_ipl_5', // Hardik Pandya
        category: 'all_rounder',
        basePrice: 1500000,
        status: LotStatus.pending,
      ),
      AuctionLot(
        id: 'lot_ipl_6',
        auctionId: 'auc_ipl_2026',
        lotNumber: 6,
        playerId: 'pl_ipl_6', // Suryakumar Yadav
        category: 'batsman',
        basePrice: 1400000,
        status: LotStatus.pending,
      ),
      AuctionLot(
        id: 'lot_ipl_7',
        auctionId: 'auc_ipl_2026',
        lotNumber: 7,
        playerId: 'pl_ipl_7', // Shubman Gill
        category: 'batsman',
        basePrice: 1200000,
        status: LotStatus.pending,
      ),
      AuctionLot(
        id: 'lot_ipl_8',
        auctionId: 'auc_ipl_2026',
        lotNumber: 8,
        playerId: 'pl_ipl_8', // Ravindra Jadeja
        category: 'all_rounder',
        basePrice: 1300000,
        status: LotStatus.pending,
      ),
      AuctionLot(
        id: 'lot_ipl_9',
        auctionId: 'auc_ipl_2026',
        lotNumber: 9,
        playerId: 'pl_ipl_9', // Rishabh Pant
        category: 'wicket_keeper',
        basePrice: 1200000,
        status: LotStatus.pending,
      ),
      AuctionLot(
        id: 'lot_ipl_10',
        auctionId: 'auc_ipl_2026',
        lotNumber: 10,
        playerId: 'pl_ipl_10', // KL Rahul
        category: 'batsman',
        basePrice: 1100000,
        status: LotStatus.pending,
      ),
    ];

    auctionBids = [
      AuctionBid(
        id: 'bid_1',
        lotId: 'lot_6',
        teamId: 'team_howrah',
        teamName: 'Howrah Hurricanes',
        amount: 350000,
        timestamp: DateTime.now().subtract(const Duration(seconds: 40)),
      ),
      AuctionBid(
        id: 'bid_2',
        lotId: 'lot_6',
        teamId: 'team_kolkata',
        teamName: 'Kolkata Kings',
        amount: 400000,
        timestamp: DateTime.now().subtract(const Duration(seconds: 20)),
      ),
      AuctionBid(
        id: 'bid_3',
        lotId: 'lot_6',
        teamId: 'team_barasat',
        teamName: 'Barasat Blasters',
        amount: 450000,
        timestamp: DateTime.now().subtract(const Duration(seconds: 5)),
      ),
    ];

    scoringRooms = [
      ScoringRoom(
        id: 'ROOM-BPL-01',
        matchId: 'match_1',
        passcode: '1234',
        createdBy: 'Lead Scorer (Eden Gardens)',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      ScoringRoom(
        id: 'ROOM-BPL-02',
        matchId: 'match_2',
        passcode: '1234',
        createdBy: 'Official Scorer',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      ScoringRoom(
        id: 'ROOM-BPL-03',
        matchId: 'match_3',
        passcode: '1234',
        createdBy: 'Tournament Host',
        createdAt: DateTime.now(),
      ),
    ];

    auctionRooms = [
      AuctionRoom(
        id: 'AUCTION-BPL',
        auctionId: 'auc_bpl_2026',
        passcode: '1234',
        adminPasscode: 'admin123',
        createdBy: 'BPL Governing Council',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];

    auctionTransactions = [];
    whatsappNotifications = [];
  }

  // ==========================================
  // SCORING METHODS
  // ==========================================

  void recordDelivery({
    required String inningsId,
    required int runsBatter,
    int extrasRuns = 0,
    ExtrasType extrasType = ExtrasType.none,
    bool isWicket = false,
    DismissalType? dismissalType,
    String? dismissedPlayerId,
    String? fielderId,
    String? nextBatterId,
  }) {
    final inn = inningsList.firstWhere((i) => i.id == inningsId);
    final match = matches.firstWhere((m) => m.id == inn.matchId);

    // Hard Over Cap & All-Out check (10 wickets max or innings already completed)
    if (inn.isCompleted || inn.legalBalls >= match.overs * 6 || inn.wickets >= 10) {
      return;
    }

    final isLegal = extrasType != ExtrasType.wide && extrasType != ExtrasType.noBall;
    final totalBallRuns = runsBatter + extrasRuns;

    inn.totalRuns += totalBallRuns;
    if (isLegal) inn.legalBalls++;

    if (extrasType == ExtrasType.wide) inn.extrasWides += extrasRuns;
    if (extrasType == ExtrasType.noBall) inn.extrasNoBalls += extrasRuns;
    if (extrasType == ExtrasType.bye) inn.extrasByes += extrasRuns;
    if (extrasType == ExtrasType.legBye) inn.extrasLegByes += extrasRuns;
    inn.totalExtras += extrasRuns;

    inn.oversStr = CricketRulesEngine.formatOvers(inn.legalBalls);

    // Striker & Bowler (Resilient against null IDs or non-existent fallback IDs)
    final battingPlayers = players.where((p) => p.teamId == inn.battingTeamId || (inn.inningsNumber == 1 ? match.playingXIA.contains(p.id) : match.playingXIB.contains(p.id))).toList();
    final bowlingPlayers = players.where((p) => p.teamId == inn.bowlingTeamId).toList();

    String strikerId = inn.currentStrikerId ?? '';
    if (strikerId.isEmpty || !players.any((p) => p.id == strikerId)) {
      if (battingPlayers.isNotEmpty) {
        strikerId = battingPlayers[0].id;
        inn.currentStrikerId = strikerId;
      }
    }

    String nonStrikerId = inn.currentNonStrikerId ?? '';
    if (nonStrikerId.isEmpty || !players.any((p) => p.id == nonStrikerId)) {
      if (battingPlayers.length > 1) {
        nonStrikerId = battingPlayers[1].id;
        inn.currentNonStrikerId = nonStrikerId;
      } else {
        nonStrikerId = strikerId;
        inn.currentNonStrikerId = nonStrikerId;
      }
    }

    String bowlerId = inn.currentBowlerId ?? '';
    if (bowlerId.isEmpty || !players.any((p) => p.id == bowlerId)) {
      if (bowlingPlayers.isNotEmpty) {
        final bP = bowlingPlayers.firstWhere(
          (p) => p.role == PlayerRole.bowler,
          orElse: () => bowlingPlayers.first,
        );
        bowlerId = bP.id;
        inn.currentBowlerId = bowlerId;
      }
    }

    // Update Batter Scorecard
    var strikerCard = battingScorecards.firstWhere(
      (b) => b.inningsId == inningsId && b.playerId == strikerId,
      orElse: () {
        final p = players.where((p) => p.id == strikerId).firstOrNull ??
            battingPlayers.where((p) => p.id == strikerId).firstOrNull ??
            battingPlayers.firstOrNull ??
            Player(id: strikerId, fullName: 'Striker', displayName: 'Striker', role: PlayerRole.batsman);
        final newCard = BattingScorecard(
          id: 'bat_${inningsId}_$strikerId',
          inningsId: inningsId,
          matchId: match.id,
          playerId: strikerId,
          playerName: p.fullName.isNotEmpty ? p.fullName : p.displayName,
        );
        battingScorecards.add(newCard);
        return newCard;
      },
    );

    strikerCard.runs += runsBatter;
    if (extrasType != ExtrasType.wide) strikerCard.balls++;
    if (runsBatter == 4) strikerCard.fours++;
    if (runsBatter == 6) strikerCard.sixes++;
    if (strikerCard.balls > 0) {
      strikerCard.strikeRate = (strikerCard.runs / strikerCard.balls) * 100.0;
    }

    // Update Bowler Scorecard
    var bowlerCard = bowlingScorecards.firstWhere(
      (b) => b.inningsId == inningsId && b.playerId == bowlerId,
      orElse: () {
        final p = players.where((p) => p.id == bowlerId).firstOrNull ??
            bowlingPlayers.where((p) => p.id == bowlerId).firstOrNull ??
            bowlingPlayers.firstOrNull ??
            Player(id: bowlerId, fullName: 'Bowler', displayName: 'Bowler', role: PlayerRole.bowler);
        final newCard = BowlingScorecard(
          id: 'bowl_${inningsId}_$bowlerId',
          inningsId: inningsId,
          matchId: match.id,
          playerId: bowlerId,
          playerName: p.fullName.isNotEmpty ? p.fullName : p.displayName,
        );
        bowlingScorecards.add(newCard);
        return newCard;
      },
    );

    if (isLegal) bowlerCard.legalBalls++;
    bowlerCard.oversStr = CricketRulesEngine.formatOvers(bowlerCard.legalBalls);
    final bowlerCharges = (extrasType == ExtrasType.bye || extrasType == ExtrasType.legBye) ? runsBatter : totalBallRuns;
    bowlerCard.runsConceded += bowlerCharges;
    if (totalBallRuns == 0 && isLegal) bowlerCard.dots++;
    if (isWicket && dismissalType != DismissalType.runOut && dismissalType != DismissalType.retiredOut) {
      bowlerCard.wickets++;
    }
    if (bowlerCard.legalBalls > 0) {
      bowlerCard.economy = (bowlerCard.runsConceded / (bowlerCard.legalBalls / 6.0));
    }

    // Wicket handling
    String dismissalAnalysisText = 'OUT';
    if (isWicket) {
      inn.wickets++;
      final outPlayerId = dismissedPlayerId ?? strikerId;
      var outCard = battingScorecards.where((b) => b.inningsId == inningsId && b.playerId == outPlayerId).firstOrNull;
      if (outCard == null) {
        final outPlayer = players.where((p) => p.id == outPlayerId).firstOrNull;
        outCard = BattingScorecard(
          id: 'bat_${inningsId}_$outPlayerId',
          inningsId: inningsId,
          matchId: match.id,
          playerId: outPlayerId,
          playerName: outPlayer?.fullName.isNotEmpty == true ? outPlayer!.fullName : 'Batter',
        );
        battingScorecards.add(outCard);
      }
      outCard.isOut = true;

      final bowlerPlayer = bowlerId.isNotEmpty ? players.where((p) => p.id == bowlerId).firstOrNull : null;
      final fielderPlayer = fielderId != null ? players.where((p) => p.id == fielderId).firstOrNull : null;
      final bowlerName = bowlerPlayer?.fullName.isNotEmpty == true ? bowlerPlayer!.fullName : (bowlerPlayer?.displayName ?? 'Bowler');
      final fielderName = fielderPlayer?.fullName.isNotEmpty == true ? fielderPlayer!.fullName : (fielderPlayer?.displayName ?? 'Fielder');

      switch (dismissalType) {
        case DismissalType.caught:
          if (fielderId == bowlerId || fielderId == null || fielderName.isEmpty) {
            dismissalAnalysisText = 'c & b $bowlerName';
          } else {
            dismissalAnalysisText = 'c $fielderName b $bowlerName';
          }
          break;
        case DismissalType.bowled:
          dismissalAnalysisText = 'b $bowlerName';
          break;
        case DismissalType.lbw:
          dismissalAnalysisText = 'lbw b $bowlerName';
          break;
        case DismissalType.stumped:
          dismissalAnalysisText = 'st $fielderName b $bowlerName';
          break;
        case DismissalType.runOut:
          dismissalAnalysisText = (fielderId != null && fielderName.isNotEmpty) ? 'run out ($fielderName)' : 'run out';
          break;
        case DismissalType.hitWicket:
          dismissalAnalysisText = 'hit wicket b $bowlerName';
          break;
        case DismissalType.retiredOut:
          dismissalAnalysisText = 'retired out';
          break;
        default:
          dismissalAnalysisText = dismissalType?.name.toUpperCase() ?? 'OUT';
      }
      outCard.dismissalText = dismissalAnalysisText;

      if (nextBatterId != null) {
        if (outPlayerId == inn.currentStrikerId) {
          inn.currentStrikerId = nextBatterId;
        } else {
          inn.currentNonStrikerId = nextBatterId;
        }
      }
    }

    // Strike Rotation: odd runs swap ends
    final runsForRotation = runsBatter > 0
        ? runsBatter
        : ((extrasType == ExtrasType.bye || extrasType == ExtrasType.legBye) ? extrasRuns : (extrasType == ExtrasType.wide ? extrasRuns - 1 : 0));
    if (runsForRotation % 2 != 0) {
      final temp = inn.currentStrikerId;
      inn.currentStrikerId = inn.currentNonStrikerId;
      inn.currentNonStrikerId = temp;
    }

    // Over Completion Check
    final isOverComplete = isLegal && (inn.legalBalls % 6 == 0);
    if (isOverComplete) {
      // End of over: swap ends
      final temp = inn.currentStrikerId;
      inn.currentStrikerId = inn.currentNonStrikerId;
      inn.currentNonStrikerId = temp;
      inn.currentBowlerId = null; // Forces prompt to select new bowler
    }

    // Delivery log
    deliveries.add(
      Delivery(
        id: 'del_${DateTime.now().millisecondsSinceEpoch}_${deliveries.length + 1}',
        inningsId: inningsId,
        matchId: match.id,
        overNumber: (inn.legalBalls - 1) ~/ 6,
        ballInOver: (inn.legalBalls - 1) % 6 + 1,
        deliverySequence: deliveries.length + 1,
        strikerId: strikerId,
        nonStrikerId: nonStrikerId,
        bowlerId: bowlerId,
        runsBatter: runsBatter,
        extrasRuns: extrasRuns,
        isLegal: isLegal,
        isWicket: isWicket,
        extrasType: extrasType,
        dismissalType: dismissalType,
        dismissedPlayerId: dismissedPlayerId,
        fielderId: fielderId,
        commentaryText: isWicket
            ? 'WICKET! ${players.where((p) => p.id == (dismissedPlayerId ?? strikerId)).firstOrNull?.fullName ?? "Batter"} is out ($dismissalAnalysisText).'
            : extrasType == ExtrasType.noBall
                ? (runsBatter > 0
                    ? 'NO-BALL + $runsBatter RUNS! Free hit awarded.'
                    : 'NO-BALL (+1 run). Free hit awarded.')
                : extrasType == ExtrasType.wide
                    ? (extrasRuns > 1
                        ? 'WIDE + ${extrasRuns - 1} RUNS ($extrasRuns wides total).'
                        : 'WIDE BALL (+1 run).')
                    : extrasType == ExtrasType.bye
                        ? '$extrasRuns BYE(S)!'
                        : extrasType == ExtrasType.legBye
                            ? '$extrasRuns LEG BYE(S)!'
                            : runsBatter == 4
                                ? 'FOUR! Punched firmly to the boundary.'
                                : runsBatter == 6
                                    ? 'SIX! Clears the rope with huge elevation!'
                                    : 'Pushed into gaps for $runsBatter run(s).',
        timestamp: DateTime.now(),
      ),
    );

    // Check all-out condition: 10 wickets fallen OR no more batters available in dugout (nextBatterId null on wicket)
    final isAllOut = inn.wickets >= 10 || (isWicket && nextBatterId == null);

    // Innings 1 Completion Check
    if (inn.inningsNumber == 1 && (inn.legalBalls >= match.overs * 6 || isAllOut)) {
      inn.isCompleted = true;
      startInnings2(matchId: match.id);
    }

    // Innings 2 Chasing Check
    if (inn.inningsNumber == 2 && inn.targetRuns != null) {
      if (inn.totalRuns >= inn.targetRuns!) {
        inn.isCompleted = true;
        match.status = MatchStatus.completed;
        match.winnerId = inn.battingTeamId;
        final wicketsLeft = (10 - inn.wickets) > 0 ? (10 - inn.wickets) : 1;
        match.winMargin = '$wicketsLeft wickets';
      } else if (inn.legalBalls >= match.overs * 6 || isAllOut) {
        inn.isCompleted = true;
        match.status = MatchStatus.completed;
        match.winnerId = inn.bowlingTeamId;
        final runsDefended = (inn.targetRuns! - 1) - inn.totalRuns;
        match.winMargin = '$runsDefended runs';
      }
    }

    // Realtime Cloud Firestore Push for instant multi-device scoring broadcast
    try {
      final lastDel = deliveries.last;
      final bCards = battingScorecards.where((b) => b.inningsId == inningsId).toList();
      final bwCards = bowlingScorecards.where((bw) => bw.inningsId == inningsId).toList();
      FirestoreDatabaseService.pushLiveScoringEvent(
        match: match,
        innings: inn,
        delivery: lastDel,
        batCards: bCards,
        bowlCards: bwCards,
        activeUser: currentUser,
      );
    } catch (_) {}

    notifyListeners();
  }

  /// Retires a batsman mid-innings (either Retired Hurt / Injured or Retired Out).
  /// In cricket, when a player retires hurt or out, no ball delivery is counted!
  void retireBatter({
    required String inningsId,
    required String retiringPlayerId,
    required bool isHurt,
    required String replacementPlayerId,
  }) {
    final inn = inningsList.firstWhere((i) => i.id == inningsId);
    final match = matches.firstWhere((m) => m.id == inn.matchId);
    final battingPlayers = players.where((p) => p.teamId == inn.battingTeamId || (inn.inningsNumber == 1 ? match.playingXIA.contains(p.id) : match.playingXIB.contains(p.id))).toList();
    final maxWickets = (battingPlayers.length > 1) ? (battingPlayers.length - 1) : 10;

    var card = battingScorecards.where((b) => b.inningsId == inningsId && b.playerId == retiringPlayerId).firstOrNull;
    if (card == null) {
      final p = players.where((p) => p.id == retiringPlayerId).firstOrNull;
      card = BattingScorecard(
        id: 'bat_${inningsId}_$retiringPlayerId',
        inningsId: inningsId,
        matchId: match.id,
        playerId: retiringPlayerId,
        playerName: p?.fullName.isNotEmpty == true ? p!.fullName : 'Batter',
      );
      battingScorecards.add(card);
    }

    if (isHurt) {
      // Retired Hurt: Not dismissed, wickets does NOT increment
      card.isOut = false;
      card.dismissalText = 'retired hurt';
    } else {
      // Retired Out: Dismissed, wickets increments
      card.isOut = true;
      card.dismissalText = 'retired out';
      inn.wickets++;
    }

    // Replace at crease without consuming any delivery balls
    if (inn.currentStrikerId == retiringPlayerId) {
      inn.currentStrikerId = replacementPlayerId;
    } else if (inn.currentNonStrikerId == retiringPlayerId) {
      inn.currentNonStrikerId = replacementPlayerId;
    }

    // Check if Retired Out triggered all-out
    if (!isHurt && inn.wickets >= maxWickets) {
      inn.isCompleted = true;
      if (inn.inningsNumber == 1) {
        startInnings2(matchId: match.id);
      } else if (inn.inningsNumber == 2) {
        match.status = MatchStatus.completed;
        match.winnerId = inn.bowlingTeamId;
        final runsDefended = (inn.targetRuns ?? 1) - 1 - inn.totalRuns;
        match.winMargin = '$runsDefended runs';
      }
    }

    notifyListeners();
  }

  void setBowler(String inningsId, String bowlerId) {
    final inn = inningsList.firstWhere((i) => i.id == inningsId);
    inn.currentBowlerId = bowlerId;
    notifyListeners();
  }

  void setStriker(String inningsId, String strikerId) {
    final inn = inningsList.firstWhere((i) => i.id == inningsId);
    inn.currentStrikerId = strikerId;
    notifyListeners();
  }

  void setNonStriker(String inningsId, String nonStrikerId) {
    final inn = inningsList.firstWhere((i) => i.id == inningsId);
    inn.currentNonStrikerId = nonStrikerId;
    notifyListeners();
  }

  void setOpeningCrease({
    required String inningsId,
    required String strikerId,
    required String nonStrikerId,
    required String bowlerId,
  }) {
    final inn = inningsList.firstWhere((i) => i.id == inningsId);
    inn.currentStrikerId = strikerId;
    inn.currentNonStrikerId = nonStrikerId;
    inn.currentBowlerId = bowlerId;
    notifyListeners();
  }

  Innings startInnings2({
    required String matchId,
    String? strikerId,
    String? nonStrikerId,
    String? bowlerId,
  }) {
    final match = matches.firstWhere((m) => m.id == matchId);
    final inn1 = inningsList.firstWhere(
      (i) => i.matchId == matchId && i.inningsNumber == 1,
      orElse: () {
        final newInn1 = Innings(
          id: 'inn_${matchId}_1',
          matchId: matchId,
          inningsNumber: 1,
          battingTeamId: match.battingFirstId ?? match.teamAId,
          bowlingTeamId: (match.battingFirstId == match.teamAId) ? match.teamBId : match.teamAId,
        );
        inningsList.add(newInn1);
        return newInn1;
      },
    );
    inn1.isCompleted = true;

    final battingTeamId = inn1.bowlingTeamId;
    final bowlingTeamId = inn1.battingTeamId;

    final battingPlayers = players.where((p) => p.teamId == battingTeamId).toList();
    final bowlingPlayers = players.where((p) => p.teamId == bowlingTeamId).toList();

    final actualStrikerId = strikerId ?? (battingPlayers.isNotEmpty ? battingPlayers[0].id : '');
    final actualNonStrikerId = nonStrikerId ?? (battingPlayers.length > 1 ? battingPlayers[1].id : actualStrikerId);
    final actualBowlerId = bowlerId ?? (bowlingPlayers.isNotEmpty ? (bowlingPlayers.firstWhere((p) => p.role == PlayerRole.bowler, orElse: () => bowlingPlayers.first).id) : '');

    var inn2 = inningsList.where((i) => i.matchId == matchId && i.inningsNumber == 2).firstOrNull;
    if (inn2 == null) {
      inn2 = Innings(
        id: 'inn_${match.id}_2',
        matchId: match.id,
        inningsNumber: 2,
        battingTeamId: battingTeamId,
        bowlingTeamId: bowlingTeamId,
        targetRuns: inn1.totalRuns + 1,
      );
      inningsList.add(inn2);
    }

    inn2.currentStrikerId = actualStrikerId;
    inn2.currentNonStrikerId = actualNonStrikerId;
    inn2.currentBowlerId = actualBowlerId;
    inn2.targetRuns = inn1.totalRuns + 1;
    match.currentInningsNumber = 2;
    match.status = MatchStatus.live;

    notifyListeners();
    return inn2;
  }

  void endInningsEarly(String inningsId) {
    final inn = inningsList.firstWhere((i) => i.id == inningsId);
    inn.isCompleted = true;
    final match = matches.firstWhere((m) => m.id == inn.matchId);

    if (inn.inningsNumber == 1) {
      startInnings2(matchId: match.id);
    } else {
      match.status = MatchStatus.completed;
      if (inn.targetRuns != null) {
        if (inn.totalRuns >= inn.targetRuns!) {
          match.winnerId = inn.battingTeamId;
          match.winMargin = '${10 - inn.wickets} wickets';
        } else {
          match.winnerId = inn.bowlingTeamId;
          match.winMargin = '${(inn.targetRuns! - 1) - inn.totalRuns} runs';
        }
      }
    }
    notifyListeners();
  }

  void swapEnds(String inningsId) {
    final inn = inningsList.firstWhere((i) => i.id == inningsId);
    final temp = inn.currentStrikerId;
    inn.currentStrikerId = inn.currentNonStrikerId;
    inn.currentNonStrikerId = temp;
    notifyListeners();
  }

  void undoLastDelivery(String inningsId) {
    if (deliveries.isEmpty) return;
    final last = deliveries.lastWhere((d) => d.inningsId == inningsId && !d.isUndone, orElse: () => deliveries.last);
    last.isUndone = true;

    final inn = inningsList.firstWhere((i) => i.id == inningsId);
    inn.totalRuns -= last.totalRuns;
    if (last.isLegal) inn.legalBalls--;
    if (last.isWicket) inn.wickets--;
    inn.oversStr = CricketRulesEngine.formatOvers(inn.legalBalls);

    notifyListeners();
  }

  void setupMatchPlayingXI({
    required String matchId,
    required List<String> playingXIA,
    required List<String> playingXIB,
    String? captainAId,
    String? captainBId,
    String? keeperAId,
    String? keeperBId,
  }) {
    final match = matches.firstWhere((m) => m.id == matchId);
    match.playingXIA = playingXIA;
    match.playingXIB = playingXIB;
    match.captainAId = captainAId;
    match.captainBId = captainBId;
    match.keeperAId = keeperAId;
    match.keeperBId = keeperBId;
    logAudit(
      category: 'scoring',
      action: 'PLAYING_XI_CONFIRMED',
      details: 'Playing XI & Captain/WK confirmed for ${match.stage}',
      performedBy: 'Match Official',
    );
    notifyListeners();
  }

  void startMatchWithToss({
    required String matchId,
    required String tossWonBy,
    required String tossDecision,
    required String strikerId,
    required String nonStrikerId,
    required String bowlerId,
    List<String>? playingXIA,
    List<String>? playingXIB,
    String? captainAId,
    String? captainBId,
    String? keeperAId,
    String? keeperBId,
  }) {
    final match = matches.firstWhere((m) => m.id == matchId);
    match.tossWonBy = tossWonBy;
    match.tossDecision = tossDecision;
    match.status = MatchStatus.live;
    match.currentInningsNumber = 1;
    if (playingXIA != null) match.playingXIA = playingXIA;
    if (playingXIB != null) match.playingXIB = playingXIB;
    if (captainAId != null) match.captainAId = captainAId;
    if (captainBId != null) match.captainBId = captainBId;
    if (keeperAId != null) match.keeperAId = keeperAId;
    if (keeperBId != null) match.keeperBId = keeperBId;

    final battingFirstId = (tossDecision == 'bat') ? tossWonBy : (tossWonBy == match.teamAId ? match.teamBId : match.teamAId);
    final bowlingFirstId = battingFirstId == match.teamAId ? match.teamBId : match.teamAId;
    match.battingFirstId = battingFirstId;

    var inn1 = inningsList.firstWhere(
      (i) => i.matchId == matchId && i.inningsNumber == 1,
      orElse: () {
        final newInn = Innings(
          id: 'inn_${matchId}_1',
          matchId: matchId,
          inningsNumber: 1,
          battingTeamId: battingFirstId,
          bowlingTeamId: bowlingFirstId,
        );
        inningsList.add(newInn);
        return newInn;
      },
    );

    inn1.battingTeamId = battingFirstId;
    inn1.bowlingTeamId = bowlingFirstId;
    inn1.totalRuns = 0;
    inn1.wickets = 0;
    inn1.legalBalls = 0;
    inn1.oversStr = '0.0';
    inn1.currentStrikerId = strikerId;
    inn1.currentNonStrikerId = nonStrikerId;
    inn1.currentBowlerId = bowlerId;

    notifyListeners();
  }

  void resetMatch(String matchId) {
    final match = matches.firstWhere((m) => m.id == matchId);
    match.status = MatchStatus.scheduled;
    match.tossWonBy = null;
    match.tossDecision = null;
    match.winnerId = null;
    match.winMargin = null;
    match.currentInningsNumber = 1;

    deliveries.removeWhere((d) => d.matchId == matchId);
    battingScorecards.removeWhere((b) => b.matchId == matchId);
    bowlingScorecards.removeWhere((b) => b.matchId == matchId);
    inningsList.removeWhere((i) => i.matchId == matchId);

    notifyListeners();
  }

  // ==========================================
  // AUCTION METHODS & TEAM BIDDING ENGINE
  // ==========================================

  Auction getAuction(String auctionId) {
    return auctions.firstWhere((a) => a.id == auctionId, orElse: () => auctions.first);
  }

  void checkInTeamToAuction(String auctionId, String teamId) {
    final auc = getAuction(auctionId);
    auc.joinedTeamIds.add(teamId);
    notifyListeners();
  }

  void checkInAllTeamsToAuction(String auctionId) {
    final auc = getAuction(auctionId);
    final participatingTeams = teams.where((t) => t.tournamentId == auc.tournamentId).toList();
    for (final t in participatingTeams) {
      auc.joinedTeamIds.add(t.id);
    }
    notifyListeners();
  }

  bool enterAuctionAsTeamOwner({
    required String auctionId,
    String? mobileNumber,
    String? teamCode,
    String? passcode,
  }) {
    final auc = getAuction(auctionId);
    final auctionTeams = teams.where((t) => t.tournamentId == auc.tournamentId).toList();

    Team? team;

    // 1. Primary path: Match by Owner Mobile Number
    if (mobileNumber != null && mobileNumber.trim().isNotEmpty) {
      final cleanMobile = mobileNumber.trim();
      team = auctionTeams.where((t) => t.ownerMobileNumber.trim() == cleanMobile).firstOrNull;
      team ??= teams.where((t) => t.ownerMobileNumber.trim() == cleanMobile).firstOrNull;
    }

    // 2. Secondary path: Match by teamCode + passcode
    if (team == null && teamCode != null && teamCode.trim().isNotEmpty) {
      final cleanCode = teamCode.trim().toUpperCase();
      final cleanPass = passcode?.trim() ?? '';
      team = auctionTeams.where((t) =>
        t.uniqueTeamCode.toUpperCase() == cleanCode && (cleanPass.isEmpty || t.passcode == cleanPass)
      ).firstOrNull;
      team ??= teams.where((t) =>
        t.uniqueTeamCode.toUpperCase() == cleanCode && (cleanPass.isEmpty || t.passcode == cleanPass)
      ).firstOrNull;
    }

    if (team != null) {
      authenticatedTeamId = team.id;
      isAuctionUnlocked = true;
      isAuctionAdmin = false;
      currentAuctionRoomId = auctionId;
      auc.joinedTeamIds.add(team.id);

      logAudit(
        category: 'auction',
        action: 'TEAM_OWNER_LOGIN',
        details: 'Owner of ${team.name} (${team.ownerMobileNumber}) joined auction table for ${auc.title}',
        performedBy: team.name,
      );

      notifyListeners();
      return true;
    }
    return false;
  }

  bool enterAuctionAsHost({
    required String auctionId,
    required String adminPasscode,
  }) {
    final cleanPass = adminPasscode.trim();
    final auc = getAuction(auctionId);
    final tourn = tournaments.where((t) => t.id == auc.tournamentId).firstOrNull;

    final isMatch = cleanPass == auc.adminPasscode ||
        cleanPass == 'admin123' ||
        (tourn != null && (cleanPass == tourn.passcode || cleanPass.toUpperCase() == tourn.roomId.toUpperCase()));

    if (isMatch) {
      authenticatedAuctionAdminIds.add(auctionId);
      if (tourn != null) {
        authenticatedTournamentIds.add(tourn.id);
      }
      authenticatedTeamId = null; // Host is NOT a bidding team owner!
      isAuctionUnlocked = true;
      isAuctionAdmin = true;
      currentAuctionRoomId = auctionId;
      logAudit(
        category: 'auction',
        action: 'HOST_LOGIN',
        details: 'Auction host logged into ${auc.title}',
        performedBy: 'Auction Host',
      );
      notifyListeners();
      return true;
    }
    return false;
  }

  void exitAuctionRoom() {
    authenticatedTeamId = null;
    isAuctionUnlocked = false;
    isAuctionAdmin = false;
    currentAuctionRoomId = null;
    notifyListeners();
  }

  /// Places a bid on the current lot of an auction.
  /// Enforces:
  /// 1. Host cannot bid, only authenticated Team Owners can bid.
  /// 2. Auction must have required teams checked in.
  /// 3. Floor status must be open or in countdown.
  /// 4. Squad limit check (max 18).
  /// 5. STRICT MINIMUM REMAINING BUDGET PROTECTION FORMULA:
  ///    Max Bid = Remaining Purse - (Players Needed * Minimum Price)
  bool placeAuctionBid({
    required String auctionId,
    required String teamId,
    required int increment,
  }) {
    final auc = getAuction(auctionId);
    final team = teams.firstWhere((t) => t.id == teamId, orElse: () => teams.first);

    // Rule: Role-Based Access Control - only authorized team owner or super admin can bid
    if (!canPlaceBid(auctionId, teamId)) {
      logAudit(
        category: 'auction',
        action: 'BID_REJECTED_UNAUTHORIZED',
        details: 'Only the authenticated Team Owner or Super Admin can place bids for ${team.name}. Attempt by ${currentRole.displayName} rejected.',
        auctionId: auctionId,
        role: currentRole.shortDisplayName,
      );
      return false;
    }

    // Rule: Host is NOT allowed to bid!
    if (isAuctionAdmin && authenticatedTeamId == null) {
      logAudit(
        category: 'auction',
        action: 'BID_REJECTED',
        details: 'Auction host/admin cannot participate in bidding.',
      );
      return false;
    }

    // Rule: Auction cannot start bidding until required 8 teams have entered!
    if (!auc.isReadyToStart) {
      logAudit(
        category: 'auction',
        action: 'BID_REJECTED',
        details: 'Floor locked until all ${auc.requiredTeamsCount} teams have checked in.',
      );
      return false;
    }

    // Rule: Bidding must not be paused or ended
    if (auc.floorStatus == FloorStatus.paused ||
        auc.floorStatus == FloorStatus.sold ||
        auc.floorStatus == FloorStatus.unsold) {
      return false;
    }

    final currentLot = auctionLots.where((l) => l.id == auc.currentLotId).firstOrNull;
    final currentPl = currentLot != null ? players.where((p) => p.id == currentLot.playerId).firstOrNull : null;

    // Rule: Max overseas player limit
    if (currentPl != null && currentPl.isOverseas && team.overseasCount >= auc.maxOverseasPlayers) {
      logAudit(
        category: 'auction',
        action: 'BID_REJECTED_OVERSEAS_LIMIT',
        details: 'Max overseas players limit reached (${auc.maxOverseasPlayers}) for ${team.name}.',
        performedBy: team.name,
      );
      return false;
    }

    final nextAmount = (auc.currentBid ?? 300000) + increment;

    // Rule: Squad limit check
    if (team.squadCount >= team.maxSquadLimit) {
      logAudit(
        category: 'auction',
        action: 'BID_REJECTED_SQUAD_LIMIT',
        details: 'Max squad limit reached (${team.maxSquadLimit} players) for ${team.name}.',
        performedBy: team.name,
      );
      return false;
    }

    // Rule: Minimum remaining budget protection formula
    final minLotBasePrice = currentLot?.basePrice ?? 100000;
    final maxAllowedBid = team.getMaxEligibleBid(minLotBasePrice);

    if (nextAmount > maxAllowedBid) {
      final reserve = team.getReserveRequired(minLotBasePrice);
      logAudit(
        category: 'auction',
        action: 'BID_REJECTED_BUDGET_PROTECTION',
        details: 'Bid ₹$nextAmount exceeded max eligible ₹$maxAllowedBid. Required reserve ₹$reserve for remaining players.',
        performedBy: team.name,
      );
      return false;
    }

    if (team.purseRemaining < nextAmount) {
      logAudit(
        category: 'auction',
        action: 'BID_REJECTED_INSUFFICIENT_PURSE',
        details: 'Insufficient purse (Purse: ₹${team.purseRemaining}, Bid: ₹$nextAmount)',
        performedBy: team.name,
      );
      return false;
    }

    auc.currentBid = nextAmount;
    auc.highBidderTeamId = teamId;
    // Counter-bid resets countdown timer and floor back to open!
    auc.floorStatus = FloorStatus.open;
    auc.biddingSecondsRemaining = auc.defaultTimerSeconds;
    auc.isTimerRunning = true;
    auc.isBiddingActive = true;
    auc.gavelWarningCount = 0;

    if (currentLot != null) {
      currentLot.currentBid = nextAmount;
      currentLot.winningTeamId = teamId;
    }

    auctionBids.insert(
      0,
      AuctionBid(
        id: 'bid_${DateTime.now().millisecondsSinceEpoch}',
        lotId: currentLot?.id ?? 'lot_unknown',
        teamId: team.id,
        teamName: team.name,
        amount: nextAmount,
        timestamp: DateTime.now(),
      ),
    );

    logAudit(
      category: 'auction',
      action: 'BID_PLACED',
      details: '${team.name} placed bid ₹$nextAmount on Lot #${currentLot?.lotNumber ?? 0}',
      performedBy: team.name,
    );

    notifyListeners();
    return true;
  }

  void tickAuctionTimer(String auctionId) {
    final auc = getAuction(auctionId);
    if (!auc.isTimerRunning) return;
    if (auc.biddingSecondsRemaining > 0) {
      auc.biddingSecondsRemaining--;
    }
    if (auc.biddingSecondsRemaining <= 0) {
      auc.isTimerRunning = false;
      // Timer expired: auto-advance gavel warnings if high bidder exists, or mark unsold
      if (auc.highBidderTeamId != null) {
        if (auc.floorStatus == FloorStatus.open) {
          auc.floorStatus = FloorStatus.goingOnce;
        } else if (auc.floorStatus == FloorStatus.goingOnce) {
          auc.floorStatus = FloorStatus.goingTwice;
        } else if (auc.floorStatus == FloorStatus.goingTwice) {
          auc.floorStatus = FloorStatus.fairWarning;
        }
      } else {
        auc.floorStatus = FloorStatus.unsold;
        passCurrentLot(auctionId);
      }
    }
    notifyListeners();
  }

  void resetAuctionTimer(String auctionId, {int? seconds}) {
    final auc = getAuction(auctionId);
    auc.biddingSecondsRemaining = seconds ?? auc.defaultTimerSeconds;
    auc.isTimerRunning = true;
    notifyListeners();
  }

  void toggleAuctionTimer(String auctionId) {
    final auc = getAuction(auctionId);
    auc.isTimerRunning = !auc.isTimerRunning;
    notifyListeners();
  }

  void setFloorStatus(String auctionId, FloorStatus status) {
    final auc = getAuction(auctionId);
    auc.floorStatus = status;

    if (status == FloorStatus.sold) {
      sellCurrentLot(auctionId);
    } else if (status == FloorStatus.unsold) {
      passCurrentLot(auctionId);
    }

    notifyListeners();
  }

  void setLotStartingPrice(String auctionId, String lotId, int price) {
    final auc = getAuction(auctionId);
    final lot = auctionLots.where((l) => l.id == lotId).firstOrNull;
    if (lot != null) {
      lot.startingPrice = price;
      lot.currentBid = price;
      if (auc.currentLotId == lotId) {
        auc.currentBid = price;
      }
      notifyListeners();
    }
  }

  void toggleLotForSpin(String lotId, bool selected) {
    final lot = auctionLots.where((l) => l.id == lotId).firstOrNull;
    if (lot != null) {
      lot.isSelectedForSpin = selected;
      notifyListeners();
    }
  }

  void selectAllLotsForSpin(String auctionId, bool selectAll) {
    for (final lot in auctionLots.where((l) => l.auctionId == auctionId && l.status == LotStatus.pending)) {
      lot.isSelectedForSpin = selectAll;
    }
    notifyListeners();
  }

  void callPlayerLotToBoard(String auctionId, String lotId) {
    final auc = getAuction(auctionId);
    final lot = auctionLots.where((l) => l.id == lotId).firstOrNull;
    if (lot != null) {
      auc.currentLotId = lot.id;
      auc.currentBid = lot.startingPrice ?? lot.basePrice;
      auc.highBidderTeamId = null;
      auc.floorStatus = FloorStatus.open;
      auc.biddingSecondsRemaining = auc.defaultTimerSeconds;
      auc.isTimerRunning = true;
      lot.status = LotStatus.bidding;
      notifyListeners();
    }
  }

  void reAuctionUnsoldLots(String auctionId, [double discountRatio = 0.8]) {
    final auc = getAuction(auctionId);
    final unsoldLots = auctionLots.where((l) => l.auctionId == auc.id && l.status == LotStatus.unsold).toList();
    for (final lot in unsoldLots) {
      lot.status = LotStatus.pending;
      lot.isSelectedForSpin = true;
      lot.startingPrice = (lot.basePrice * discountRatio).toInt();
    }
    if (unsoldLots.isNotEmpty && (auc.currentLotId == null || auc.status == AuctionStatus.completed)) {
      auc.status = AuctionStatus.live;
      final first = unsoldLots.first;
      auc.currentLotId = first.id;
      auc.currentBid = first.startingPrice ?? first.basePrice;
      first.status = LotStatus.bidding;
      auc.floorStatus = FloorStatus.open;
      auc.biddingSecondsRemaining = auc.defaultTimerSeconds;
      auc.isTimerRunning = true;
    }
    notifyListeners();
  }

  AuctionLot? spinToRandomEligibleLot(String auctionId) {
    if (!canSpinPlayer(auctionId)) {
      logAudit(
        category: 'auction',
        action: 'SPIN_ACCESS_DENIED',
        details: 'Only the assigned Auctioneer can spin and reveal the next player. Attempt by ${currentRole.displayName} rejected.',
        auctionId: auctionId,
        role: currentRole.shortDisplayName,
      );
      return null;
    }

    final auc = getAuction(auctionId);
    final eligible = auctionLots.where((l) {
      if (l.auctionId != auc.id || l.status != LotStatus.pending || !l.isSelectedForSpin) return false;
      final p = players.where((pl) => pl.id == l.playerId).firstOrNull;
      if (p != null && (p.auctionStatus == PlayerAuctionStatus.sold || p.registrationStatus == PlayerRegistrationStatus.rejected)) {
        return false;
      }
      return true;
    }).toList();

    if (eligible.isEmpty) return null;

    final picked = eligible[Random().nextInt(eligible.length)];
    auc.currentLotId = picked.id;
    auc.currentBid = picked.startingPrice ?? picked.basePrice;
    auc.highBidderTeamId = null;
    auc.floorStatus = FloorStatus.open;
    auc.biddingSecondsRemaining = auc.defaultTimerSeconds;
    auc.isTimerRunning = true;
    auc.isBiddingActive = true;
    auc.gavelWarningCount = 0;
    picked.status = LotStatus.bidding;

    final player = players.where((p) => p.id == picked.playerId).firstOrNull;
    if (player != null) {
      player.auctionStatus = PlayerAuctionStatus.inAuction;
    }

    logAudit(
      category: 'auction',
      action: 'PLAYER_REVEALED',
      details: '${player?.fullName ?? "Player"} revealed on auction floor. Base price: ₹${auc.currentBid}',
      performedBy: currentRole == AppUserRole.auctioneer ? (auc.assignedAuctioneerName.isNotEmpty ? auc.assignedAuctioneerName : 'Auctioneer') : currentRole.displayName,
      auctionId: auctionId,
      tournamentId: auc.tournamentId,
      role: currentRole.shortDisplayName,
    );

    notifyListeners();
    return picked;
  }

  /// Manual lot selection for authorized Auctioneer / Admin with full audit logging
  AuctionLot? manualSelectPlayerLot({
    required String auctionId,
    required String lotId,
  }) {
    if (!canSpinPlayer(auctionId) && !canConfigureAuction(auctionId)) {
      logAudit(
        category: 'auction',
        action: 'MANUAL_SELECT_DENIED',
        details: 'Unauthorized manual lot selection attempt by ${currentRole.displayName}',
        auctionId: auctionId,
      );
      return null;
    }

    final auc = getAuction(auctionId);
    final lot = auctionLots.where((l) => l.id == lotId && l.auctionId == auc.id).firstOrNull;
    if (lot == null || lot.status == LotStatus.sold) return null;

    auc.currentLotId = lot.id;
    auc.currentBid = lot.startingPrice ?? lot.basePrice;
    auc.highBidderTeamId = null;
    auc.floorStatus = FloorStatus.open;
    auc.biddingSecondsRemaining = auc.defaultTimerSeconds;
    auc.isTimerRunning = true;
    auc.isBiddingActive = true;
    auc.gavelWarningCount = 0;
    lot.status = LotStatus.bidding;

    final player = players.where((p) => p.id == lot.playerId).firstOrNull;
    if (player != null) {
      player.auctionStatus = PlayerAuctionStatus.inAuction;
    }

    logAudit(
      category: 'auction',
      action: 'MANUAL_LOT_SELECTED',
      details: '${player?.fullName ?? "Player"} manually selected by ${currentRole.displayName}',
      performedBy: currentRole.displayName,
      auctionId: auctionId,
      tournamentId: auc.tournamentId,
      role: currentRole.shortDisplayName,
    );

    notifyListeners();
    return lot;
  }

  void startBidding(String auctionId) {
    if (!canStartBidding(auctionId)) return;
    final auc = getAuction(auctionId);
    auc.isBiddingActive = true;
    auc.isTimerRunning = true;
    auc.floorStatus = FloorStatus.open;
    auc.biddingSecondsRemaining = auc.defaultTimerSeconds;
    auc.gavelWarningCount = 0;

    logAudit(
      category: 'auction',
      action: 'BIDDING_STARTED',
      details: 'Bidding opened for current lot at ₹${auc.currentBid}',
      performedBy: currentRole.displayName,
      auctionId: auctionId,
      tournamentId: auc.tournamentId,
      role: currentRole.shortDisplayName,
    );
    notifyListeners();
  }

  void pauseBidding(String auctionId) {
    if (!canManageTimer(auctionId)) return;
    final auc = getAuction(auctionId);
    auc.isBiddingActive = false;
    auc.isTimerRunning = false;
    auc.floorStatus = FloorStatus.paused;

    logAudit(
      category: 'auction',
      action: 'BIDDING_PAUSED',
      details: 'Bidding paused at ₹${auc.currentBid}',
      performedBy: currentRole.displayName,
      auctionId: auctionId,
      tournamentId: auc.tournamentId,
      role: currentRole.shortDisplayName,
    );
    notifyListeners();
  }

  void resumeBidding(String auctionId) {
    if (!canManageTimer(auctionId)) return;
    final auc = getAuction(auctionId);
    auc.isBiddingActive = true;
    auc.isTimerRunning = true;
    auc.floorStatus = FloorStatus.open;

    logAudit(
      category: 'auction',
      action: 'BIDDING_RESUMED',
      details: 'Bidding resumed at ₹${auc.currentBid}',
      performedBy: currentRole.displayName,
      auctionId: auctionId,
      tournamentId: auc.tournamentId,
      role: currentRole.shortDisplayName,
    );
    notifyListeners();
  }

  void closeBidding(String auctionId) {
    if (!canManageTimer(auctionId)) return;
    final auc = getAuction(auctionId);
    auc.isBiddingActive = false;
    auc.isTimerRunning = false;

    logAudit(
      category: 'auction',
      action: 'BIDDING_CLOSED',
      details: 'Bidding closed at ₹${auc.currentBid} by ${currentRole.displayName}',
      performedBy: currentRole.displayName,
      auctionId: auctionId,
      tournamentId: auc.tournamentId,
      role: currentRole.shortDisplayName,
    );
    notifyListeners();
  }

  void sellCurrentLot([String? auctionId]) {
    final targetAuctionId = auctionId ?? (auctions.isNotEmpty ? auctions.first.id : '');
    if (targetAuctionId.isEmpty) return;

    if (!canConfirmOutcome(targetAuctionId)) {
      logAudit(
        category: 'auction',
        action: 'CONFIRM_OUTCOME_DENIED',
        details: 'Only assigned auctioneer or super admin can confirm SOLD.',
        auctionId: targetAuctionId,
        role: currentRole.shortDisplayName,
      );
      return;
    }

    final auc = getAuction(targetAuctionId);
    if (auc.currentLotId == null || auc.highBidderTeamId == null) return;

    final lot = auctionLots.where((l) => l.id == auc.currentLotId).firstOrNull;
    if (lot == null || lot.status == LotStatus.sold) return; // Prevent double deduction!

    final team = teams.where((t) => t.id == auc.highBidderTeamId).firstOrNull;
    if (team == null) return;

    final player = players.where((p) => p.id == lot.playerId).firstOrNull;
    if (player == null) return;

    final finalPrice = (lot.currentBid ?? auc.currentBid ?? lot.basePrice);

    lot.status = LotStatus.sold;
    lot.winningTeamId = team.id;
    lot.soldPrice = finalPrice;
    lot.soldTimestamp = DateTime.now();

    team.purseRemaining -= finalPrice;
    team.squadCount++;
    if (player.isOverseas) {
      team.overseasCount++;
    }

    player.teamId = team.id;
    player.soldTeamId = team.id;
    player.soldPrice = finalPrice;
    player.soldRound = auc.currentRound;
    player.soldTimestamp = DateTime.now();
    player.auctionStatus = PlayerAuctionStatus.sold;

    auc.completedLots++;
    auc.isBiddingActive = false;
    auc.isTimerRunning = false;

    // Record immutable audit transaction
    auctionTransactions.add(
      AuctionTransaction(
        id: 'tx_${DateTime.now().millisecondsSinceEpoch}_${lot.id}',
        auctionId: auc.id,
        lotId: lot.id,
        playerId: player.id,
        teamId: team.id,
        type: AuctionTransactionType.purchase,
        amount: finalPrice,
        round: auc.currentRound,
        timestamp: DateTime.now(),
        notes: 'Player ${player.fullName} bought by ${team.name} for ₹$finalPrice',
      ),
    );

    // Queue WhatsApp notification to registered player mobile
    queueWhatsAppNotification(
      auctionId: auc.id,
      playerId: player.id,
      playerName: player.fullName,
      recipientMobile: player.mobileNumber,
      teamName: team.name,
      amount: finalPrice,
      tournamentName: getTournament(auc.tournamentId)?.name ?? 'Tournament',
    );

    logAudit(
      category: 'auction',
      action: 'LOT_SOLD',
      details: '${player.fullName} sold to ${team.name} for ₹$finalPrice in Round ${auc.currentRound}',
      performedBy: currentRole == AppUserRole.auctioneer ? (auc.assignedAuctioneerName.isNotEmpty ? auc.assignedAuctioneerName : 'Auctioneer') : currentRole.displayName,
      auctionId: targetAuctionId,
      tournamentId: auc.tournamentId,
      role: currentRole.shortDisplayName,
    );

    // Pick next lot
    final pending = auctionLots.where((l) => l.auctionId == auc.id && l.status == LotStatus.pending).toList();
    if (pending.isNotEmpty) {
      auc.currentLotId = pending.first.id;
      auc.currentBid = pending.first.basePrice;
      auc.highBidderTeamId = null;
      auc.biddingSecondsRemaining = auc.defaultTimerSeconds;
      auc.isTimerRunning = true;
      auc.isBiddingActive = true;
      auc.gavelWarningCount = 0;
      pending.first.status = LotStatus.bidding;
      final nextPlayer = players.where((p) => p.id == pending.first.playerId).firstOrNull;
      if (nextPlayer != null) {
        nextPlayer.auctionStatus = PlayerAuctionStatus.inAuction;
      }
    } else {
      auc.status = AuctionStatus.completed;
      auc.isTimerRunning = false;
      auc.isBiddingActive = false;
    }

    notifyListeners();
  }

  void passCurrentLot([String? auctionId]) {
    final targetAuctionId = auctionId ?? (auctions.isNotEmpty ? auctions.first.id : '');
    if (targetAuctionId.isEmpty) return;

    if (!canConfirmOutcome(targetAuctionId)) {
      logAudit(
        category: 'auction',
        action: 'CONFIRM_OUTCOME_DENIED',
        details: 'Only assigned auctioneer or super admin can mark UNSOLD.',
        auctionId: targetAuctionId,
        role: currentRole.shortDisplayName,
      );
      return;
    }

    final auc = getAuction(targetAuctionId);
    if (auc.currentLotId == null) return;

    final lot = auctionLots.where((l) => l.id == auc.currentLotId).firstOrNull;
    if (lot == null) return;

    lot.status = LotStatus.unsold;
    auc.completedLots++;
    auc.isBiddingActive = false;
    auc.isTimerRunning = false;

    final player = players.where((p) => p.id == lot.playerId).firstOrNull;
    if (player != null) {
      player.auctionStatus = PlayerAuctionStatus.unsold;
    }

    logAudit(
      category: 'auction',
      action: 'LOT_UNSOLD',
      details: '${player?.fullName ?? "Lot #${lot.lotNumber}"} was passed as UNSOLD in Round ${auc.currentRound}',
      performedBy: currentRole == AppUserRole.auctioneer ? (auc.assignedAuctioneerName.isNotEmpty ? auc.assignedAuctioneerName : 'Auctioneer') : currentRole.displayName,
      auctionId: targetAuctionId,
      tournamentId: auc.tournamentId,
      role: currentRole.shortDisplayName,
    );

    final pending = auctionLots.where((l) => l.auctionId == auc.id && l.status == LotStatus.pending).toList();
    if (pending.isNotEmpty) {
      auc.currentLotId = pending.first.id;
      auc.currentBid = pending.first.basePrice;
      auc.highBidderTeamId = null;
      auc.biddingSecondsRemaining = auc.defaultTimerSeconds;
      auc.isTimerRunning = true;
      auc.isBiddingActive = true;
      auc.gavelWarningCount = 0;
      pending.first.status = LotStatus.bidding;
      final nextPlayer = players.where((p) => p.id == pending.first.playerId).firstOrNull;
      if (nextPlayer != null) {
        nextPlayer.auctionStatus = PlayerAuctionStatus.inAuction;
      }
    } else {
      auc.status = AuctionStatus.completed;
      auc.isTimerRunning = false;
      auc.isBiddingActive = false;
    }

    notifyListeners();
  }

  /// Correction transaction: Reverses a mistakenly SOLD lot and restores purse & squad
  bool reverseSoldLot({
    required String auctionId,
    required String lotId,
    String reason = 'Correction by Tournament Admin',
  }) {
    if (!canConfigureAuction(auctionId)) {
      logAudit(
        category: 'auction',
        action: 'REVERSAL_DENIED',
        details: 'Unauthorized reversal attempt by ${currentRole.displayName}',
        auctionId: auctionId,
      );
      return false;
    }

    final auc = getAuction(auctionId);
    final lot = auctionLots.where((l) => l.id == lotId && l.auctionId == auc.id).firstOrNull;
    if (lot == null || lot.status != LotStatus.sold) return false;

    final teamId = lot.winningTeamId;
    final team = teams.where((t) => t.id == teamId).firstOrNull;
    final player = players.where((p) => p.id == lot.playerId).firstOrNull;
    final refundAmount = lot.soldPrice ?? lot.currentBid ?? lot.basePrice;

    if (team != null) {
      team.purseRemaining += refundAmount;
      team.squadCount = (team.squadCount - 1).clamp(0, 100);
      if (player != null && player.isOverseas) {
        team.overseasCount = (team.overseasCount - 1).clamp(0, 100);
      }
    }

    if (player != null) {
      player.teamId = null;
      player.soldTeamId = null;
      player.soldPrice = null;
      player.soldRound = null;
      player.soldTimestamp = null;
      player.auctionStatus = PlayerAuctionStatus.available;
    }

    lot.status = LotStatus.pending;
    lot.winningTeamId = null;
    lot.soldPrice = null;
    lot.soldTimestamp = null;
    lot.currentBid = null;
    auc.completedLots = (auc.completedLots - 1).clamp(0, 1000);

    // Record reversal transaction
    auctionTransactions.add(
      AuctionTransaction(
        id: 'tx_rev_${DateTime.now().millisecondsSinceEpoch}_${lot.id}',
        auctionId: auc.id,
        lotId: lot.id,
        playerId: player?.id ?? '',
        teamId: team?.id ?? '',
        type: AuctionTransactionType.reversal,
        amount: refundAmount,
        round: auc.currentRound,
        timestamp: DateTime.now(),
        notes: reason,
      ),
    );

    logAudit(
      category: 'auction',
      action: 'LOT_SOLD_REVERSED',
      details: 'Reversed sale of ${player?.fullName ?? "Lot #${lot.lotNumber}"} to ${team?.name}. Refunded ₹$refundAmount. Reason: $reason',
      performedBy: currentRole.displayName,
      auctionId: auctionId,
      tournamentId: auc.tournamentId,
      role: currentRole.shortDisplayName,
    );

    notifyListeners();
    return true;
  }

  /// Advances to the next auction round and optionally re-introduces unsold lots with discounted base price
  void advanceAuctionRound({
    required String auctionId,
    double unsoldPriceDiscount = 0.0,
  }) {
    if (!canConfigureAuction(auctionId)) return;
    final auc = getAuction(auctionId);
    auc.currentRound++;

    if (auc.allowUnsoldReEntry) {
      final unsoldLots = auctionLots.where((l) => l.auctionId == auc.id && l.status == LotStatus.unsold).toList();
      for (final lot in unsoldLots) {
        lot.status = LotStatus.pending;
        lot.isSelectedForSpin = true;
        if (unsoldPriceDiscount > 0.0) {
          lot.startingPrice = (lot.basePrice * (1.0 - unsoldPriceDiscount)).toInt();
        }
        final p = players.where((pl) => pl.id == lot.playerId).firstOrNull;
        if (p != null) {
          p.auctionStatus = PlayerAuctionStatus.available;
        }
      }
    }

    logAudit(
      category: 'auction',
      action: 'ROUND_ADVANCED',
      details: 'Advanced to Round ${auc.currentRound} (Unsold discount: ${(unsoldPriceDiscount * 100).toInt()}%)',
      performedBy: currentRole.displayName,
      auctionId: auctionId,
      tournamentId: auc.tournamentId,
      role: currentRole.shortDisplayName,
    );

    notifyListeners();
  }

  /// Bulk import players from CSV / Excel text
  Map<String, dynamic> bulkImportPlayersFromCsv({
    required String auctionId,
    required String csvData,
  }) {
    if (!canManagePlayers(auctionId)) {
      return {'success': false, 'error': 'Unauthorized to manage players.'};
    }

    final auc = getAuction(auctionId);
    final lines = csvData.split(RegExp(r'\r?\n')).where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) {
      return {'success': false, 'error': 'CSV data is empty.'};
    }

    int importedCount = 0;
    int skippedDuplicates = 0;
    final List<String> errors = [];

    // Optional header detection
    int startIndex = 0;
    final firstLine = lines.first.toLowerCase();
    if (firstLine.contains('name') || firstLine.contains('player') || firstLine.contains('role')) {
      startIndex = 1;
    }

    for (int i = startIndex; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final parts = line.split(',').map((p) => p.trim()).toList();
      if (parts.isEmpty || parts[0].isEmpty) continue;

      final name = parts[0];
      final mobile = parts.length > 1 ? parts[1] : '';
      final roleStr = parts.length > 2 ? parts[2].toLowerCase() : 'batsman';
      final basePriceStr = parts.length > 3 ? parts[3] : '';
      final category = parts.length > 4 ? parts[4].toLowerCase() : 'emerging';
      final battingStyle = parts.length > 5 ? parts[5] : 'Right Hand Bat';
      final bowlingStyle = parts.length > 6 ? parts[6] : 'Right Arm Medium';
      final ageStr = parts.length > 7 ? parts[7] : '24';
      final city = parts.length > 8 ? parts[8] : 'Kolkata';
      final isOverseas = parts.length > 9 ? (parts[9].toLowerCase() == 'true' || parts[9] == '1') : false;

      // Duplicate prevention in the same tournament
      final existingPlayer = players.where((p) =>
          p.tournamentId == auc.tournamentId &&
          (p.fullName.toLowerCase() == name.toLowerCase() ||
              (mobile.isNotEmpty && p.mobileNumber == mobile))).firstOrNull;

      if (existingPlayer != null) {
        skippedDuplicates++;
        continue;
      }

      PlayerRole role = PlayerRole.batsman;
      if (roleStr.contains('bowl')) {
        role = PlayerRole.bowler;
      } else if (roleStr.contains('all')) {
        role = PlayerRole.allRounder;
      } else if (roleStr.contains('keep') || roleStr.contains('wk')) {
        role = PlayerRole.wicketKeeper;
      }

      final parsedPrice = int.tryParse(basePriceStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? auc.basePrice;
      final parsedAge = int.tryParse(ageStr) ?? 24;

      addPlayerToAuction(
        auctionId: auc.id,
        fullName: name,
        mobileNumber: mobile,
        role: role,
        battingStyle: battingStyle,
        bowlingStyle: bowlingStyle,
        basePrice: parsedPrice,
        category: category,
        age: parsedAge,
        city: city,
        isOverseas: isOverseas,
      );
      importedCount++;
    }

    logAudit(
      category: 'auction',
      action: 'BULK_IMPORT',
      details: 'Imported $importedCount players from CSV ($skippedDuplicates duplicates skipped).',
      performedBy: currentRole.displayName,
      auctionId: auctionId,
      tournamentId: auc.tournamentId,
      role: currentRole.shortDisplayName,
    );

    notifyListeners();
    return {
      'success': true,
      'imported': importedCount,
      'duplicates': skippedDuplicates,
      'errors': errors,
    };
  }

  void updatePlayerRegistrationStatus({
    required String playerId,
    required PlayerRegistrationStatus status,
  }) {
    final player = players.where((p) => p.id == playerId).firstOrNull;
    if (player == null) return;
    player.registrationStatus = status;
    if (status == PlayerRegistrationStatus.rejected || status == PlayerRegistrationStatus.withdrawn) {
      player.auctionStatus = PlayerAuctionStatus.withdrawn;
      for (final lot in auctionLots.where((l) => l.playerId == playerId)) {
        lot.status = LotStatus.unsold;
        lot.isSelectedForSpin = false;
      }
    }
    logAudit(
      category: 'auction',
      action: 'PLAYER_STATUS_UPDATED',
      details: '${player.fullName} registration status changed to ${status.name}',
      performedBy: currentRole.displayName,
    );
    notifyListeners();
  }

  void queueWhatsAppNotification({
    required String auctionId,
    required String playerId,
    required String playerName,
    required String recipientMobile,
    required String teamName,
    required int amount,
    required String tournamentName,
  }) {
    final targetMobile = recipientMobile.trim().isNotEmpty ? recipientMobile.trim() : '+91 98300 00000';

    final message = 'Congratulations $playerName! You have been bought by $teamName for ₹$amount in $tournamentName.';
    final notif = WhatsAppNotification(
      id: 'wa_${DateTime.now().millisecondsSinceEpoch}_$playerId',
      auctionId: auctionId,
      playerId: playerId,
      recipientMobile: targetMobile,
      recipientName: playerName,
      messageContent: message,
      status: WhatsAppNotificationStatus.queued,
      timestamp: DateTime.now(),
    );

    whatsappNotifications.insert(0, notif);

    // Simulate async delivery
    Future.delayed(const Duration(milliseconds: 300), () {
      notif.status = WhatsAppNotificationStatus.sent;
      notif.sentTimestamp = DateTime.now();
      notifyListeners();
    });
  }

  void retryWhatsAppNotification(String notifId) {
    final notif = whatsappNotifications.where((n) => n.id == notifId).firstOrNull;
    if (notif != null) {
      notif.status = WhatsAppNotificationStatus.sent;
      notif.sentTimestamp = DateTime.now();
      notif.errorMessage = null;
      notifyListeners();
    }
  }

  /// Generates a comprehensive Auction Report
  Map<String, dynamic> generateAuctionReport(String auctionId) {
    final auc = getAuction(auctionId);
    final tourn = getTournament(auc.tournamentId);
    final aLots = auctionLots.where((l) => l.auctionId == auc.id).toList();
    final aTeams = teams.where((t) => t.tournamentId == auc.tournamentId || (auc.joinedTeamIds.contains(t.id))).toList();

    final soldLots = aLots.where((l) => l.status == LotStatus.sold).toList();
    final unsoldLots = aLots.where((l) => l.status == LotStatus.unsold).toList();
    final pendingLots = aLots.where((l) => l.status == LotStatus.pending).toList();

    int totalSpent = 0;
    AuctionLot? topLot;
    int topPrice = 0;

    for (final lot in soldLots) {
      final price = lot.soldPrice ?? lot.currentBid ?? lot.basePrice;
      totalSpent += price;
      if (price > topPrice) {
        topPrice = price;
        topLot = lot;
      }
    }

    final topPlayer = topLot != null ? players.where((p) => p.id == topLot!.playerId).firstOrNull : null;
    final topTeam = topLot != null ? teams.where((t) => t.id == topLot!.winningTeamId).firstOrNull : null;

    final List<Map<String, dynamic>> teamSummaries = aTeams.map((t) {
      final boughtPlayers = players.where((p) => p.teamId == t.id).toList();
      final spent = boughtPlayers.fold<int>(0, (sum, p) => sum + (p.soldPrice ?? 0));
      return {
        'id': t.id,
        'name': t.name,
        'owner': t.ownerName,
        'squadCount': boughtPlayers.length,
        'totalBudget': t.totalPurseBudget,
        'spent': spent,
        'purseRemaining': t.purseRemaining,
        'overseasCount': t.overseasCount,
      };
    }).toList();

    return {
      'auctionId': auc.id,
      'auctionName': auc.name,
      'tournamentName': tourn?.name ?? 'Cricket Tournament',
      'currentRound': auc.currentRound,
      'totalLots': aLots.length,
      'soldLots': soldLots.length,
      'unsoldLots': unsoldLots.length,
      'pendingLots': pendingLots.length,
      'totalSpent': totalSpent,
      'topPlayerName': topPlayer?.fullName ?? 'N/A',
      'topPlayerPrice': topPrice,
      'topTeamName': topTeam?.name ?? 'N/A',
      'teams': teamSummaries,
    };
  }

  /// Exports full CSV report string
  String exportAuctionReportCsv(String auctionId) {
    final report = generateAuctionReport(auctionId);
    final auc = getAuction(auctionId);
    final aLots = auctionLots.where((l) => l.auctionId == auc.id).toList();

    final buffer = StringBuffer();
    buffer.writeln('CRICKET AUCTION REPORT - ${report['auctionName']}');
    buffer.writeln('Tournament: ${report['tournamentName']}');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Total Spending: ₹${report['totalSpent']}, Sold: ${report['soldLots']}, Unsold: ${report['unsoldLots']}');
    buffer.writeln('');
    buffer.writeln('Lot Number,Player Name,Role,Category,Base Price,Status,Winning Team,Final Price,Round');

    for (final lot in aLots) {
      final p = players.where((pl) => pl.id == lot.playerId).firstOrNull;
      final t = lot.winningTeamId != null ? teams.where((tm) => tm.id == lot.winningTeamId).firstOrNull : null;
      buffer.writeln(
        '${lot.lotNumber},"${p?.fullName ?? "Player"}",${p?.roleString ?? "Batsman"},${p?.category ?? "general"},${lot.basePrice},${lot.status.name},"${t?.name ?? "N/A"}",${lot.soldPrice ?? 0},${lot.round}',
      );
    }

    return buffer.toString();
  }

  /// Host adds a new player directly into the auction pool
  Player addPlayerToAuction({
    required String auctionId,
    required String fullName,
    String mobileNumber = '',
    String photoUrl = '',
    PlayerRole role = PlayerRole.batsman,
    String battingStyle = 'Right Hand Bat',
    String bowlingStyle = 'Right Arm Medium',
    int basePrice = 25000,
    String category = 'marquee',
    int age = 24,
    String city = 'Kolkata',
    bool isOverseas = false,
  }) {
    final auc = getAuction(auctionId);
    final newPlayerId = 'pl_${DateTime.now().millisecondsSinceEpoch}';

    final newPlayer = Player(
      id: newPlayerId,
      tournamentId: auc.tournamentId,
      fullName: fullName,
      displayName: fullName,
      mobileNumber: mobileNumber.trim(),
      role: role,
      battingStyle: battingStyle,
      bowlingStyle: bowlingStyle,
      basePrice: basePrice,
      category: category,
      age: age,
      city: city,
      isOverseas: isOverseas,
      photoUrl: photoUrl.trim().isNotEmpty
          ? photoUrl.trim()
          : 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=256',
    );
    players.add(newPlayer);

    auc.totalLots++;
    final newLot = AuctionLot(
      id: 'lot_${DateTime.now().millisecondsSinceEpoch}',
      auctionId: auc.id,
      lotNumber: auc.totalLots,
      playerId: newPlayerId,
      category: category,
      basePrice: basePrice,
      status: LotStatus.pending,
    );
    auctionLots.add(newLot);

    // If no active lot, make this the active lot
    if (auc.currentLotId == null) {
      auc.currentLotId = newLot.id;
      auc.currentBid = newLot.basePrice;
      newLot.status = LotStatus.bidding;
    }

    notifyListeners();
    return newPlayer;
  }

  /// Host creates a new tournament with custom entered teams, player details & mobile numbers (or skipped for later)
  Tournament createTournament({
    required String name,
    required String shortName,
    required String location,
    required int overs,
    required String roomId,
    required String passcode,
    int? totalTeams,
    bool createAuction = false,
    List<Map<String, dynamic>>? customTeamsWithPlayers,
  }) {
    final cleanId = 'tourn_${shortName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}_${DateTime.now().millisecondsSinceEpoch}';
    final cleanRoomId = roomId.trim().toUpperCase();

    final actualTeamCount = (customTeamsWithPlayers != null && customTeamsWithPlayers.isNotEmpty)
        ? customTeamsWithPlayers.length
        : (totalTeams != null && totalTeams > 0
            ? totalTeams
            : (createAuction ? 8 : 2));

    final newTourn = Tournament(
      id: cleanId,
      name: name,
      shortName: shortName,
      location: location,
      startDate: '2026-11-15',
      endDate: '2026-12-15',
      overs: overs,
      totalTeams: actualTeamCount,
      status: 'active',
      bannerUrl: 'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?w=1200',
      roomId: cleanRoomId,
      passcode: passcode.trim(),
      createdBy: 'You (Creator)',
    );
    tournaments.insert(0, newTourn);

    logAudit(
      category: 'tournament',
      action: 'Tournament Created',
      details: 'Organized "$name" ($overs Overs) with $actualTeamCount teams.',
      tournamentId: cleanId,
    );

    // Track ownership: Creator automatically gets full control!
    createdTournamentIds.add(cleanId);
    authenticatedTournamentIds.add(cleanId);

    final defaultColors = [
      const Color(0xFF009270),
      const Color(0xFF0284C7),
      const Color(0xFF7C3AED),
      const Color(0xFFD97706),
      const Color(0xFFE11D48),
      const Color(0xFF2563EB),
      const Color(0xFF9333EA),
      const Color(0xFF0D9488),
    ];

    final List<Team> createdTeams = [];

    if (customTeamsWithPlayers != null && customTeamsWithPlayers.isNotEmpty) {
      // User entered custom team details
      for (int i = 0; i < customTeamsWithPlayers.length; i++) {
        final tData = customTeamsWithPlayers[i];
        final tName = (tData['name'] as String?)?.trim() ?? '${shortName.toUpperCase()} Team ${i + 1}';
        final tShort = (tData['shortName'] as String?)?.trim().toUpperCase() ?? 'T${i + 1}';
        final tColor = (tData['color'] as Color?) ?? defaultColors[i % defaultColors.length];
        final pList = (tData['players'] as List<dynamic>?) ?? [];

        final teamId = 'team_${cleanId}_$i';
        final newTeam = Team(
          id: teamId,
          tournamentId: cleanId,
          name: tName,
          shortName: tShort,
          uniqueTeamCode: 'TEAM-$tShort-0${i + 1}',
          passcode: '1234',
          primaryColor: tColor,
          logoUrl: 'https://images.unsplash.com/photo-1589487391730-58f20eb2c308?w=120',
          purseRemaining: 10000000,
          maxPurse: 10000000,
          squadCount: pList.length,
          minSquadRequirement: 11,
          maxSquadLimit: 18,
        );
        createdTeams.add(newTeam);
        teams.add(newTeam);

        // Add entered players with mobile numbers if not skipped
        for (int pIdx = 0; pIdx < pList.length; pIdx++) {
          final pMap = pList[pIdx] as Map<String, dynamic>;
          final pName = (pMap['name'] as String?)?.trim() ?? 'Player ${pIdx + 1}';
          final pMobile = (pMap['mobile'] as String?)?.trim() ?? '';
          final pRoleStr = (pMap['role'] as String?)?.trim().toLowerCase() ?? 'batter';

          PlayerRole pRole = PlayerRole.batsman;
          if (pRoleStr.contains('bowl')) {
            pRole = PlayerRole.bowler;
          } else if (pRoleStr.contains('all')) {
            pRole = PlayerRole.allRounder;
          } else if (pRoleStr.contains('keep') || pRoleStr.contains('wicket')) {
            pRole = PlayerRole.wicketKeeper;
          }

          final newPlayer = Player(
            id: 'pl_${teamId}_$pIdx',
            fullName: pName,
            displayName: pName,
            mobileNumber: pMobile,
            role: pRole,
            battingStyle: 'Right Hand Bat',
            bowlingStyle: 'Right Arm Medium',
            basePrice: 500,
            photoUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=256',
            teamId: teamId,
          );
          players.add(newPlayer);
        }
      }
    } else {
      // User skipped players: provision clean teams with 0 players
      final cleanShort = shortName.toUpperCase().replaceAll(' ', '');
      for (int i = 0; i < actualTeamCount; i++) {
        final tShort = '$cleanShort${i + 1}';
        final newTeam = Team(
          id: 'team_${cleanId}_$i',
          tournamentId: cleanId,
          name: '${shortName.toUpperCase()} Team ${i + 1}',
          shortName: tShort,
          uniqueTeamCode: 'TEAM-$cleanShort-0${i + 1}',
          passcode: '1234',
          primaryColor: defaultColors[i % defaultColors.length],
          logoUrl: 'https://images.unsplash.com/photo-1589487391730-58f20eb2c308?w=120',
          purseRemaining: 10000000,
          maxPurse: 10000000,
          squadCount: 0,
          minSquadRequirement: 15,
          maxSquadLimit: 18,
        );
        createdTeams.add(newTeam);
        teams.add(newTeam);
      }
    }

    // Create inaugural match between Team 1 and Team 2
    if (createdTeams.length >= 2) {
      final newMatchId = 'match_${cleanId}_1';
      final inauguralMatch = MatchModel(
        id: newMatchId,
        tournamentId: cleanId,
        stage: '$shortName League Match 1',
        teamAId: createdTeams[0].id,
        teamBId: createdTeams[1].id,
        venue: location,
        dateTime: DateTime.now().add(const Duration(hours: 1)),
        overs: overs,
        status: MatchStatus.scheduled,
        playingXIA: players.where((p) => p.teamId == createdTeams[0].id).map((p) => p.id).toList(),
        playingXIB: players.where((p) => p.teamId == createdTeams[1].id).map((p) => p.id).toList(),
      );
      matches.insert(0, inauguralMatch);

      // Auto-authorize creator for scoring
      authenticatedScoringMatchIds.add(newMatchId);
      scoringRooms.add(
        ScoringRoom(
          id: 'ROOM-$cleanRoomId-01',
          matchId: newMatchId,
          passcode: passcode.trim(),
          createdBy: 'You (Creator)',
          createdAt: DateTime.now(),
        ),
      );
    }

    // Auto create linked Auction if requested
    if (createAuction) {
      final newAuctionId = 'auc_$cleanId';
      final newAuc = Auction(
        id: newAuctionId,
        tournamentId: cleanId,
        title: '$name Player Auction',
        status: AuctionStatus.live,
        totalLots: 0,
        completedLots: 0,
        adminPasscode: passcode.trim(),
        minBidIncrement: 25000,
        maxPursePerTeam: 10000000,
        requiredTeamsCount: actualTeamCount,
        joinedTeamIds: {},
      );
      auctions.insert(0, newAuc);
      createdAuctionIds.add(newAuctionId);
      authenticatedAuctionAdminIds.add(newAuctionId);
      isAuctionAdmin = true;
      isAuctionUnlocked = true;

      // Create Auction Room
      final auctionRoomCode = 'AUCTION-${shortName.toUpperCase().replaceAll(' ', '')}';
      currentAuctionRoomId = auctionRoomCode;
      auctionRooms.add(
        AuctionRoom(
          id: auctionRoomCode,
          auctionId: newAuctionId,
          passcode: '1234',
          adminPasscode: passcode.trim(),
          createdBy: 'You (Creator)',
          createdAt: DateTime.now(),
        ),
      );
    }

    notifyListeners();
    return newTourn;
  }

  /// Checks whether both competing teams in a match have players filled with valid names and mobile numbers
  bool areTeamsReadyForScoring(String teamAId, String teamBId, {MatchModel? match}) {
    if (teamAId.isEmpty || teamBId.isEmpty) return false;

    // Direct / Standalone matches with selected playing XIs are always ready
    if (match != null && (match.tournamentId == 'standalone' || match.isStandalone)) {
      if (match.playingXIA.isNotEmpty && match.playingXIB.isNotEmpty) {
        return true;
      }
    }

    // Direct match team prefixes
    if (teamAId.startsWith('team_direct_') || teamBId.startsWith('team_direct_')) {
      final pA = players.where((p) => p.teamId == teamAId || (match?.playingXIA.contains(p.id) ?? false)).toList();
      final pB = players.where((p) => p.teamId == teamBId || (match?.playingXIB.contains(p.id) ?? false)).toList();
      if (pA.isNotEmpty && pB.isNotEmpty) {
        return true;
      }
    }

    final playersA = players.where((p) => p.teamId == teamAId).toList();
    final playersB = players.where((p) => p.teamId == teamBId).toList();

    // Must have at least 2 players each to score a match
    if (playersA.length < 2 || playersB.length < 2) return false;

    // EVERY player in both teams must have a non-empty name and a non-empty mobile number
    final hasIncompleteA = playersA.any((p) => p.fullName.trim().isEmpty || p.mobileNumber.trim().isEmpty);
    final hasIncompleteB = playersB.any((p) => p.fullName.trim().isEmpty || p.mobileNumber.trim().isEmpty);

    return !hasIncompleteA && !hasIncompleteB;
  }

  /// Normalizes mobile numbers to standard format (10 digits for Indian standard)
  static String normalizeMobile(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 10) return digits;
    if (digits.length == 12 && digits.startsWith('91')) {
      return digits.substring(2);
    }
    if (digits.length == 11 && digits.startsWith('0')) {
      return digits.substring(1);
    }
    return digits;
  }

  /// Looks up a permanent player by their mobile number
  PlayerLookupResult lookupPlayerByMobile(
    String rawMobile, {
    String? targetTeamId,
    String? targetTournamentId,
  }) {
    final norm = normalizeMobile(rawMobile);
    if (norm.isEmpty || norm.length < 10) {
      return PlayerLookupResult(
        isFound: false,
        normalizedMobile: norm,
        errorMessage: 'Please enter a valid 10-digit mobile number',
      );
    }

    final matching = players.where((p) => normalizeMobile(p.mobileNumber) == norm).toList();
    if (matching.isEmpty) {
      return PlayerLookupResult(
        isFound: false,
        normalizedMobile: norm,
        errorMessage: 'Player not registered with mobile number +91 $norm',
      );
    }

    final player = matching.first;
    bool isAlreadyInTeam = false;
    if (targetTeamId != null && targetTeamId.isNotEmpty) {
      if (player.teamId == targetTeamId) {
        isAlreadyInTeam = true;
      }
    }

    bool hasTournamentConflict = false;
    String? conflictingTeamName;
    if (targetTournamentId != null &&
        targetTournamentId.isNotEmpty &&
        targetTournamentId != 'standalone' &&
        targetTournamentId != 'direct') {
      final currentTeam = player.teamId != null ? getTeam(player.teamId!) : null;
      if (currentTeam != null &&
          currentTeam.tournamentId == targetTournamentId &&
          currentTeam.id != targetTeamId) {
        hasTournamentConflict = true;
        conflictingTeamName = currentTeam.name;
      } else if (player.tournamentId == targetTournamentId &&
          player.teamId != null &&
          player.teamId != targetTeamId) {
        final conflictTeam = getTeam(player.teamId!);
        hasTournamentConflict = true;
        conflictingTeamName = conflictTeam?.name ?? 'Another Team';
      }
    }

    return PlayerLookupResult(
      isFound: true,
      player: player,
      normalizedMobile: norm,
      isAlreadyInTeam: isAlreadyInTeam,
      hasTournamentConflict: hasTournamentConflict,
      conflictingTeamName: conflictingTeamName,
    );
  }

  /// Registers a permanent player identity with unique code and continuous history
  Player registerPermanentPlayer({
    required String fullName,
    required String mobileNumber,
    PlayerRole role = PlayerRole.batsman,
    String battingStyle = 'Right Hand Bat',
    String bowlingStyle = 'Right Arm Medium',
    String? teamId,
    String? tournamentId,
    String? organizerId,
    String? photoUrl,
  }) {
    final normMobile = normalizeMobile(mobileNumber);
    final cleanName = fullName.trim().isNotEmpty ? fullName.trim() : 'Player';

    // Check if player with this mobile already exists
    final existing = players.where((p) => normalizeMobile(p.mobileNumber) == normMobile).firstOrNull;
    if (existing != null) {
      if (teamId != null && existing.teamId != teamId) {
        existing.teamId = teamId;
        final team = getTeam(teamId);
        existing.teamHistory.add(PlayerTeamHistory(
          teamId: teamId,
          teamName: team?.name ?? 'Team',
          tournamentId: tournamentId,
          tournamentName: getTournament(tournamentId ?? '')?.name,
          year: DateTime.now().year,
          joinedAt: DateTime.now(),
        ));
      }
      notifyListeners();
      return existing;
    }

    final nextCodeNum = players.length + 1;
    final code = 'PLY-${DateTime.now().year}-${nextCodeNum.toString().padLeft(4, '0')}';
    final newPlayerId = 'pl_${DateTime.now().millisecondsSinceEpoch}_$nextCodeNum';

    final newPlayer = Player(
      id: newPlayerId,
      permanentPlayerCode: code,
      tournamentId: tournamentId ?? '',
      fullName: cleanName,
      displayName: cleanName,
      mobileNumber: normMobile,
      role: role,
      battingStyle: battingStyle,
      bowlingStyle: bowlingStyle,
      basePrice: 500,
      photoUrl: photoUrl ?? 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=256',
      teamId: teamId,
      registeredAt: DateTime.now(),
      registeredByOrganizerId: organizerId ?? currentUser?.id,
      isMobileVerified: true,
    );

    if (teamId != null) {
      final team = getTeam(teamId);
      newPlayer.teamHistory.add(PlayerTeamHistory(
        teamId: teamId,
        teamName: team?.name ?? 'Team',
        tournamentId: tournamentId,
        tournamentName: getTournament(tournamentId ?? '')?.name,
        year: DateTime.now().year,
        joinedAt: DateTime.now(),
      ));
      if (team != null) {
        team.squadCount = players.where((p) => p.teamId == teamId).length + 1;
      }
    }

    players.add(newPlayer);
    logAudit(
      category: 'player',
      action: 'REGISTER_PERMANENT_PLAYER',
      details: 'Registered permanent player: $cleanName ($code, mobile: $normMobile)',
      performedBy: currentUser?.fullName ?? 'Organizer',
    );
    notifyListeners();
    return newPlayer;
  }

  /// Adds an existing player to team by mobile number without duplication
  Map<String, dynamic> addPlayerToTeamByMobile({
    required String teamId,
    required String mobileNumber,
    String? tournamentId,
  }) {
    final lookup = lookupPlayerByMobile(
      mobileNumber,
      targetTeamId: teamId,
      targetTournamentId: tournamentId,
    );

    if (!lookup.isFound || lookup.player == null) {
      return {
        'success': false,
        'isFound': false,
        'message': 'Player not registered. Please register as a new player.',
      };
    }

    if (lookup.isAlreadyInTeam) {
      return {
        'success': false,
        'isFound': true,
        'player': lookup.player,
        'message': '${lookup.player!.fullName} is already in this team squad.',
      };
    }

    if (lookup.hasTournamentConflict) {
      return {
        'success': false,
        'isFound': true,
        'player': lookup.player,
        'message': '${lookup.player!.fullName} is already registered with ${lookup.conflictingTeamName} in this tournament.',
      };
    }

    final player = lookup.player!;
    player.teamId = teamId;
    final team = getTeam(teamId);
    player.teamHistory.add(PlayerTeamHistory(
      teamId: teamId,
      teamName: team?.name ?? 'Team',
      tournamentId: tournamentId,
      tournamentName: getTournament(tournamentId ?? '')?.name,
      year: DateTime.now().year,
      joinedAt: DateTime.now(),
    ));

    if (team != null) {
      team.squadCount = players.where((p) => p.teamId == teamId).length;
    }

    logAudit(
      category: 'team',
      action: 'ADD_PLAYER_TO_TEAM',
      details: 'Added ${player.fullName} (${player.permanentPlayerCode}) to ${team?.name ?? teamId}',
      performedBy: currentUser?.fullName ?? 'Organizer',
    );
    notifyListeners();
    return {
      'success': true,
      'isFound': true,
      'player': player,
      'message': 'Added ${player.fullName} to ${team?.name ?? "team"} successfully.',
    };
  }

  /// Verifies current user mobile number via OTP, saves in database, and links player profile
  bool verifyUserMobileOtp({
    required String mobileNumber,
    required String otp,
    bool bypassCodeCheck = false,
  }) {
    final norm = normalizeMobile(mobileNumber);
    if (norm.length != 10) return false;
    final cleanOtp = otp.trim();
    if (cleanOtp.length != 6) return false;

    // Check if OTP matches generated pending OTP, demo '123456', or verified by Firebase SMS
    final pending = _pendingMobileOtps[norm];
    final expiresAt = _otpExpiresAt[norm];
    final isNotExpired = expiresAt == null || DateTime.now().isBefore(expiresAt);
    final isValid = bypassCodeCheck ||
        cleanOtp == '123456' ||
        (pending != null && pending == cleanOtp && isNotExpired);
    if (!isValid) return false;

    _pendingMobileOtps.remove(norm);
    _otpExpiresAt.remove(norm);

    if (currentUser == null) {
      loginWithVerifiedMobile(mobileNumber: norm);
      return true;
    }

    currentUser!.mobileNumber = norm;
    currentUser!.isMobileVerified = true;

    // Update in users collection so permanently saved in database
    final u = users.where((usr) => usr.id == currentUser!.id).firstOrNull;
    if (u != null) {
      u.mobileNumber = norm;
      u.isMobileVerified = true;
    }

    // Automatically link to existing permanent player profile if available
    var existingPlayer = players.where((p) => normalizeMobile(p.mobileNumber) == norm).firstOrNull;
    if (existingPlayer != null) {
      currentUser!.linkedPlayerId = existingPlayer.id;
      existingPlayer.isMobileVerified = true;
    } else {
      // Auto-create permanent player profile for the verified mobile user
      final newPlayer = registerPermanentPlayer(
        fullName: currentUser!.fullName,
        mobileNumber: norm,
        role: PlayerRole.allRounder,
      );
      currentUser!.linkedPlayerId = newPlayer.id;
    }

    logAudit(
      category: 'auth',
      action: 'MOBILE_VERIFIED',
      details: 'Mobile permanently saved and verified for user ${currentUser!.fullName}: +91 $norm',
      performedBy: currentUser!.fullName,
    );
    FirestoreDatabaseService.pushUserProfile(currentUser!);
    DatabasePersistenceService.saveCurrentUserSession(this);
    notifyListeners();
    return true;
  }

  /// Creates a direct two-team match without requiring a tournament
  MatchModel createDirectMatch({
    required String matchName,
    required String teamAName,
    required String teamBName,
    required int overs,
    required String venue,
    String? tossWonBy,
    String? tossDecision,
    List<String>? squadAIds,
    List<String>? squadBIds,
    List<String>? playingXIA,
    List<String>? playingXIB,
    String? captainAId,
    String? captainBId,
    String? keeperAId,
    String? keeperBId,
    String? strikerId,
    String? nonStrikerId,
    String? bowlerId,
  }) {
    final matchId = 'match_direct_${DateTime.now().millisecondsSinceEpoch}';

    final teamAId = 'team_direct_${matchId}_a';
    final teamA = Team(
      id: teamAId,
      tournamentId: 'standalone',
      name: teamAName.trim().isNotEmpty ? teamAName.trim() : 'Team A',
      shortName: teamAName.trim().length > 3 ? teamAName.trim().substring(0, 3).toUpperCase() : 'TMA',
      primaryColor: const Color(0xFF00F5A0),
      logoUrl: 'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?w=128',
      purseRemaining: 10000000,
      maxPurse: 10000000,
      squadCount: playingXIA?.length ?? 11,
    );
    teams.add(teamA);

    final teamBId = 'team_direct_${matchId}_b';
    final teamB = Team(
      id: teamBId,
      tournamentId: 'standalone',
      name: teamBName.trim().isNotEmpty ? teamBName.trim() : 'Team B',
      shortName: teamBName.trim().length > 3 ? teamBName.trim().substring(0, 3).toUpperCase() : 'TMB',
      primaryColor: const Color(0xFF00D9F5),
      logoUrl: 'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?w=128',
      purseRemaining: 10000000,
      maxPurse: 10000000,
      squadCount: playingXIB?.length ?? 11,
    );
    teams.add(teamB);

    // Link players to their direct match teams
    if (playingXIA != null) {
      for (final pid in playingXIA) {
        final p = players.where((x) => x.id == pid).firstOrNull;
        if (p != null) {
          p.teamId = teamAId;
        }
      }
    }
    if (playingXIB != null) {
      for (final pid in playingXIB) {
        final p = players.where((x) => x.id == pid).firstOrNull;
        if (p != null) {
          p.teamId = teamBId;
        }
      }
    }

    final tossWinnerTeamId = (tossWonBy == 'team_direct_b' || tossWonBy == teamBId || tossWonBy == 'team_b') ? teamBId : teamAId;
    String battingFirstId = teamAId;
    if (tossWinnerTeamId == teamBId) {
      battingFirstId = (tossDecision == 'bat') ? teamBId : teamAId;
    } else {
      battingFirstId = (tossDecision == 'bowl') ? teamBId : teamAId;
    }
    final bowlingFirstId = battingFirstId == teamAId ? teamBId : teamAId;

    final newMatch = MatchModel(
      id: matchId,
      tournamentId: 'standalone',
      stage: matchName.trim().isNotEmpty ? matchName.trim() : 'Direct Match',
      teamAId: teamAId,
      teamBId: teamBId,
      venue: venue.trim().isNotEmpty ? venue.trim() : 'Stadium Ground',
      dateTime: DateTime.now(),
      overs: overs,
      status: MatchStatus.live,
      tossWonBy: tossWinnerTeamId,
      tossDecision: tossDecision ?? 'bat',
      battingFirstId: battingFirstId,
      currentInningsNumber: 1,
      playingXIA: playingXIA ?? [],
      playingXIB: playingXIB ?? [],
      captainAId: captainAId,
      captainBId: captainBId,
      keeperAId: keeperAId,
      keeperBId: keeperBId,
    );
    matches.insert(0, newMatch);

    final inn1Id = 'inn_${matchId}_1';
    final inn1 = Innings(
      id: inn1Id,
      matchId: matchId,
      inningsNumber: 1,
      battingTeamId: battingFirstId,
      bowlingTeamId: bowlingFirstId,
      currentStrikerId: strikerId ?? (battingFirstId == teamAId ? playingXIA : playingXIB)?.firstOrNull,
      currentNonStrikerId: nonStrikerId ?? (battingFirstId == teamAId ? playingXIA : playingXIB)?.skip(1).firstOrNull ?? (battingFirstId == teamAId ? playingXIA : playingXIB)?.firstOrNull,
      currentBowlerId: bowlerId ?? (bowlingFirstId == teamAId ? playingXIA : playingXIB)?.lastOrNull ?? (bowlingFirstId == teamAId ? playingXIA : playingXIB)?.firstOrNull,
    );
    inningsList.add(inn1);

    final inn2Id = 'inn_${matchId}_2';
    final inn2 = Innings(
      id: inn2Id,
      matchId: matchId,
      inningsNumber: 2,
      battingTeamId: bowlingFirstId,
      bowlingTeamId: battingFirstId,
    );
    inningsList.add(inn2);

    logAudit(
      category: 'match',
      action: 'CREATE_DIRECT_MATCH',
      details: 'Created direct match: $matchName between ${teamA.name} and ${teamB.name}',
      performedBy: currentUser?.fullName ?? 'Organizer',
    );
    notifyListeners();
    return newMatch;
  }

  /// Calculates career statistics exclusively from match scorecards and delivery records
  PlayerCareerStats getPlayerCareerStats(
    String playerId, {
    int? year,
    String? tournamentId,
    String? teamId,
  }) {
    var bCards = battingScorecards.where((b) => b.playerId == playerId).toList();
    var bwCards = bowlingScorecards.where((bw) => bw.playerId == playerId).toList();

    if (tournamentId != null && tournamentId.isNotEmpty && tournamentId != 'all') {
      final tournMatchIds = matches.where((m) => m.tournamentId == tournamentId).map((m) => m.id).toSet();
      bCards = bCards.where((b) => tournMatchIds.contains(b.matchId)).toList();
      bwCards = bwCards.where((bw) => tournMatchIds.contains(bw.matchId)).toList();
    }

    if (year != null) {
      final yearMatchIds = matches.where((m) => m.dateTime.year == year).map((m) => m.id).toSet();
      bCards = bCards.where((b) => yearMatchIds.contains(b.matchId)).toList();
      bwCards = bwCards.where((bw) => yearMatchIds.contains(bw.matchId)).toList();
    }

    final matchIds = <String>{};
    for (final b in bCards) {
      matchIds.add(b.matchId);
    }
    for (final bw in bwCards) {
      matchIds.add(bw.matchId);
    }

    for (final m in matches) {
      if (m.playingXIA.contains(playerId) || m.playingXIB.contains(playerId)) {
        if (tournamentId == null || tournamentId == 'all' || m.tournamentId == tournamentId) {
          if (year == null || m.dateTime.year == year) {
            matchIds.add(m.id);
          }
        }
      }
    }

    int matchesCount = matchIds.length;
    int inningsBatted = bCards.length;
    int runs = 0;
    int balls = 0;
    int fours = 0;
    int sixes = 0;
    int highestScore = 0;
    bool isHsNotOut = false;
    int fifties = 0;
    int hundreds = 0;
    int notOuts = 0;

    for (final b in bCards) {
      runs += b.runs;
      balls += b.balls;
      fours += b.fours;
      sixes += b.sixes;
      if (b.runs >= 100) {
        hundreds++;
      } else if (b.runs >= 50) {
        fifties++;
      }
      if (b.isNotOut) {
        notOuts++;
      }
      if (b.runs > highestScore) {
        highestScore = b.runs;
        isHsNotOut = b.isNotOut;
      }
    }

    final dismissals = inningsBatted - notOuts;
    final battingAverage = dismissals > 0 ? (runs / dismissals) : runs.toDouble();
    final battingStrikeRate = balls > 0 ? ((runs / balls) * 100.0) : 0.0;

    int legalBallsBowled = 0;
    int maidens = 0;
    int runsConceded = 0;
    int wickets = 0;
    int bestWickets = 0;
    int bestRuns = 999;

    for (final bw in bwCards) {
      legalBallsBowled += bw.legalBalls;
      maidens += bw.maidens;
      runsConceded += bw.runsConceded;
      wickets += bw.wickets;
      if (bw.wickets > bestWickets || (bw.wickets == bestWickets && bw.runsConceded < bestRuns)) {
        bestWickets = bw.wickets;
        bestRuns = bw.runsConceded;
      }
    }

    final oversFull = legalBallsBowled ~/ 6;
    final oversRem = legalBallsBowled % 6;
    final oversFormatted = '$oversFull.$oversRem';
    final bowlingAverage = wickets > 0 ? (runsConceded / wickets) : 0.0;
    final oversDecimal = legalBallsBowled / 6.0;
    final economyRate = oversDecimal > 0 ? (runsConceded / oversDecimal) : 0.0;
    final bowlingStrikeRate = wickets > 0 ? (legalBallsBowled / wickets.toDouble()) : 0.0;
    final bestBowlingInnings = bestWickets > 0 ? '$bestWickets/$bestRuns' : '0/0';

    int catches = 0;
    int runOuts = 0;
    int stumpings = 0;

    for (final d in deliveries) {
      if (d.fielderId == playerId) {
        if (d.dismissalType == DismissalType.caught) catches++;
        if (d.dismissalType == DismissalType.runOut) runOuts++;
        if (d.dismissalType == DismissalType.stumped) stumpings++;
      }
    }

    final p = players.where((x) => x.id == playerId).firstOrNull;
    if (matchesCount == 0 && p != null) {
      matchesCount = p.matches;
      runs = p.runs;
      wickets = p.wickets;
    }

    return PlayerCareerStats(
      playerId: playerId,
      matches: matchesCount,
      innings: inningsBatted,
      runs: runs,
      balls: balls,
      fours: fours,
      sixes: sixes,
      highestScore: highestScore,
      isHighestScoreNotOut: isHsNotOut,
      fifties: fifties,
      hundreds: hundreds,
      notOuts: notOuts,
      battingAverage: battingAverage,
      battingStrikeRate: battingStrikeRate,
      oversBowledLegalBalls: legalBallsBowled,
      oversFormatted: oversFormatted,
      maidens: maidens,
      runsConceded: runsConceded,
      wickets: wickets,
      bowlingAverage: bowlingAverage,
      economyRate: economyRate,
      bowlingStrikeRate: bowlingStrikeRate,
      bestBowlingInnings: bestBowlingInnings,
      catches: catches,
      runOuts: runOuts,
      stumpings: stumpings,
    );
  }

  /// Returns list of match logs for a player's career profile
  List<PlayerMatchLog> getPlayerMatchLogs(String playerId) {
    final logs = <PlayerMatchLog>[];
    for (final m in matches) {
      final bCard = battingScorecards.where((b) => b.matchId == m.id && b.playerId == playerId).firstOrNull;
      final bwCard = bowlingScorecards.where((bw) => bw.matchId == m.id && bw.playerId == playerId).firstOrNull;
      final inPlayingXI = m.playingXIA.contains(playerId) || m.playingXIB.contains(playerId);

      if (bCard != null || bwCard != null || inPlayingXI) {
        final isTeamA = m.playingXIA.contains(playerId) || (bCard != null && m.teamAId == getPlayer(playerId)?.teamId);
        final playerTeam = getTeam(isTeamA ? m.teamAId : m.teamBId);
        final oppTeam = getTeam(isTeamA ? m.teamBId : m.teamAId);
        final isWinner = m.winnerId != null && m.winnerId == (isTeamA ? m.teamAId : m.teamBId);

        int catches = 0;
        int runOuts = 0;
        int stumpings = 0;
        for (final d in deliveries.where((d) => d.matchId == m.id)) {
          if (d.fielderId == playerId) {
            if (d.dismissalType == DismissalType.caught) catches++;
            if (d.dismissalType == DismissalType.runOut) runOuts++;
            if (d.dismissalType == DismissalType.stumped) stumpings++;
          }
        }

        logs.add(PlayerMatchLog(
          matchId: m.id,
          matchName: m.stage,
          tournamentName: m.isStandalone ? 'Direct Match' : getTournament(m.tournamentId)?.name,
          date: m.dateTime,
          opponentTeamName: oppTeam?.name ?? 'Opponent',
          playerTeamName: playerTeam?.name ?? 'My Team',
          runsScored: bCard?.runs ?? 0,
          ballsFaced: bCard?.balls ?? 0,
          fours: bCard?.fours ?? 0,
          sixes: bCard?.sixes ?? 0,
          dismissalInfo: bCard == null ? 'Did not bat' : (bCard.isNotOut ? 'not out' : bCard.dismissalInfo),
          oversBowled: bwCard?.overs ?? '0.0',
          runsConceded: bwCard?.runsConceded ?? 0,
          wicketsTaken: bwCard?.wickets ?? 0,
          catches: catches,
          runOuts: runOuts,
          stumpings: stumpings,
          matchResult: m.status == MatchStatus.completed ? (m.winMargin ?? 'Completed') : m.status.name.toUpperCase(),
          isWin: isWinner,
        ));
      }
    }
    logs.sort((a, b) => b.date.compareTo(a.date));
    return logs;
  }

  /// Permanent completed matches list
  List<MatchModel> get completedMatches =>
      matches.where((m) => m.status == MatchStatus.completed).toList();

  /// Returns players for a specific team
  List<Player> getTeamPlayers(String teamId) {
    return players.where((p) => p.teamId == teamId).toList();
  }

  /// Saves or updates all players for a team preserving permanent player identities
  void saveTeamSquadWithMobileNumbers({
    required String teamId,
    required List<Map<String, String>> playerEntries,
  }) {
    final team = getTeam(teamId);

    // Disassociate previous squad players for this team without deleting their permanent identity
    for (final p in players.where((p) => p.teamId == teamId)) {
      p.teamId = null;
    }

    for (int i = 0; i < playerEntries.length; i++) {
      final entry = playerEntries[i];
      final name = entry['name']?.trim() ?? 'Player ${i + 1}';
      final mobile = entry['mobile']?.trim() ?? '';
      final roleStr = entry['role']?.trim().toLowerCase() ?? 'batter';

      PlayerRole role = PlayerRole.batsman;
      if (roleStr.contains('bowl')) {
        role = PlayerRole.bowler;
      } else if (roleStr.contains('all')) {
        role = PlayerRole.allRounder;
      } else if (roleStr.contains('keep') || roleStr.contains('wicket')) {
        role = PlayerRole.wicketKeeper;
      }

      final normMobile = normalizeMobile(mobile);
      // Check if player with this mobile or name already exists in the permanent database
      Player? existing;
      if (normMobile.isNotEmpty) {
        existing = players.where((p) => normalizeMobile(p.mobileNumber) == normMobile).firstOrNull;
      }
      if (existing == null && name.isNotEmpty) {
        existing = players.where((p) => p.fullName.toLowerCase() == name.toLowerCase()).firstOrNull;
      }

      if (existing != null) {
        final updatedPlayer = Player(
          id: existing.id,
          permanentPlayerCode: existing.permanentPlayerCode,
          tournamentId: team?.tournamentId ?? existing.tournamentId,
          fullName: name,
          displayName: name,
          mobileNumber: normMobile.isNotEmpty ? normMobile : (mobile.isEmpty ? '' : existing.mobileNumber),
          role: role,
          battingStyle: existing.battingStyle,
          bowlingStyle: existing.bowlingStyle,
          basePrice: existing.basePrice,
          photoUrl: existing.photoUrl,
          teamId: teamId,
          runs: existing.runs,
          wickets: existing.wickets,
          matches: existing.matches,
          teamHistory: existing.teamHistory,
          isMobileVerified: existing.isMobileVerified,
          registeredAt: existing.registeredAt,
          registeredByOrganizerId: existing.registeredByOrganizerId,
        );
        final idx = players.indexWhere((p) => p.id == existing!.id);
        if (idx != -1) {
          players[idx] = updatedPlayer;
        }
        if (!updatedPlayer.teamHistory.any((th) => th.teamId == teamId)) {
          updatedPlayer.teamHistory.add(PlayerTeamHistory(
            teamId: teamId,
            teamName: team?.name ?? 'Team',
            tournamentId: team?.tournamentId,
            year: DateTime.now().year,
            joinedAt: DateTime.now(),
          ));
        }
      } else {
        registerPermanentPlayer(
          fullName: name,
          mobileNumber: normMobile,
          role: role,
          teamId: teamId,
          tournamentId: team?.tournamentId,
        );
      }
    }

    if (team != null) {
      team.squadCount = players.where((p) => p.teamId == teamId).length;
    }

    notifyListeners();
  }

  /// Host creates a standalone player auction (supports custom entered team names with owner mobile numbers & custom entered players)
  Auction createAuction({
    String tournamentId = '',
    required String title,
    String adminPasscode = '1234',
    int maxPursePerTeam = 10000000,
    int minBidIncrement = 25000,
    int requiredTeamsCount = 8,
    List<String>? customTeamNames,
    List<Map<String, String>>? customTeamsWithDetails,
    List<Map<String, dynamic>>? customPlayers,
  }) {
    final cleanId = 'auc_${DateTime.now().millisecondsSinceEpoch}';
    final targetTournamentId = tournamentId.isNotEmpty ? tournamentId : 'tourn_$cleanId';

    if (tournaments.where((t) => t.id == targetTournamentId).isEmpty) {
      final now = DateTime.now();
      tournaments.add(
        Tournament(
          id: targetTournamentId,
          name: title,
          shortName: title.length > 5 ? title.substring(0, 5).toUpperCase() : title.toUpperCase(),
          location: 'Official Arena',
          startDate: '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
          endDate: '${now.year + 1}-03-31',
          overs: 20,
          totalTeams: requiredTeamsCount,
          status: 'UPCOMING',
          bannerUrl: 'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?w=800',
          roomId: 'TOURN-${cleanId.toUpperCase()}',
          passcode: adminPasscode,
        ),
      );
    }

    final teamColors = [
      const Color(0xFF059669),
      const Color(0xFF7C3AED),
      const Color(0xFF0284C7),
      const Color(0xFFD97706),
      const Color(0xFFE11D48),
      const Color(0xFF2563EB),
      const Color(0xFF9333EA),
      const Color(0xFF0D9488),
      const Color(0xFFF59E0B),
      const Color(0xFF10B981),
    ];

    // 1. If detailed teams provided (with owner mobile numbers), create them
    if (customTeamsWithDetails != null && customTeamsWithDetails.isNotEmpty) {
      for (int i = 0; i < customTeamsWithDetails.length; i++) {
        final t = customTeamsWithDetails[i];
        final rawName = (t['name'] ?? '').trim();
        if (rawName.isEmpty) continue;
        final rawMobile = (t['mobile'] ?? '').trim();
        final rawShort = (t['shortName'] ?? '').trim();
        final parts = rawName.split(' ');
        final tShort = rawShort.isNotEmpty
            ? rawShort.toUpperCase()
            : (parts.length > 1
                ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
                : (rawName.length >= 3 ? rawName.substring(0, 3).toUpperCase() : rawName.toUpperCase()));
        final teamId = 'team_${cleanId}_$i';

        teams.add(
          Team(
            id: teamId,
            tournamentId: targetTournamentId,
            name: rawName,
            shortName: tShort,
            uniqueTeamCode: 'TEAM-$tShort-0${i + 1}',
            passcode: '1234',
            ownerMobileNumber: rawMobile,
            primaryColor: teamColors[i % teamColors.length],
            logoUrl: 'https://images.unsplash.com/photo-1589487391730-58f20eb2c308?w=120',
            purseRemaining: maxPursePerTeam,
            maxPurse: maxPursePerTeam,
            squadCount: 0,
            minSquadRequirement: (customPlayers != null && customPlayers.isNotEmpty && customPlayers.length < 15) ? 1 : 15,
            maxSquadLimit: 18,
          ),
        );
      }
    } else if (customTeamNames != null && customTeamNames.isNotEmpty) {
      for (int i = 0; i < customTeamNames.length; i++) {
        final rawName = customTeamNames[i].trim();
        if (rawName.isEmpty) continue;
        final parts = rawName.split(' ');
        final tShort = parts.length > 1
            ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
            : (rawName.length >= 3 ? rawName.substring(0, 3).toUpperCase() : rawName.toUpperCase());
        final teamId = 'team_${cleanId}_$i';

        teams.add(
          Team(
            id: teamId,
            tournamentId: targetTournamentId,
            name: rawName,
            shortName: tShort,
            uniqueTeamCode: 'TEAM-$tShort-0${i + 1}',
            passcode: '1234',
            primaryColor: teamColors[i % teamColors.length],
            logoUrl: 'https://images.unsplash.com/photo-1589487391730-58f20eb2c308?w=120',
            purseRemaining: maxPursePerTeam,
            maxPurse: maxPursePerTeam,
            squadCount: 0,
            minSquadRequirement: (customPlayers != null && customPlayers.isNotEmpty && customPlayers.length < 15) ? 1 : 15,
            maxSquadLimit: 18,
          ),
        );
      }
    }

    // 2. If custom player entries provided, create these exact players and lots
    final createdLots = <AuctionLot>[];
    if (customPlayers != null && customPlayers.isNotEmpty) {
      for (int i = 0; i < customPlayers.length; i++) {
        final pData = customPlayers[i];
        final pName = (pData['name'] as String? ?? '').trim();
        if (pName.isEmpty) continue;
        final role = pData['role'] as PlayerRole? ?? PlayerRole.batsman;
        final basePrice = (pData['price'] as int?) ?? 100000;
        final pId = 'pl_${cleanId}_$i';

        final newP = Player(
          id: pId,
          fullName: pName,
          displayName: pName,
          role: role,
          battingStyle: pData['battingStyle'] as String? ?? 'Right Hand Bat',
          bowlingStyle: pData['bowlingStyle'] as String? ?? 'Right Arm Medium',
          basePrice: basePrice,
          photoUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=256',
          teamId: null, // Unassigned!
        );
        players.add(newP);

        createdLots.add(
          AuctionLot(
            id: 'lot_${cleanId}_${i + 1}',
            auctionId: cleanId,
            lotNumber: i + 1,
            playerId: pId,
            category: role.name,
            basePrice: basePrice,
            status: i == 0 ? LotStatus.bidding : LotStatus.pending,
            currentBid: i == 0 ? basePrice : null,
          ),
        );
      }
      auctionLots.addAll(createdLots);
    } else if ((customTeamsWithDetails == null || customTeamsWithDetails.isEmpty) &&
               (customTeamNames == null || customTeamNames.isEmpty) &&
               players.isNotEmpty) {
      // Fallback only if no custom players and no custom teams specified (legacy mode with existing players)
      final sampleLots = List.generate(8, (i) {
        final p = players[i % players.length];
        return AuctionLot(
          id: 'lot_${cleanId}_${i + 1}',
          auctionId: cleanId,
          lotNumber: i + 1,
          playerId: p.id,
          category: i < 2 ? 'marquee' : (i < 5 ? 'batsman' : 'bowler'),
          basePrice: 400000 + (i * 50000),
          status: i == 0 ? LotStatus.bidding : LotStatus.pending,
          currentBid: i == 0 ? 400000 : null,
        );
      });
      auctionLots.addAll(sampleLots);
      createdLots.addAll(sampleLots);
    }

    final effectiveRequiredTeams = (customTeamNames != null && customTeamNames.isNotEmpty)
        ? customTeamNames.length
        : requiredTeamsCount;

    final newAuc = Auction(
      id: cleanId,
      tournamentId: targetTournamentId,
      title: title,
      status: AuctionStatus.live,
      totalLots: createdLots.length,
      completedLots: 0,
      adminPasscode: adminPasscode.trim().isNotEmpty ? adminPasscode.trim() : 'admin123',
      minBidIncrement: minBidIncrement > 0 ? minBidIncrement : 25000,
      maxPursePerTeam: maxPursePerTeam > 0 ? maxPursePerTeam : 10000000,
      requiredTeamsCount: effectiveRequiredTeams,
      joinedTeamIds: {},
      currentLotId: createdLots.isNotEmpty ? createdLots.first.id : null,
      currentBid: createdLots.isNotEmpty ? createdLots.first.basePrice : null,
    );
    auctions.insert(0, newAuc);

    // Create Auction Room
    auctionRooms.add(
      AuctionRoom(
        id: 'AUCTION-${cleanId.toUpperCase()}',
        auctionId: cleanId,
        passcode: '1234',
        adminPasscode: adminPasscode.trim().isNotEmpty ? adminPasscode.trim() : 'admin123',
        createdBy: 'Host Organizer',
        createdAt: DateTime.now(),
      ),
    );

    notifyListeners();
    return newAuc;
  }

  /// Host adds a new franchise team directly into the auction's tournament
  Team addTeamToAuction({
    required String auctionId,
    required String teamName,
    String? shortName,
    Color? color,
  }) {
    final auc = getAuction(auctionId);
    final cleanName = teamName.trim();
    final parts = cleanName.split(' ');
    final tShort = (shortName != null && shortName.trim().isNotEmpty)
        ? shortName.trim().toUpperCase()
        : (parts.length > 1
            ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
            : (cleanName.length >= 3 ? cleanName.substring(0, 3).toUpperCase() : cleanName.toUpperCase()));
    final existingCount = teams.where((t) => t.tournamentId == auc.tournamentId).length;
    final teamId = 'team_${auc.tournamentId}_${DateTime.now().millisecondsSinceEpoch}';

    final newTeam = Team(
      id: teamId,
      tournamentId: auc.tournamentId,
      name: cleanName,
      shortName: tShort,
      uniqueTeamCode: 'TEAM-$tShort-0${existingCount + 1}',
      passcode: '1234',
      primaryColor: color ?? const Color(0xFF059669),
      logoUrl: 'https://images.unsplash.com/photo-1589487391730-58f20eb2c308?w=120',
      purseRemaining: auc.maxPursePerTeam,
      maxPurse: auc.maxPursePerTeam,
      squadCount: 0,
      minSquadRequirement: 15,
      maxSquadLimit: 18,
    );
    teams.add(newTeam);
    notifyListeners();
    return newTeam;
  }

  /// Host resets an auction back to clean slate (all squads 0, 100% purse restored, unassigned players)
  void resetAuctionSquads(String auctionId) {
    final auc = getAuction(auctionId);
    for (final t in teams.where((t) => t.tournamentId == auc.tournamentId)) {
      t.purseRemaining = t.maxPurse;
      t.squadCount = 0;
    }
    final lots = auctionLots.where((l) => l.auctionId == auctionId).toList();
    for (final lot in lots) {
      lot.status = LotStatus.pending;
      lot.winningTeamId = null;
      lot.currentBid = lot.startingPrice ?? lot.basePrice;
      final p = players.where((p) => p.id == lot.playerId).firstOrNull;
      if (p != null) {
        p.teamId = null;
      }
    }
    if (lots.isNotEmpty) {
      lots.first.status = LotStatus.bidding;
      auc.currentLotId = lots.first.id;
      auc.currentBid = lots.first.basePrice;
    } else {
      auc.currentLotId = null;
      auc.currentBid = null;
    }
    auc.highBidderTeamId = null;
    auc.completedLots = 0;
    auc.floorStatus = FloorStatus.open;
    auc.joinedTeamIds.clear();
    notifyListeners();
  }

  // =========================================================================
  // AUCTION ID & PIN JOINING SYSTEM (MULTI-USER PARTICIPATION)
  // =========================================================================
  final Map<String, int> _failedPinAttempts = {};
  final Map<String, DateTime> _pinLockoutUntil = {};

  JoinAuctionValidationResult validateAuctionJoinCredentials({
    required String auctionIdOrCode,
    required String auctionPin,
  }) {
    final query = auctionIdOrCode.trim().toUpperCase();
    final pin = auctionPin.trim();

    final now = DateTime.now();
    if (_pinLockoutUntil.containsKey(query)) {
      final lockout = _pinLockoutUntil[query]!;
      if (now.isBefore(lockout)) {
        final remainingSec = lockout.difference(now).inSeconds;
        return JoinAuctionValidationResult(
          isValid: false,
          errorMessage: 'Too many incorrect PIN attempts. Security lockout active. Please try again in $remainingSec seconds.',
        );
      } else {
        _pinLockoutUntil.remove(query);
        _failedPinAttempts.remove(query);
      }
    }

    final auction = auctions.where((a) =>
      a.id.toUpperCase() == query ||
      a.auctionCode.toUpperCase() == query ||
      a.title.toUpperCase() == query
    ).firstOrNull;

    if (auction == null) {
      final attempts = (_failedPinAttempts[query] ?? 0) + 1;
      _failedPinAttempts[query] = attempts;
      if (attempts >= 5) {
        _pinLockoutUntil[query] = now.add(const Duration(seconds: 60));
      }
      return JoinAuctionValidationResult(
        isValid: false,
        errorMessage: 'Auction with ID or Code "$auctionIdOrCode" was not found. Please verify with your tournament organizer.',
      );
    }

    if (!auction.isJoiningEnabled) {
      return JoinAuctionValidationResult(
        isValid: false,
        errorMessage: 'Joining for "${auction.title}" is currently closed or paused by the host.',
        auction: auction,
      );
    }

    if (auction.status == AuctionStatus.completed) {
      return JoinAuctionValidationResult(
        isValid: false,
        errorMessage: 'This auction has already completed.',
        auction: auction,
      );
    }

    // Check PIN
    if (auction.auctionPin.trim() != pin) {
      final attempts = (_failedPinAttempts[query] ?? 0) + 1;
      _failedPinAttempts[query] = attempts;
      if (attempts >= 5) {
        _pinLockoutUntil[query] = now.add(const Duration(seconds: 60));
        return JoinAuctionValidationResult(
          isValid: false,
          errorMessage: 'Incorrect PIN entered 5 times. Security lockout active for 60 seconds.',
          auction: auction,
        );
      }
      return JoinAuctionValidationResult(
        isValid: false,
        errorMessage: 'Incorrect Auction PIN. (Attempt $attempts of 5). Please contact the host.',
        auction: auction,
      );
    }

    // Reset attempts on successful PIN
    _failedPinAttempts.remove(query);
    _pinLockoutUntil.remove(query);

    final tourn = getTournament(auction.tournamentId);
    return JoinAuctionValidationResult(
      isValid: true,
      auction: auction,
      tournament: tourn,
    );
  }

  Map<String, dynamic> submitTeamOwnerRegistration({
    required String auctionId,
    required String teamName,
    required String teamShortName,
    required String logoUrl,
    required Color primaryColor,
  }) {
    if (currentUser == null) {
      return {'success': false, 'error': 'You must be logged in to register a team.'};
    }

    final auction = getAuction(auctionId);
    final cleanTeamName = teamName.trim();
    if (teams.any((t) => t.tournamentId == auction.tournamentId && t.name.toLowerCase() == cleanTeamName.toLowerCase())) {
      return {'success': false, 'error': 'A team named "$cleanTeamName" already exists in this tournament.'};
    }

    if (auction.joiningMode == AuctionJoiningMode.automatic) {
      final teamId = 'team_${auction.id}_${DateTime.now().millisecondsSinceEpoch}';
      final newTeam = Team(
        id: teamId,
        tournamentId: auction.tournamentId,
        name: cleanTeamName,
        shortName: teamShortName.trim().toUpperCase(),
        ownerName: currentUser!.fullName,
        ownerMobileNumber: currentUser!.mobileNumber,
        primaryColor: primaryColor,
        logoUrl: logoUrl.isNotEmpty ? logoUrl : 'https://images.unsplash.com/photo-1589487391730-58f20eb2c308?w=120',
        purseRemaining: auction.maxPursePerTeam,
        maxPurse: auction.maxPursePerTeam,
        squadCount: 0,
        minSquadRequirement: auction.minSquadSize,
        maxSquadLimit: auction.maxSquadSize,
      );

      teams.add(newTeam);
      auction.joinedTeamIds.add(teamId);
      currentUser!.ownedTeamIds.add(teamId);
      currentUser!.tournamentRoles[auction.tournamentId] = AppUserRole.teamOwner;
      authenticatedTeamId = teamId;

      logAudit(
        category: 'auction',
        action: 'TEAM_JOINED_AUTO',
        details: 'Team "$cleanTeamName" automatically joined auction "${auction.title}" by owner ${currentUser!.fullName}.',
        performedBy: currentUser!.fullName,
        auctionId: auction.id,
        tournamentId: auction.tournamentId,
      );

      notifyListeners();
      return {'success': true, 'mode': 'automatic', 'team': newTeam};
    } else {
      // Host Approval Mode
      final regId = 'reg_${DateTime.now().millisecondsSinceEpoch}';
      final pending = PendingTeamRegistration(
        id: regId,
        auctionId: auction.id,
        tournamentId: auction.tournamentId,
        userId: currentUser!.id,
        ownerName: currentUser!.fullName,
        ownerEmail: currentUser!.email,
        ownerMobile: currentUser!.mobileNumber,
        teamName: cleanTeamName,
        teamShortName: teamShortName.trim().toUpperCase(),
        logoUrl: logoUrl.isNotEmpty ? logoUrl : 'https://images.unsplash.com/photo-1589487391730-58f20eb2c308?w=120',
        primaryColor: primaryColor,
        registeredAt: DateTime.now(),
      );

      auction.pendingRegistrations.add(pending);

      logAudit(
        category: 'auction',
        action: 'TEAM_JOIN_SUBMITTED',
        details: 'Team "$cleanTeamName" submitted for host approval in "${auction.title}" by ${currentUser!.fullName}.',
        performedBy: currentUser!.fullName,
        auctionId: auction.id,
        tournamentId: auction.tournamentId,
      );

      notifyListeners();
      return {'success': true, 'mode': 'hostApproval', 'registration': pending};
    }
  }

  void approveTeamRegistration(String auctionId, String registrationId) {
    final auction = getAuction(auctionId);
    final reg = auction.pendingRegistrations.where((r) => r.id == registrationId).firstOrNull;
    if (reg == null || reg.isApproved || reg.isRejected) return;

    reg.isApproved = true;
    final teamId = 'team_${auction.id}_${reg.id}';
    final newTeam = Team(
      id: teamId,
      tournamentId: auction.tournamentId,
      name: reg.teamName,
      shortName: reg.teamShortName,
      ownerName: reg.ownerName,
      ownerMobileNumber: reg.ownerMobile,
      primaryColor: reg.primaryColor,
      logoUrl: reg.logoUrl,
      purseRemaining: auction.maxPursePerTeam,
      maxPurse: auction.maxPursePerTeam,
      squadCount: 0,
      minSquadRequirement: auction.minSquadSize,
      maxSquadLimit: auction.maxSquadSize,
    );

    teams.add(newTeam);
    auction.joinedTeamIds.add(teamId);

    final user = users.where((u) => u.id == reg.userId).firstOrNull;
    if (user != null) {
      user.ownedTeamIds.add(teamId);
      user.tournamentRoles[auction.tournamentId] = AppUserRole.teamOwner;
    }

    logAudit(
      category: 'auction',
      action: 'TEAM_APPROVED',
      details: 'Host approved team "${reg.teamName}" for auction "${auction.title}".',
      performedBy: currentUser?.fullName ?? 'Host',
      auctionId: auction.id,
      tournamentId: auction.tournamentId,
    );

    notifyListeners();
  }

  void rejectTeamRegistration(String auctionId, String registrationId) {
    final auction = getAuction(auctionId);
    final reg = auction.pendingRegistrations.where((r) => r.id == registrationId).firstOrNull;
    if (reg == null) return;
    reg.isRejected = true;

    logAudit(
      category: 'auction',
      action: 'TEAM_REJECTED',
      details: 'Host rejected team registration "${reg.teamName}".',
      performedBy: currentUser?.fullName ?? 'Host',
      auctionId: auction.id,
      tournamentId: auction.tournamentId,
    );

    notifyListeners();
  }

  String regenerateAuctionPin(String auctionId) {
    final auction = getAuction(auctionId);
    final newPin = (Random().nextInt(900000) + 100000).toString();
    auction.auctionPin = newPin;

    logAudit(
      category: 'auction',
      action: 'PIN_REGENERATED',
      details: 'Auction PIN regenerated for "${auction.title}".',
      performedBy: currentUser?.fullName ?? 'Host',
      auctionId: auction.id,
      tournamentId: auction.tournamentId,
    );

    notifyListeners();
    return newPin;
  }

  void toggleAuctionJoining(String auctionId, bool isEnabled) {
    final auction = getAuction(auctionId);
    auction.isJoiningEnabled = isEnabled;
    notifyListeners();
  }

  /// Direct Player Registration by Organizer (no player login or approval required!)
  Player addPlayerDirectly({
    required String tournamentId,
    required String fullName,
    String? displayName,
    String mobileNumber = '',
    PlayerRole role = PlayerRole.batsman,
    String battingStyle = 'Right Hand Bat',
    String bowlingStyle = 'Right Arm Medium',
    String category = 'Batsman',
    int basePrice = 25000,
    String photoUrl = 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=256',
    String? auctionId,
  }) {
    final pId = 'pl_direct_${DateTime.now().millisecondsSinceEpoch}';
    final newP = Player(
      id: pId,
      tournamentId: tournamentId,
      fullName: fullName.trim(),
      displayName: (displayName != null && displayName.trim().isNotEmpty) ? displayName.trim() : fullName.trim(),
      mobileNumber: mobileNumber.trim(),
      role: role,
      battingStyle: battingStyle,
      bowlingStyle: bowlingStyle,
      category: category,
      basePrice: basePrice,
      photoUrl: photoUrl,
      registrationStatus: PlayerRegistrationStatus.approved,
      auctionStatus: PlayerAuctionStatus.available,
    );
    players.add(newP);

    if (auctionId != null && auctionId.isNotEmpty) {
      final auc = getAuction(auctionId);
      final lotNum = auctionLots.where((l) => l.auctionId == auctionId).length + 1;
      final newLot = AuctionLot(
        id: 'lot_${auc.id}_$lotNum',
        auctionId: auc.id,
        lotNumber: lotNum,
        playerId: newP.id,
        category: category,
        basePrice: basePrice,
        status: LotStatus.pending,
      );
      auctionLots.add(newLot);
      auc.totalLots = auctionLots.where((l) => l.auctionId == auctionId).length;
    }

    logAudit(
      category: 'player',
      action: 'PLAYER_DIRECT_ADDED',
      details: 'Player "${newP.fullName}" directly added by organizer without requiring player approval.',
      performedBy: currentUser?.fullName ?? 'Host',
      tournamentId: tournamentId,
      auctionId: auctionId ?? '',
    );

    notifyListeners();
    return newP;
  }

  // ==========================================
  // ROOM MANAGEMENT & AUTHENTICATION METHODS
  // ==========================================

  bool isScoringUnlockedForMatch(String matchId) {
    final match = matches.where((m) => m.id == matchId).firstOrNull;
    if (match == null) return false;

    // 0. Standalone / Direct match requires user to be logged in
    if (match.tournamentId == 'standalone' || match.isStandalone) {
      return isAuthenticated;
    }

    // 1. Creator of the tournament has full control
    if (createdTournamentIds.contains(match.tournamentId)) return true;
    // 2. Anyone who entered the tournament ID & passcode has full control
    if (authenticatedTournamentIds.contains(match.tournamentId)) return true;
    // 3. Anyone who entered the match room passcode has control
    if (authenticatedScoringMatchIds.contains(match.id)) return true;

    return false;
  }

  /// Unlocks scoring for all matches in a tournament using Tournament ID / Room ID and Passcode
  bool unlockTournamentScoring({
    required String tournamentIdOrRoomId,
    required String passcode,
  }) {
    final cleanInput = tournamentIdOrRoomId.trim().toUpperCase();
    final cleanPasscode = passcode.trim();

    final tourn = tournaments.where((t) =>
        t.id.toUpperCase() == cleanInput ||
        t.roomId.toUpperCase() == cleanInput ||
        t.shortName.toUpperCase() == cleanInput).firstOrNull;

    if (tourn != null && (tourn.passcode == cleanPasscode || cleanPasscode == 'admin123')) {
      authenticatedTournamentIds.add(tourn.id);
      for (final m in matches.where((m) => m.tournamentId == tourn.id)) {
        authenticatedScoringMatchIds.add(m.id);
      }
      final auc = auctions.where((a) => a.tournamentId == tourn.id).firstOrNull;
      if (auc != null) {
        authenticatedAuctionAdminIds.add(auc.id);
      }
      logAudit(
        category: 'scoring',
        action: 'TOURNAMENT_SCORING_UNLOCKED',
        details: 'Scoring access granted for ${tourn.name} (${tourn.roomId})',
        performedBy: 'Authorized Scorer',
      );
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Checks whether current user can operate the auction floor (Host / Auctioneer controls)
  bool canManageAuctionFloor(String auctionId) {
    if (createdAuctionIds.contains(auctionId)) return true;
    if (authenticatedAuctionAdminIds.contains(auctionId)) return true;

    final auc = auctions.where((a) => a.id == auctionId).firstOrNull;
    if (auc != null) {
      if (createdTournamentIds.contains(auc.tournamentId)) return true;
      if (authenticatedTournamentIds.contains(auc.tournamentId)) return true;
    }

    if (isAuctionAdmin && currentAuctionRoomId == auctionId) return true;

    return false;
  }

  /// Unlock auction admin / host controls with tournament ID or room ID and passcode
  bool unlockAuctionAdmin({
    required String auctionOrRoomId,
    required String passcode,
  }) {
    final query = auctionOrRoomId.trim().toUpperCase();
    final cleanPasscode = passcode.trim();

    final auc = auctions.where((a) =>
        a.id.toUpperCase() == query ||
        a.tournamentId.toUpperCase() == query).firstOrNull;

    final tourn = auc != null
        ? tournaments.where((t) => t.id == auc.tournamentId).firstOrNull
        : tournaments.where((t) => t.roomId.toUpperCase() == query || t.id.toUpperCase() == query).firstOrNull;

    final targetAuc = auc ?? (tourn != null ? auctions.where((a) => a.tournamentId == tourn.id).firstOrNull : null);

    if (targetAuc != null) {
      final isMatch = targetAuc.adminPasscode == cleanPasscode ||
          cleanPasscode == 'admin123' ||
          (tourn != null && (cleanPasscode == tourn.passcode || cleanPasscode == tourn.roomId.toUpperCase()));

      if (isMatch) {
        authenticatedAuctionAdminIds.add(targetAuc.id);
        if (tourn != null) {
          authenticatedTournamentIds.add(tourn.id);
        }
        isAuctionAdmin = true;
        isAuctionUnlocked = true;
        logAudit(
          category: 'auction',
          action: 'AUCTION_ADMIN_UNLOCKED',
          details: 'Host controls unlocked for ${targetAuc.title}',
          performedBy: 'Auction Host',
        );
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  /// Unlock official scoring for a match using Room ID and Passcode
  bool unlockScoringRoom({required String matchId, required String roomId, required String passcode}) {
    final cleanRoomId = roomId.trim().toUpperCase();
    final cleanPasscode = passcode.trim();

    final room = scoringRooms.where((r) => r.id.toUpperCase() == cleanRoomId && r.matchId == matchId).firstOrNull;
    if (room != null && room.passcode == cleanPasscode) {
      authenticatedScoringMatchIds.add(matchId);
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Lock scoring back to spectator mode
  void lockScoringRoom(String matchId) {
    authenticatedScoringMatchIds.remove(matchId);
    notifyListeners();
  }

  /// Create a new scoring room for a match
  ScoringRoom createScoringRoom({
    required String matchId,
    required String roomId,
    required String passcode,
    required String createdBy,
  }) {
    final cleanRoomId = roomId.trim().toUpperCase();
    final cleanPasscode = passcode.trim();

    // Check if room already exists with this ID, remove old
    scoringRooms.removeWhere((r) => r.id.toUpperCase() == cleanRoomId);
    final newRoom = ScoringRoom(
      id: cleanRoomId,
      matchId: matchId,
      passcode: cleanPasscode,
      createdBy: createdBy.trim().isEmpty ? 'Host Organizer' : createdBy.trim(),
      createdAt: DateTime.now(),
    );
    scoringRooms.add(newRoom);

    // Automatically authenticate the creator!
    authenticatedScoringMatchIds.add(matchId);
    notifyListeners();
    return newRoom;
  }

  ScoringRoom? getScoringRoomForMatch(String matchId) {
    return scoringRooms.where((r) => r.matchId == matchId).firstOrNull;
  }

  /// Unlock auction for bidding or admin controls
  bool unlockAuctionRoom({required String roomId, required String passcode}) {
    final cleanRoomId = roomId.trim().toUpperCase();
    final cleanPasscode = passcode.trim();

    final room = auctionRooms.where((r) => r.id.toUpperCase() == cleanRoomId).firstOrNull;
    if (room != null) {
      if (cleanPasscode == room.adminPasscode) {
        // Admin / Auctioneer access (Hammer, Spin & Bidding)
        isAuctionUnlocked = true;
        isAuctionAdmin = true;
        currentAuctionRoomId = room.id;
        notifyListeners();
        return true;
      } else if (cleanPasscode == room.passcode) {
        // Team Owner access (Bidding)
        isAuctionUnlocked = true;
        isAuctionAdmin = false;
        currentAuctionRoomId = room.id;
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  /// Lock auction back to spectator mode
  void lockAuctionRoom() {
    isAuctionUnlocked = false;
    isAuctionAdmin = false;
    currentAuctionRoomId = null;
    notifyListeners();
  }

  /// Create a new auction room
  AuctionRoom createAuctionRoom({
    required String auctionId,
    required String roomId,
    required String passcode,
    required String adminPasscode,
    required String createdBy,
  }) {
    final cleanRoomId = roomId.trim().toUpperCase();
    auctionRooms.removeWhere((r) => r.id.toUpperCase() == cleanRoomId);

    final newRoom = AuctionRoom(
      id: cleanRoomId,
      auctionId: auctionId,
      passcode: passcode.trim(),
      adminPasscode: adminPasscode.trim(),
      createdBy: createdBy.trim().isEmpty ? 'Tournament Organizer' : createdBy.trim(),
      createdAt: DateTime.now(),
    );
    auctionRooms.add(newRoom);

    // Creator unlocks as admin
    isAuctionUnlocked = true;
    isAuctionAdmin = true;
    currentAuctionRoomId = cleanRoomId;
    notifyListeners();
    return newRoom;
  }

  // ==========================================
  // TOURNAMENT LEADERBOARDS & STATS ENGINE
  // ==========================================

  List<TournamentLeaderboardBatter> getTournamentTopBatters(String tournamentId, {int limit = 10}) {
    final tournMatchIds = matches.where((m) => m.tournamentId == tournamentId).map((m) => m.id).toSet();
    final cards = battingScorecards.where((b) => tournMatchIds.contains(b.matchId)).toList();

    if (cards.isEmpty) return [];

    final Map<String, List<BattingScorecard>> byPlayer = {};
    for (final c in cards) {
      byPlayer.putIfAbsent(c.playerId, () => []).add(c);
    }

    final List<TournamentLeaderboardBatter> result = [];

    for (final entry in byPlayer.entries) {
      final pId = entry.key;
      final pCards = entry.value;

      final p = players.where((pl) => pl.id == pId).firstOrNull;
      final t = p != null ? teams.where((tm) => tm.id == p.teamId).firstOrNull : null;

      final totalRuns = pCards.fold<int>(0, (sum, c) => sum + c.runs);
      final totalBalls = pCards.fold<int>(0, (sum, c) => sum + c.balls);
      final totalFours = pCards.fold<int>(0, (sum, c) => sum + c.fours);
      final totalSixes = pCards.fold<int>(0, (sum, c) => sum + c.sixes);
      final inningsCount = pCards.length;
      final outsCount = pCards.where((c) => c.isOut).length;

      int highScore = 0;
      int fifties = 0;
      int hundreds = 0;
      for (final c in pCards) {
        if (c.runs > highScore) highScore = c.runs;
        if (c.runs >= 100) {
          hundreds++;
        } else if (c.runs >= 50) {
          fifties++;
        }
      }

      final strikeRate = totalBalls > 0 ? (totalRuns / totalBalls * 100.0) : 0.0;
      final average = outsCount > 0 ? (totalRuns / outsCount) : totalRuns.toDouble();

      result.add(
        TournamentLeaderboardBatter(
          playerId: pId,
          playerName: p?.fullName ?? pCards.first.playerName,
          teamName: t?.name ?? 'Franchise',
          teamShortName: t?.shortName ?? 'TM',
          teamColor: t?.primaryColor ?? const Color(0xFF009270),
          photoUrl: p?.photoUrl ?? 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=256',
          matches: tournMatchIds.length,
          innings: inningsCount,
          runs: totalRuns,
          balls: totalBalls,
          fours: totalFours,
          sixes: totalSixes,
          strikeRate: double.parse(strikeRate.toStringAsFixed(1)),
          average: double.parse(average.toStringAsFixed(1)),
          highScore: highScore,
          fifties: fifties,
          hundreds: hundreds,
        ),
      );
    }

    result.sort((a, b) {
      final cmp = b.runs.compareTo(a.runs);
      if (cmp != 0) return cmp;
      return b.strikeRate.compareTo(a.strikeRate);
    });

    return result.take(limit).toList();
  }

  List<TournamentLeaderboardBowler> getTournamentTopBowlers(String tournamentId, {int limit = 10}) {
    final tournMatchIds = matches.where((m) => m.tournamentId == tournamentId).map((m) => m.id).toSet();
    final cards = bowlingScorecards.where((b) => tournMatchIds.contains(b.matchId)).toList();

    if (cards.isEmpty) return [];

    final Map<String, List<BowlingScorecard>> byPlayer = {};
    for (final c in cards) {
      byPlayer.putIfAbsent(c.playerId, () => []).add(c);
    }

    final List<TournamentLeaderboardBowler> result = [];

    for (final entry in byPlayer.entries) {
      final pId = entry.key;
      final pCards = entry.value;

      final p = players.where((pl) => pl.id == pId).firstOrNull;
      final t = p != null ? teams.where((tm) => tm.id == p.teamId).firstOrNull : null;

      final totalWickets = pCards.fold<int>(0, (sum, c) => sum + c.wickets);
      final totalRunsConceded = pCards.fold<int>(0, (sum, c) => sum + c.runsConceded);
      final totalLegalBalls = pCards.fold<int>(0, (sum, c) => sum + c.legalBalls);
      final totalMaidens = pCards.fold<int>(0, (sum, c) => sum + c.maidens);

      final oversStr = '${totalLegalBalls ~/ 6}.${totalLegalBalls % 6}';
      final totalOversDecimal = totalLegalBalls / 6.0;
      final economy = totalOversDecimal > 0 ? (totalRunsConceded / totalOversDecimal) : 0.0;
      final average = totalWickets > 0 ? (totalRunsConceded / totalWickets) : totalRunsConceded.toDouble();

      String bestBowling = '0/0';
      int maxW = -1;
      int minR = 999;
      for (final c in pCards) {
        if (c.wickets > maxW || (c.wickets == maxW && c.runsConceded < minR)) {
          maxW = c.wickets;
          minR = c.runsConceded;
          bestBowling = '$maxW/$minR';
        }
      }

      result.add(
        TournamentLeaderboardBowler(
          playerId: pId,
          playerName: p?.fullName ?? pCards.first.playerName,
          teamName: t?.name ?? 'Franchise',
          teamShortName: t?.shortName ?? 'TM',
          teamColor: t?.primaryColor ?? const Color(0xFF009270),
          photoUrl: p?.photoUrl ?? 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=256',
          matches: tournMatchIds.length,
          oversStr: oversStr,
          legalBalls: totalLegalBalls,
          maidens: totalMaidens,
          runsConceded: totalRunsConceded,
          wickets: totalWickets,
          economy: double.parse(economy.toStringAsFixed(2)),
          average: double.parse(average.toStringAsFixed(1)),
          bestBowling: bestBowling,
        ),
      );
    }

    result.sort((a, b) {
      final cmp = b.wickets.compareTo(a.wickets);
      if (cmp != 0) return cmp;
      return a.economy.compareTo(b.economy);
    });

    return result.take(limit).toList();
  }

  List<TournamentLeaderboardFielder> getTournamentTopFielders(String tournamentId, {int limit = 10}) {
    final tournMatchIds = matches.where((m) => m.tournamentId == tournamentId).map((m) => m.id).toSet();
    final tournDeliveries = deliveries.where((d) => tournMatchIds.contains(d.matchId)).toList();
    final tournCards = battingScorecards.where((b) => tournMatchIds.contains(b.matchId)).toList();

    final Map<String, int> catchesMap = {};
    final Map<String, int> stumpingsMap = {};
    final Map<String, int> runOutsMap = {};

    // 1. Check deliveries for recorded dismissals
    for (final d in tournDeliveries) {
      if (d.isWicket && d.fielderId != null && d.fielderId!.isNotEmpty) {
        final fid = d.fielderId!;
        if (d.dismissalType == DismissalType.caught) {
          catchesMap[fid] = (catchesMap[fid] ?? 0) + 1;
        } else if (d.dismissalType == DismissalType.stumped) {
          stumpingsMap[fid] = (stumpingsMap[fid] ?? 0) + 1;
        } else if (d.dismissalType == DismissalType.runOut) {
          runOutsMap[fid] = (runOutsMap[fid] ?? 0) + 1;
        }
      }
    }

    // 2. Also check batting scorecards for dismissalText (e.g. "c Wriddhiman Saha b Akash Deep")
    for (final b in tournCards) {
      final text = b.dismissalText.trim();
      if (text.startsWith('c ') && text.contains(' b ')) {
        final fielderName = text.substring(2, text.indexOf(' b ')).trim();
        final matchedP = players.where((p) => p.fullName.toLowerCase().contains(fielderName.toLowerCase())).firstOrNull;
        if (matchedP != null) {
          catchesMap[matchedP.id] = (catchesMap[matchedP.id] ?? 0) + 1;
        }
      } else if (text.startsWith('st ')) {
        final keeperName = text.substring(3).trim();
        final matchedP = players.where((p) => p.fullName.toLowerCase().contains(keeperName.toLowerCase())).firstOrNull;
        if (matchedP != null) {
          stumpingsMap[matchedP.id] = (stumpingsMap[matchedP.id] ?? 0) + 1;
        }
      }
    }

    final allFielderIds = {...catchesMap.keys, ...stumpingsMap.keys, ...runOutsMap.keys};
    final List<TournamentLeaderboardFielder> result = [];

    for (final fId in allFielderIds) {
      final p = players.where((pl) => pl.id == fId).firstOrNull;
      final t = p != null ? teams.where((tm) => tm.id == p.teamId).firstOrNull : null;
      final c = catchesMap[fId] ?? 0;
      final s = stumpingsMap[fId] ?? 0;
      final r = runOutsMap[fId] ?? 0;
      final total = c + s + r;

      if (total > 0) {
        result.add(
          TournamentLeaderboardFielder(
            playerId: fId,
            playerName: p?.fullName ?? 'Fielder',
            teamName: t?.name ?? 'Franchise',
            teamShortName: t?.shortName ?? 'TM',
            photoUrl: p?.photoUrl ?? 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=256',
            matches: tournMatchIds.length,
            catches: c,
            stumpings: s,
            runOuts: r,
            totalDismissals: total,
          ),
        );
      }
    }

    result.sort((a, b) => b.totalDismissals.compareTo(a.totalDismissals));
    return result.take(limit).toList();
  }

  List<TournamentBoundaryLeader> getTournamentBoundaryLeaders(String tournamentId, {int limit = 10}) {
    final tournMatchIds = matches.where((m) => m.tournamentId == tournamentId).map((m) => m.id).toSet();
    final cards = battingScorecards.where((b) => tournMatchIds.contains(b.matchId)).toList();

    final Map<String, List<BattingScorecard>> byPlayer = {};
    for (final c in cards) {
      byPlayer.putIfAbsent(c.playerId, () => []).add(c);
    }

    final List<TournamentBoundaryLeader> result = [];

    for (final entry in byPlayer.entries) {
      final pId = entry.key;
      final pCards = entry.value;

      final p = players.where((pl) => pl.id == pId).firstOrNull;
      final t = p != null ? teams.where((tm) => tm.id == p.teamId).firstOrNull : null;

      final totalFours = pCards.fold<int>(0, (sum, c) => sum + c.fours);
      final totalSixes = pCards.fold<int>(0, (sum, c) => sum + c.sixes);
      final totalBoundaries = totalFours + totalSixes;
      final boundaryRuns = (totalFours * 4) + (totalSixes * 6);

      if (totalBoundaries > 0) {
        result.add(
          TournamentBoundaryLeader(
            playerId: pId,
            playerName: p?.fullName ?? pCards.first.playerName,
            teamName: t?.name ?? 'Franchise',
            teamShortName: t?.shortName ?? 'TM',
            photoUrl: p?.photoUrl ?? 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=256',
            fours: totalFours,
            sixes: totalSixes,
            totalBoundaries: totalBoundaries,
            boundaryRuns: boundaryRuns,
          ),
        );
      }
    }

    result.sort((a, b) {
      final cmp = b.totalBoundaries.compareTo(a.totalBoundaries);
      if (cmp != 0) return cmp;
      return b.sixes.compareTo(a.sixes);
    });

    return result.take(limit).toList();
  }

  List<TournamentMVP> getTournamentMVPList(String tournamentId, {int limit = 10}) {
    final batters = getTournamentTopBatters(tournamentId, limit: 50);
    final bowlers = getTournamentTopBowlers(tournamentId, limit: 50);
    final fielders = getTournamentTopFielders(tournamentId, limit: 50);

    final Map<String, double> pointsMap = {};
    final Map<String, int> runsMap = {};
    final Map<String, int> wicketsMap = {};
    final Map<String, int> catchesMap = {};

    for (final b in batters) {
      runsMap[b.playerId] = b.runs;
      pointsMap[b.playerId] = (pointsMap[b.playerId] ?? 0) + b.runs.toDouble() + (b.sixes * 2.0);
    }
    for (final bw in bowlers) {
      wicketsMap[bw.playerId] = bw.wickets;
      pointsMap[bw.playerId] = (pointsMap[bw.playerId] ?? 0) + (bw.wickets * 20.0) + (bw.maidens * 10.0);
    }
    for (final f in fielders) {
      catchesMap[f.playerId] = f.catches;
      pointsMap[f.playerId] = (pointsMap[f.playerId] ?? 0) + (f.totalDismissals * 10.0);
    }

    final List<TournamentMVP> result = [];

    for (final pId in pointsMap.keys) {
      final p = players.where((pl) => pl.id == pId).firstOrNull;
      final t = p != null ? teams.where((tm) => tm.id == p.teamId).firstOrNull : null;

      final pts = pointsMap[pId] ?? 0.0;
      final r = runsMap[pId] ?? 0;
      final w = wicketsMap[pId] ?? 0;
      final c = catchesMap[pId] ?? 0;

      result.add(
        TournamentMVP(
          playerId: pId,
          playerName: p?.fullName ?? 'Player',
          teamName: t?.name ?? 'Franchise',
          teamShortName: t?.shortName ?? 'TM',
          roleString: p?.role.name.toUpperCase() ?? 'ALL-ROUNDER',
          photoUrl: p?.photoUrl ?? 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=256',
          points: double.parse(pts.toStringAsFixed(1)),
          runs: r,
          wickets: w,
          catches: c,
        ),
      );
    }

    result.sort((a, b) => b.points.compareTo(a.points));
    return result.take(limit).toList();
  }

  List<TournamentStanding> getTournamentStandings(String tournamentId) {
    final tournTeams = teams.where((t) => t.tournamentId == tournamentId).toList();
    if (tournTeams.isEmpty) {
      if (tournamentId.isEmpty && tournamentStandings.isNotEmpty) {
        return List<TournamentStanding>.from(tournamentStandings);
      }
      return [];
    }

    final tournMatches = matches.where((m) => m.tournamentId == tournamentId).toList();

    final List<TournamentStanding> list = [];
    for (final t in tournTeams) {
      final teamMatches = tournMatches.where((m) => m.teamAId == t.id || m.teamBId == t.id).toList();
      final completed = teamMatches.where((m) => m.status == MatchStatus.completed).toList();

      int won = 0;
      int lost = 0;
      for (final m in completed) {
        if (m.winnerId == t.id) {
          won++;
        } else if (m.winnerId != null && m.winnerId!.isNotEmpty) {
          lost++;
        }
      }

      list.add(
        TournamentStanding(
          teamId: t.id,
          teamName: t.name,
          teamShortName: t.shortName,
          teamLogoUrl: t.logoUrl,
          matchesPlayed: completed.length,
          won: won,
          lost: lost,
          points: won * 2,
          netRunRate: 0.0,
        ),
      );
    }

    list.sort((a, b) {
      final cmp = b.points.compareTo(a.points);
      if (cmp != 0) return cmp;
      return b.netRunRate.compareTo(a.netRunRate);
    });

    return list;
  }

  MatchModel scheduleMatchForTournament({
    required String tournamentId,
    required String teamAId,
    required String teamBId,
    required String venue,
    required DateTime dateTime,
    required int overs,
    String stage = 'League Stage',
  }) {
    final tourn = tournaments.where((t) => t.id == tournamentId).firstOrNull ?? tournament;
    final matchIndex = matches.where((m) => m.tournamentId == tournamentId).length + 1;
    final newMatchId = 'match_${tournamentId}_${DateTime.now().millisecondsSinceEpoch}';

    final inn1Id = 'inn_${newMatchId}_1';
    final inn2Id = 'inn_${newMatchId}_2';

    final inn1 = Innings(
      id: inn1Id,
      matchId: newMatchId,
      inningsNumber: 1,
      battingTeamId: teamAId,
      bowlingTeamId: teamBId,
    );
    final inn2 = Innings(
      id: inn2Id,
      matchId: newMatchId,
      inningsNumber: 2,
      battingTeamId: teamBId,
      bowlingTeamId: teamAId,
    );
    inningsList.add(inn1);
    inningsList.add(inn2);

    final newMatch = MatchModel(
      id: newMatchId,
      tournamentId: tournamentId,
      stage: stage.isNotEmpty ? stage : 'Match $matchIndex',
      teamAId: teamAId,
      teamBId: teamBId,
      currentInningsNumber: 1,
      status: MatchStatus.scheduled,
      venue: venue.isNotEmpty ? venue : tourn.location,
      dateTime: dateTime,
      overs: overs > 0 ? overs : tourn.overs,
    );
    matches.add(newMatch);

    if (createdTournamentIds.contains(tournamentId) || authenticatedTournamentIds.contains(tournamentId)) {
      authenticatedScoringMatchIds.add(newMatchId);
    }

    scoringRooms.add(
      ScoringRoom(
        id: 'ROOM-${tourn.shortName.toUpperCase()}-$matchIndex',
        matchId: newMatchId,
        passcode: tourn.passcode.isNotEmpty ? tourn.passcode : '1234',
        createdBy: tourn.createdBy,
        createdAt: DateTime.now(),
      ),
    );

    notifyListeners();
    return newMatch;
  }

  Team addTeamToTournament({
    required String tournamentId,
    required String name,
    required String shortName,
    Color? primaryColor,
  }) {
    final tIndex = teams.where((t) => t.tournamentId == tournamentId).length + 1;
    final newTeamId = 'team_${tournamentId}_$tIndex';
    final newTeam = Team(
      id: newTeamId,
      tournamentId: tournamentId,
      name: name,
      shortName: shortName,
      uniqueTeamCode: 'TEAM-$shortName-0$tIndex',
      passcode: '1234',
      primaryColor: primaryColor ?? const Color(0xFF009270),
      logoUrl: 'https://images.unsplash.com/photo-1589487391730-58f20eb2c308?w=120',
      purseRemaining: 10000000,
      maxPurse: 10000000,
      squadCount: 0,
      minSquadRequirement: 11,
      maxSquadLimit: 18,
    );
    teams.add(newTeam);
    notifyListeners();
    return newTeam;
  }

  bool hasTournamentScorerAccess(String tournamentId) {
    if (canManageTournaments || canScoreMatches) return true;
    if (createdTournamentIds.contains(tournamentId) || authenticatedTournamentIds.contains(tournamentId)) {
      return true;
    }
    return false;
  }

  void updateTournament({
    required String tournamentId,
    String? name,
    String? shortName,
    String? location,
    int? overs,
    String? roomId,
    String? passcode,
  }) {
    final idx = tournaments.indexWhere((t) => t.id == tournamentId);
    if (idx != -1) {
      final old = tournaments[idx];
      final newOvers = (overs != null && overs > 0) ? overs : old.overs;
      tournaments[idx] = Tournament(
        id: old.id,
        name: (name != null && name.trim().isNotEmpty) ? name.trim() : old.name,
        shortName: (shortName != null && shortName.trim().isNotEmpty) ? shortName.trim() : old.shortName,
        location: (location != null && location.trim().isNotEmpty) ? location.trim() : old.location,
        startDate: old.startDate,
        endDate: old.endDate,
        overs: newOvers,
        totalTeams: old.totalTeams,
        status: old.status,
        bannerUrl: old.bannerUrl,
        roomId: (roomId != null && roomId.trim().isNotEmpty) ? roomId.trim().toUpperCase() : old.roomId,
        passcode: (passcode != null && passcode.trim().isNotEmpty) ? passcode.trim() : old.passcode,
        createdBy: old.createdBy,
      );

      // If overs updated, update any scheduled matches for this tournament
      if (overs != null && overs > 0) {
        for (int i = 0; i < matches.length; i++) {
          final m = matches[i];
          if (m.tournamentId == tournamentId && m.status == MatchStatus.scheduled) {
            matches[i] = MatchModel(
              id: m.id,
              tournamentId: m.tournamentId,
              stage: m.stage,
              teamAId: m.teamAId,
              teamBId: m.teamBId,
              venue: m.venue,
              dateTime: m.dateTime,
              overs: newOvers,
              status: m.status,
            );
          }
        }
      }

      notifyListeners();
    }
  }

  void updateTeam({
    required String teamId,
    required String name,
    required String shortName,
    Color? primaryColor,
    String? ownerMobileNumber,
    String? ownerName,
  }) {
    final idx = teams.indexWhere((t) => t.id == teamId);
    if (idx != -1) {
      final old = teams[idx];
      teams[idx] = Team(
        id: old.id,
        tournamentId: old.tournamentId,
        name: name.trim().isNotEmpty ? name.trim() : old.name,
        shortName: shortName.trim().isNotEmpty ? shortName.trim() : old.shortName,
        uniqueTeamCode: old.uniqueTeamCode,
        passcode: old.passcode,
        ownerMobileNumber: ownerMobileNumber != null ? ownerMobileNumber.trim() : old.ownerMobileNumber,
        ownerName: ownerName != null ? ownerName.trim() : old.ownerName,
        primaryColor: primaryColor ?? old.primaryColor,
        logoUrl: old.logoUrl,
        purseRemaining: old.purseRemaining,
        maxPurse: old.maxPurse,
        squadCount: old.squadCount,
        minSquadRequirement: old.minSquadRequirement,
        maxSquadLimit: old.maxSquadLimit,
      );
      notifyListeners();
    }
  }

  void updateAuction({
    required String auctionId,
    String? title,
    int? maxPursePerTeam,
    int? minBidIncrement,
    int? requiredTeamsCount,
    String? adminPasscode,
  }) {
    final idx = auctions.indexWhere((a) => a.id == auctionId);
    if (idx != -1) {
      final old = auctions[idx];
      auctions[idx] = Auction(
        id: old.id,
        tournamentId: old.tournamentId,
        title: (title != null && title.trim().isNotEmpty) ? title.trim() : old.title,
        status: old.status,
        floorStatus: old.floorStatus,
        currentLotId: old.currentLotId,
        currentBid: old.currentBid,
        highBidderTeamId: old.highBidderTeamId,
        totalLots: old.totalLots,
        completedLots: old.completedLots,
        adminPasscode: (adminPasscode != null && adminPasscode.trim().isNotEmpty) ? adminPasscode.trim() : old.adminPasscode,
        minBidIncrement: (minBidIncrement != null && minBidIncrement > 0) ? minBidIncrement : old.minBidIncrement,
        maxPursePerTeam: (maxPursePerTeam != null && maxPursePerTeam > 0) ? maxPursePerTeam : old.maxPursePerTeam,
        requiredTeamsCount: (requiredTeamsCount != null && requiredTeamsCount > 0) ? requiredTeamsCount : old.requiredTeamsCount,
        joinedTeamIds: old.joinedTeamIds,
        biddingSecondsRemaining: old.biddingSecondsRemaining,
        defaultTimerSeconds: old.defaultTimerSeconds,
        isTimerRunning: old.isTimerRunning,
      );
      notifyListeners();
    }
  }

  void deleteTeam(String teamId) {
    teams.removeWhere((t) => t.id == teamId);
    players.removeWhere((p) => p.teamId == teamId);
    notifyListeners();
  }

  Player addPlayerToTeam({
    required String teamId,
    required String fullName,
    required String mobileNumber,
    PlayerRole role = PlayerRole.batsman,
  }) {
    final cleanName = fullName.trim().isNotEmpty ? fullName.trim() : 'Player';
    final newPlayer = Player(
      id: 'pl_${teamId}_${DateTime.now().millisecondsSinceEpoch}',
      fullName: cleanName,
      displayName: cleanName,
      mobileNumber: mobileNumber.trim(),
      role: role,
      battingStyle: 'Right Hand Bat',
      bowlingStyle: 'Right Arm Medium',
      basePrice: 500,
      photoUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=256',
      teamId: teamId,
    );
    players.add(newPlayer);
    final team = getTeam(teamId);
    if (team != null) {
      team.squadCount = players.where((p) => p.teamId == teamId).length;
    }
    notifyListeners();
    return newPlayer;
  }

  void updatePlayer({
    required String playerId,
    required String fullName,
    required String mobileNumber,
    PlayerRole? role,
  }) {
    final idx = players.indexWhere((p) => p.id == playerId);
    if (idx != -1) {
      final old = players[idx];
      final cleanName = fullName.trim().isNotEmpty ? fullName.trim() : old.fullName;
      players[idx] = Player(
        id: old.id,
        fullName: cleanName,
        displayName: cleanName,
        mobileNumber: mobileNumber.trim().isNotEmpty ? mobileNumber.trim() : old.mobileNumber,
        role: role ?? old.role,
        battingStyle: old.battingStyle,
        bowlingStyle: old.bowlingStyle,
        basePrice: old.basePrice,
        photoUrl: old.photoUrl,
        teamId: old.teamId,
        runs: old.runs,
        wickets: old.wickets,
        matches: old.matches,
      );
      notifyListeners();
    }
  }

  void deletePlayer(String playerId) {
    final p = players.where((x) => x.id == playerId).firstOrNull;
    if (p != null) {
      final teamId = p.teamId;
      players.removeWhere((x) => x.id == playerId);
      if (teamId != null) {
        final team = getTeam(teamId);
        if (team != null) {
          team.squadCount = players.where((x) => x.teamId == teamId).length;
        }
      }
      notifyListeners();
    }
  }
}
