import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
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
    final isCreator = db.createdTournamentIds.contains(activeTourn.id);
    final isUnlocked = db.authenticatedTournamentIds.contains(activeTourn.id);

    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        backgroundColor: const Color(0xFF009270),
        elevation: 0,
        title: const Text('Standings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        actions: [
          const RoleSwitcherChip(compact: true),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Create Tournament',
            icon: const Icon(Icons.add_circle, color: Colors.white, size: 22),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => CreateTournamentDialog(db: db),
              );
            },
          ),
          const SizedBox(width: 6),
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
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isCreator
                              ? const Color(0xFF059669).withValues(alpha: 0.3)
                              : isUnlocked
                                  ? const Color(0xFF0284C7).withValues(alpha: 0.3)
                                  : Colors.white10,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isCreator
                                ? const Color(0xFF34D399)
                                : isUnlocked
                                    ? const Color(0xFF38BDF8)
                                    : Colors.white24,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isCreator ? Icons.star : (isUnlocked ? Icons.check_circle : Icons.visibility),
                              size: 12,
                              color: isCreator
                                  ? const Color(0xFF34D399)
                                  : isUnlocked
                                      ? const Color(0xFF38BDF8)
                                      : Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isCreator
                                  ? 'Created by You (Full Control)'
                                  : isUnlocked
                                      ? 'Scoring Unlocked (Authorized Scorer)'
                                      : 'Viewer Mode (Public Scores Only)',
                              style: TextStyle(
                                color: isCreator
                                    ? const Color(0xFF34D399)
                                    : isUnlocked
                                        ? const Color(0xFF38BDF8)
                                        : Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (!isCreator && !isUnlocked)
                        ElevatedButton.icon(
                          onPressed: () => _showUnlockTournamentDialog(context, db, activeTourn),
                          icon: const Icon(Icons.vpn_key, size: 12),
                          label: const Text('Unlock to Score', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          ),
                        ),
                    ],
                  ),
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

  void _showUnlockTournamentDialog(BuildContext context, MockDatabase db, Tournament tourn) {
    final roomController = TextEditingController(text: tourn.roomId.isNotEmpty ? tourn.roomId : tourn.id);
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
                Text('Unlock Tournament Scoring', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Enter the Tournament ID/Room ID and Passcode set by the tournament organizer to unlock full scoring control for all matches in ${tourn.name}.',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: roomController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Tournament / Room ID',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: passController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Host Passcode / PIN',
                    labelStyle: const TextStyle(color: Colors.white70),
                    hintText: 'e.g. ${tourn.passcode}',
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
              ElevatedButton(
                onPressed: () {
                  final ok = db.unlockTournamentScoring(
                    tournamentIdOrRoomId: roomController.text,
                    passcode: passController.text,
                  );
                  if (ok) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF059669),
                        content: Text('Scoring access unlocked for ${tourn.name}!'),
                      ),
                    );
                  } else {
                    setDialogState(() => errorMessage = 'Invalid Tournament ID or Passcode PIN.');
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF34D399), foregroundColor: Colors.black),
                child: const Text('Unlock Scoring', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }
}
