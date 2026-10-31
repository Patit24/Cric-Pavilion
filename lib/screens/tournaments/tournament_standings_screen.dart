import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/mock_database.dart';

class TournamentStandingsScreen extends StatelessWidget {
  const TournamentStandingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = context.watch<MockDatabase>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: const Text('Points Table & NRR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Series Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF064E3B), Color(0xFF022C22)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('FEATURED COMPETITION', style: TextStyle(color: Color(0xFF34D399), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                  const SizedBox(height: 4),
                  Text(db.tournament.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text('${db.tournament.overs} Overs T20 • ${db.tournament.location}', style: const TextStyle(color: Colors.white60, fontSize: 11)),
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
                          Expanded(flex: 1, child: Text('${s.matchesPlayed}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 12))),
                          Expanded(flex: 1, child: Text('${s.won}', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF34D399), fontSize: 12, fontWeight: FontWeight.bold))),
                          Expanded(flex: 1, child: Text('${s.lost}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, fontSize: 12))),
                          Expanded(flex: 2, child: Text('${s.points}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900))),
                          Expanded(
                            flex: 2,
                            child: Text(
                              s.netRunRate >= 0 ? '+${s.netRunRate.toStringAsFixed(3)}' : s.netRunRate.toStringAsFixed(3),
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: s.netRunRate >= 0 ? const Color(0xFF34D399) : Colors.red.shade400,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
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
