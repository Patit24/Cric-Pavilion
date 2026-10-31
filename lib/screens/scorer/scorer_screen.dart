import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/mock_database.dart';
import '../../services/cricket_rules_engine.dart';
import 'crease_hud_widget.dart';
import 'over_complete_dialog.dart';
import 'wicket_dialog.dart';
import 'toss_wizard_sheet.dart';
import 'full_scorecard_dialog.dart';

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
    final match = db.matches.firstWhere(
      (m) => m.id == selectedMatchId,
      orElse: () => db.matches.first,
    );

    final isScorer = db.isScoringUnlockedForMatch(match.id);
    final currentRoom = db.getScoringRoomForMatch(match.id);

    final teamA = db.teams.firstWhere((t) => t.id == match.teamAId);
    final teamB = db.teams.firstWhere((t) => t.id == match.teamBId);

    final matchInnings = db.inningsList.where((i) => i.matchId == match.id).toList();
    final inn1 = matchInnings.where((i) => i.inningsNumber == 1).firstOrNull;
    final inn2 = matchInnings.where((i) => i.inningsNumber == 2).firstOrNull;

    // Track active innings
    final currentInnings = (selectedInningsNum == 2 && inn2 != null) ? inn2 : (inn1 ?? matchInnings.firstOrNull);

    final isPreMatch = match.status == MatchStatus.scheduled || match.status == MatchStatus.toss || inn1 == null;
    final isMatchCompleted = match.status == MatchStatus.completed;

    // Roster players
    final teamAPlayers = db.players.where((p) => p.teamId == teamA.id).toList();
    final teamBPlayers = db.players.where((p) => p.teamId == teamB.id).toList();
    final safeTeamAPlayers = teamAPlayers.isNotEmpty ? teamAPlayers : db.players.sublist(0, 5);
    final safeTeamBPlayers = teamBPlayers.isNotEmpty ? teamBPlayers : db.players.sublist(5, 10);

    // Batting & Bowling Teams for active innings
    final battingTeamId = currentInnings?.battingTeamId ?? match.battingFirstId ?? teamA.id;
    final battingTeamPlayers = battingTeamId == teamA.id ? safeTeamAPlayers : safeTeamBPlayers;
    final bowlingTeamPlayers = battingTeamId == teamA.id ? safeTeamBPlayers : safeTeamAPlayers;

    // Crease Players
    final striker = db.players.where((p) => p.id == currentInnings?.currentStrikerId).firstOrNull ?? battingTeamPlayers.firstOrNull;
    final nonStriker = db.players.where((p) => p.id == currentInnings?.currentNonStrikerId).firstOrNull ?? (battingTeamPlayers.length > 1 ? battingTeamPlayers[1] : null);
    final bowler = db.players.where((p) => p.id == currentInnings?.currentBowlerId).firstOrNull;

    // Crease Scorecards
    final strikerCard = db.battingScorecards.where((b) => b.inningsId == currentInnings?.id && b.playerId == striker?.id).firstOrNull ??
        BattingScorecard(id: 'temp_str', inningsId: currentInnings?.id ?? '', matchId: match.id, playerId: striker?.id ?? '', playerName: striker?.fullName ?? '');

    final nonStrikerCard = db.battingScorecards.where((b) => b.inningsId == currentInnings?.id && b.playerId == nonStriker?.id).firstOrNull ??
        BattingScorecard(id: 'temp_non', inningsId: currentInnings?.id ?? '', matchId: match.id, playerId: nonStriker?.id ?? '', playerName: nonStriker?.fullName ?? '');

    final bowlerCard = db.bowlingScorecards.where((b) => b.inningsId == currentInnings?.id && b.playerId == bowler?.id).firstOrNull ??
        BowlingScorecard(id: 'temp_bowl', inningsId: currentInnings?.id ?? '', matchId: match.id, playerId: bowler?.id ?? '', playerName: bowler?.fullName ?? '');

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedMatchId,
                dropdownColor: const Color(0xFF1E293B),
                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 18),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                items: db.matches.map((m) {
                  return DropdownMenuItem<String>(
                    value: m.id,
                    child: Text('${m.stage} (${m.status.name.toUpperCase()})'),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      selectedMatchId = val;
                      final newMatch = db.matches.firstWhere((m) => m.id == val);
                      selectedInningsNum = newMatch.currentInningsNumber;
                    });
                  }
                },
              ),
            ),
            Row(
              children: [
                Icon(
                  isScorer ? Icons.check_circle : Icons.lock_outline,
                  size: 11,
                  color: isScorer ? const Color(0xFF34D399) : Colors.amber,
                ),
                const SizedBox(width: 4),
                Text(
                  isScorer
                      ? 'Scorer Room: ${currentRoom?.id ?? "ROOM-BPL-01"}'
                      : 'Spectator Mode (Live Score Only)',
                  style: TextStyle(
                    color: isScorer ? const Color(0xFF34D399) : Colors.amber.shade300,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (!isScorer) ...[
            TextButton.icon(
              onPressed: () => _showEnterRoomDialog(context, db, match),
              icon: const Icon(Icons.vpn_key, size: 14, color: Color(0xFF34D399)),
              label: const Text('Enter Room', style: TextStyle(color: Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.bold)),
            ),
            IconButton(
              tooltip: 'Create Scoring Room',
              icon: const Icon(Icons.add_circle_outline, color: Colors.amber, size: 20),
              onPressed: () => _showCreateRoomDialog(context, db, match),
            ),
          ] else ...[
            TextButton.icon(
              onPressed: () {
                db.lockScoringRoom(match.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Locked scoring console. Returned to Spectator Mode.')),
                );
              },
              icon: const Icon(Icons.lock, size: 14, color: Colors.redAccent),
              label: const Text('Exit Scorer', style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
            IconButton(
              tooltip: 'Reset Match',
              icon: const Icon(Icons.refresh, color: Colors.white70, size: 20),
              onPressed: () => _confirmResetMatch(context, db, match),
            ),
          ],
          IconButton(
            tooltip: 'View Full Scorecard',
            icon: const Icon(Icons.table_chart, color: Color(0xFF34D399), size: 20),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => FullScorecardDialog(match: match, db: db),
              );
            },
          ),
        ],
      ),
      body: isPreMatch
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
                    const SizedBox(height: 8),
                    Text(
                      'Demo Room: ${currentRoom?.id ?? "ROOM-BPL-01"}  •  Passcode: 1234',
                      style: const TextStyle(color: Colors.white38, fontSize: 10),
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
                    Text(db.teams.firstWhere((t) => t.id == inn1.battingTeamId).name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                    Text(db.teams.firstWhere((t) => t.id == inn2.battingTeamId).name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                  onTap: (inn2 != null || inn1?.isCompleted == true)
                      ? () => setState(() => selectedInningsNum = 2)
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Innings 2 unlocks after Innings 1 completes (20 ov or 10 wkts).')),
                          );
                        },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: selectedInningsNum == 2 ? const Color(0xFF059669) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Innings 2 ${inn2 != null ? "(${inn2.totalRuns}/${inn2.wickets})" : "(Locked)"}',
                      style: TextStyle(
                        color: (inn2 != null || inn1?.isCompleted == true) ? Colors.white : Colors.white30,
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
                // MAIN SCORE BANNER
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF064E3B), Color(0xFF022C22)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF047857)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${match.stage} • Innings ${currentInnings.inningsNumber}',
                            style: const TextStyle(color: Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.bold),
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
                            style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w900),
                          ),
                          Text(
                            '/${currentInnings.wickets}',
                            style: const TextStyle(color: Color(0xFF34D399), fontSize: 32, fontWeight: FontWeight.w900),
                          ),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'CRR: ${currentInnings.runRate.toStringAsFixed(2)}',
                                style: const TextStyle(color: Color(0xFF34D399), fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              if (currentInnings.targetRuns != null)
                                Text(
                                  'Target: ${currentInnings.targetRuns} (Need $runsRemaining in $ballsRemaining b, RRR: $rrr)',
                                  style: const TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                            ],
                          ),
                        ],
                      ),
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
                const SizedBox(height: 4),
                Text(
                  'Demo: Room: ${currentRoom?.id ?? "ROOM-BPL-01"}  •  PIN: 1234',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white38, fontSize: 9),
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
                label: Text(bowler?.displayName ?? 'Pick Bowler', style: const TextStyle(color: Color(0xFF34D399), fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Runs Keypad (0, 1, 2, 3, 4, 6)
          Row(
            children: [0, 1, 2, 3, 4, 6].map((run) {
              final isBoundary = run == 4 || run == 6;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: ElevatedButton(
                    onPressed: bowler == null
                        ? () {
                            _showBowlerSelectDialog(context, db, currentInnings, bowlingTeamPlayers, prevBowlerId);
                          }
                        : () {
                            db.recordDelivery(
                              inningsId: currentInnings.id,
                              runsBatter: run,
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isBoundary
                          ? (run == 4 ? Colors.blue.shade700 : Colors.purple.shade700)
                          : (run == 0 ? Colors.grey.shade800 : Colors.white),
                      foregroundColor: (run == 0 || isBoundary) ? Colors.white : Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      '$run',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 10),

          // Action Row: EXTRAS & WICKET
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: bowler == null
                      ? null
                      : () => _showExtrasDialog(context, db, currentInnings),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade700,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('EXTRAS (Wd/Nb/B)', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: (bowler == null || striker == null || nonStriker == null)
                      ? null
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
                                db.recordDelivery(
                                  inningsId: currentInnings.id,
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('WICKET (OUT!)', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
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
                  // Demo autofill chip
                  InkWell(
                    onTap: () {
                      setDialogState(() {
                        roomController.text = existingRoom?.id ?? 'ROOM-BPL-01';
                        passController.text = existingRoom?.passcode ?? '1234';
                        errorMessage = null;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.touch_app, size: 12, color: Colors.amber),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Auto-fill Demo: ${existingRoom?.id ?? "ROOM-BPL-01"} / 1234',
                              style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
                      errorMessage = 'Invalid Room ID or Passcode for this match.';
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

  void _showExtrasDialog(BuildContext context, MockDatabase db, Innings inn) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('RECORD EXTRAS', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Wide (+1 Run)'),
                subtitle: const Text('Bowler charged 1 run, not a legal ball'),
                leading: const Icon(Icons.arrow_forward, color: Colors.amber),
                onTap: () {
                  Navigator.pop(ctx);
                  db.recordDelivery(inningsId: inn.id, runsBatter: 0, extrasRuns: 1, extrasType: ExtrasType.wide);
                },
              ),
              ListTile(
                title: const Text('No-Ball (+1 Run)'),
                subtitle: const Text('Bowler charged 1 run, free hit awarded'),
                leading: const Icon(Icons.not_interested, color: Colors.red),
                onTap: () {
                  Navigator.pop(ctx);
                  db.recordDelivery(inningsId: inn.id, runsBatter: 0, extrasRuns: 1, extrasType: ExtrasType.noBall);
                },
              ),
              ListTile(
                title: const Text('Bye / Leg Bye (+1 Run)'),
                subtitle: const Text('Runs not charged to bowler, counts as legal delivery'),
                leading: const Icon(Icons.run_circle, color: Colors.blue),
                onTap: () {
                  Navigator.pop(ctx);
                  db.recordDelivery(inningsId: inn.id, runsBatter: 0, extrasRuns: 1, extrasType: ExtrasType.bye);
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
}
