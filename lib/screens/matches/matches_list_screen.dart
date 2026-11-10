import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/mock_database.dart';
import '../../widgets/role_switcher_chip.dart';
import 'match_detail_screen.dart';
import '../scorer/scorer_screen.dart';

class MatchesListScreen extends StatefulWidget {
  const MatchesListScreen({super.key});

  @override
  State<MatchesListScreen> createState() => _MatchesListScreenState();
}

class _MatchesListScreenState extends State<MatchesListScreen> {
  String filter = 'all'; // 'all', 'live', 'completed', 'scheduled'

  @override
  Widget build(BuildContext context) {
    final db = context.watch<MockDatabase>();

    final filteredMatches = db.matches.where((m) {
      if (filter == 'live') return m.status == MatchStatus.live;
      if (filter == 'completed') return m.status == MatchStatus.completed;
      if (filter == 'scheduled') return m.status == MatchStatus.scheduled || m.status == MatchStatus.toss;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: const Text('Matches & Scorecards', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: const [
          RoleSwitcherChip(compact: true),
          SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          // Filter Pills
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: ['all', 'live', 'completed', 'scheduled'].map((f) {
                final isSelected = filter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      f == 'all' ? 'All (${db.matches.length})' : f.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.black : Colors.white70,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFF34D399),
                    backgroundColor: const Color(0xFF1E293B),
                    onSelected: (val) => setState(() => filter = f),
                  ),
                );
              }).toList(),
            ),
          ),

          // Matches List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filteredMatches.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final m = filteredMatches[i];
                final teamA = db.teams.firstWhere((t) => t.id == m.teamAId);
                final teamB = db.teams.firstWhere((t) => t.id == m.teamBId);
                final inn1 = db.inningsList.where((inn) => inn.matchId == m.id && inn.inningsNumber == 1).firstOrNull;
                final inn2 = db.inningsList.where((inn) => inn.matchId == m.id && inn.inningsNumber == 2).firstOrNull;

                final isLive = m.status == MatchStatus.live;
                final isCompleted = m.status == MatchStatus.completed;

                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (ctx) => MatchDetailScreen(matchId: m.id)),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isLive ? Colors.red.shade400 : const Color(0xFF334155),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Card Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(m.stage, style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isLive ? Colors.red : (isCompleted ? const Color(0xFF059669) : Colors.white12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                m.status.name.toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Team A
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(radius: 12, backgroundColor: teamA.primaryColor, child: Text(teamA.shortName, style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold))),
                                const SizedBox(width: 8),
                                Text(teamA.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                              ],
                            ),
                            if (inn1 != null)
                              Text('${inn1.totalRuns}/${inn1.wickets} (${inn1.oversStr} ov)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))
                            else
                              const Text('Ready', style: TextStyle(color: Colors.white38, fontSize: 11)),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Team B
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(radius: 12, backgroundColor: teamB.primaryColor, child: Text(teamB.shortName, style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold))),
                                const SizedBox(width: 8),
                                Text(teamB.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                              ],
                            ),
                            if (inn2 != null)
                              Text('${inn2.totalRuns}/${inn2.wickets} (${inn2.oversStr} ov)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))
                            else
                              const Text('Ready', style: TextStyle(color: Colors.white38, fontSize: 11)),
                          ],
                        ),

                        // Result or Action Footer
                        const Divider(color: Color(0xFF334155), height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(m.venue, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                            if (m.status == MatchStatus.scheduled || m.status == MatchStatus.toss)
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (ctx) => ScorerScreen(initialMatchId: m.id)),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF059669),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('🪙 Conduct Toss & Score', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                              )
                            else if (isCompleted)
                              Text('${db.teams.firstWhere((t) => t.id == m.winnerId).name} won by ${m.winMargin}', style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold, fontSize: 11))
                            else
                              const Text('Live Match Centre →', style: TextStyle(color: Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
