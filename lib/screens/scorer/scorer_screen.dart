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
        title: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selectedMatchId,
            dropdownColor: const Color(0xFF1E293B),
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
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
        actions: [
          IconButton(
            tooltip: 'View Full Scorecard',
            icon: const Icon(Icons.table_chart, color: Color(0xFF34D399)),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => FullScorecardDialog(match: match, db: db),
              );
            },
          ),
          IconButton(
            tooltip: 'Reset Match',
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: () => _confirmResetMatch(context, db, match),
          ),
        ],
      ),
      body: isPreMatch
          ? _buildPreMatchTossView(context, db, match, teamA, teamB, safeTeamAPlayers, safeTeamBPlayers)
          : isMatchCompleted
              ? _buildCompletedMatchView(context, db, match, inn1, inn2)
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
  ) {
    return Center(
      child: Padding(
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
            const SizedBox(height: 32),
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
          ],
        ),
      ),
    );
  }

  // ==========================================
  // COMPLETED MATCH VIEW
  // ==========================================
  Widget _buildCompletedMatchView(BuildContext context, MockDatabase db, MatchModel match, Innings? inn1, Innings? inn2) {
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
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => _confirmResetMatch(context, db, match),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white70),
                  child: const Text('Reset Match'),
                ),
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
                  onSwapEnds: () => db.swapEnds(currentInnings.id),
                  onChangeBowler: () {
                    _showBowlerSelectDialog(context, db, currentInnings, bowlingTeamPlayers, prevBowlerId);
                  },
                ),
              ],
            ),
          ),
        ),

        // FIXED BOTTOM ERGONOMIC KEYPAD
        Container(
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
        ),
      ],
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
