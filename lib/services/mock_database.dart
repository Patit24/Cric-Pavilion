import 'dart:math';
import 'package:flutter/material.dart';
import '../models/models.dart';
import 'cricket_rules_engine.dart';

class MockDatabase extends ChangeNotifier {
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
    scoringRooms = [];
    auctionRooms = [];
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
    notifyListeners();
  }

  /// Reloads sample demo tournament (BPL 2026) for testing and inspection
  void reloadDemoData() {
    _initializeSeedData();
    isDemoDataLoaded = true;
    notifyListeners();
  }

  // Role-Based Access Control State
  AppUserRole currentRole = AppUserRole.superAdmin;
  final List<AuditLog> auditLogs = [];

  void setRole(AppUserRole role, {String? teamId}) {
    currentRole = role;
    if (role == AppUserRole.superAdmin) {
      isAuctionAdmin = true;
      isAuctionUnlocked = true;
    } else if (role == AppUserRole.auctionAdmin) {
      isAuctionAdmin = true;
      isAuctionUnlocked = true;
      authenticatedTeamId = null;
    } else if (role == AppUserRole.teamOwner) {
      isAuctionAdmin = false;
      isAuctionUnlocked = true;
      if (teamId != null) {
        authenticatedTeamId = teamId;
      } else if (authenticatedTeamId == null && teams.isNotEmpty) {
        authenticatedTeamId = teams.first.id;
      }
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
  bool get isViewer => currentRole == AppUserRole.viewer;

  void logAudit({
    required String category,
    required String action,
    required String details,
    String? performedBy,
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
      ),
    );
  }

  Team? get currentAuthenticatedTeam =>
      authenticatedTeamId != null ? teams.where((t) => t.id == authenticatedTeamId).firstOrNull : null;

  MockDatabase({bool loadDemoSeed = false}) {
    if (loadDemoSeed) {
      _initializeSeedData();
      isDemoDataLoaded = true;
    } else {
      clearAllDemoData();
    }
  }

  void _initializeSeedData() {
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

    // Hard 20-Over Cap check
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

    // Striker & Bowler
    final strikerId = inn.currentStrikerId ?? 'pl_1';
    final nonStrikerId = inn.currentNonStrikerId ?? 'pl_3';
    final bowlerId = inn.currentBowlerId ?? 'pl_4';

    // Update Batter Scorecard
    var strikerCard = battingScorecards.firstWhere(
      (b) => b.inningsId == inningsId && b.playerId == strikerId,
      orElse: () {
        final p = players.firstWhere((p) => p.id == strikerId);
        final newCard = BattingScorecard(
          id: 'bat_${inningsId}_$strikerId',
          inningsId: inningsId,
          matchId: match.id,
          playerId: strikerId,
          playerName: p.fullName,
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
        final p = players.firstWhere((p) => p.id == bowlerId);
        final newCard = BowlingScorecard(
          id: 'bowl_${inningsId}_$bowlerId',
          inningsId: inningsId,
          matchId: match.id,
          playerId: bowlerId,
          playerName: p.fullName,
        );
        bowlingScorecards.add(newCard);
        return newCard;
      },
    );

    if (isLegal) bowlerCard.legalBalls++;
    bowlerCard.oversStr = CricketRulesEngine.formatOvers(bowlerCard.legalBalls);
    bowlerCard.runsConceded += totalBallRuns;
    if (totalBallRuns == 0 && isLegal) bowlerCard.dots++;
    if (isWicket && dismissalType != DismissalType.runOut) bowlerCard.wickets++;
    if (bowlerCard.legalBalls > 0) {
      bowlerCard.economy = (bowlerCard.runsConceded / (bowlerCard.legalBalls / 6.0));
    }

    // Wicket handling
    if (isWicket) {
      inn.wickets++;
      final outPlayerId = dismissedPlayerId ?? strikerId;
      var outCard = battingScorecards.firstWhere((b) => b.inningsId == inningsId && b.playerId == outPlayerId);
      outCard.isOut = true;
      outCard.dismissalText = dismissalType?.name.toUpperCase() ?? 'OUT';

      if (inn.wickets < 10 && nextBatterId != null) {
        if (outPlayerId == inn.currentStrikerId) {
          inn.currentStrikerId = nextBatterId;
        } else {
          inn.currentNonStrikerId = nextBatterId;
        }
      }
    }

    // Strike Rotation: odd runs swap ends
    if (runsBatter % 2 != 0) {
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
        id: 'del_${DateTime.now().millisecondsSinceEpoch}',
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
            ? 'WICKET! Dismissed ($dismissalType).'
            : runsBatter == 4
                ? 'FOUR! Punched firmly to the boundary.'
                : runsBatter == 6
                    ? 'SIX! Clears the rope with huge elevation!'
                    : 'Pushed into gaps for $runsBatter run(s).',
        timestamp: DateTime.now(),
      ),
    );

    // Innings 1 Completion Check
    if (inn.inningsNumber == 1 && (inn.legalBalls >= match.overs * 6 || inn.wickets >= 10)) {
      inn.isCompleted = true;
      match.status = MatchStatus.inningsBreak;

      // Auto initialize Innings 2 if not present
      if (!inningsList.any((i) => i.matchId == match.id && i.inningsNumber == 2)) {
        final inn2 = Innings(
          id: 'inn_${match.id}_2',
          matchId: match.id,
          inningsNumber: 2,
          battingTeamId: inn.bowlingTeamId,
          bowlingTeamId: inn.battingTeamId,
          targetRuns: inn.totalRuns + 1,
        );
        inningsList.add(inn2);
        match.currentInningsNumber = 2;
      }
    }

    // Innings 2 Chasing Check
    if (inn.inningsNumber == 2 && inn.targetRuns != null) {
      if (inn.totalRuns >= inn.targetRuns!) {
        inn.isCompleted = true;
        match.status = MatchStatus.completed;
        match.winnerId = inn.battingTeamId;
        final wicketsLeft = 10 - inn.wickets;
        match.winMargin = '$wicketsLeft wickets';
      } else if (inn.legalBalls >= match.overs * 6 || inn.wickets >= 10) {
        inn.isCompleted = true;
        match.status = MatchStatus.completed;
        match.winnerId = inn.bowlingTeamId;
        final runsDefended = (inn.targetRuns! - 1) - inn.totalRuns;
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
    required String teamCode,
    required String passcode,
  }) {
    final cleanCode = teamCode.trim().toUpperCase();
    final cleanPass = passcode.trim();

    final team = teams.where((t) => t.uniqueTeamCode.toUpperCase() == cleanCode && t.passcode == cleanPass).firstOrNull;
    if (team != null) {
      authenticatedTeamId = team.id;
      isAuctionUnlocked = true;
      isAuctionAdmin = false;
      currentAuctionRoomId = auctionId;

      final auc = getAuction(auctionId);
      auc.joinedTeamIds.add(team.id);

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

    final team = teams.firstWhere((t) => t.id == teamId, orElse: () => teams.first);
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
    final currentLot = auctionLots.where((l) => l.id == auc.currentLotId).firstOrNull;
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
    final auc = getAuction(auctionId);
    final eligible = auctionLots.where((l) => l.auctionId == auc.id && l.status == LotStatus.pending && l.isSelectedForSpin).toList();
    if (eligible.isEmpty) return null;

    final picked = eligible[Random().nextInt(eligible.length)];
    auc.currentLotId = picked.id;
    auc.currentBid = picked.startingPrice ?? picked.basePrice;
    auc.highBidderTeamId = null;
    auc.floorStatus = FloorStatus.open;
    auc.biddingSecondsRemaining = auc.defaultTimerSeconds;
    auc.isTimerRunning = true;
    picked.status = LotStatus.bidding;
    notifyListeners();
    return picked;
  }

  void sellCurrentLot([String? auctionId]) {
    final targetAuctionId = auctionId ?? auctions.first.id;
    final auc = getAuction(targetAuctionId);

    if (auc.currentLotId == null || auc.highBidderTeamId == null) return;

    final lot = auctionLots.firstWhere((l) => l.id == auc.currentLotId);
    final team = teams.firstWhere((t) => t.id == auc.highBidderTeamId);
    final player = players.firstWhere((p) => p.id == lot.playerId);

    lot.status = LotStatus.sold;
    lot.winningTeamId = team.id;
    team.purseRemaining -= (lot.currentBid ?? lot.basePrice);
    team.squadCount++;
    player.teamId = team.id;
    auc.completedLots++;

    logAudit(
      category: 'auction',
      action: 'LOT_SOLD',
      details: '${player.fullName} sold to ${team.name} for ₹${lot.currentBid ?? lot.basePrice}',
      performedBy: 'Auctioneer',
    );

    // Pick next lot
    final pending = auctionLots.where((l) => l.auctionId == auc.id && l.status == LotStatus.pending).toList();
    if (pending.isNotEmpty) {
      auc.currentLotId = pending.first.id;
      auc.currentBid = pending.first.basePrice;
      auc.highBidderTeamId = null;
      auc.biddingSecondsRemaining = auc.defaultTimerSeconds;
      auc.isTimerRunning = true;
      pending.first.status = LotStatus.bidding;
    } else {
      auc.status = AuctionStatus.completed;
      auc.isTimerRunning = false;
    }

    notifyListeners();
  }

  void passCurrentLot([String? auctionId]) {
    final targetAuctionId = auctionId ?? auctions.first.id;
    final auc = getAuction(targetAuctionId);

    if (auc.currentLotId == null) return;
    final lot = auctionLots.firstWhere((l) => l.id == auc.currentLotId);
    lot.status = LotStatus.unsold;
    auc.completedLots++;

    logAudit(
      category: 'auction',
      action: 'LOT_UNSOLD',
      details: 'Lot #${lot.lotNumber} was marked unsold',
      performedBy: 'Auctioneer',
    );

    final pending = auctionLots.where((l) => l.auctionId == auc.id && l.status == LotStatus.pending).toList();
    if (pending.isNotEmpty) {
      auc.currentLotId = pending.first.id;
      auc.currentBid = pending.first.basePrice;
      auc.highBidderTeamId = null;
      auc.biddingSecondsRemaining = auc.defaultTimerSeconds;
      auc.isTimerRunning = true;
      pending.first.status = LotStatus.bidding;
    } else {
      auc.status = AuctionStatus.completed;
      auc.isTimerRunning = false;
    }

    notifyListeners();
  }

  /// Host adds a new player directly into the auction pool
  void addPlayerToAuction({
    required String auctionId,
    required String fullName,
    required String photoUrl,
    required PlayerRole role,
    required String battingStyle,
    required String bowlingStyle,
    required int basePrice,
    required String category,
  }) {
    final auc = getAuction(auctionId);
    final newPlayerId = 'pl_${DateTime.now().millisecondsSinceEpoch}';

    final newPlayer = Player(
      id: newPlayerId,
      fullName: fullName,
      displayName: fullName,
      role: role,
      battingStyle: battingStyle,
      bowlingStyle: bowlingStyle,
      basePrice: basePrice,
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
            displayName: pName.split(' ').first,
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
  bool areTeamsReadyForScoring(String teamAId, String teamBId) {
    if (teamAId.isEmpty || teamBId.isEmpty) return false;
    final playersA = players.where((p) => p.teamId == teamAId).toList();
    final playersB = players.where((p) => p.teamId == teamBId).toList();

    // Must have at least 2 players each to score a match
    if (playersA.length < 2 || playersB.length < 2) return false;

    // EVERY player in both teams must have a non-empty name and a non-empty mobile number
    final hasIncompleteA = playersA.any((p) => p.fullName.trim().isEmpty || p.mobileNumber.trim().isEmpty);
    final hasIncompleteB = playersB.any((p) => p.fullName.trim().isEmpty || p.mobileNumber.trim().isEmpty);

    return !hasIncompleteA && !hasIncompleteB;
  }

  /// Returns players for a specific team
  List<Player> getTeamPlayers(String teamId) {
    return players.where((p) => p.teamId == teamId).toList();
  }

  /// Saves or updates all players for a team with mobile numbers
  void saveTeamSquadWithMobileNumbers({
    required String teamId,
    required List<Map<String, String>> playerEntries,
  }) {
    players.removeWhere((p) => p.teamId == teamId);
    final team = getTeam(teamId);

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

      final newP = Player(
        id: 'pl_${teamId}_${DateTime.now().millisecondsSinceEpoch}_$i',
        fullName: name,
        displayName: name.split(' ').first,
        mobileNumber: mobile,
        role: role,
        battingStyle: 'Right Hand Bat',
        bowlingStyle: 'Right Arm Medium',
        basePrice: 500,
        photoUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=256',
        teamId: teamId,
      );
      players.add(newP);
    }

    if (team != null) {
      team.squadCount = playerEntries.length;
    }

    notifyListeners();
  }

  /// Host creates a standalone player auction (supports custom entered team names & custom entered players)
  Auction createAuction({
    required String tournamentId,
    required String title,
    required String adminPasscode,
    required int maxPursePerTeam,
    required int minBidIncrement,
    required int requiredTeamsCount,
    List<String>? customTeamNames,
    List<Map<String, dynamic>>? customPlayers,
  }) {
    final cleanId = 'auc_${DateTime.now().millisecondsSinceEpoch}';
    final targetTournamentId = tournamentId.isNotEmpty ? tournamentId : 'tourn_$cleanId';

    // 1. If custom team names provided, create these exact teams fresh
    if (customTeamNames != null && customTeamNames.isNotEmpty) {
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
    } else if (customTeamNames == null || customTeamNames.isEmpty) {
      // Fallback only if no custom players and no custom teams specified (legacy mode)
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

  // ==========================================
  // ROOM MANAGEMENT & AUTHENTICATION METHODS
  // ==========================================

  bool isScoringUnlockedForMatch(String matchId) {
    final match = matches.where((m) => m.id == matchId).firstOrNull;
    if (match == null) return false;

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

    // 3. Baseline for demo tournament if no catches were registered yet
    if (catchesMap.isEmpty && tournamentId == 'tourn_bpl_2026') {
      catchesMap['pl_3'] = 3; // Wriddhiman Saha
      stumpingsMap['pl_3'] = 1;
      catchesMap['pl_2'] = 2; // Manoj Tiwary
      catchesMap['pl_5'] = 1; // Suman Biswas
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
    if (tournamentStandings.isNotEmpty && (tournamentId == 'tourn_bpl_2026' || tournamentId.isEmpty)) {
      final list = List<TournamentStanding>.from(tournamentStandings);
      list.sort((a, b) {
        final cmp = b.points.compareTo(a.points);
        if (cmp != 0) return cmp;
        return b.netRunRate.compareTo(a.netRunRate);
      });
      return list;
    }

    final tournTeams = teams.where((t) => t.tournamentId == tournamentId).toList();
    if (tournTeams.isEmpty) return [];

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
}
