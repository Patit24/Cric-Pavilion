import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/mock_database.dart';
import '../../services/cricket_rules_engine.dart';
import '../../theme/neo_glass_theme.dart';
import 'crease_hud_widget.dart';
import 'over_complete_dialog.dart';
import 'wicket_dialog.dart';
import 'toss_wizard_sheet.dart';
import 'full_scorecard_dialog.dart';
import '../tournaments/create_tournament_dialog.dart';
import '../tournaments/tournament_hub_screen.dart';
import 'fill_team_squad_dialog.dart';
import '../matches/create_direct_match_dialog.dart';
import '../../widgets/auth_modal_dialog.dart';
import '../../widgets/cloud_sync_dialog.dart';
import 'extras_scoring_sheet.dart';
import 'start_innings2_dialog.dart';
import 'retire_batter_dialog.dart';

class ScorerScreen extends StatefulWidget {
  final String? initialMatchId;

  const ScorerScreen({super.key, this.initialMatchId});

  @override
  State<ScorerScreen> createState() => _ScorerScreenState();
}

class _ScorerScreenState extends State<ScorerScreen> {
  late String selectedMatchId;
  int selectedInningsNum = 1;

  @override
  void initState() {
    super.initState();
    selectedMatchId = widget.initialMatchId ?? 'match_1';
  }

  @override
  Widget build(BuildContext context) {
    final db = context.watch<MockDatabase>();

    if (db.matches.isEmpty) {
      return Scaffold(
        backgroundColor: NeoGlassTheme.bgCanvas,
        appBar: AppBar(
          backgroundColor: NeoGlassTheme.bgSurface,
          elevation: 0,
          shape: const Border(bottom: BorderSide(color: Color(0x18FFFFFF))),
          title: const Text('Live Scorer Console', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: GlassTokens.inkPrimary)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.sports_cricket, size: 54, color: Color(0xFF009270)),
                const SizedBox(height: 16),
                const Text('No Matches Scheduled', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text(
                  'Organize a tournament to schedule matches, conduct toss, and score live ball-by-ball.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: GlassTokens.inkSecondary, fontSize: 12),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => CreateTournamentDialog(db: db),
                    );
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Create Tournament'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF009270),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final match = db.matches.where((m) => m.id == selectedMatchId).firstOrNull ?? db.matches.first;

    final isScorer = db.isAuthenticated && db.isScoringUnlockedForMatch(match.id);
    final currentRoom = db.getScoringRoomForMatch(match.id);

    final teamA = db.getTeam(match.teamAId) ?? MockDatabase.emptyTeam;
    final teamB = db.getTeam(match.teamBId) ?? MockDatabase.emptyTeam;

    final matchInnings = db.inningsList.where((i) => i.matchId == match.id).toList();
    final inn1 = matchInnings.where((i) => i.inningsNumber == 1).firstOrNull;
    final inn2 = matchInnings.where((i) => i.inningsNumber == 2).firstOrNull;

    // Auto-advance selectedInningsNum if Innings 1 is completed and Innings 2 is active
    if (match.currentInningsNumber == 2 && inn2 != null && !inn2.isCompleted && selectedInningsNum == 1 && (inn1?.isCompleted ?? false)) {
      selectedInningsNum = 2;
    }

    // Track active innings
    final currentInnings = (selectedInningsNum == 2 && inn2 != null) ? inn2 : (inn1 ?? matchInnings.firstOrNull);

    final isPreMatch = match.status == MatchStatus.scheduled || match.status == MatchStatus.toss || inn1 == null;
    final isMatchCompleted = match.status == MatchStatus.completed;

    // Roster players safely
    final teamAPlayers = db.players.where((p) => match.playingXIA.contains(p.id) || p.teamId == teamA.id).toList();
    final teamBPlayers = db.players.where((p) => match.playingXIB.contains(p.id) || p.teamId == teamB.id).toList();
    final safeTeamAPlayers = teamAPlayers;
    final safeTeamBPlayers = teamBPlayers;

    // Batting & Bowling Teams for active innings
    final battingTeamId = currentInnings?.battingTeamId ?? match.battingFirstId ?? teamA.id;
    final battingTeamPlayers = battingTeamId == teamA.id ? safeTeamAPlayers : safeTeamBPlayers;
    final bowlingTeamPlayers = battingTeamId == teamA.id ? safeTeamBPlayers : safeTeamAPlayers;

    // Crease Players
    final striker = db.players.where((p) => p.id == currentInnings?.currentStrikerId).firstOrNull ?? battingTeamPlayers.firstOrNull;
    final nonStriker = db.players.where((p) => p.id == currentInnings?.currentNonStrikerId).firstOrNull ?? (battingTeamPlayers.length > 1 ? battingTeamPlayers[1] : null);
    final bowler = db.players.where((p) => p.id == currentInnings?.currentBowlerId).firstOrNull ??
        bowlingTeamPlayers.where((p) => p.role == PlayerRole.bowler).firstOrNull ??
        bowlingTeamPlayers.firstOrNull;

    if (currentInnings != null) {
      if (currentInnings.currentStrikerId == null && striker != null) {
        currentInnings.currentStrikerId = striker.id;
      }
      if (currentInnings.currentNonStrikerId == null && nonStriker != null) {
        currentInnings.currentNonStrikerId = nonStriker.id;
      }
      if (currentInnings.currentBowlerId == null && bowler != null) {
        currentInnings.currentBowlerId = bowler.id;
      }
    }

    // Crease Scorecards
    final strikerCard = db.battingScorecards.where((b) => b.inningsId == currentInnings?.id && b.playerId == striker?.id).firstOrNull ??
        BattingScorecard(id: 'temp_str', inningsId: currentInnings?.id ?? '', matchId: match.id, playerId: striker?.id ?? '', playerName: striker?.fullName ?? '');

    final nonStrikerCard = db.battingScorecards.where((b) => b.inningsId == currentInnings?.id && b.playerId == nonStriker?.id).firstOrNull ??
        BattingScorecard(id: 'temp_non', inningsId: currentInnings?.id ?? '', matchId: match.id, playerId: nonStriker?.id ?? '', playerName: nonStriker?.fullName ?? '');

    final bowlerCard = db.bowlingScorecards.where((b) => b.inningsId == currentInnings?.id && b.playerId == bowler?.id).firstOrNull ??
        BowlingScorecard(id: 'temp_bowl', inningsId: currentInnings?.id ?? '', matchId: match.id, playerId: bowler?.id ?? '', playerName: bowler?.fullName ?? '');

    final bool isStandaloneMatch = match.tournamentId == 'standalone' || match.isStandalone;
    final bool areTeamsReady = isStandaloneMatch
        ? (safeTeamAPlayers.isNotEmpty && safeTeamBPlayers.isNotEmpty)
        : db.areTeamsReadyForScoring(match.teamAId, match.teamBId, match: match);

    return Scaffold(
      backgroundColor: GlassTokens.bgIcyWhite,
      appBar: AppBar(
        backgroundColor: GlassTokens.glassFillHigh,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: GlassTokens.inkPrimary),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: GlassTokens.glassHairline),
        ),
        titleSpacing: 8,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.42),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedMatchId,
                  isExpanded: true,
                  isDense: true,
                  dropdownColor: Colors.white,
                  icon: const Icon(Icons.keyboard_arrow_down, color: GlassTokens.mintGreen, size: 18),
                  style: const TextStyle(color: GlassTokens.inkPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                  items: db.matches.map((m) {
                    return DropdownMenuItem<String>(
                      value: m.id,
                      child: Text(
                        '${m.stage} (${m.status.name.toUpperCase()})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        selectedMatchId = val;
                        final newMatch = db.matches.where((m) => m.id == val).firstOrNull;
                        if (newMatch != null) {
                          selectedInningsNum = newMatch.currentInningsNumber;
                        }
                      });
                    }
                  },
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isScorer ? Icons.check_circle : Icons.lock_outline,
                  size: 11,
                  color: isScorer ? GlassTokens.mintGreen : const Color(0xFFB45309),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    isScorer
                        ? 'Scorer: ${currentRoom?.id ?? "ROOM-01"}'
                        : 'Spectator Mode',
                    style: TextStyle(
                      color: isScorer ? GlassTokens.mintGreen : const Color(0xFFB45309),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Multi-Device Cloud Sync
          IconButton(
            tooltip: 'Sync with Mobile / Central Server',
            icon: const Icon(Icons.cloud_sync, color: GlassTokens.electricBlue, size: 20),
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () => CloudSyncDialog.show(context),
          ),
          IconButton(
            tooltip: 'Team Squads & Mobile Numbers',
            icon: const Icon(Icons.people_alt, color: GlassTokens.inkSecondary, size: 18),
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => FillTeamSquadDialog(
                  match: match,
                  db: db,
                  onSquadsSaved: () => setState(() {}),
                ),
              );
            },
          ),
          // Overflow-proof Secondary Actions Popup Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: GlassTokens.inkPrimary, size: 20),
            tooltip: 'Match Options',
            color: GlassTokens.bgLightBlue,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) {
              switch (value) {
                case 'cloud_sync':
                  CloudSyncDialog.show(context);
                  break;
                case 'scorecard':
                  showDialog(
                    context: context,
                    builder: (ctx) => FullScorecardDialog(match: match, db: db),
                  );
                  break;
                case 'tournament':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => TournamentHubScreen(initialTournamentId: match.tournamentId),
                    ),
                  );
                  break;
                case 'enter_scorer':
                  if (!db.isAuthenticated) {
                    showDialog(
                      context: context,
                      builder: (ctx) => AuthModalDialog(
                        initialActionPrompt: 'Login Required: Please sign in or register to enter scoring room.',
                        onAuthSuccess: () => setState(() {}),
                      ),
                    );
                    break;
                  }
                  _showEnterRoomDialog(context, db, match);
                  break;
                case 'exit_scorer':
                  db.lockScoringRoom(match.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Locked scoring console. Returned to Spectator Mode.')),
                  );
                  break;
                case 'end_inn1_early':
                  _confirmEndInnings1Early(context, db, match, inn1, safeTeamAPlayers, safeTeamBPlayers);
                  break;
                case 'retire_batter':
                  if (currentInnings != null) {
                    _showRetireBatterDialog(
                      context: context,
                      db: db,
                      inn: currentInnings,
                      striker: striker,
                      nonStriker: nonStriker,
                      battingTeamPlayers: battingTeamPlayers,
                    );
                  }
                  break;
                case 'reset_match':
                  _confirmResetMatch(context, db, match);
                  break;
                case 'create_quick_match':
                  if (!db.isAuthenticated) {
                    showDialog(
                      context: context,
                      builder: (ctx) => AuthModalDialog(
                        initialActionPrompt: 'Login Required: Please sign in or register to score friendly matches.',
                        onAuthSuccess: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => CreateDirectMatchDialog(db: db),
                          );
                        },
                      ),
                    );
                    break;
                  }
                  showDialog(
                    context: context,
                    builder: (ctx) => CreateDirectMatchDialog(db: db),
                  );
                  break;
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'create_quick_match',
                child: Row(
                  children: [
                    Icon(Icons.flash_on, color: Color(0xFF00F5A0), size: 17),
                    SizedBox(width: 10),
                    Text('Create Another Quick Match', style: TextStyle(color: Color(0xFF00F5A0), fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'scorecard',
                child: Row(
                  children: [
                    Icon(Icons.table_chart, color: GlassTokens.inkSecondary, size: 17),
                    SizedBox(width: 10),
                    Text('Full Scorecard', style: TextStyle(color: GlassTokens.inkPrimary, fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'tournament',
                child: Row(
                  children: [
                    Icon(Icons.emoji_events, color: Color(0xFFD97706), size: 17),
                    SizedBox(width: 10),
                    Text('Tournament Hub', style: TextStyle(color: GlassTokens.inkPrimary, fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'cloud_sync',
                child: Row(
                  children: [
                    Icon(Icons.cloud_sync, color: Color(0xFF00F5A0), size: 17),
                    SizedBox(width: 10),
                    Text('Cloud Sync (Mobile & Desktop)', style: TextStyle(color: GlassTokens.inkPrimary, fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuDivider(height: 8),
              if (!isScorer)
                const PopupMenuItem(
                  value: 'enter_scorer',
                  child: Row(
                    children: [
                      Icon(Icons.vpn_key, color: Color(0xFF34D399), size: 17),
                      SizedBox(width: 10),
                      Text('Enter Scorer Mode', style: TextStyle(color: Color(0xFF34D399), fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              else ...[
                if (inn2 == null && currentInnings?.inningsNumber == 1)
                  const PopupMenuItem(
                    value: 'end_inn1_early',
                    child: Row(
                      children: [
                        Icon(Icons.flag_circle, color: Color(0xFF34D399), size: 17),
                        SizedBox(width: 10),
                        Text('End Innings 1 & Start Chase', style: TextStyle(color: Color(0xFF34D399), fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                if (currentInnings != null && !currentInnings.isCompleted)
                  const PopupMenuItem(
                    value: 'retire_batter',
                    child: Row(
                      children: [
                        Icon(Icons.medical_services_outlined, color: Colors.orangeAccent, size: 17),
                        SizedBox(width: 10),
                        Text('Retire Batter (Hurt / Out)', style: TextStyle(color: Colors.orangeAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'reset_match',
                  child: Row(
                    children: [
                      Icon(Icons.refresh, color: Color(0xFFD97706), size: 17),
                      SizedBox(width: 10),
                      Text('Reset Match', style: TextStyle(color: GlassTokens.inkPrimary, fontSize: 13)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'exit_scorer',
                  child: Row(
                    children: [
                      Icon(Icons.lock, color: Colors.redAccent, size: 17),
                      SizedBox(width: 10),
                      Text('Exit Scorer Mode', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: !areTeamsReady
          ? _buildMissingSquadScreen(context, db, match, teamA, teamB)
          : isPreMatch
              ? _buildPreMatchTossView(context, db, match, teamA, teamB, safeTeamAPlayers, safeTeamBPlayers, isScorer, currentRoom)
              : isMatchCompleted
                  ? _buildCompletedMatchView(context, db, match, inn1, inn2, isScorer)
                  : _buildLiveScoringView(
                      context,
                      db,
                      match,
                      currentInnings!,
                      inn1,
                      inn2,
                      striker,
                      nonStriker,
                      bowler,
                      strikerCard,
                      nonStrikerCard,
                      bowlerCard,
                      battingTeamPlayers,
                      bowlingTeamPlayers,
                      isScorer,
                      currentRoom,
                      safeTeamAPlayers,
                      safeTeamBPlayers,
                    ),
    );
  }

  // ==========================================
  // REQUIRED SQUAD & MOBILE NUMBERS BARRIER
  // ==========================================
  Widget _buildMissingSquadScreen(
    BuildContext context,
    MockDatabase db,
    MatchModel match,
    Team teamA,
    Team teamB,
  ) {
    final playersA = db.players.where((p) => match.playingXIA.contains(p.id) || p.teamId == teamA.id).toList();
    final playersB = db.players.where((p) => match.playingXIB.contains(p.id) || p.teamId == teamB.id).toList();
    final playersAWithMobile = playersA.where((p) => p.mobileNumber.trim().isNotEmpty && p.fullName.trim().isNotEmpty).toList();
    final playersBWithMobile = playersB.where((p) => p.mobileNumber.trim().isNotEmpty && p.fullName.trim().isNotEmpty).toList();

    final isAReady = playersA.length >= 2 && playersAWithMobile.length == playersA.length;
    final isBReady = playersB.length >= 2 && playersBWithMobile.length == playersB.length;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [GlassTokens.bgLightBlue, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.6)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Alert Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.phonelink_lock, size: 14, color: Colors.amber),
                          SizedBox(width: 6),
                          Text(
                            'SQUAD REGISTRATION REQUIRED',
                            style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Fill Players with Mobile Numbers to Start Scoring',
                  style: TextStyle(color: GlassTokens.inkPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Tournament rules require both teams to enter all playing squad names along with their contact mobile numbers before ball-by-ball scoring can begin.',
                  style: TextStyle(color: GlassTokens.inkSecondary, fontSize: 11.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Team A Status Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: GlassTokens.bgLightBlue,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isAReady ? const Color(0xFF059669) : Colors.redAccent.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(radius: 14, backgroundImage: NetworkImage(teamA.logoUrl)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(teamA.name, style: const TextStyle(color: GlassTokens.inkPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                            Text(
                              '${playersA.length} Players (${playersAWithMobile.length} with mobile)',
                              style: TextStyle(color: isAReady ? const Color(0xFF34D399) : GlassTokens.inkSecondary, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isAReady ? const Color(0xFF059669).withValues(alpha: 0.2) : Colors.redAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: isAReady ? const Color(0xFF34D399) : Colors.redAccent),
                        ),
                        child: Text(
                          isAReady ? '✓ Ready' : 'Incomplete',
                          style: TextStyle(
                            color: isAReady ? const Color(0xFF34D399) : Colors.redAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Team B Status Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: GlassTokens.bgLightBlue,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isBReady ? const Color(0xFF059669) : Colors.redAccent.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(radius: 14, backgroundImage: NetworkImage(teamB.logoUrl)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(teamB.name, style: const TextStyle(color: GlassTokens.inkPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                            Text(
                              '${playersB.length} Players (${playersBWithMobile.length} with mobile)',
                              style: TextStyle(color: isBReady ? const Color(0xFF34D399) : GlassTokens.inkSecondary, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isBReady ? const Color(0xFF059669).withValues(alpha: 0.2) : Colors.redAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: isBReady ? const Color(0xFF34D399) : Colors.redAccent),
                        ),
                        child: Text(
                          isBReady ? '✓ Ready' : 'Incomplete',
                          style: TextStyle(
                            color: isBReady ? const Color(0xFF34D399) : Colors.redAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Primary Action Button: Fill Players Now
                ElevatedButton.icon(
                  onPressed: () {
                    if (!db.isAuthenticated) {
                      showDialog(
                        context: context,
                        builder: (ctx) => AuthModalDialog(
                          initialActionPrompt: 'Login Required: Please sign in or register to manage squads and score matches.',
                          onAuthSuccess: () => setState(() {}),
                        ),
                      );
                      return;
                    }
                    showDialog(
                      context: context,
                      builder: (ctx) => FillTeamSquadDialog(
                        match: match,
                        db: db,
                        onSquadsSaved: () => setState(() {}),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_note, size: 18),
                  label: const Text('Fill Players & Mobile Numbers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF009270),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // PRE-MATCH TOSS VIEW
  // ==========================================
  Widget _buildPreMatchTossView(
    BuildContext context,
    MockDatabase db,
    MatchModel match,
    Team teamA,
    Team teamB,
    List<Player> teamAPlayers,
    List<Player> teamBPlayers,
    bool isScorer,
    ScoringRoom? currentRoom,
  ) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF064E3B),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF34D399), width: 2),
              ),
              child: const Icon(Icons.sports_cricket, size: 48, color: GlassTokens.inkPrimary),
            ),
            const SizedBox(height: 20),
            Text(
              match.stage,
              style: const TextStyle(color: GlassTokens.inkPrimary, fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              '${teamA.name} vs ${teamB.name}',
              style: const TextStyle(color: GlassTokens.inkSecondary, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '${match.venue} • ${match.overs} Overs T20',
              style: const TextStyle(color: GlassTokens.inkMuted, fontSize: 12),
            ),
            const SizedBox(height: 28),

            if (isScorer) ...[
              // OFFICIAL SCORER UNLOCKED BUTTON
              ElevatedButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) => TossWizardSheet(
                      match: match,
                      teamA: teamA,
                      teamB: teamB,
                      teamAPlayers: teamAPlayers,
                      teamBPlayers: teamBPlayers,
                      onStartMatch: ({
                        required tossWonBy,
                        required tossDecision,
                        required strikerId,
                        required nonStrikerId,
                        required bowlerId,
                      }) {
                        db.startMatchWithToss(
                          matchId: match.id,
                          tossWonBy: tossWonBy,
                          tossDecision: tossDecision,
                          strikerId: strikerId,
                          nonStrikerId: nonStrikerId,
                          bowlerId: bowlerId,
                        );
                        setState(() => selectedInningsNum = 1);
                      },
                    ),
                  );
                },
                icon: const Icon(Icons.monetization_on, color: Colors.black),
                label: const Text('CONDUCT COIN TOSS & START MATCH', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF34D399),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ] else if (!db.isAuthenticated) ...[
              // LOGIN REQUIRED TO SCORE BANNER
              _buildLoginRequiredToScoreBanner(context, db),
            ] else ...[
              // SPECTATOR LOCKED BANNER
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: GlassTokens.bgLightBlue,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.lock, color: Colors.amber, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Scoring Room Protected',
                          style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Toss and lineup setup require official room credentials. Normal spectators can follow live ball-by-ball once the match commences.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: GlassTokens.inkSecondary, fontSize: 11),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showEnterRoomDialog(context, db, match),
                            icon: const Icon(Icons.vpn_key, size: 14),
                            label: const Text('Enter Scoring Room', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF34D399),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showCreateRoomDialog(context, db, match),
                            icon: const Icon(Icons.add_circle_outline, size: 14),
                            label: const Text('Create Room', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: GlassTokens.inkMuted),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoginRequiredToScoreBanner(BuildContext context, MockDatabase db) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: GlassTokens.bgLightBlue,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF00F5A0).withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00F5A0).withValues(alpha: 0.08),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF00F5A0).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_outline, color: Color(0xFF00F5A0), size: 28),
          ),
          const SizedBox(height: 12),
          const Text(
            'Login Required to Score Matches',
            style: TextStyle(color: GlassTokens.inkPrimary, fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Match scoring, coin toss, and official ball-by-ball records require an authenticated user account. Please log in or register to begin live scoring.',
            textAlign: TextAlign.center,
            style: TextStyle(color: GlassTokens.inkSecondary, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AuthModalDialog(
                  initialActionPrompt: 'Login Required: Please sign in or register to score matches.',
                  onAuthSuccess: () => setState(() {}),
                ),
              );
            },
            icon: const Icon(Icons.login, color: Colors.black, size: 18),
            label: const Text('Log In / Register to Score', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00F5A0),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // COMPLETED MATCH VIEW
  // ==========================================
  Widget _buildCompletedMatchView(
    BuildContext context,
    MockDatabase db,
    MatchModel match,
    Innings? inn1,
    Innings? inn2,
    bool isScorer,
  ) {
    final winner = db.teams.where((t) => t.id == match.winnerId).firstOrNull;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events, size: 64, color: Colors.amber),
            const SizedBox(height: 16),
            const Text('MATCH CONCLUDED', style: TextStyle(color: GlassTokens.inkSecondary, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
            const SizedBox(height: 6),
            Text(
              '${winner?.name ?? "Winner"} won by ${match.winMargin ?? "runs"}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: GlassTokens.inkPrimary, fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 24),

            // Innings Summaries
            if (inn1 != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(color: GlassTokens.bgLightBlue, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(db.getTeam(inn1.battingTeamId)?.name ?? "Team", style: const TextStyle(color: GlassTokens.inkPrimary, fontWeight: FontWeight.bold)),
                    Text('${inn1.totalRuns}/${inn1.wickets} (${inn1.oversStr} ov)', style: const TextStyle(color: GlassTokens.inkPrimary, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            if (inn2 != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: GlassTokens.bgLightBlue, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(db.getTeam(inn2.battingTeamId)?.name ?? "Team", style: const TextStyle(color: GlassTokens.inkPrimary, fontWeight: FontWeight.bold)),
                    Text('${inn2.totalRuns}/${inn2.wickets} (${inn2.oversStr} ov)', style: const TextStyle(color: GlassTokens.inkPrimary, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => FullScorecardDialog(match: match, db: db),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669)),
                  child: const Text('View Full Scorecard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                if (isScorer) ...[
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => _confirmResetMatch(context, db, match),
                    style: OutlinedButton.styleFrom(foregroundColor: GlassTokens.inkSecondary),
                    child: const Text('Reset Match'),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => CreateDirectMatchDialog(db: db),
                );
              },
              icon: const Icon(Icons.flash_on, color: Colors.black, size: 18),
              label: const Text('CREATE ANOTHER QUICK MATCH', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00F5A0),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // LIVE SCORING VIEW
  // ==========================================
  Widget _buildLiveScoringView(
    BuildContext context,
    MockDatabase db,
    MatchModel match,
    Innings currentInnings,
    Innings? inn1,
    Innings? inn2,
    Player? striker,
    Player? nonStriker,
    Player? bowler,
    BattingScorecard strikerCard,
    BattingScorecard nonStrikerCard,
    BowlingScorecard bowlerCard,
    List<Player> battingTeamPlayers,
    List<Player> bowlingTeamPlayers,
    bool isScorer,
    ScoringRoom? currentRoom,
    List<Player> safeTeamAPlayers,
    List<Player> safeTeamBPlayers,
  ) {
    final runsRemaining = (currentInnings.targetRuns != null) ? (currentInnings.targetRuns! - currentInnings.totalRuns) : null;
    final ballsRemaining = (match.overs * 6) - currentInnings.legalBalls;
    final rrr = (runsRemaining != null && ballsRemaining > 0) ? ((runsRemaining / ballsRemaining) * 6.0).toStringAsFixed(2) : null;

    final prevBowlerId = CricketRulesEngine.getPreviousOverBowlerId(
      deliveries: db.deliveries,
      inningsId: currentInnings.id,
      legalBalls: currentInnings.legalBalls,
    );

    return Column(
      children: [
        // Innings Selector Tabs
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: GlassTokens.glassFillMid,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: GlassTokens.glassHairline),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => setState(() => selectedInningsNum = 1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: selectedInningsNum == 1 ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: selectedInningsNum == 1
                          ? Border.all(color: GlassTokens.glassHairline)
                          : null,
                      boxShadow: selectedInningsNum == 1
                          ? [
                              BoxShadow(
                                color: Color(0x1017233C),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Innings 1 ${inn1 != null ? "(${inn1.totalRuns}/${inn1.wickets})" : ""}',
                      style: TextStyle(
                        color: selectedInningsNum == 1 ? GlassTokens.inkPrimary : GlassTokens.inkSecondary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    if (inn2 != null) {
                      setState(() => selectedInningsNum = 2);
                    } else {
                      _showStartInnings2Modal(context, db, match, inn1, safeTeamAPlayers, safeTeamBPlayers);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: selectedInningsNum == 2 ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: selectedInningsNum == 2
                          ? Border.all(color: GlassTokens.glassHairline)
                          : null,
                      boxShadow: selectedInningsNum == 2
                          ? [
                              BoxShadow(
                                color: Color(0x1017233C),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Innings 2 ${inn2 != null ? "(${inn2.totalRuns}/${inn2.wickets})" : "(Start Chase)"}',
                      style: TextStyle(
                        color: selectedInningsNum == 2
                            ? GlassTokens.inkPrimary
                            : (inn2 != null ? GlassTokens.inkSecondary : GlassTokens.electricBlue),
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Scrollable Upper Crease & Scoreboard
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // MAIN SCORE BANNER (Neo-Glass Card)
                NeoGlassCard(
                  padding: const EdgeInsets.all(18),
                  borderRadius: 22,
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xEBFFFFFF),
                      Color(0xDCEAF2FF),
                      Color(0xD1F1EEFF),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderColor: const Color(0xD9FFFFFF),
                  glowColor: GlassTokens.electricBlue.withValues(alpha: 0.14),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: GlassTokens.mintGreen,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${match.stage} • Innings ${currentInnings.inningsNumber}',
                                style: const TextStyle(color: Color(0xFF047857), fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Text(
                            'Max ${match.overs} Ov (4 ov/bowler)',
                            style: const TextStyle(color: GlassTokens.inkSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${currentInnings.totalRuns}',
                            style: const TextStyle(
                              color: GlassTokens.inkPrimary,
                              fontSize: 46,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                          Text(
                            '/${currentInnings.wickets}',
                            style: const TextStyle(
                              color: GlassTokens.mintGreen,
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'CRR: ${currentInnings.runRate.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: GlassTokens.electricBlue,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                              if (currentInnings.targetRuns != null)
                                Text(
                                  runsRemaining != null && runsRemaining <= 0
                                      ? 'Target Reached! (${10 - currentInnings.wickets} wkts victory)'
                                      : 'Target: ${currentInnings.targetRuns} (Need $runsRemaining in $ballsRemaining b, RRR: $rrr)',
                                  style: TextStyle(
                                    color: runsRemaining != null && runsRemaining <= 0
                                        ? const Color(0xFF047857)
                                        : const Color(0xFFB45309),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Overs: ${currentInnings.oversStr} (${currentInnings.legalBalls} balls)',
                            style: const TextStyle(
                              color: GlassTokens.inkSecondary,
                              fontSize: 12,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Extras: ${currentInnings.totalExtras}',
                            style: const TextStyle(
                              color: GlassTokens.inkSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                if (currentInnings.legalBalls == 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: const Color(0xCCEAF2FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: currentInnings.inningsNumber == 1
                            ? GlassTokens.mintGreen.withValues(alpha: 0.45)
                            : GlassTokens.electricBlue.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          currentInnings.inningsNumber == 1 ? Icons.sports_cricket : Icons.flag_circle,
                          color: currentInnings.inningsNumber == 1 ? const Color(0xFF047857) : GlassTokens.electricBlue,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentInnings.inningsNumber == 1
                                    ? 'Innings 1 Opening Crease Lineup'
                                    : 'Innings 2 Chase Target: ${currentInnings.targetRuns ?? ((inn1?.totalRuns ?? 0) + 1)} runs in ${match.overs} ov',
                                style: TextStyle(
                                  color: currentInnings.inningsNumber == 1 ? const Color(0xFF047857) : GlassTokens.electricBlue,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Striker: ${_formatPlayerName(striker, "Select")} • Non-Striker: ${_formatPlayerName(nonStriker, "Select")} • Bowler: ${_formatPlayerName(bowler, "Select")}',
                                style: const TextStyle(color: GlassTokens.inkPrimary, fontSize: 10),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (isScorer)
                          InkWell(
                            onTap: () => _showOpeningCreaseDialog(
                              context,
                              db,
                              currentInnings,
                              battingTeamPlayers,
                              bowlingTeamPlayers,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: currentInnings.inningsNumber == 1 ? const Color(0xFF009270) : const Color(0xFF059669),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('Change Crease', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // CREASE HUD (BATTERS & BOWLER TABLES)
                CreaseHudWidget(
                  innings: currentInnings,
                  striker: striker,
                  nonStriker: nonStriker,
                  bowler: bowler,
                  strikerCard: strikerCard,
                  nonStrikerCard: nonStrikerCard,
                  bowlerCard: bowlerCard,
                  onSwapEnds: isScorer ? () => db.swapEnds(currentInnings.id) : null,
                  onChangeBowler: isScorer
                      ? () {
                          _showBowlerSelectDialog(context, db, currentInnings, bowlingTeamPlayers, prevBowlerId);
                        }
                      : null,
                  onChangeStriker: isScorer && currentInnings.legalBalls == 0
                      ? () => _showBatterSelectDialog(
                            context,
                            db,
                            currentInnings,
                            battingTeamPlayers,
                            isStriker: true,
                            otherBatterId: currentInnings.currentNonStrikerId,
                          )
                      : null,
                  onChangeNonStriker: isScorer && currentInnings.legalBalls == 0
                      ? () => _showBatterSelectDialog(
                            context,
                            db,
                            currentInnings,
                            battingTeamPlayers,
                            isStriker: false,
                            otherBatterId: currentInnings.currentStrikerId,
                          )
                      : null,
                  onChangeOpeningCrease: isScorer && currentInnings.legalBalls == 0
                      ? () => _showOpeningCreaseDialog(
                            context,
                            db,
                            currentInnings,
                            battingTeamPlayers,
                            bowlingTeamPlayers,
                          )
                      : null,
                ),
              ],
            ),
          ),
        ),

        // BOTTOM CONSOLE: Either Official Scorer Keypad OR Spectator Mode Console
        if (isScorer)
          _buildOfficialScorerKeypad(
            context,
            db,
            match,
            currentInnings,
            striker,
            nonStriker,
            bowler,
            battingTeamPlayers,
            bowlingTeamPlayers,
            prevBowlerId,
          )
        else
          _buildSpectatorBottomConsole(
            context,
            db,
            match,
            currentInnings,
            currentRoom,
          ),
      ],
    );
  }

  // ==========================================
  // SPECTATOR BOTTOM CONSOLE (READ-ONLY)
  // ==========================================
  Widget _buildSpectatorBottomConsole(
    BuildContext context,
    MockDatabase db,
    MatchModel match,
    Innings currentInnings,
    ScoringRoom? currentRoom,
  ) {
    final recentDeliveries = db.deliveries
        .where((d) => d.inningsId == currentInnings.id && !d.isUndone)
        .toList();
    final lastBalls = recentDeliveries.reversed.take(6).toList().reversed.toList();
    final latestDelivery = recentDeliveries.isNotEmpty ? recentDeliveries.last : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: GlassTokens.bgIcyWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Live Over Deliveries Strip
          Row(
            children: [
              const Text(
                'THIS OVER: ',
                style: TextStyle(color: GlassTokens.inkSecondary, fontSize: 10, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 6),
              if (lastBalls.isEmpty)
                const Text('Over in progress...', style: TextStyle(color: GlassTokens.inkMuted, fontSize: 11))
              else
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: lastBalls.map((d) {
                        final isWicket = d.isWicket;
                        final isBoundary = d.runsBatter == 4 || d.runsBatter == 6;
                        final label = isWicket
                            ? 'W'
                            : (d.extrasType != ExtrasType.none
                                ? (d.extrasType == ExtrasType.wide
                                    ? '${d.totalRuns}wd'
                                    : (d.extrasType == ExtrasType.noBall ? '${d.totalRuns}nb' : '${d.totalRuns}b'))
                                : '${d.runsBatter}');
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isWicket
                                ? Colors.red
                                : (isBoundary
                                    ? (d.runsBatter == 4 ? Colors.blue.shade700 : Colors.purple.shade700)
                                    : GlassTokens.bgLightBlue),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: GlassTokens.glassHairline),
                          ),
                          child: Text(
                            label,
                            style: const TextStyle(color: GlassTokens.inkPrimary, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
            ],
          ),

          if (latestDelivery != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: GlassTokens.bgLightBlue.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.comment, size: 12, color: Color(0xFF34D399)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Ball ${latestDelivery.overNumber}.${latestDelivery.ballInOver}: ${latestDelivery.commentaryText}',
                      style: const TextStyle(color: GlassTokens.inkSecondary, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Spectator Mode Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xEBFFFFFF), Color(0xD9F5F8FC)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.35)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1017233C),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.visibility, size: 14, color: Color(0xFFB45309)),
                    const SizedBox(width: 6),
                    const Text(
                      'LIVE SPECTATOR BROADCAST',
                      style: TextStyle(color: Color(0xFFB45309), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: GlassTokens.bgLightBlue,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: GlassTokens.glassHairline),
                      ),
                      child: const Text('Read Only', style: TextStyle(color: GlassTokens.inkSecondary, fontSize: 9, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (!db.isAuthenticated) ...[
                  const Text(
                    'Scoring is restricted to authenticated users. Log in or create an account to start scoring matches.',
                    style: TextStyle(color: GlassTokens.inkSecondary, fontSize: 11.5),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AuthModalDialog(
                          initialActionPrompt: 'Login Required: Please sign in or register to score matches.',
                          onAuthSuccess: () => setState(() {}),
                        ),
                      );
                    },
                    icon: const Icon(Icons.login, size: 15, color: Colors.white),
                    label: const Text('LOG IN TO BEGIN SCORING', style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w800)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GlassTokens.electricBlue,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ] else ...[
                  const Text(
                    'Scoring controls are locked. Official scorers can enter the Scoring Room with the Room ID and Passcode PIN to record deliveries.',
                    style: TextStyle(color: GlassTokens.inkSecondary, fontSize: 10.5),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showEnterRoomDialog(context, db, match),
                          icon: const Icon(Icons.vpn_key, size: 14),
                          label: const Text('ENTER SCORING ROOM', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GlassTokens.mintGreen,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showCreateRoomDialog(context, db, match),
                          icon: const Icon(Icons.add_circle_outline, size: 14),
                          label: const Text('CREATE ROOM', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: GlassTokens.inkPrimary,
                            side: const BorderSide(color: GlassTokens.glassHairline),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // OFFICIAL SCORER KEYPAD (UNLOCKED)
  // ==========================================
  Widget _buildOfficialScorerKeypad(
    BuildContext context,
    MockDatabase db,
    MatchModel match,
    Innings currentInnings,
    Player? striker,
    Player? nonStriker,
    Player? bowler,
    List<Player> battingTeamPlayers,
    List<Player> bowlingTeamPlayers,
    String? prevBowlerId,
  ) {
    // If innings or match is completed, show intuitive transition/result console instead of locked run keys
    if (currentInnings.isCompleted || match.status == MatchStatus.completed) {
      final isInn1 = currentInnings.inningsNumber == 1;
      final inn2 = db.inningsList.where((i) => i.matchId == match.id && i.inningsNumber == 2).firstOrNull;
      final inn1 = db.inningsList.where((i) => i.matchId == match.id && i.inningsNumber == 1).firstOrNull;
      final chasingTeam = db.getTeam(isInn1 ? (inn1?.bowlingTeamId ?? match.teamBId) : currentInnings.battingTeamId) ?? MockDatabase.emptyTeam;
      final target = (inn1?.totalRuns ?? 0) + 1;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: GlassTokens.bgIcyWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isInn1) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF064E3B).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF059669)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Color(0xFF34D399), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'INNINGS 1 CONCLUDED (${inn1?.totalRuns ?? 0}/${inn1?.wickets ?? 0})',
                            style: const TextStyle(color: GlassTokens.inkPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Target for ${chasingTeam.name}: $target runs in ${match.overs} overs.',
                      style: const TextStyle(color: Color(0xFF34D399), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  if (inn2 != null) {
                    setState(() => selectedInningsNum = 2);
                  } else {
                    _showStartInnings2Modal(context, db, match, inn1, battingTeamPlayers, bowlingTeamPlayers);
                  }
                },
                icon: const Icon(Icons.play_arrow, size: 18),
                label: Text(
                  inn2 != null ? 'Switch to Live Innings 2 Chase →' : 'Start Innings 2 Run Chase →',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF009270),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ] else ...[
              // Match Finished / Innings 2 Completed
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: GlassTokens.bgLightBlue,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Color(0xFFD97706).withValues(alpha: 0.5)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.emoji_events, color: Colors.amber, size: 28),
                    const SizedBox(height: 6),
                    Text(
                      match.winMargin != null && match.winnerId != null
                          ? '${db.getTeam(match.winnerId)?.name ?? "Winner"} won by ${match.winMargin}'
                          : 'MATCH COMPLETED',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: GlassTokens.inkPrimary, fontWeight: FontWeight.w900, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Final Score: ${currentInnings.totalRuns}/${currentInnings.wickets} in ${currentInnings.oversStr} ov',
                      style: const TextStyle(color: GlassTokens.inkSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmResetMatch(context, db, match),
                      icon: const Icon(Icons.refresh, size: 16, color: Colors.amber),
                      label: const Text('Reset', style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.amber),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => FullScorecardDialog(match: match, db: db),
                        );
                      },
                      icon: const Icon(Icons.receipt_long, size: 16),
                      label: const Text('Full Scorecard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF009270),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: const BoxDecoration(
        color: GlassTokens.bgIcyWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top control strip: Undo, Swap Ends, Retire, Bowler
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () => db.undoLastDelivery(currentInnings.id),
                icon: const Icon(Icons.undo, size: 14, color: GlassTokens.inkSecondary),
                label: const Text('Undo', style: TextStyle(color: GlassTokens.inkSecondary, fontSize: 11)),
              ),
              TextButton.icon(
                onPressed: () => db.swapEnds(currentInnings.id),
                icon: const Icon(Icons.swap_horiz, size: 14, color: Colors.amber),
                label: const Text('Swap Strike', style: TextStyle(color: Colors.amber, fontSize: 11)),
              ),
              TextButton.icon(
                onPressed: () {
                  _showRetireBatterDialog(
                    context: context,
                    db: db,
                    inn: currentInnings,
                    striker: striker,
                    nonStriker: nonStriker,
                    battingTeamPlayers: battingTeamPlayers,
                  );
                },
                icon: const Icon(Icons.medical_services_outlined, size: 14, color: Colors.orangeAccent),
                label: const Text('Retire', style: TextStyle(color: Colors.orangeAccent, fontSize: 11)),
              ),
              TextButton.icon(
                onPressed: () {
                  _showBowlerSelectDialog(context, db, currentInnings, bowlingTeamPlayers, prevBowlerId);
                },
                icon: const Icon(Icons.person, size: 14, color: Color(0xFF34D399)),
                label: Text(
                  _formatPlayerName(bowler, 'Pick Bowler'),
                  style: const TextStyle(color: Color(0xFF34D399), fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // THIS OVER BALL-BY-BALL STRIP
          Builder(builder: (context) {
            final innDeliveries = db.deliveries
                .where((d) => d.inningsId == currentInnings.id && !d.isUndone)
                .toList();
            int legalCount = 0;
            final currentOverBallsReversed = <Delivery>[];
            final ballsInCurrentOver = (currentInnings.legalBalls % 6 == 0 && currentInnings.legalBalls > 0)
                ? 6
                : (currentInnings.legalBalls % 6);
            for (final d in innDeliveries.reversed) {
              final isLegal = d.extrasType != ExtrasType.wide && d.extrasType != ExtrasType.noBall;
              currentOverBallsReversed.add(d);
              if (isLegal) {
                legalCount++;
                if (legalCount >= ballsInCurrentOver && ballsInCurrentOver > 0) break;
              }
            }
            final currentOverBalls = (ballsInCurrentOver == 0 && currentInnings.legalBalls == 0)
                ? innDeliveries
                : currentOverBallsReversed.reversed.toList();

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF131D31),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: GlassTokens.glassHairline),
              ),
              child: Row(
                children: [
                  Text(
                    'THIS OVER (${currentInnings.legalBalls ~/ 6 + 1}):',
                    style: const TextStyle(color: GlassTokens.inkSecondary, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  if (currentOverBalls.isEmpty)
                    const Text('Ready for first ball...', style: TextStyle(color: GlassTokens.inkMuted, fontSize: 10))
                  else
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: currentOverBalls.map((d) {
                            final isWicket = d.isWicket;
                            final isFour = d.runsBatter == 4;
                            final isSix = d.runsBatter == 6;
                            final isDot = d.runsBatter == 0 && d.extrasRuns == 0 && !isWicket;
                            final isWide = d.extrasType == ExtrasType.wide;
                            final isNb = d.extrasType == ExtrasType.noBall;
                            final isBye = d.extrasType == ExtrasType.bye || d.extrasType == ExtrasType.legBye;

                            String ballText;
                            Color badgeColor;
                            Color textColor = Colors.white;

                            if (isWicket) {
                              ballText = 'W';
                              badgeColor = Colors.red.shade700;
                            } else if (isNb) {
                              ballText = d.runsBatter > 0 ? 'Nb+${d.runsBatter}' : '${d.totalRuns}Nb';
                              badgeColor = Colors.deepOrange.shade800;
                            } else if (isWide) {
                              ballText = '${d.totalRuns}Wd';
                              badgeColor = Colors.amber.shade800;
                            } else if (isBye) {
                              ballText = '${d.totalRuns}B';
                              badgeColor = Colors.teal.shade800;
                            } else if (isSix) {
                              ballText = '6';
                              badgeColor = const Color(0xFF7C3AED);
                            } else if (isFour) {
                              ballText = '4';
                              badgeColor = const Color(0xFF0284C7);
                            } else if (isDot) {
                              ballText = '•';
                              badgeColor = GlassTokens.bgLightBlue;
                              textColor = GlassTokens.inkSecondary;
                            } else {
                              ballText = '${d.runsBatter}';
                              badgeColor = GlassTokens.bgLightBlue;
                            }

                            return Container(
                              margin: const EdgeInsets.only(right: 5),
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: badgeColor,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isWicket ? Colors.redAccent : GlassTokens.glassHairline,
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                ballText,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
          const SizedBox(height: 6),

          // Runs Keypad (0, 1, 2, 3, 4, 6) - Tactile Neo-Glass Keypad
          Row(
            children: [0, 1, 2, 3, 4, 6].map((run) {
              final isFour = run == 4;
              final isSix = run == 6;
              final isDot = run == 0;

              LinearGradient? buttonGradient;
              Color buttonColor = Colors.white;
              Color textColor = Colors.white;
              Color borderColor = GlassTokens.glassHairline;
              Color? glowColor;

              if (isFour) {
                buttonGradient = const LinearGradient(
                  colors: [Color(0xFF0284C7), Color(0xFF00D9F5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                );
                textColor = Colors.black;
                glowColor = NeoGlassTheme.neonCyan;
                borderColor = Colors.transparent;
              } else if (isSix) {
                buttonGradient = const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                );
                textColor = Colors.white;
                glowColor = NeoGlassTheme.neonViolet;
                borderColor = Colors.transparent;
              } else if (isDot) {
                buttonColor = GlassTokens.bgIcyWhite;
                textColor = GlassTokens.inkSecondary;
                borderColor = GlassTokens.glassHairline;
              } else {
                buttonColor = const Color(0xFF131D31);
                textColor = NeoGlassTheme.neonEmerald;
                borderColor = NeoGlassTheme.neonEmerald.withValues(alpha: 0.35);
              }

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: InkWell(
                    onTap: (striker == null || nonStriker == null)
                        ? () {
                            _showOpeningCreaseDialog(context, db, currentInnings, battingTeamPlayers, bowlingTeamPlayers);
                          }
                        : bowler == null
                            ? () {
                                _showBowlerSelectDialog(context, db, currentInnings, bowlingTeamPlayers, prevBowlerId);
                              }
                            : () {
                                _executeDelivery(
                                  context: context,
                                  db: db,
                                  inn: currentInnings,
                                  bowlingPlayers: bowlingTeamPlayers,
                                  runsBatter: run,
                                );
                              },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: buttonGradient == null ? buttonColor : null,
                        gradient: buttonGradient,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor, width: 1.2),
                        boxShadow: [
                          NeoGlassTheme.neoDarkShadow,
                          NeoGlassTheme.neoLightHighlight,
                          if (glowColor != null)
                            NeoGlassTheme.neoGlowShadow(glowColor, opacity: 0.35),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$run',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 10),

          // Action Row: EXTRAS & WICKET (Tactile Neo-Glass Action Buttons)
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: (striker == null || nonStriker == null)
                      ? () => _showOpeningCreaseDialog(context, db, currentInnings, battingTeamPlayers, bowlingTeamPlayers)
                      : bowler == null
                          ? () => _showBowlerSelectDialog(context, db, currentInnings, bowlingTeamPlayers, prevBowlerId)
                          : () => _showExtrasDialog(
                              context,
                              db,
                              currentInnings,
                              bowlingTeamPlayers,
                              striker: striker,
                              nonStriker: nonStriker,
                              bowler: bowler,
                            ),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      gradient: NeoGlassTheme.amberGoldGradient,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Color(0xFFD97706).withValues(alpha: 0.5)),
                      boxShadow: [
                        NeoGlassTheme.neoDarkShadow,
                        NeoGlassTheme.neoGlowShadow(Colors.amber, opacity: 0.25),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'EXTRAS (Wd/Nb/B)',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: (striker == null || nonStriker == null)
                      ? () => _showOpeningCreaseDialog(context, db, currentInnings, battingTeamPlayers, bowlingTeamPlayers)
                      : bowler == null
                          ? () => _showBowlerSelectDialog(context, db, currentInnings, bowlingTeamPlayers, prevBowlerId)
                          : () {
                              showDialog(
                                context: context,
                                builder: (ctx) => WicketDialog(
                                  striker: striker,
                                  nonStriker: nonStriker,
                                  battingTeamPlayers: battingTeamPlayers,
                                  bowlingTeamPlayers: bowlingTeamPlayers,
                                  deliveries: db.deliveries,
                                  inningsId: currentInnings.id,
                                  currentWickets: currentInnings.wickets,
                                  onConfirmWicket: ({
                                    required dismissalType,
                                    required dismissedPlayerId,
                                    fielderId,
                                    nextBatterId,
                                  }) {
                                    _executeDelivery(
                                      context: context,
                                      db: db,
                                      inn: currentInnings,
                                      bowlingPlayers: bowlingTeamPlayers,
                                      runsBatter: 0,
                                      isWicket: true,
                                      dismissalType: dismissalType,
                                      dismissedPlayerId: dismissedPlayerId,
                                      fielderId: fielderId,
                                      nextBatterId: nextBatterId,
                                    );
                                  },
                                ),
                              );
                            },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFF87171)),
                      boxShadow: [
                        NeoGlassTheme.neoDarkShadow,
                        NeoGlassTheme.neoGlowShadow(NeoGlassTheme.neonRose, opacity: 0.35),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'WICKET (OUT!)',
                      style: TextStyle(
                        color: GlassTokens.inkPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ROOM MODALS
  // ==========================================

  void _showEnterRoomDialog(BuildContext context, MockDatabase db, MatchModel match) {
    if (!db.isAuthenticated) {
      showDialog(
        context: context,
        builder: (ctx) => AuthModalDialog(
          initialActionPrompt: 'Login Required: Please sign in or register to enter scoring room.',
          onAuthSuccess: () => setState(() {}),
        ),
      );
      return;
    }

    final existingRoom = db.getScoringRoomForMatch(match.id);
    final roomController = TextEditingController(text: existingRoom?.id ?? 'ROOM-BPL-01');
    final passController = TextEditingController();
    String? errorMessage;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: GlassTokens.bgLightBlue,
            title: Row(
              children: const [
                Icon(Icons.vpn_key, color: Color(0xFF34D399), size: 20),
                SizedBox(width: 8),
                Text('Enter Scoring Room', style: TextStyle(color: GlassTokens.inkPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Unlock official ball-by-ball scoring for ${match.stage}.',
                    style: const TextStyle(color: GlassTokens.inkSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: roomController,
                    style: const TextStyle(color: GlassTokens.inkPrimary),
                    decoration: InputDecoration(
                      labelText: 'Scoring Room ID',
                      labelStyle: const TextStyle(color: GlassTokens.inkSecondary),
                      hintText: 'e.g. ROOM-BPL-01',
                      hintStyle: const TextStyle(color: GlassTokens.inkMuted),
                      prefixIcon: const Icon(Icons.meeting_room, color: GlassTokens.inkSecondary),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passController,
                    obscureText: true,
                    style: const TextStyle(color: GlassTokens.inkPrimary),
                    decoration: InputDecoration(
                      labelText: 'Passcode PIN',
                      labelStyle: const TextStyle(color: GlassTokens.inkSecondary),
                      hintText: 'e.g. 1234',
                      hintStyle: const TextStyle(color: GlassTokens.inkMuted),
                      prefixIcon: const Icon(Icons.password, color: GlassTokens.inkSecondary),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: GlassTokens.inkSecondary)),
              ),
              ElevatedButton(
                onPressed: () {
                  final success = db.unlockScoringRoom(
                    matchId: match.id,
                    roomId: roomController.text,
                    passcode: passController.text,
                  ) || db.unlockTournamentScoring(
                    tournamentIdOrRoomId: roomController.text,
                    passcode: passController.text,
                  );
                  if (success) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF059669),
                        content: Text('Scoring console unlocked for ${match.stage}!'),
                      ),
                    );
                  } else {
                    setDialogState(() {
                      errorMessage = 'Invalid Tournament ID, Room ID, or Passcode.';
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF34D399),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Unlock Console', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCreateRoomDialog(BuildContext context, MockDatabase db, MatchModel match) {
    if (!db.isAuthenticated) {
      showDialog(
        context: context,
        builder: (ctx) => AuthModalDialog(
          initialActionPrompt: 'Login Required: Please sign in or register to create scoring room.',
          onAuthSuccess: () => setState(() {}),
        ),
      );
      return;
    }

    final generatedRoomId = 'ROOM-BPL-0${match.id.replaceAll(RegExp(r'[^0-9]'), '')}';
    final roomController = TextEditingController(text: generatedRoomId);
    final passController = TextEditingController(text: '1234');
    final nameController = TextEditingController(text: 'Host Scorer');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: GlassTokens.bgLightBlue,
        title: Row(
          children: const [
            Icon(Icons.add_circle, color: Color(0xFF34D399), size: 20),
            SizedBox(width: 8),
            Text('Create Scoring Room', style: TextStyle(color: GlassTokens.inkPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Create a private room for ${match.stage}. Only individuals who receive the Room ID & PIN will be able to change or conduct scores.',
                style: const TextStyle(color: GlassTokens.inkSecondary, fontSize: 12),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: roomController,
                style: const TextStyle(color: GlassTokens.inkPrimary),
                decoration: InputDecoration(
                  labelText: 'Room ID',
                  labelStyle: const TextStyle(color: GlassTokens.inkSecondary),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passController,
                style: const TextStyle(color: GlassTokens.inkPrimary),
                decoration: InputDecoration(
                  labelText: 'Secret Passcode PIN',
                  labelStyle: const TextStyle(color: GlassTokens.inkSecondary),
                  hintText: 'e.g. 1234',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                style: const TextStyle(color: GlassTokens.inkPrimary),
                decoration: InputDecoration(
                  labelText: 'Created By (Your Name / Role)',
                  labelStyle: const TextStyle(color: GlassTokens.inkSecondary),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: GlassTokens.inkSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              if (roomController.text.trim().isEmpty || passController.text.trim().isEmpty) return;
              final newRoom = db.createScoringRoom(
                matchId: match.id,
                roomId: roomController.text,
                passcode: passController.text,
                createdBy: nameController.text,
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF059669),
                  content: Text('Room "${newRoom.id}" created! Official scorer mode activated.'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF34D399),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Create & Start Scoring', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // HELPER DIALOGS
  // ==========================================

  String _formatPlayerName(Player? p, String fallback) {
    if (p == null) return fallback;
    final fn = p.fullName.trim();
    if (fn.isNotEmpty) return fn;
    final dn = p.displayName.trim();
    if (dn.isNotEmpty) return dn;
    return fallback;
  }

  void _showBatterSelectDialog(
    BuildContext context,
    MockDatabase db,
    Innings inn,
    List<Player> batters, {
    required bool isStriker,
    String? otherBatterId,
  }) {
    final available = batters.where((p) => p.id != otherBatterId).toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: GlassTokens.bgLightBlue,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isStriker ? 'SELECT OPENING STRIKER (Facing 0.1)' : 'SELECT OPENING NON-STRIKER',
                textAlign: TextAlign.center,
                style: const TextStyle(color: GlassTokens.inkPrimary, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...available.map((p) {
                final pName = p.fullName.isNotEmpty ? p.fullName : p.displayName;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isStriker ? Colors.amber.withValues(alpha: 0.2) : const Color(0xFF009270).withValues(alpha: 0.2),
                    child: Icon(isStriker ? Icons.sports_cricket : Icons.directions_run, color: isStriker ? Colors.amber : const Color(0xFF34D399), size: 18),
                  ),
                  title: Text(pName, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: Text(p.battingStyle, style: const TextStyle(color: GlassTokens.inkSecondary, fontSize: 11)),
                  onTap: () {
                    Navigator.pop(ctx);
                    if (isStriker) {
                      db.setStriker(inn.id, p.id);
                    } else {
                      db.setNonStriker(inn.id, p.id);
                    }
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _executeDelivery({
    required BuildContext context,
    required MockDatabase db,
    required Innings inn,
    required List<Player> bowlingPlayers,
    required int runsBatter,
    int extrasRuns = 0,
    ExtrasType extrasType = ExtrasType.none,
    bool isWicket = false,
    DismissalType? dismissalType,
    String? dismissedPlayerId,
    String? fielderId,
    String? nextBatterId,
  }) {
    if (!db.isAuthenticated) {
      showDialog(
        context: context,
        builder: (ctx) => AuthModalDialog(
          initialActionPrompt: 'Login Required: Please sign in or register to record deliveries.',
          onAuthSuccess: () => setState(() {}),
        ),
      );
      return;
    }

    final activeBowlerBeforeBall = inn.currentBowlerId;
    db.recordDelivery(
      inningsId: inn.id,
      runsBatter: runsBatter,
      extrasRuns: extrasRuns,
      extrasType: extrasType,
      isWicket: isWicket,
      dismissalType: dismissalType,
      dismissedPlayerId: dismissedPlayerId,
      fielderId: fielderId,
      nextBatterId: nextBatterId,
    );

    final updated = db.inningsList.firstWhere((i) => i.id == inn.id);
    final match = db.matches.firstWhere((m) => m.id == inn.matchId);

    if (updated.inningsNumber == 1 && updated.isCompleted) {
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final teamAPlayers = db.players.where((p) => match.playingXIA.contains(p.id) || p.teamId == match.teamAId).toList();
          final teamBPlayers = db.players.where((p) => match.playingXIB.contains(p.id) || p.teamId == match.teamBId).toList();
          _showStartInnings2Modal(context, db, match, updated, teamAPlayers, teamBPlayers);
        }
      });
      return;
    }

    if (updated.currentBowlerId == null && !updated.isCompleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showBowlerSelectDialog(context, db, updated, bowlingPlayers, activeBowlerBeforeBall);
        }
      });
    }
  }

  void _showOpeningCreaseDialog(
    BuildContext context,
    MockDatabase db,
    Innings inn,
    List<Player> battingPlayers,
    List<Player> bowlingPlayers,
  ) {
    String? curStrikerId = inn.currentStrikerId ?? battingPlayers.firstOrNull?.id;
    String? curNonStrikerId = inn.currentNonStrikerId ?? (battingPlayers.length > 1 ? battingPlayers[1].id : battingPlayers.firstOrNull?.id);
    String? curBowlerId = inn.currentBowlerId ?? bowlingPlayers.where((p) => p.role == PlayerRole.bowler).firstOrNull?.id ??
        (bowlingPlayers.isNotEmpty ? bowlingPlayers.first.id : (battingPlayers.isNotEmpty ? battingPlayers.first.id : null));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: GlassTokens.bgLightBlue,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(builder: (sheetCtx, setSheetState) {
          final isSameBatter = curStrikerId != null && curNonStrikerId != null && curStrikerId == curNonStrikerId && battingPlayers.length > 1;
          return Padding(
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'SELECT OPENING CREASE LINEUP (INNINGS ${inn.inningsNumber})',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: GlassTokens.inkPrimary, fontSize: 13.5, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),

                  // Striker
                  const Text('Opening Striker (* facing ball 0.1):', style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: curStrikerId,
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    style: const TextStyle(color: GlassTokens.inkPrimary, fontSize: 12),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: battingPlayers.map((p) {
                      final pName = p.fullName.isNotEmpty ? p.fullName : p.displayName;
                      return DropdownMenuItem(value: p.id, child: Text(pName, overflow: TextOverflow.ellipsis));
                    }).toList(),
                    onChanged: (val) => setSheetState(() => curStrikerId = val),
                  ),
                  const SizedBox(height: 10),

                  // Non-Striker
                  const Text('Opening Non-Striker (runner):', style: TextStyle(color: GlassTokens.inkSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: curNonStrikerId,
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    style: const TextStyle(color: GlassTokens.inkPrimary, fontSize: 12),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: battingPlayers.map((p) {
                      final pName = p.fullName.isNotEmpty ? p.fullName : p.displayName;
                      return DropdownMenuItem(value: p.id, child: Text(pName, overflow: TextOverflow.ellipsis));
                    }).toList(),
                    onChanged: (val) => setSheetState(() => curNonStrikerId = val),
                  ),
                  const SizedBox(height: 10),

                  if (isSameBatter) ...[
                    const Text('⚠️ Striker & Non-Striker must be different players.', style: TextStyle(color: Colors.redAccent, fontSize: 11)),
                    const SizedBox(height: 10),
                  ],

                  // Bowler
                  const Text('Opening Bowler (Over 1):', style: TextStyle(color: Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: curBowlerId,
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    style: const TextStyle(color: GlassTokens.inkPrimary, fontSize: 12),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: bowlingPlayers.map((p) {
                      final pName = p.fullName.isNotEmpty ? p.fullName : p.displayName;
                      return DropdownMenuItem(value: p.id, child: Text(pName, overflow: TextOverflow.ellipsis));
                    }).toList(),
                    onChanged: (val) => setSheetState(() => curBowlerId = val),
                  ),
                  const SizedBox(height: 18),

                  ElevatedButton(
                    onPressed: (!isSameBatter && curStrikerId != null && curNonStrikerId != null && curBowlerId != null)
                        ? () {
                            Navigator.pop(ctx);
                            db.setOpeningCrease(
                              inningsId: inn.id,
                              strikerId: curStrikerId!,
                              nonStrikerId: curNonStrikerId!,
                              bowlerId: curBowlerId!,
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF009270),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Save Crease Lineup', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  void _showBowlerSelectDialog(BuildContext context, MockDatabase db, Innings inn, List<Player> bowlers, String? prevBowlerId) {
    showDialog(
      context: context,
      builder: (ctx) => OverCompleteDialog(
        completedOverNumber: (inn.legalBalls ~/ 6),
        bowlingTeamPlayers: bowlers,
        deliveries: db.deliveries,
        inningsId: inn.id,
        previousOverBowlerId: prevBowlerId,
        maxOversPerBowler: 4,
        onSelectBowler: (bowlerId) {
          db.setBowler(inn.id, bowlerId);
        },
      ),
    );
  }

  void _showExtrasDialog(
    BuildContext context,
    MockDatabase db,
    Innings inn,
    List<Player> bowlingTeamPlayers, {
    Player? striker,
    Player? nonStriker,
    Player? bowler,
  }) {
    ExtrasScoringSheet.show(
      context,
      innings: inn,
      striker: striker,
      nonStriker: nonStriker,
      bowler: bowler,
      onConfirmExtras: ({
        required ExtrasType extrasType,
        required int extrasRuns,
        required int runsBatter,
      }) {
        _executeDelivery(
          context: context,
          db: db,
          inn: inn,
          bowlingPlayers: bowlingTeamPlayers,
          runsBatter: runsBatter,
          extrasRuns: extrasRuns,
          extrasType: extrasType,
        );
      },
    );
  }

  void _showRetireBatterDialog({
    required BuildContext context,
    required MockDatabase db,
    required Innings inn,
    required Player? striker,
    required Player? nonStriker,
    required List<Player> battingTeamPlayers,
  }) {
    if (striker == null || nonStriker == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Both striker and non-striker must be selected before retiring a player.')),
      );
      return;
    }

    final availableDugout = CricketRulesEngine.getAvailableIncomingBatsmen(
      teamPlayers: battingTeamPlayers,
      deliveries: db.deliveries,
      inningsId: inn.id,
      currentStrikerId: striker.id,
      currentNonStrikerId: nonStriker.id,
    );

    if (availableDugout.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No remaining players available in the squad dugout!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    RetireBatterDialog.show(
      context,
      striker: striker,
      nonStriker: nonStriker,
      availableDugout: availableDugout,
      onConfirmRetire: ({
        required String retiringPlayerId,
        required bool isHurt,
        required String replacementPlayerId,
      }) {
        db.retireBatter(
          inningsId: inn.id,
          retiringPlayerId: retiringPlayerId,
          isHurt: isHurt,
          replacementPlayerId: replacementPlayerId,
        );
        setState(() {});
      },
    );
  }

  void _confirmResetMatch(BuildContext context, MockDatabase db, MatchModel match) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Match Scoring?'),
        content: Text('Are you sure you want to reset "${match.stage}"? Deliveries and scorecards will be cleared so you can re-conduct the toss.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              db.resetMatch(match.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmEndInnings1Early(
    BuildContext context,
    MockDatabase db,
    MatchModel match,
    Innings? inn1,
    List<Player> teamAPlayers,
    List<Player> teamBPlayers,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => NeoGlassDialog(
        glowColor: NeoGlassTheme.neonEmerald,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'End Innings 1 Early & Start Chase?',
              style: TextStyle(color: GlassTokens.inkPrimary, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Innings 1 is currently ${inn1?.totalRuns ?? 0}/${inn1?.wickets ?? 0} in ${(inn1?.legalBalls ?? 0) ~/ 6}.${(inn1?.legalBalls ?? 0) % 6} overs.\n\nDo you want to declare/conclude Innings 1 and start Innings 2 with a target of ${(inn1?.totalRuns ?? 0) + 1} runs?',
              style: const TextStyle(color: GlassTokens.inkSecondary, fontSize: 12),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: GlassTokens.inkSecondary)),
                ),
                const SizedBox(width: 8),
                NeoGlassButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showStartInnings2Modal(context, db, match, inn1, teamAPlayers, teamBPlayers);
                  },
                  gradient: NeoGlassTheme.neonGradient,
                  child: const Text('Yes, Start Innings 2', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showStartInnings2Modal(
    BuildContext context,
    MockDatabase db,
    MatchModel match,
    Innings? inn1,
    List<Player> teamAPlayers,
    List<Player> teamBPlayers,
  ) {
    if (inn1 == null) return;
    final chasingTeamId = (inn1.battingTeamId == match.teamAId) ? match.teamBId : match.teamAId;
    final defendingTeamId = (chasingTeamId == match.teamAId) ? match.teamBId : match.teamAId;

    final chasingTeam = db.getTeam(chasingTeamId) ?? MockDatabase.emptyTeam;
    final defendingTeam = db.getTeam(defendingTeamId) ?? MockDatabase.emptyTeam;

    final chasingPlayers = chasingTeamId == match.teamAId ? teamAPlayers : teamBPlayers;
    final defendingPlayers = defendingTeamId == match.teamAId ? teamAPlayers : teamBPlayers;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StartInnings2Dialog(
        match: match,
        inn1: inn1,
        chasingTeam: chasingTeam,
        defendingTeam: defendingTeam,
        chasingPlayers: chasingPlayers,
        defendingPlayers: defendingPlayers,
        onConfirmLineup: ({
          required String strikerId,
          required String nonStrikerId,
          required String bowlerId,
        }) {
          db.startInnings2(
            matchId: match.id,
            strikerId: strikerId,
            nonStrikerId: nonStrikerId,
            bowlerId: bowlerId,
          );
          setState(() => selectedInningsNum = 2);
        },
      ),
    );
  }
}
