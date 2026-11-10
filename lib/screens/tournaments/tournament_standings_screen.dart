import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/mock_database.dart';
import '../../widgets/role_switcher_chip.dart';
import 'create_tournament_dialog.dart';

class TournamentStandingsScreen extends StatefulWidget {
  const TournamentStandingsScreen({super.key});

  @override
  State<TournamentStandingsScreen> createState() => _TournamentStandingsScreenState();
}

class _TournamentStandingsScreenState extends State<TournamentStandingsScreen> {
  String? selectedTournamentId;

  @override
  Widget build(BuildContext context) {
    final db = context.watch<MockDatabase>();
    final activeTourn = db.tournaments.where((t) => t.id == selectedTournamentId).firstOrNull ?? db.tournament;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: const Text('Tournaments & Standings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          const RoleSwitcherChip(compact: true),
          const SizedBox(width: 4),
          TextButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => CreateTournamentDialog(db: db),
              );
            },
            icon: const Icon(Icons.add_circle, color: Color(0xFF34D399), size: 16),
            label: const Text('Create Tournament', style: TextStyle(color: Color(0xFF34D399), fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tournaments Horizontal Picker
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: db.tournaments.map((t) {
                  final isSelected = t.id == activeTourn.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: isSelected,
                      label: Text('${t.shortName} (${t.overs} Ov)'),
                      selectedColor: const Color(0xFF059669),
                      backgroundColor: const Color(0xFF1E293B),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => selectedTournamentId = t.id);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // Series Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF064E3B), Color(0xFF022C22)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF059669)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('COMPETITION STAGE', style: TextStyle(color: Color(0xFF34D399), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.amber),
                        ),
                        child: Text(
                          'Room: ${activeTourn.roomId.isNotEmpty ? activeTourn.roomId : "TOURN-BPL"} (PIN: ${activeTourn.passcode})',
                          style: const TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(activeTourn.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text('${activeTourn.overs} Overs T20 • ${activeTourn.location} • 8 Franchises', style: const TextStyle(color: Colors.white60, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Standings Card Table
            Card(
              color: const Color(0xFF1E293B),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  // Headers
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0F172A),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: const Row(
                      children: [
                        Expanded(flex: 5, child: Text('Team', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold))),
                        Expanded(flex: 1, child: Text('P', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold))),
                        Expanded(flex: 1, child: Text('W', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold))),
                        Expanded(flex: 1, child: Text('L', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold))),
                        Expanded(flex: 2, child: Text('PTS', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold))),
                        Expanded(flex: 2, child: Text('NRR', textAlign: TextAlign.right, style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ),

                  // Team Rows
                  ...db.tournamentStandings.asMap().entries.map((entry) {
                    final rank = entry.key + 1;
                    final s = entry.value;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: Row(
                              children: [
                                Text('$rank', style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                CircleAvatar(
                                  radius: 10,
                                  backgroundImage: NetworkImage(s.teamLogoUrl),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    s.teamName,
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(flex: 1, child: Text('${s.matchesPlayed}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 11))),
                          Expanded(flex: 1, child: Text('${s.won}', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.bold))),
                          Expanded(flex: 1, child: Text('${s.lost}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent, fontSize: 11))),
                          Expanded(flex: 2, child: Text('${s.points}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold))),
                          Expanded(flex: 2, child: Text(s.netRunRate.toStringAsFixed(3), textAlign: TextAlign.right, style: const TextStyle(color: Colors.white70, fontSize: 11))),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
