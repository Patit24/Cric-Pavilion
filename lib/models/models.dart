import 'package:flutter/material.dart';

enum MatchStatus { scheduled, toss, live, inningsBreak, completed, abandoned }
enum DismissalType { bowled, caught, lbw, runOut, stumped, hitWicket, retiredOut }
enum ExtrasType { none, wide, noBall, bye, legBye, penalty }
enum PlayerRole { batsman, bowler, allRounder, wicketKeeper }
enum AuctionStatus { draft, preview, live, paused, completed }
enum LotStatus { pending, bidding, sold, unsold }
enum FloorStatus { open, paused, goingOnce, goingTwice, fairWarning, sold, unsold }

enum AppUserRole {
  superAdmin,
  tournamentAdmin,
  auctionAdmin,
  teamOwner,
  scorer,
  viewer;

  String get displayName {
    switch (this) {
      case AppUserRole.superAdmin:
        return 'Super Admin';
      case AppUserRole.tournamentAdmin:
        return 'Tournament Admin';
      case AppUserRole.auctionAdmin:
        return 'Auction Admin';
      case AppUserRole.teamOwner:
        return 'Team Owner';
      case AppUserRole.scorer:
        return 'Match Scorer';
      case AppUserRole.viewer:
        return 'Viewer (Public)';
    }
  }

  String get badgeLabel {
    switch (this) {
      case AppUserRole.superAdmin:
        return 'SUPER ADMIN';
      case AppUserRole.tournamentAdmin:
        return 'TOURNAMENT ADMIN';
      case AppUserRole.auctionAdmin:
        return 'AUCTION ADMIN';
      case AppUserRole.teamOwner:
        return 'TEAM OWNER';
      case AppUserRole.scorer:
        return 'SCORER';
      case AppUserRole.viewer:
        return 'PUBLIC SPECTATOR';
    }
  }

  IconData get icon {
    switch (this) {
      case AppUserRole.superAdmin:
        return Icons.admin_panel_settings;
      case AppUserRole.tournamentAdmin:
        return Icons.emoji_events;
      case AppUserRole.auctionAdmin:
        return Icons.gavel;
      case AppUserRole.teamOwner:
        return Icons.business_center;
      case AppUserRole.scorer:
        return Icons.sports_score;
      case AppUserRole.viewer:
        return Icons.visibility;
    }
  }

  Color get color {
    switch (this) {
      case AppUserRole.superAdmin:
        return const Color(0xFFE11D48); // Rose
      case AppUserRole.tournamentAdmin:
        return const Color(0xFF7C3AED); // Purple
      case AppUserRole.auctionAdmin:
        return const Color(0xFFD97706); // Amber
      case AppUserRole.teamOwner:
        return const Color(0xFF0284C7); // Sky Blue
      case AppUserRole.scorer:
        return const Color(0xFF059669); // Emerald
      case AppUserRole.viewer:
        return const Color(0xFF64748B); // Slate
    }
  }

  String get description {
    switch (this) {
      case AppUserRole.superAdmin:
        return 'Full control: tournaments, auctions, teams, scorers, and rules.';
      case AppUserRole.tournamentAdmin:
        return 'Create tournaments, manage teams, fixtures, and assign officials.';
      case AppUserRole.auctionAdmin:
        return 'Configure auction floor, spin wheel, manage timer, and hammer sold/unsold.';
      case AppUserRole.teamOwner:
        return 'Participate in live bidding with budget protection and inspect squad.';
      case AppUserRole.scorer:
        return 'Operate ball-by-ball matches, toss, crease hud, and scorecards.';
      case AppUserRole.viewer:
        return 'Public live scorecards, commentary, standings, and squad viewer.';
    }
  }
}

class Tournament {
  final String id;
  final String name;
  final String shortName;
  final String location;
  final String startDate;
  final String endDate;
  final int overs;
  final int totalTeams;
  final String status;
  final String bannerUrl;
  final String roomId;
  final String passcode;

  Tournament({
    required this.id,
    required this.name,
    required this.shortName,
    required this.location,
    required this.startDate,
    required this.endDate,
    required this.overs,
    required this.totalTeams,
    required this.status,
    required this.bannerUrl,
    this.roomId = '',
    this.passcode = '1234',
  });
}

class Team {
  final String id;
  final String tournamentId;
  final String name;
  final String shortName;
  final String uniqueTeamCode; // e.g. "TEAM-BBL-01"
  final String passcode; // e.g. "1234"
  final Color primaryColor;
  final String logoUrl;
  int purseRemaining;
  final int maxPurse;
  int squadCount;
  final int minSquadRequirement;
  final int maxSquadLimit;

  Team({
    required this.id,
    this.tournamentId = 'tourn_bpl_2026',
    required this.name,
    required this.shortName,
    this.uniqueTeamCode = '',
    this.passcode = '1234',
    required this.primaryColor,
    required this.logoUrl,
    required this.purseRemaining,
    required this.maxPurse,
    required this.squadCount,
    this.minSquadRequirement = 15,
    this.maxSquadLimit = 18,
  });

  int get playersStillNeeded => (minSquadRequirement - squadCount).clamp(0, minSquadRequirement);

  /// Minimum Remaining Budget Protection Formula:
  /// Maximum Bid = Remaining Purse - (Other Players Needed * Minimum Player Base Price)
  /// Where Other Players Needed is max(0, minSquadRequirement - squadCount - 1)
  int getMaxEligibleBid(int minPlayerBasePrice) {
    if (squadCount >= maxSquadLimit) return 0;
    final otherPlayersNeeded = (minSquadRequirement - squadCount - 1).clamp(0, minSquadRequirement);
    final reserveRequired = otherPlayersNeeded * minPlayerBasePrice;
    final maxBid = purseRemaining - reserveRequired;
    return maxBid.clamp(0, purseRemaining);
  }

  int getReserveRequired(int minPlayerBasePrice) {
    final otherPlayersNeeded = (minSquadRequirement - squadCount - 1).clamp(0, minSquadRequirement);
    return otherPlayersNeeded * minPlayerBasePrice;
  }
}

class Player {
  final String id;
  final String fullName;
  final String displayName;
  final PlayerRole role;
  final String battingStyle;
  final String bowlingStyle;
  final int basePrice;
  final String photoUrl;
  String? teamId;
  int runs;
  int wickets;
  int matches;

  Player({
    required this.id,
    required this.fullName,
    required this.displayName,
    required this.role,
    required this.battingStyle,
    required this.bowlingStyle,
    required this.basePrice,
    required this.photoUrl,
    this.teamId,
    this.runs = 0,
    this.wickets = 0,
    this.matches = 0,
  });

  String get roleString {
    switch (role) {
      case PlayerRole.batsman:
        return 'Batter';
      case PlayerRole.bowler:
        return 'Bowler';
      case PlayerRole.allRounder:
        return 'All-Rounder';
      case PlayerRole.wicketKeeper:
        return 'Wicketkeeper';
    }
  }
}

class MatchModel {
  final String id;
  final String tournamentId;
  final String stage;
  final String teamAId;
  final String teamBId;
  final String venue;
  final DateTime dateTime;
  final int overs;
  MatchStatus status;
  String? tossWonBy;
  String? tossDecision; // 'bat' or 'bowl'
  String? battingFirstId;
  String? winnerId;
  String? winMargin;
  int currentInningsNumber;
  List<String> playingXIA;
  List<String> playingXIB;
  String? captainAId;
  String? captainBId;
  String? keeperAId;
  String? keeperBId;

  MatchModel({
    required this.id,
    required this.tournamentId,
    required this.stage,
    required this.teamAId,
    required this.teamBId,
    required this.venue,
    required this.dateTime,
    required this.overs,
    this.status = MatchStatus.scheduled,
    this.tossWonBy,
    this.tossDecision,
    this.battingFirstId,
    this.winnerId,
    this.winMargin,
    this.currentInningsNumber = 1,
    List<String>? playingXIA,
    List<String>? playingXIB,
    this.captainAId,
    this.captainBId,
    this.keeperAId,
    this.keeperBId,
  })  : playingXIA = playingXIA ?? [],
        playingXIB = playingXIB ?? [];
}

class Innings {
  final String id;
  final String matchId;
  final int inningsNumber;
  String battingTeamId;
  String bowlingTeamId;
  int totalRuns;
  int wickets;
  int legalBalls;
  String oversStr;
  int extrasWides;
  int extrasNoBalls;
  int extrasByes;
  int extrasLegByes;
  int totalExtras;
  bool isCompleted;
  String? currentStrikerId;
  String? currentNonStrikerId;
  String? currentBowlerId;
  int? targetRuns;

  Innings({
    required this.id,
    required this.matchId,
    required this.inningsNumber,
    required this.battingTeamId,
    required this.bowlingTeamId,
    this.totalRuns = 0,
    this.wickets = 0,
    this.legalBalls = 0,
    this.oversStr = '0.0',
    this.extrasWides = 0,
    this.extrasNoBalls = 0,
    this.extrasByes = 0,
    this.extrasLegByes = 0,
    this.totalExtras = 0,
    this.isCompleted = false,
    this.currentStrikerId,
    this.currentNonStrikerId,
    this.currentBowlerId,
    this.targetRuns,
  });

  double get runRate {
    if (legalBalls == 0) return 0.0;
    return (totalRuns / (legalBalls / 6.0));
  }
}

class Delivery {
  final String id;
  final String inningsId;
  final String matchId;
  final int overNumber;
  final int ballInOver;
  final int deliverySequence;
  final String strikerId;
  final String nonStrikerId;
  final String bowlerId;
  final int runsBatter;
  final int extrasRuns;
  final bool isLegal;
  final bool isWicket;
  final ExtrasType extrasType;
  final DismissalType? dismissalType;
  final String? dismissedPlayerId;
  final String? fielderId;
  final String commentaryText;
  final DateTime timestamp;
  bool isUndone;

  Delivery({
    required this.id,
    required this.inningsId,
    required this.matchId,
    required this.overNumber,
    required this.ballInOver,
    required this.deliverySequence,
    required this.strikerId,
    required this.nonStrikerId,
    required this.bowlerId,
    this.runsBatter = 0,
    this.extrasRuns = 0,
    this.isLegal = true,
    this.isWicket = false,
    this.extrasType = ExtrasType.none,
    this.dismissalType,
    this.dismissedPlayerId,
    this.fielderId,
    required this.commentaryText,
    required this.timestamp,
    this.isUndone = false,
  });

  int get totalRuns => runsBatter + extrasRuns;
}

class BattingScorecard {
  final String id;
  final String inningsId;
  final String matchId;
  final String playerId;
  final String playerName;
  int runs;
  int balls;
  int fours;
  int sixes;
  double strikeRate;
  String dismissalText;
  bool isOut;

  BattingScorecard({
    required this.id,
    required this.inningsId,
    required this.matchId,
    required this.playerId,
    required this.playerName,
    this.runs = 0,
    this.balls = 0,
    this.fours = 0,
    this.sixes = 0,
    this.strikeRate = 0.0,
    this.dismissalText = 'not out',
    this.isOut = false,
  });
}

class BowlingScorecard {
  final String id;
  final String inningsId;
  final String matchId;
  final String playerId;
  final String playerName;
  String oversStr;
  int legalBalls;
  int maidens;
  int runsConceded;
  int wickets;
  int dots;
  double economy;

  BowlingScorecard({
    required this.id,
    required this.inningsId,
    required this.matchId,
    required this.playerId,
    required this.playerName,
    this.oversStr = '0.0',
    this.legalBalls = 0,
    this.maidens = 0,
    this.runsConceded = 0,
    this.wickets = 0,
    this.dots = 0,
    this.economy = 0.0,
  });
}

class Auction {
  final String id;
  final String tournamentId;
  final String title;
  AuctionStatus status;
  FloorStatus floorStatus;
  String? currentLotId;
  int? currentBid;
  String? highBidderTeamId;
  int totalLots;
  int completedLots;
  final String adminPasscode;
  final int minBidIncrement;
  final int maxPursePerTeam;
  final int requiredTeamsCount;
  final Set<String> joinedTeamIds;
  int biddingSecondsRemaining;
  int defaultTimerSeconds;
  bool isTimerRunning;

  Auction({
    required this.id,
    required this.tournamentId,
    required this.title,
    this.status = AuctionStatus.live,
    this.floorStatus = FloorStatus.open,
    this.currentLotId,
    this.currentBid,
    this.highBidderTeamId,
    required this.totalLots,
    this.completedLots = 0,
    this.adminPasscode = 'admin123',
    this.minBidIncrement = 25000,
    this.maxPursePerTeam = 10000000,
    this.requiredTeamsCount = 8,
    Set<String>? joinedTeamIds,
    this.biddingSecondsRemaining = 15,
    this.defaultTimerSeconds = 15,
    this.isTimerRunning = false,
  }) : joinedTeamIds = joinedTeamIds ?? {};

  bool get isReadyToStart => joinedTeamIds.length >= requiredTeamsCount;
}

class AuctionLot {
  final String id;
  final String auctionId;
  final int lotNumber;
  final String playerId;
  final String category;
  final int basePrice;
  int? startingPrice; // Manually set by host
  int? currentBid;
  String? winningTeamId;
  LotStatus status;
  bool isSelectedForSpin; // Host toggle for active spin wheel pool

  AuctionLot({
    required this.id,
    required this.auctionId,
    required this.lotNumber,
    required this.playerId,
    required this.category,
    required this.basePrice,
    this.startingPrice,
    this.currentBid,
    this.winningTeamId,
    this.status = LotStatus.pending,
    this.isSelectedForSpin = true,
  });
}

class AuctionBid {
  final String id;
  final String lotId;
  final String teamId;
  final String teamName;
  final int amount;
  final DateTime timestamp;

  AuctionBid({
    required this.id,
    required this.lotId,
    required this.teamId,
    required this.teamName,
    required this.amount,
    required this.timestamp,
  });
}

class TournamentStanding {
  final String teamId;
  final String teamName;
  final String teamShortName;
  final String teamLogoUrl;
  final int matchesPlayed;
  final int won;
  final int lost;
  final int points;
  final double netRunRate;

  TournamentStanding({
    required this.teamId,
    required this.teamName,
    required this.teamShortName,
    required this.teamLogoUrl,
    required this.matchesPlayed,
    required this.won,
    required this.lost,
    required this.points,
    required this.netRunRate,
  });
}

class ScoringRoom {
  final String id; // e.g. "ROOM-BPL-01"
  final String matchId;
  final String passcode; // e.g. "1234"
  final String createdBy;
  final DateTime createdAt;

  ScoringRoom({
    required this.id,
    required this.matchId,
    required this.passcode,
    required this.createdBy,
    required this.createdAt,
  });
}

class AuctionRoom {
  final String id; // e.g. "AUCTION-BPL"
  final String auctionId;
  final String passcode; // Team bidding PIN e.g. "1234"
  final String adminPasscode; // Auctioneer PIN e.g. "admin123"
  final String createdBy;
  final DateTime createdAt;

  AuctionRoom({
    required this.id,
    required this.auctionId,
    required this.passcode,
    required this.adminPasscode,
    required this.createdBy,
    required this.createdAt,
  });
}

class AuditLog {
  final String id;
  final DateTime timestamp;
  final String category; // 'auction', 'scoring', 'tournament'
  final String action;
  final String details;
  final String performedBy;

  AuditLog({
    required this.id,
    required this.timestamp,
    required this.category,
    required this.action,
    required this.details,
    required this.performedBy,
  });
}

