import 'package:flutter/material.dart';
import '../models/models.dart';
import 'cricket_rules_engine.dart';

class MockDatabase extends ChangeNotifier {
  late Tournament tournament;
  late List<Team> teams;
  late List<Player> players;
  late List<MatchModel> matches;
  late List<Innings> inningsList;
  late List<Delivery> deliveries;
  late List<BattingScorecard> battingScorecards;
  late List<BowlingScorecard> bowlingScorecards;
  late List<TournamentStanding> tournamentStandings;

  late Auction auction;
  late List<AuctionLot> auctionLots;
  late List<AuctionBid> auctionBids;

  late List<ScoringRoom> scoringRooms;
  late List<AuctionRoom> auctionRooms;
  final Set<String> authenticatedScoringMatchIds = {};
  bool isAuctionUnlocked = false;
  bool isAuctionAdmin = false;
  String? currentAuctionRoomId;

  MockDatabase() {
    _initializeSeedData();
  }

  void _initializeSeedData() {
    tournament = Tournament(
      id: 'tourn_bpl_2026',
      name: 'Bengal Premier League 2026',
      shortName: 'BPL 2026',
      location: 'Eden Gardens, Kolkata',
      startDate: '2026-11-01',
      endDate: '2026-11-28',
      overs: 20,
      totalTeams: 4,
      status: 'active',
      bannerUrl: 'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?w=1200',
    );

    teams = [
      Team(
        id: 'team_barasat',
        name: 'Barasat Blasters',
        shortName: 'BBL',
        primaryColor: const Color(0xFF059669), // Emerald
        logoUrl: 'https://images.unsplash.com/photo-1589487391730-58f20eb2c308?w=120',
        purseRemaining: 8500000,
        maxPurse: 10000000,
        squadCount: 16,
      ),
      Team(
        id: 'team_kolkata',
        name: 'Kolkata Kings',
        shortName: 'KK',
        primaryColor: const Color(0xFF7C3AED), // Purple
        logoUrl: 'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=120',
        purseRemaining: 7250000,
        maxPurse: 10000000,
        squadCount: 15,
      ),
      Team(
        id: 'team_howrah',
        name: 'Howrah Hurricanes',
        shortName: 'HH',
        primaryColor: const Color(0xFF0284C7), // Sky Blue
        logoUrl: 'https://images.unsplash.com/photo-1517649763962-0c623266ddc0?w=120',
        purseRemaining: 6500000,
        maxPurse: 10000000,
        squadCount: 14,
      ),
      Team(
        id: 'team_hooghly',
        name: 'Hooghly Heroes',
        shortName: 'HOH',
        primaryColor: const Color(0xFFD97706), // Amber
        logoUrl: 'https://images.unsplash.com/photo-1579952363873-27f3bade9f55?w=120',
        purseRemaining: 9000000,
        maxPurse: 10000000,
        squadCount: 15,
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
    auction = Auction(
      id: 'auc_bpl_2026',
      tournamentId: 'tourn_bpl_2026',
      title: 'BPL 2026 Franchise Mega Auction',
      status: AuctionStatus.live,
      currentLotId: 'lot_6',
      currentBid: 450000,
      highBidderTeamId: 'team_barasat',
      totalLots: 8,
      completedLots: 5,
    );

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

  void startMatchWithToss({
    required String matchId,
    required String tossWonBy,
    required String tossDecision,
    required String strikerId,
    required String nonStrikerId,
    required String bowlerId,
  }) {
    final match = matches.firstWhere((m) => m.id == matchId);
    match.tossWonBy = tossWonBy;
    match.tossDecision = tossDecision;
    match.status = MatchStatus.live;
    match.currentInningsNumber = 1;

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
  // AUCTION METHODS
  // ==========================================

  void placeAuctionBid(String teamId, int increment) {
    final team = teams.firstWhere((t) => t.id == teamId);
    final nextAmount = (auction.currentBid ?? 300000) + increment;

    if (team.purseRemaining < nextAmount) return;

    auction.currentBid = nextAmount;
    auction.highBidderTeamId = teamId;

    final currentLot = auctionLots.firstWhere((l) => l.id == auction.currentLotId);
    currentLot.currentBid = nextAmount;
    currentLot.winningTeamId = teamId;

    auctionBids.insert(
      0,
      AuctionBid(
        id: 'bid_${DateTime.now().millisecondsSinceEpoch}',
        lotId: currentLot.id,
        teamId: team.id,
        teamName: team.name,
        amount: nextAmount,
        timestamp: DateTime.now(),
      ),
    );

    notifyListeners();
  }

  void sellCurrentLot() {
    if (auction.currentLotId == null || auction.highBidderTeamId == null) return;

    final lot = auctionLots.firstWhere((l) => l.id == auction.currentLotId);
    final team = teams.firstWhere((t) => t.id == auction.highBidderTeamId);
    final player = players.firstWhere((p) => p.id == lot.playerId);

    lot.status = LotStatus.sold;
    lot.winningTeamId = team.id;
    team.purseRemaining -= (lot.currentBid ?? lot.basePrice);
    team.squadCount++;
    player.teamId = team.id;
    auction.completedLots++;

    // Pick next lot
    final pending = auctionLots.where((l) => l.status == LotStatus.pending).toList();
    if (pending.isNotEmpty) {
      auction.currentLotId = pending.first.id;
      auction.currentBid = pending.first.basePrice;
      auction.highBidderTeamId = null;
      pending.first.status = LotStatus.bidding;
    } else {
      auction.status = AuctionStatus.completed;
    }

    notifyListeners();
  }

  void passCurrentLot() {
    if (auction.currentLotId == null) return;
    final lot = auctionLots.firstWhere((l) => l.id == auction.currentLotId);
    lot.status = LotStatus.unsold;
    auction.completedLots++;

    final pending = auctionLots.where((l) => l.status == LotStatus.pending).toList();
    if (pending.isNotEmpty) {
      auction.currentLotId = pending.first.id;
      auction.currentBid = pending.first.basePrice;
      auction.highBidderTeamId = null;
      pending.first.status = LotStatus.bidding;
    } else {
      auction.status = AuctionStatus.completed;
    }

    notifyListeners();
  }

  // ==========================================
  // ROOM MANAGEMENT & AUTHENTICATION METHODS
  // ==========================================

  bool isScoringUnlockedForMatch(String matchId) {
    return authenticatedScoringMatchIds.contains(matchId);
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
}
