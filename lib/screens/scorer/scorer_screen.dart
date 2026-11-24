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
          title: const Text('Live Scorer Console', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
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
                  style: TextStyle(color: Colors.white60, fontSize: 12),
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

    final isScorer = db.isScoringUnlockedForMatch(match.id);
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
      backgroundColor: NeoGlassTheme.bgCanvas,
      appBar: AppBar(
        backgroundColor: const Color(0xCC0B1120),
        elevation: 0,
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
                  dropdownColor: const Color(0xFF0F172A),
                  icon: const Icon(Icons.keyboard_arrow_down, color: NeoGlassTheme.neonEmerald, size: 18),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
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
                  color: isScorer ? NeoGlassTheme.neonEmerald : Colors.amberAccent,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    isScorer
                        ? 'Scorer: ${currentRoom?.id ?? "ROOM-01"}'
                        : 'Spectator Mode',
                    style: TextStyle(
                      color: isScorer ? NeoGlassTheme.neonEmerald : Colors.amberAccent,
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
          IconButton(
            tooltip: 'Team Squads & Mobile Numbers',
            icon: const Icon(Icons.people_alt, color: Colors.white70, size: 18),
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
            icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
            tooltip: 'Match Options',
            color: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) {
              switch (value) {
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
                case 'reset_match':
                  _confirmResetMatch(context, db, match);
                  break;
                case 'create_quick_match':
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
                    Icon(Icons.table_chart, color: Colors.white70, size: 17),
                    SizedBox(width: 10),
                    Text('Full Scorecard', style: TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'tournament',
                child: Row(
                  children: [
                    Icon(Icons.emoji_events, color: Colors.amberAccent, size: 17),
                    SizedBox(width: 10),
                    Text('Tournament Hub', style: TextStyle(color: Colors.white, fontSize: 13)),
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
                const PopupMenuItem(
                  value: 'reset_match',
                  child: Row(
                    children: [
                      Icon(Icons.refresh, color: Colors.amberAccent, size: 17),
                      SizedBox(width: 10),
                      Text('Reset Match', style: TextStyle(color: Colors.white, fontSize: 13)),
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
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
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
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Tournament rules require both teams to enter all playing squad names along with their contact mobile numbers before ball-by-ball scoring can begin.',
                  style: TextStyle(color: Colors.white70, fontSize: 11.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Team A Status Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
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
                            Text(teamA.name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                            Text(
                              '${playersA.length} Players (${playersAWithMobile.length} with mobile)',
                              style: TextStyle(color: isAReady ? const Color(0xFF34D399) : Colors.white54, fontSize: 11),
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
                    color: const Color(0xFF1E293B),
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
                            Text(teamB.name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                            Text(
                              '${playersB.length} Players (${playersBWithMobile.length} with mobile)',
                              style: TextStyle(color: isBReady ? const Color(0xFF34D399) : Colors.white54, fontSize: 11),
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
              child: const Icon(Icons.sports_cricket, size: 48, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              match.stage,
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              '${teamA.name} vs ${teamB.name}',
              style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '${match.venue} • ${match.overs} Overs T20',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
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
            ] else ...[
              // SPECTATOR LOCKED BANNER
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
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
                      style: TextStyle(color: Colors.white70, fontSize: 11),
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
                              side: const BorderSide(color: Colors.white38),
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
            const Text('MATCH CONCLUDED', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
            const SizedBox(height: 6),
            Text(
              '${winner?.name ?? "Winner"} won by ${match.winMargin ?? "runs"}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 24),

            // Innings Summaries
            if (inn1 != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(db.getTeam(inn1.battingTeamId)?.name ?? "Team", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text('${inn1.totalRuns}/${inn1.wickets} (${inn1.oversStr} ov)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            if (inn2 != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(db.getTeam(inn2.battingTeamId)?.name ?? "Team", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text('${inn2.totalRuns}/${inn2.wickets} (${inn2.oversStr} ov)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.white70),
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
          decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => selectedInningsNum = 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: selectedInningsNum == 1 ? const Color(0xFF059669) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Innings 1 ${inn1 != null ? "(${inn1.totalRuns}/${inn1.wickets})" : ""}',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () {
                    if (inn2 != null) {
                      setState(() => selectedInningsNum = 2);
                    } else {
                      _showStartInnings2Modal(context, db, match, inn1, safeTeamAPlayers, safeTeamBPlayers);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: selectedInningsNum == 2 ? const Color(0xFF059669) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Innings 2 ${inn2 != null ? "(${inn2.totalRuns}/${inn2.wickets})" : "(Start Chase)"}',
                      style: TextStyle(
                        color: selectedInningsNum == 2
                            ? Colors.white
                            : (inn2 != null ? Colors.white70 : const Color(0xFF34D399)),
                        fontSize: 11,
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
                  padding: const EdgeInsets.all(16),
                  borderRadius: 22,
                  gradient: const LinearGradient(
                    colors: [
                      Color(0x3300F5A0),
                      Color(0x1800D9F5),
                      Color(0xF00B1120),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderColor: NeoGlassTheme.glassBorder,
                  glowColor: NeoGlassTheme.neonEmerald,
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
                                  color: NeoGlassTheme.neonEmerald,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${match.stage} • Innings ${currentInnings.inningsNumber}',
                                style: const TextStyle(color: NeoGlassTheme.neonEmerald, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Text(
                            'Max ${match.overs} Ov (4 ov/bowler)',
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${currentInnings.totalRuns}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 46,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                            ),
                          ),
                          Text(
                            '/${currentInnings.wickets}',
                            style: const TextStyle(
                              color: NeoGlassTheme.neonEmerald,
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'CRR: ${currentInnings.runRate.toStringAsFixed(2)}',
                                style: const TextStyle(color: NeoGlassTheme.neonCyan, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              if (currentInnings.targetRuns != null)
                                Text(
                                  runsRemaining != null && runsRemaining <= 0
                                      ? 'Target Reached! (${10 - currentInnings.wickets} wkts victory)'
                                      : 'Target: ${currentInnings.targetRuns} (Need $runsRemaining in $ballsRemaining b, RRR: $rrr)',
                                  style: TextStyle(
                                    color: runsRemaining != null && runsRemaining <= 0 ? NeoGlassTheme.neonEmerald : Colors.amber,
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
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          const Spacer(),
                          Text(
                            'Extras: ${currentInnings.totalExtras}',
                            style: const TextStyle(color: Colors.white54, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                if (currentInnings.legalBalls == 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: currentInnings.inningsNumber == 1
                            ? const Color(0xFF00F5A0).withValues(alpha: 0.6)
                            : const Color(0xFF34D399).withValues(alpha: 0.6),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          currentInnings.inningsNumber == 1 ? Icons.sports_cricket : Icons.flag_circle,
                          color: currentInnings.inningsNumber == 1 ? const Color(0xFF00F5A0) : const Color(0xFF34D399),
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
                                  color: currentInnings.inningsNumber == 1 ? const Color(0xFF00F5A0) : const Color(0xFF34D399),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Striker: ${_formatPlayerName(striker, "Select")} • Non-Striker: ${_formatPlayerName(nonStriker, "Select")} • Bowler: ${_formatPlayerName(bowler, "Select")}',
                                style: const TextStyle(color: Colors.white70, fontSize: 10),
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
        color: Color(0xFF0B1120),
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
                style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 6),
              if (lastBalls.isEmpty)
                const Text('Over in progress...', style: TextStyle(color: Colors.white30, fontSize: 11))
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
                                    : const Color(0xFF1E293B)),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Text(
                            label,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
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
                color: const Color(0xFF1E293B).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.comment, size: 12, color: Color(0xFF34D399)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Ball ${latestDelivery.overNumber}.${latestDelivery.ballInOver}: ${latestDelivery.commentaryText}',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.visibility, size: 14, color: Colors.amber),
                    const SizedBox(width: 6),
                    const Text(
                      'LIVE SPECTATOR BROADCAST',
                      style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('Read Only', style: TextStyle(color: Colors.white60, fontSize: 9)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Scoring controls are locked. Official scorers can enter the Scoring Room with the Room ID and Passcode PIN to record deliveries.',
                  style: TextStyle(color: Colors.white60, fontSize: 10),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showEnterRoomDialog(context, db, match),
                        icon: const Icon(Icons.vpn_key, size: 14),
                        label: const Text('ENTER SCORING ROOM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF34D399),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showCreateRoomDialog(context, db, match),
                        icon: const Icon(Icons.add_circle_outline, size: 14),
                        label: const Text('CREATE ROOM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white38),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
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
          color: Color(0xFF0B1120),
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
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
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
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.5)),
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
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Final Score: ${currentInnings.totalRuns}/${currentInnings.wickets} in ${currentInnings.oversStr} ov',
                      style: const TextStyle(color: Colors.white60, fontSize: 11),
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
        color: Color(0xFF0B1120),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top control strip: Undo & Swap Ends
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () => db.undoLastDelivery(currentInnings.id),
                icon: const Icon(Icons.undo, size: 14, color: Colors.white70),
                label: const Text('Undo', style: TextStyle(color: Colors.white70, fontSize: 11)),
              ),
              TextButton.icon(
                onPressed: () => db.swapEnds(currentInnings.id),
                icon: const Icon(Icons.swap_horiz, size: 14, color: Colors.amber),
                label: const Text('Swap Strike', style: TextStyle(color: Colors.amber, fontSize: 11)),
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

          // Runs Keypad (0, 1, 2, 3, 4, 6) - Tactile Neo-Glass Keypad
          Row(
            children: [0, 1, 2, 3, 4, 6].map((run) {
              final isFour = run == 4;
              final isSix = run == 6;
              final isDot = run == 0;

              LinearGradient? buttonGradient;
              Color buttonColor = const Color(0xFF0F172A);
              Color textColor = Colors.white;
              Color borderColor = Colors.white12;
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
                buttonColor = const Color(0xFF0B1120);
                textColor = Colors.white54;
                borderColor = Colors.white10;
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
                          : () => _showExtrasDialog(context, db, currentInnings, bowlingTeamPlayers),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      gradient: NeoGlassTheme.amberGoldGradient,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.5)),
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
                        color: Colors.white,
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
    final existingRoom = db.getScoringRoomForMatch(match.id);
    final roomController = TextEditingController(text: existingRoom?.id ?? 'ROOM-BPL-01');
    final passController = TextEditingController();
    String? errorMessage;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            title: Row(
              children: const [
                Icon(Icons.vpn_key, color: Color(0xFF34D399), size: 20),
                SizedBox(width: 8),
                Text('Enter Scoring Room', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Unlock official ball-by-ball scoring for ${match.stage}.',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: roomController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Scoring Room ID',
                      labelStyle: const TextStyle(color: Colors.white70),
                      hintText: 'e.g. ROOM-BPL-01',
                      hintStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(Icons.meeting_room, color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Passcode PIN',
                      labelStyle: const TextStyle(color: Colors.white70),
                      hintText: 'e.g. 1234',
                      hintStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(Icons.password, color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
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
                child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
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
    final generatedRoomId = 'ROOM-BPL-0${match.id.replaceAll(RegExp(r'[^0-9]'), '')}';
    final roomController = TextEditingController(text: generatedRoomId);
    final passController = TextEditingController(text: '1234');
    final nameController = TextEditingController(text: 'Host Scorer');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Row(
          children: const [
            Icon(Icons.add_circle, color: Color(0xFF34D399), size: 20),
            SizedBox(width: 8),
            Text('Create Scoring Room', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Create a private room for ${match.stage}. Only individuals who receive the Room ID & PIN will be able to change or conduct scores.',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: roomController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Room ID',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Secret Passcode PIN',
                  labelStyle: const TextStyle(color: Colors.white70),
                  hintText: 'e.g. 1234',
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Created By (Your Name / Role)',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
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
      backgroundColor: const Color(0xFF1E293B),
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
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
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
                  subtitle: Text(p.battingStyle, style: const TextStyle(color: Colors.white54, fontSize: 11)),
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
      backgroundColor: const Color(0xFF1E293B),
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
                    style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),

                  // Striker
                  const Text('Opening Striker (* facing ball 0.1):', style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: curStrikerId,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF0F172A),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
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
                  const Text('Opening Non-Striker (runner):', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: curNonStrikerId,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF0F172A),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
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
                    dropdownColor: const Color(0xFF0F172A),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
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

  void _showExtrasDialog(BuildContext context, MockDatabase db, Innings inn, List<Player> bowlingTeamPlayers) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xF50B1120),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: NeoGlassTheme.glassBorder, width: 1.2),
            boxShadow: [
              NeoGlassTheme.neoDarkShadow,
              NeoGlassTheme.neoLightHighlight,
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'RECORD EXTRAS',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: NeoGlassTheme.neonEmerald,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Wide (+1 Run)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: const Text('Bowler charged 1 run, not a legal ball', style: TextStyle(color: Colors.white60, fontSize: 11)),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.arrow_forward, color: Colors.amber, size: 20),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _executeDelivery(
                    context: context,
                    db: db,
                    inn: inn,
                    bowlingPlayers: bowlingTeamPlayers,
                    runsBatter: 0,
                    extrasRuns: 1,
                    extrasType: ExtrasType.wide,
                  );
                },
              ),
              const Divider(color: Colors.white12, height: 1),
              ListTile(
                title: const Text('No-Ball (+1 Run)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: const Text('Bowler charged 1 run, free hit awarded', style: TextStyle(color: Colors.white60, fontSize: 11)),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.not_interested, color: Colors.redAccent, size: 20),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _executeDelivery(
                    context: context,
                    db: db,
                    inn: inn,
                    bowlingPlayers: bowlingTeamPlayers,
                    runsBatter: 0,
                    extrasRuns: 1,
                    extrasType: ExtrasType.noBall,
                  );
                },
              ),
              const Divider(color: Colors.white12, height: 1),
              ListTile(
                title: const Text('Bye (+1 Run)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: const Text('Runs not charged to bowler, counts as legal delivery', style: TextStyle(color: Colors.white60, fontSize: 11)),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.blueAccent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.directions_run, color: Colors.blueAccent, size: 20),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _executeDelivery(
                    context: context,
                    db: db,
                    inn: inn,
                    bowlingPlayers: bowlingTeamPlayers,
                    runsBatter: 0,
                    extrasRuns: 1,
                    extrasType: ExtrasType.bye,
                  );
                },
              ),
              const Divider(color: Colors.white12, height: 1),
              ListTile(
                title: const Text('Leg Bye (+1 Run)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: const Text('Ball hit pad/body, counts as legal delivery', style: TextStyle(color: Colors.white60, fontSize: 11)),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFF34D399).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.shield_outlined, color: Color(0xFF34D399), size: 20),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _executeDelivery(
                    context: context,
                    db: db,
                    inn: inn,
                    bowlingPlayers: bowlingTeamPlayers,
                    runsBatter: 0,
                    extrasRuns: 1,
                    extrasType: ExtrasType.legBye,
                  );
                },
              ),
            ],
          ),
        );
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
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Innings 1 is currently ${inn1?.totalRuns ?? 0}/${inn1?.wickets ?? 0} in ${(inn1?.legalBalls ?? 0) ~/ 6}.${(inn1?.legalBalls ?? 0) % 6} overs.\n\nDo you want to declare/conclude Innings 1 and start Innings 2 with a target of ${(inn1?.totalRuns ?? 0) + 1} runs?',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
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
    final chasingTeamId = (inn1?.battingTeamId == match.teamAId) ? match.teamBId : match.teamAId;
    final defendingTeamId = (chasingTeamId == match.teamAId) ? match.teamBId : match.teamAId;

    final chasingTeam = db.getTeam(chasingTeamId) ?? MockDatabase.emptyTeam;
    final defendingTeam = db.getTeam(defendingTeamId) ?? MockDatabase.emptyTeam;

    final chasingPlayers = chasingTeamId == match.teamAId ? teamAPlayers : teamBPlayers;
    final defendingPlayers = defendingTeamId == match.teamAId ? teamAPlayers : teamBPlayers;

    String? selectedStrikerId = chasingPlayers.isNotEmpty ? chasingPlayers[0].id : null;
    String? selectedNonStrikerId = chasingPlayers.length > 1 ? chasingPlayers[1].id : selectedStrikerId;
    String? selectedBowlerId = defendingPlayers.where((p) => p.role == PlayerRole.bowler).firstOrNull?.id ??
        (defendingPlayers.isNotEmpty ? defendingPlayers[0].id : null);

    final target = (inn1?.totalRuns ?? 0) + 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final isSameBatter = selectedStrikerId != null &&
                selectedNonStrikerId != null &&
                selectedStrikerId == selectedNonStrikerId;

            return Container(
              decoration: BoxDecoration(
                color: NeoGlassTheme.bgSurface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: NeoGlassTheme.glassBorder),
                boxShadow: [NeoGlassTheme.neoDarkShadow],
              ),
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: NeoGlassTheme.neonEmerald.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: NeoGlassTheme.neonEmerald.withValues(alpha: 0.5)),
                          ),
                          child: const Icon(Icons.sports_cricket, color: NeoGlassTheme.neonEmerald, size: 22),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Start Innings 2 (Chase)',
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${chasingTeam.name} needs $target runs in ${match.overs} overs to win',
                                style: const TextStyle(color: NeoGlassTheme.neonEmerald, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(modalCtx),
                          icon: const Icon(Icons.close, color: Colors.white54),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Innings 1 Summary Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: NeoGlassTheme.bgCanvas,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Innings 1 Total', style: TextStyle(color: Colors.white60, fontSize: 10)),
                              Text(
                                '${defendingTeam.name}: ${inn1?.totalRuns ?? 0}/${inn1?.wickets ?? 0} (${(inn1?.legalBalls ?? 0) ~/ 6}.${(inn1?.legalBalls ?? 0) % 6} ov)',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: NeoGlassTheme.neonGradient,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Target: $target',
                              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    const Text(
                      'SELECT OPENING CREASE LINEUP FOR INNINGS 2',
                      style: TextStyle(color: NeoGlassTheme.neonEmerald, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 10),

                    // Striker
                    Text('Opening Striker (${chasingTeam.name}):', style: const TextStyle(color: NeoGlassTheme.neonAmber, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: selectedStrikerId,
                      isExpanded: true,
                      dropdownColor: NeoGlassTheme.bgSurface,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      decoration: NeoGlassTheme.inputDecoration(hintText: 'Select Opening Striker'),
                      items: chasingPlayers.map((p) {
                        final pName = p.fullName.isNotEmpty ? p.fullName : p.displayName;
                        return DropdownMenuItem(value: p.id, child: Text(pName, overflow: TextOverflow.ellipsis));
                      }).toList(),
                      onChanged: (val) => setModalState(() => selectedStrikerId = val),
                    ),
                    const SizedBox(height: 10),

                    // Non-Striker
                    Text('Opening Non-Striker (${chasingTeam.name}):', style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: selectedNonStrikerId,
                      isExpanded: true,
                      dropdownColor: NeoGlassTheme.bgSurface,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      decoration: NeoGlassTheme.inputDecoration(hintText: 'Select Opening Non-Striker'),
                      items: chasingPlayers.map((p) {
                        final pName = p.fullName.isNotEmpty ? p.fullName : p.displayName;
                        return DropdownMenuItem(value: p.id, child: Text(pName, overflow: TextOverflow.ellipsis));
                      }).toList(),
                      onChanged: (val) => setModalState(() => selectedNonStrikerId = val),
                    ),
                    const SizedBox(height: 10),

                    if (isSameBatter) ...[
                      const Text('⚠️ Striker & Non-Striker must be different players.', style: TextStyle(color: Colors.redAccent, fontSize: 11)),
                      const SizedBox(height: 10),
                    ],

                    // Bowler
                    Text('Opening Bowler (${defendingTeam.name}):', style: const TextStyle(color: NeoGlassTheme.neonEmerald, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: selectedBowlerId,
                      isExpanded: true,
                      dropdownColor: NeoGlassTheme.bgSurface,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      decoration: NeoGlassTheme.inputDecoration(hintText: 'Select Opening Bowler'),
                      items: defendingPlayers.map((p) {
                        final pName = p.fullName.isNotEmpty ? p.fullName : p.displayName;
                        return DropdownMenuItem(value: p.id, child: Text(pName, overflow: TextOverflow.ellipsis));
                      }).toList(),
                      onChanged: (val) => setModalState(() => selectedBowlerId = val),
                    ),
                    const SizedBox(height: 18),

                    NeoGlassButton(
                      onPressed: (!isSameBatter && selectedStrikerId != null && selectedNonStrikerId != null && selectedBowlerId != null)
                          ? () {
                              Navigator.pop(modalCtx);
                              db.startInnings2(
                                matchId: match.id,
                                strikerId: selectedStrikerId,
                                nonStrikerId: selectedNonStrikerId,
                                bowlerId: selectedBowlerId,
                              );
                              setState(() => selectedInningsNum = 2);
                            }
                          : null,
                      gradient: NeoGlassTheme.neonGradient,
                      icon: Icons.play_arrow,
                      child: const Text('Start Innings 2 & Begin Scoring', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
