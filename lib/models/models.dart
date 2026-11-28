import 'package:flutter/material.dart';

enum MatchStatus { scheduled, toss, live, inningsBreak, completed, abandoned }
enum DismissalType { bowled, caught, lbw, runOut, stumped, hitWicket, retiredOut }
enum ExtrasType { none, wide, noBall, bye, legBye, penalty }
enum PlayerRole { batsman, bowler, allRounder, wicketKeeper }
enum AuctionStatus { draft, preview, live, paused, completed }
enum LotStatus { pending, bidding, sold, unsold }
enum FloorStatus { open, paused, goingOnce, goingTwice, fairWarning, sold, unsold }

enum PlayerRegistrationStatus {
  pendingApproval,
  approved,
  rejected,
  withdrawn;

  String get label {
    switch (this) {
      case PlayerRegistrationStatus.pendingApproval:
        return 'Pending Approval';
      case PlayerRegistrationStatus.approved:
        return 'Approved';
      case PlayerRegistrationStatus.rejected:
        return 'Rejected';
      case PlayerRegistrationStatus.withdrawn:
        return 'Withdrawn';
    }
  }
}

enum PlayerAuctionStatus {
  available,
  inAuction,
  sold,
  unsold,
  withdrawn;

  String get displayName => label;

  String get label {
    switch (this) {
      case PlayerAuctionStatus.available:
        return 'Available';
      case PlayerAuctionStatus.inAuction:
        return 'In Auction';
      case PlayerAuctionStatus.sold:
        return 'Sold';
      case PlayerAuctionStatus.unsold:
        return 'Unsold';
      case PlayerAuctionStatus.withdrawn:
        return 'Withdrawn';
    }
  }

  Color get color {
    switch (this) {
      case PlayerAuctionStatus.available:
        return const Color(0xFF38BDF8); // Sky blue
      case PlayerAuctionStatus.inAuction:
        return const Color(0xFFF59E0B); // Amber
      case PlayerAuctionStatus.sold:
        return const Color(0xFF10B981); // Emerald
      case PlayerAuctionStatus.unsold:
        return const Color(0xFFEF4444); // Red
      case PlayerAuctionStatus.withdrawn:
        return const Color(0xFF94A3B8); // Slate grey
    }
  }
}

enum AppUserRole {
  superAdmin,
  tournamentAdmin,
  auctionAdmin,
  auctioneer,
  auctionOperator,
  teamOwner,
  player,
  scorer,
  viewer;

  String get displayName {
    switch (this) {
      case AppUserRole.superAdmin:
        return 'Super Admin';
      case AppUserRole.tournamentAdmin:
        return 'Tournament Admin';
      case AppUserRole.auctionAdmin:
        return 'Auction Host';
      case AppUserRole.auctioneer:
        return 'Official Auctioneer';
      case AppUserRole.auctionOperator:
        return 'Auction Operator';
      case AppUserRole.teamOwner:
        return 'Team Owner (Bidder)';
      case AppUserRole.player:
        return 'Registered Player';
      case AppUserRole.scorer:
        return 'Match Scorer';
      case AppUserRole.viewer:
        return 'Public Viewer';
    }
  }

  String get shortDisplayName {
    switch (this) {
      case AppUserRole.superAdmin:
        return 'Admin';
      case AppUserRole.tournamentAdmin:
        return 'T. Admin';
      case AppUserRole.auctionAdmin:
        return 'Host';
      case AppUserRole.auctioneer:
        return 'Auctioneer';
      case AppUserRole.auctionOperator:
        return 'Operator';
      case AppUserRole.teamOwner:
        return 'Owner';
      case AppUserRole.player:
        return 'Player';
      case AppUserRole.scorer:
        return 'Scorer';
      case AppUserRole.viewer:
        return 'Viewer';
    }
  }

  String get badge => badgeLabel;

  String get badgeLabel {
    switch (this) {
      case AppUserRole.superAdmin:
        return 'SUPER ADMIN';
      case AppUserRole.tournamentAdmin:
        return 'TOURNAMENT ADMIN';
      case AppUserRole.auctionAdmin:
        return 'AUCTION ADMIN';
      case AppUserRole.auctioneer:
        return 'AUCTIONEER';
      case AppUserRole.auctionOperator:
        return 'OPERATOR';
      case AppUserRole.teamOwner:
        return 'TEAM OWNER';
      case AppUserRole.player:
        return 'PLAYER';
      case AppUserRole.scorer:
        return 'SCORER';
      case AppUserRole.viewer:
        return 'PUBLIC VIEWER';
    }
  }

  IconData get icon {
    switch (this) {
      case AppUserRole.superAdmin:
        return Icons.admin_panel_settings;
      case AppUserRole.tournamentAdmin:
        return Icons.emoji_events;
      case AppUserRole.auctionAdmin:
        return Icons.tune;
      case AppUserRole.auctioneer:
        return Icons.gavel;
      case AppUserRole.auctionOperator:
        return Icons.manage_accounts;
      case AppUserRole.teamOwner:
        return Icons.business_center;
      case AppUserRole.player:
        return Icons.sports_cricket;
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
      case AppUserRole.auctioneer:
        return const Color(0xFFEA580C); // Orange-Red Gavel
      case AppUserRole.auctionOperator:
        return const Color(0xFF0D9488); // Teal
      case AppUserRole.teamOwner:
        return const Color(0xFF0284C7); // Sky Blue
      case AppUserRole.player:
        return const Color(0xFF10B981); // Emerald
      case AppUserRole.scorer:
        return const Color(0xFF059669); // Green
      case AppUserRole.viewer:
        return const Color(0xFF64748B); // Slate
    }
  }

  String get description {
    switch (this) {
      case AppUserRole.superAdmin:
        return 'Master control: manage all tournaments, users, permissions, and audit logs.';
      case AppUserRole.tournamentAdmin:
        return 'Configure tournaments, player pools, franchise budgets, and officials.';
      case AppUserRole.auctionAdmin:
        return 'Configure auction floor, rules, increments, and WhatsApp notifications.';
      case AppUserRole.auctioneer:
        return 'Sole authority to spin and reveal players, start bidding, and confirm sold/unsold.';
      case AppUserRole.auctionOperator:
        return 'Manage queue, timer, screen displays, and assist the Auctioneer.';
      case AppUserRole.teamOwner:
        return 'Live interactive bidding console with budget protection and squad inspector.';
      case AppUserRole.player:
        return 'Personal player dashboard: registration status, auction outcome, and team details.';
      case AppUserRole.scorer:
        return 'Operate live ball-by-ball matches, coin toss, crease HUD, and scorecards.';
      case AppUserRole.viewer:
        return 'Full broadcast viewer: projector mode, stats, leaderboards, and results.';
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
  final String createdBy;

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
    this.createdBy = 'Official Board',
  });
}

class Team {
  final String id;
  final String tournamentId;
  final String name;
  final String shortName;
  final String uniqueTeamCode; // e.g. "TEAM-BBL-01"
  final String passcode; // e.g. "1234"
  final String ownerMobileNumber; // e.g. "9876543210"
  final String ownerName;
  final Color primaryColor;
  final String logoUrl;
  int purseRemaining;
  final int maxPurse;
  int squadCount;
  final int minSquadRequirement;
  final int maxSquadLimit;

  int get totalSpent => (maxPurse - purseRemaining).clamp(0, maxPurse);
  int get totalPurseBudget => maxPurse;
  int overseasCount;

  Team({
    required this.id,
    this.tournamentId = '',
    required this.name,
    required this.shortName,
    this.uniqueTeamCode = '',
    this.passcode = '1234',
    this.ownerMobileNumber = '',
    this.ownerName = '',
    required this.primaryColor,
    required this.logoUrl,
    required this.purseRemaining,
    required this.maxPurse,
    required this.squadCount,
    this.minSquadRequirement = 15,
    this.maxSquadLimit = 18,
    this.overseasCount = 0,
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

class PlayerTeamHistory {
  final String teamId;
  final String teamName;
  final String? tournamentId;
  final String? tournamentName;
  final int year;
  final DateTime joinedAt;
  final DateTime? leftAt;

  PlayerTeamHistory({
    required this.teamId,
    required this.teamName,
    this.tournamentId,
    this.tournamentName,
    required this.year,
    required this.joinedAt,
    this.leftAt,
  });
}

class PlayerCareerStats {
  final String playerId;
  final int matches;
  final int innings;
  final int runs;
  final int balls;
  final int fours;
  final int sixes;
  final int highestScore;
  final bool isHighestScoreNotOut;
  final int fifties;
  final int hundreds;
  final int notOuts;
  final double battingAverage;
  final double battingStrikeRate;

  final int oversBowledLegalBalls;
  final String oversFormatted; // e.g. "14.2"
  final int maidens;
  final int runsConceded;
  final int wickets;
  final double bowlingAverage;
  final double economyRate;
  final double bowlingStrikeRate;
  final String bestBowlingInnings; // e.g. "4/18"

  final int catches;
  final int runOuts;
  final int stumpings;

  PlayerCareerStats({
    required this.playerId,
    this.matches = 0,
    this.innings = 0,
    this.runs = 0,
    this.balls = 0,
    this.fours = 0,
    this.sixes = 0,
    this.highestScore = 0,
    this.isHighestScoreNotOut = false,
    this.fifties = 0,
    this.hundreds = 0,
    this.notOuts = 0,
    this.battingAverage = 0.0,
    this.battingStrikeRate = 0.0,
    this.oversBowledLegalBalls = 0,
    this.oversFormatted = '0.0',
    this.maidens = 0,
    this.runsConceded = 0,
    this.wickets = 0,
    this.bowlingAverage = 0.0,
    this.economyRate = 0.0,
    this.bowlingStrikeRate = 0.0,
    this.bestBowlingInnings = '0/0',
    this.catches = 0,
    this.runOuts = 0,
    this.stumpings = 0,
  });
}

class PlayerMatchLog {
  final String matchId;
  final String matchName;
  final String? tournamentName;
  final DateTime date;
  final String opponentTeamName;
  final String playerTeamName;
  final int runsScored;
  final int ballsFaced;
  final int fours;
  final int sixes;
  final String dismissalInfo;
  final String oversBowled;
  final int runsConceded;
  final int wicketsTaken;
  final int catches;
  final int runOuts;
  final int stumpings;
  final String matchResult;
  final bool isWin;

  PlayerMatchLog({
    required this.matchId,
    required this.matchName,
    this.tournamentName,
    required this.date,
    required this.opponentTeamName,
    required this.playerTeamName,
    this.runsScored = 0,
    this.ballsFaced = 0,
    this.fours = 0,
    this.sixes = 0,
    this.dismissalInfo = 'not out',
    this.oversBowled = '0.0',
    this.runsConceded = 0,
    this.wicketsTaken = 0,
    this.catches = 0,
    this.runOuts = 0,
    this.stumpings = 0,
    required this.matchResult,
    this.isWin = false,
  });
}

class PlayerLookupResult {
  final bool isFound;
  final Player? player;
  final String normalizedMobile;
  final String? errorMessage;
  final bool isAlreadyInTeam;
  final bool hasTournamentConflict;
  final String? conflictingTeamName;

  PlayerLookupResult({
    required this.isFound,
    this.player,
    required this.normalizedMobile,
    this.errorMessage,
    this.isAlreadyInTeam = false,
    this.hasTournamentConflict = false,
    this.conflictingTeamName,
  });
}

class Player {
  final String id;
  final String permanentPlayerCode; // e.g. "PLY-2026-0001"
  final String tournamentId;
  final String fullName;
  final String displayName;
  final String mobileNumber;
  final int age;
  final String dateOfBirth;
  final String city;
  final PlayerRole role;
  final String battingStyle;
  final String bowlingStyle;
  final int experienceYears;
  final String category; // 'Marquee', 'Batsman', 'Bowler', 'All-Rounder', 'Wicketkeeper', 'Emerging'
  final int basePrice;
  final String photoUrl;
  PlayerRegistrationStatus registrationStatus;
  PlayerAuctionStatus auctionStatus;
  String? teamId;
  String? get soldTeamId => teamId;
  set soldTeamId(String? val) => teamId = val;
  int? soldPrice;
  int? soldRound;
  DateTime? soldTimestamp;
  final bool isOverseas;
  int runs;
  int wickets;
  int matches;
  final DateTime? registeredAt;
  final String? registeredByOrganizerId;
  bool isMobileVerified;
  List<PlayerTeamHistory> teamHistory;

  Player({
    required this.id,
    String? permanentPlayerCode,
    this.tournamentId = '',
    required this.fullName,
    required this.displayName,
    this.mobileNumber = '',
    this.age = 24,
    this.dateOfBirth = '2000-01-01',
    this.city = 'Kolkata',
    required this.role,
    this.battingStyle = 'Right Hand Bat',
    this.bowlingStyle = 'Right Arm Medium',
    this.experienceYears = 3,
    this.category = 'Batsman',
    this.basePrice = 500,
    this.photoUrl = 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=256',
    this.registrationStatus = PlayerRegistrationStatus.approved,
    this.auctionStatus = PlayerAuctionStatus.available,
    this.teamId,
    this.soldPrice,
    this.soldRound,
    this.soldTimestamp,
    this.isOverseas = false,
    this.runs = 0,
    this.wickets = 0,
    this.matches = 0,
    this.registeredAt,
    this.registeredByOrganizerId,
    this.isMobileVerified = false,
    List<PlayerTeamHistory>? teamHistory,
  })  : permanentPlayerCode = permanentPlayerCode ?? (id.startsWith('pl_') ? 'PLY-2026-${id.hashCode.abs().toString().padLeft(4, '0').substring(0, 4)}' : id),
        teamHistory = teamHistory ?? [];

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

  bool get isSold => auctionStatus == PlayerAuctionStatus.sold && teamId != null;
  bool get isAvailable => auctionStatus == PlayerAuctionStatus.available && registrationStatus == PlayerRegistrationStatus.approved;
  bool get isInAuction => auctionStatus == PlayerAuctionStatus.inAuction;
  bool get isUnsold => auctionStatus == PlayerAuctionStatus.unsold;
}

class MatchModel {
  final String id;
  final String tournamentId;
  final String stage;
  final String teamAId;
  final String teamBId;
  final String venue;
  final DateTime dateTime;
  int overs;
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
  String? playerOfTheMatchId;
  String? playerOfTheMatchName;
  bool isLocked;

  bool get isStandalone =>
      tournamentId.isEmpty || tournamentId == 'standalone' || tournamentId == 'direct';

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
    this.playerOfTheMatchId,
    this.playerOfTheMatchName,
    this.isLocked = false,
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

  bool get isNotOut => !isOut;
  String get dismissalInfo => dismissalText;
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

  String get overs => oversStr;

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

enum AuctionJoiningMode {
  automatic,
  hostApproval;

  String get label {
    switch (this) {
      case AuctionJoiningMode.automatic:
        return 'Automatic (Instant Entry)';
      case AuctionJoiningMode.hostApproval:
        return 'Host Approval Required';
    }
  }
}

class PendingTeamRegistration {
  final String id;
  final String auctionId;
  final String tournamentId;
  final String userId;
  final String ownerName;
  final String ownerEmail;
  final String ownerMobile;
  final String teamName;
  final String teamShortName;
  final String logoUrl;
  final Color primaryColor;
  final DateTime registeredAt;
  bool isApproved;
  bool isRejected;

  PendingTeamRegistration({
    required this.id,
    required this.auctionId,
    required this.tournamentId,
    required this.userId,
    required this.ownerName,
    required this.ownerEmail,
    required this.ownerMobile,
    required this.teamName,
    required this.teamShortName,
    required this.logoUrl,
    required this.primaryColor,
    required this.registeredAt,
    this.isApproved = false,
    this.isRejected = false,
  });
}

class UserAccount {
  final String id;
  String fullName;
  String email;
  String mobileNumber;
  final String passwordHash;
  final DateTime createdAt;
  final Map<String, AppUserRole> tournamentRoles;
  final List<String> ownedTeamIds;
  final List<String> conductorAuctionIds;
  final List<String> scorerMatchIds;
  bool isMobileVerified;
  String? linkedPlayerId;
  bool isGoogleAuthEnabled;
  String? googleAuthSecret;
  List<String> googleAuthRecoveryCodes;
  DateTime? googleAuthEnabledAt;
  bool isGoogleOAuthUser;

  UserAccount({
    required this.id,
    required this.fullName,
    required this.email,
    required this.mobileNumber,
    required this.passwordHash,
    required this.createdAt,
    Map<String, AppUserRole>? tournamentRoles,
    List<String>? ownedTeamIds,
    List<String>? conductorAuctionIds,
    List<String>? scorerMatchIds,
    this.isMobileVerified = false,
    this.linkedPlayerId,
    this.isGoogleAuthEnabled = false,
    this.googleAuthSecret,
    List<String>? googleAuthRecoveryCodes,
    this.googleAuthEnabledAt,
    this.isGoogleOAuthUser = false,
  })  : tournamentRoles = tournamentRoles ?? {},
        ownedTeamIds = ownedTeamIds ?? [],
        conductorAuctionIds = conductorAuctionIds ?? [],
        scorerMatchIds = scorerMatchIds ?? [],
        googleAuthRecoveryCodes = googleAuthRecoveryCodes ?? [];

  bool isHostOf(String tournamentId) =>
      tournamentRoles[tournamentId] == AppUserRole.tournamentAdmin ||
      tournamentRoles[tournamentId] == AppUserRole.superAdmin;

  bool isConductorOf(String auctionId) => conductorAuctionIds.contains(auctionId);
  bool isScorerOf(String matchId) => scorerMatchIds.contains(matchId);

  /// Returns true if the user has a verified 10-digit mobile number saved in the database
  bool get hasVerifiedMobile => isMobileVerified && mobileNumber.trim().isNotEmpty;

  /// Returns true if the user has BOTH a valid Gmail/email and a verified mobile number
  bool get isProfileComplete =>
      (hasVerifiedMobile || isGoogleOAuthUser) &&
      email.trim().contains('@') &&
      email.trim().contains('.');
}

class JoinAuctionValidationResult {
  final bool isValid;
  final String? errorMessage;
  final Auction? auction;
  final Tournament? tournament;

  JoinAuctionValidationResult({
    required this.isValid,
    this.errorMessage,
    this.auction,
    this.tournament,
  });
}

class Auction {
  final String id;
  final String tournamentId;
  final String title;
  String get name => title;
  final String auctionCode;
  String auctionPin;
  bool isJoiningEnabled;
  AuctionJoiningMode joiningMode;
  final List<PendingTeamRegistration> pendingRegistrations;
  final String hostUserId;
  final bool isPursePublic;
  final List<String> committeeUserIds;
  int gavelWarningCount;
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
  bool isBiddingActive;

  // Role Assignments
  final String assignedAuctioneerId;
  final String assignedAuctioneerName;
  final List<String> assignedOperatorIds;

  // Tournament & Round Configuration
  int currentRound;
  final int totalRounds;
  final int minSquadSize;
  final int maxSquadSize;
  final int maxOverseasPlayers;
  final bool allowUnsoldReEntry;
  final int basePrice;
  final List<int> bidIncrements;

  // WhatsApp Integration Settings
  final bool whatsappEnabled;
  final String whatsappPhoneNumberId;
  final String whatsappAccessToken;
  final String whatsappTemplateName;
  final String whatsappOrganizingCommittee;

  Auction({
    required this.id,
    required this.tournamentId,
    required this.title,
    String? auctionCode,
    this.auctionPin = '583921',
    this.isJoiningEnabled = true,
    this.joiningMode = AuctionJoiningMode.automatic,
    List<PendingTeamRegistration>? pendingRegistrations,
    this.hostUserId = 'user_admin_01',
    this.isPursePublic = true,
    List<String>? committeeUserIds,
    this.status = AuctionStatus.live,
    this.floorStatus = FloorStatus.open,
    this.gavelWarningCount = 0,
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
    this.isBiddingActive = false,
    this.assignedAuctioneerId = 'auctioneer_01',
    this.assignedAuctioneerName = 'Official Auctioneer (Gavel Master)',
    List<String>? assignedOperatorIds,
    this.currentRound = 1,
    this.totalRounds = 3,
    this.minSquadSize = 15,
    this.maxSquadSize = 18,
    this.maxOverseasPlayers = 4,
    this.allowUnsoldReEntry = true,
    this.basePrice = 25000,
    List<int>? bidIncrements,
    this.whatsappEnabled = true,
    this.whatsappPhoneNumberId = 'WHATSAPP-CRIC-CLOUD-01',
    this.whatsappAccessToken = 'CRIC_WHATSAPP_TOKEN_SECURE',
    this.whatsappTemplateName = 'cricket_auction_player_sold_v1',
    this.whatsappOrganizingCommittee = 'CricPavilion Organizing Committee',
  })  : auctionCode = auctionCode ?? 'AUC-${id.replaceAll("auc_", "").replaceAll("-", "").toUpperCase().padRight(4, "0").substring(0, 4)}-${id.hashCode.abs() % 9000 + 1000}',
        pendingRegistrations = pendingRegistrations ?? [],
        committeeUserIds = committeeUserIds ?? [],
        joinedTeamIds = joinedTeamIds ?? {},
        assignedOperatorIds = assignedOperatorIds ?? ['operator_01'],
        bidIncrements = bidIncrements ?? [10000, 25000, 50000, 100000, 250000];

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
  int round;
  int? soldPrice;
  DateTime? soldTimestamp;

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
    this.round = 1,
    this.soldPrice,
    this.soldTimestamp,
  });
}

class AuctionBid {
  final String id;
  final String lotId;
  final String teamId;
  final String teamName;
  final int amount;
  final DateTime timestamp;
  final String auctionId;
  final String playerId;
  final int round;
  final bool isValid;
  final String? rejectionReason;

  AuctionBid({
    required this.id,
    required this.lotId,
    required this.teamId,
    required this.teamName,
    required this.amount,
    required this.timestamp,
    this.auctionId = '',
    this.playerId = '',
    this.round = 1,
    this.isValid = true,
    this.rejectionReason,
  });
}

class AuctionTransactionType {
  static const String purchase = 'PURCHASE';
  static const String reversal = 'REVERSAL';
  static const String adjustment = 'ADJUSTMENT';
}

class AuctionTransaction {
  final String id;
  final String tournamentId;
  final String auctionId;
  final String lotId;
  final String playerId;
  final String playerName;
  final String teamId;
  final String teamName;
  final int amount;
  final int round;
  final String type; // 'PURCHASE', 'REVERSAL', 'ADJUSTMENT'
  final DateTime timestamp;
  final String performedBy;
  final String? notes;

  AuctionTransaction({
    required this.id,
    this.tournamentId = '',
    required this.auctionId,
    required this.lotId,
    required this.playerId,
    this.playerName = '',
    required this.teamId,
    this.teamName = '',
    required this.amount,
    required this.round,
    required this.type,
    required this.timestamp,
    this.performedBy = 'Auctioneer',
    this.notes,
  });
}

enum WhatsAppNotificationStatus {
  queued,
  sent,
  delivered,
  failed;

  String get label {
    switch (this) {
      case WhatsAppNotificationStatus.queued:
        return 'Queued';
      case WhatsAppNotificationStatus.sent:
        return 'Sent';
      case WhatsAppNotificationStatus.delivered:
        return 'Delivered';
      case WhatsAppNotificationStatus.failed:
        return 'Failed';
    }
  }

  Color get color {
    switch (this) {
      case WhatsAppNotificationStatus.queued:
        return const Color(0xFFF59E0B);
      case WhatsAppNotificationStatus.sent:
        return const Color(0xFF38BDF8);
      case WhatsAppNotificationStatus.delivered:
        return const Color(0xFF10B981);
      case WhatsAppNotificationStatus.failed:
        return const Color(0xFFEF4444);
    }
  }
}

class WhatsAppNotification {
  final String id;
  final String tournamentId;
  final String auctionId;
  final String playerId;
  final String playerName;
  final String recipientMobile;
  final String messageType; // 'SOLD', 'UNSOLD', 'REGISTRATION', 'REMINDER'
  final String messageBody;
  WhatsAppNotificationStatus status;
  final DateTime timestamp;
  DateTime? deliveredTimestamp;
  String? errorMessage;
  final String? responseId;

  String get recipientName => playerName;
  String get messageContent => messageBody;
  DateTime? get sentTimestamp => deliveredTimestamp;
  set sentTimestamp(DateTime? val) => deliveredTimestamp = val;

  WhatsAppNotification({
    required this.id,
    this.tournamentId = '',
    required this.auctionId,
    required this.playerId,
    String? playerName,
    String? recipientName,
    required this.recipientMobile,
    this.messageType = 'SOLD',
    String? messageBody,
    String? messageContent,
    this.status = WhatsAppNotificationStatus.queued,
    required this.timestamp,
    this.deliveredTimestamp,
    this.errorMessage,
    this.responseId,
  })  : playerName = playerName ?? recipientName ?? '',
        messageBody = messageBody ?? messageContent ?? '';
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
  final String tournamentId;
  final String auctionId;
  final String role;

  AuditLog({
    required this.id,
    required this.timestamp,
    required this.category,
    required this.action,
    required this.details,
    required this.performedBy,
    this.tournamentId = '',
    this.auctionId = '',
    this.role = '',
  });
}

class TournamentLeaderboardBatter {
  final String playerId;
  final String playerName;
  final String teamName;
  final String teamShortName;
  final Color teamColor;
  final String photoUrl;
  final int matches;
  final int innings;
  final int runs;
  final int balls;
  final int fours;
  final int sixes;
  final double strikeRate;
  final double average;
  final int highScore;
  final int fifties;
  final int hundreds;

  TournamentLeaderboardBatter({
    required this.playerId,
    required this.playerName,
    required this.teamName,
    required this.teamShortName,
    required this.teamColor,
    required this.photoUrl,
    required this.matches,
    required this.innings,
    required this.runs,
    required this.balls,
    required this.fours,
    required this.sixes,
    required this.strikeRate,
    required this.average,
    required this.highScore,
    required this.fifties,
    required this.hundreds,
  });
}

class TournamentLeaderboardBowler {
  final String playerId;
  final String playerName;
  final String teamName;
  final String teamShortName;
  final Color teamColor;
  final String photoUrl;
  final int matches;
  final String oversStr;
  final int legalBalls;
  final int maidens;
  final int runsConceded;
  final int wickets;
  final double economy;
  final double average;
  final String bestBowling;

  TournamentLeaderboardBowler({
    required this.playerId,
    required this.playerName,
    required this.teamName,
    required this.teamShortName,
    required this.teamColor,
    required this.photoUrl,
    required this.matches,
    required this.oversStr,
    required this.legalBalls,
    required this.maidens,
    required this.runsConceded,
    required this.wickets,
    required this.economy,
    required this.average,
    required this.bestBowling,
  });
}

class TournamentLeaderboardFielder {
  final String playerId;
  final String playerName;
  final String teamName;
  final String teamShortName;
  final String photoUrl;
  final int matches;
  final int catches;
  final int stumpings;
  final int runOuts;
  final int totalDismissals;

  TournamentLeaderboardFielder({
    required this.playerId,
    required this.playerName,
    required this.teamName,
    required this.teamShortName,
    required this.photoUrl,
    required this.matches,
    required this.catches,
    required this.stumpings,
    required this.runOuts,
    required this.totalDismissals,
  });
}

class TournamentBoundaryLeader {
  final String playerId;
  final String playerName;
  final String teamName;
  final String teamShortName;
  final String photoUrl;
  final int fours;
  final int sixes;
  final int totalBoundaries;
  final int boundaryRuns;

  TournamentBoundaryLeader({
    required this.playerId,
    required this.playerName,
    required this.teamName,
    required this.teamShortName,
    required this.photoUrl,
    required this.fours,
    required this.sixes,
    required this.totalBoundaries,
    required this.boundaryRuns,
  });
}

class TournamentMVP {
  final String playerId;
  final String playerName;
  final String teamName;
  final String teamShortName;
  final String roleString;
  final String photoUrl;
  final double points;
  final int runs;
  final int wickets;
  final int catches;

  TournamentMVP({
    required this.playerId,
    required this.playerName,
    required this.teamName,
    required this.teamShortName,
    required this.roleString,
    required this.photoUrl,
    required this.points,
    required this.runs,
    required this.wickets,
    required this.catches,
  });
}


