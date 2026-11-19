import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/mock_database.dart';
import '../scorer/full_scorecard_dialog.dart';

class MatchDetailScreen extends StatefulWidget {
  final String matchId;

  const MatchDetailScreen({super.key, required this.matchId});

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final db = context.watch<MockDatabase>();
    final match = db.matches.where((m) => m.id == widget.matchId).firstOrNull ??
        db.matches.firstOrNull ??
        MockDatabase.emptyMatch;

    final teamA = db.getTeam(match.teamAId) ?? MockDatabase.emptyTeam;
    final teamB = db.getTeam(match.teamBId) ?? MockDatabase.emptyTeam;

    final matchInnings = db.inningsList.where((i) => i.matchId == match.id).toList();
    final inn1 = matchInnings.where((i) => i.inningsNumber == 1).firstOrNull;
    final inn2 = matchInnings.where((i) => i.inningsNumber == 2).firstOrNull;
    final currentInnings = (match.currentInningsNumber == 2 && inn2 != null) ? inn2 : (inn1 ?? matchInnings.firstOrNull);

    final deliveries = db.deliveries.where((d) => d.matchId == match.id && !d.isUndone).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        backgroundColor: const Color(0xFF009270),
        elevation: 0,
        title: Text(match.stage, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Live Score'),
            Tab(text: 'Scorecard'),
            Tab(text: 'Commentary'),
            Tab(text: 'Squads'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Header Match Scores Summary
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF064E3B), Color(0xFF022C22)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(teamA.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    if (inn1 != null)
                      Text('${inn1.totalRuns}/${inn1.wickets} (${inn1.oversStr} ov)', style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.w900, fontSize: 18))
                    else
                      const Text('Yet to bat', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
                const Text('VS', style: TextStyle(color: Colors.white24, fontWeight: FontWeight.w900, fontSize: 16)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(teamB.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    if (inn2 != null)
                      Text('${inn2.totalRuns}/${inn2.wickets} (${inn2.oversStr} ov)', style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.w900, fontSize: 18))
                    else
                      const Text('Yet to bat', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: LIVE CREASE
                _buildLiveTab(context, db, match, currentInnings, deliveries),

                // TAB 2: FULL SCORECARD
                _buildScorecardTab(context, db, match, inn1, inn2),

                // TAB 3: BALL-BY-BALL COMMENTARY
                _buildCommentaryTab(context, deliveries),

                // TAB 4: SQUADS
                _buildSquadsTab(context, db, teamA, teamB),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveTab(BuildContext context, MockDatabase db, MatchModel match, Innings? inn, List<Delivery> dels) {
    if (inn == null) {
      return const Center(child: Text('No active innings yet', style: TextStyle(color: Colors.white54)));
    }

    final striker = db.players.where((p) => p.id == inn.currentStrikerId).firstOrNull;
    final nonStriker = db.players.where((p) => p.id == inn.currentNonStrikerId).firstOrNull;
    final bowler = db.players.where((p) => p.id == inn.currentBowlerId).firstOrNull;

    final strikerCard = db.battingScorecards.where((b) => b.inningsId == inn.id && b.playerId == striker?.id).firstOrNull;
    final bowlerCard = db.bowlingScorecards.where((b) => b.inningsId == inn.id && b.playerId == bowler?.id).firstOrNull;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Batters Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('BATTERS AT CREASE', style: TextStyle(color: Color(0xFF34D399), fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (striker != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('★ ${striker.fullName} (Striker)', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('${strikerCard?.runs ?? 62}* (${strikerCard?.balls ?? 38}b) • SR ${strikerCard?.strikeRate.toStringAsFixed(1) ?? "163.2"}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                const SizedBox(height: 6),
                if (nonStriker != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('• ${nonStriker.fullName} (Non-Striker)', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      const Text('45* (31b) • SR 145.2', style: TextStyle(color: Colors.white60, fontSize: 12)),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Bowler Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ACTIVE BOWLER', style: TextStyle(color: Color(0xFF34D399), fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(bowler?.fullName ?? 'Active Bowler', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(bowler?.bowlingStyle ?? 'Right Arm Medium', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                  ],
                ),
                Text(
                  '${bowlerCard?.oversStr ?? "2.4"}-${bowlerCard?.maidens ?? 0}-${bowlerCard?.runsConceded ?? 24}-${bowlerCard?.wickets ?? 1}\nEcon: ${bowlerCard?.economy.toStringAsFixed(2) ?? "9.00"}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScorecardTab(BuildContext context, MockDatabase db, MatchModel match, Innings? inn1, Innings? inn2) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => FullScorecardDialog(match: match, db: db),
              );
            },
            icon: const Icon(Icons.fullscreen),
            label: const Text('Open Full Screen Interactive Scorecard'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentaryTab(BuildContext context, List<Delivery> dels) {
    if (dels.isEmpty) {
      return const Center(child: Text('No commentary logged yet', style: TextStyle(color: Colors.white54)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: dels.length,
      separatorBuilder: (ctx, i) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        final d = dels.reversed.toList()[i];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: d.isWicket ? Colors.red : (d.runsBatter >= 4 ? Colors.purple : const Color(0xFF334155)),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  d.isWicket ? 'W' : '${d.runsBatter}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Over ${d.overNumber}.${d.ballInOver}', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                    const SizedBox(height: 2),
                    Text(d.commentaryText, style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSquadsTab(BuildContext context, MockDatabase db, Team teamA, Team teamB) {
    final teamAPlayers = db.players.where((p) => p.teamId == teamA.id).toList();
    final teamBPlayers = db.players.where((p) => p.teamId == teamB.id).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('${teamA.name} Squad', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        ...teamAPlayers.map((p) => ListTile(
              leading: CircleAvatar(backgroundImage: NetworkImage(p.photoUrl)),
              title: Text(p.fullName, style: const TextStyle(color: Colors.white, fontSize: 13)),
              subtitle: Text(p.roleString, style: const TextStyle(color: Colors.white54, fontSize: 11)),
            )),
        const Divider(color: Colors.white24, height: 32),
        Text('${teamB.name} Squad', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        ...teamBPlayers.map((p) => ListTile(
              leading: CircleAvatar(backgroundImage: NetworkImage(p.photoUrl)),
              title: Text(p.fullName, style: const TextStyle(color: Colors.white, fontSize: 13)),
              subtitle: Text(p.roleString, style: const TextStyle(color: Colors.white54, fontSize: 11)),
            )),
      ],
    );
  }
}
