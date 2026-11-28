import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/mock_database.dart';
import '../scorer/full_scorecard_dialog.dart';

class CompletedMatchesScreen extends StatefulWidget {
  const CompletedMatchesScreen({super.key});

  @override
  State<CompletedMatchesScreen> createState() => _CompletedMatchesScreenState();
}

class _CompletedMatchesScreenState extends State<CompletedMatchesScreen> {
  final _searchController = TextEditingController();
  String _selectedTournamentId = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final db = context.watch<MockDatabase>();
    final completed = db.completedMatches;
    final query = _searchController.text.trim().toLowerCase();

    // Tournaments with completed matches
    final tournamentIdsWithCompleted = completed.map((m) => m.tournamentId).toSet();
    final completedTournaments = db.tournaments.where((t) => tournamentIdsWithCompleted.contains(t.id)).toList();

    final filtered = completed.where((m) {
      if (_selectedTournamentId != 'all' && m.tournamentId != _selectedTournamentId) {
        return false;
      }
      if (query.isNotEmpty) {
        final teamA = db.getTeam(m.teamAId)?.name.toLowerCase() ?? '';
        final teamB = db.getTeam(m.teamBId)?.name.toLowerCase() ?? '';
        final stage = m.stage.toLowerCase();
        final venue = m.venue.toLowerCase();
        final tourn = db.getTournament(m.tournamentId);
        final tournName = tourn?.name.toLowerCase() ?? '';
        final tournShort = tourn?.shortName.toLowerCase() ?? '';

        return teamA.contains(query) ||
            teamB.contains(query) ||
            stage.contains(query) ||
            venue.contains(query) ||
            tournName.contains(query) ||
            tournShort.contains(query);
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: const Text(
          'Completed Matches',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Text(
                '${completed.length} Finished',
                style: const TextStyle(color: Color(0xFF00F5A0), fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              border: Border(bottom: BorderSide(color: Colors.white12)),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search match results by tournament, team, or venue...',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF00F5A0), size: 18),
                suffixIcon: (_searchController.text.isNotEmpty || _selectedTournamentId != 'all')
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54, size: 16),
                        onPressed: () => setState(() {
                          _searchController.clear();
                          _selectedTournamentId = 'all';
                        }),
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF1E293B),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          // Tournament Filter Chips
          if (completedTournaments.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFF0B132B),
                border: Border(bottom: BorderSide(color: Colors.white12)),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildTournChip(
                      label: 'All Tournaments (${completed.length})',
                      isSelected: _selectedTournamentId == 'all' && query.isEmpty,
                      onTap: () {
                        setState(() {
                          _selectedTournamentId = 'all';
                          _searchController.clear();
                        });
                      },
                    ),
                    ...completedTournaments.map((tourn) {
                      final count = completed.where((m) => m.tournamentId == tourn.id).length;
                      final isSelected = _selectedTournamentId == tourn.id;
                      return _buildTournChip(
                        label: '${tourn.shortName.isNotEmpty ? tourn.shortName : tourn.name} ($count)',
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            _selectedTournamentId = isSelected ? 'all' : tourn.id;
                            _searchController.clear();
                          });
                        },
                      );
                    }),
                  ],
                ),
              ),
            ),

          // Matches List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          (query.isNotEmpty || _selectedTournamentId != 'all') ? Icons.search_off : Icons.sports_cricket,
                          color: Colors.white24,
                          size: 52,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          (query.isNotEmpty || _selectedTournamentId != 'all')
                              ? 'No results found for this tournament'
                              : 'No completed matches yet',
                          style: const TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            (query.isNotEmpty || _selectedTournamentId != 'all')
                                ? 'Try searching for another tournament or reset filters.'
                                : 'Matches will permanently appear here with full ball-by-ball scorecards and career statistics once finalized.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white38, fontSize: 12),
                          ),
                        ),
                        if (query.isNotEmpty || _selectedTournamentId != 'all') ...[
                          const SizedBox(height: 14),
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _selectedTournamentId = 'all';
                              });
                            },
                            icon: const Icon(Icons.refresh, size: 14),
                            label: const Text('Reset Search Filter'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00F5A0),
                              foregroundColor: Colors.black,
                              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final m = filtered[index];
                      final teamA = db.getTeam(m.teamAId);
                      final teamB = db.getTeam(m.teamBId);
                      final inn1 = db.inningsList.where((i) => i.matchId == m.id && i.inningsNumber == 1).firstOrNull;
                      final inn2 = db.inningsList.where((i) => i.matchId == m.id && i.inningsNumber == 2).firstOrNull;
                      final tourn = m.isStandalone ? null : db.getTournament(m.tournamentId);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white12),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 8),
                          ],
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => FullScorecardDialog(match: m, db: db),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Header: Tournament / Standalone & Date
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: m.isStandalone
                                            ? Colors.amber.withValues(alpha: 0.15)
                                            : const Color(0xFF00F5A0).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: m.isStandalone ? Colors.amberAccent : const Color(0xFF00F5A0),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Text(
                                        m.isStandalone ? 'Direct 2-Team Match' : (tourn?.name ?? 'Tournament'),
                                        style: TextStyle(
                                          color: m.isStandalone ? Colors.amberAccent : const Color(0xFF00F5A0),
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${m.stage} • ${m.overs} Ov',
                                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                                    ),
                                    const Spacer(),
                                    const Icon(Icons.verified, color: Color(0xFF00F5A0), size: 14),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'Permanent Record',
                                      style: TextStyle(color: Color(0xFF00F5A0), fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Team A Score Row
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: teamA?.primaryColor ?? Colors.blueGrey,
                                      child: Text(
                                        teamA?.shortName.substring(0, 1) ?? 'A',
                                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        teamA?.name ?? 'Team A',
                                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    if (inn1 != null && inn1.battingTeamId == m.teamAId)
                                      Text(
                                        '${inn1.totalRuns}/${inn1.wickets} (${inn1.oversStr} ov)',
                                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                      )
                                    else if (inn2 != null && inn2.battingTeamId == m.teamAId)
                                      Text(
                                        '${inn2.totalRuns}/${inn2.wickets} (${inn2.oversStr} ov)',
                                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Team B Score Row
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: teamB?.primaryColor ?? Colors.teal,
                                      child: Text(
                                        teamB?.shortName.substring(0, 1) ?? 'B',
                                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        teamB?.name ?? 'Team B',
                                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    if (inn1 != null && inn1.battingTeamId == m.teamBId)
                                      Text(
                                        '${inn1.totalRuns}/${inn1.wickets} (${inn1.oversStr} ov)',
                                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                      )
                                    else if (inn2 != null && inn2.battingTeamId == m.teamBId)
                                      Text(
                                        '${inn2.totalRuns}/${inn2.wickets} (${inn2.oversStr} ov)',
                                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Divider(color: Colors.white12, height: 1),
                                const SizedBox(height: 8),

                                // Footer: Result Banner & Venue
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            m.winMargin ?? 'Match Completed',
                                            style: const TextStyle(
                                              color: Color(0xFF00F5A0),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                          if ((m.playerOfTheMatchName ?? '').isNotEmpty) ...[
                                            const SizedBox(height: 3),
                                            Text(
                                              '🏆 Man of the Match: ${m.playerOfTheMatchName}',
                                              style: const TextStyle(
                                                color: Colors.amberAccent,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                          const SizedBox(height: 2),
                                          Text(
                                            '📍 ${m.venue}',
                                            style: const TextStyle(color: Colors.white54, fontSize: 10.5),
                                          ),
                                        ],
                                      ),
                                    ),
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (ctx) => FullScorecardDialog(match: m, db: db),
                                        );
                                      },
                                      icon: const Icon(Icons.menu_book, size: 13, color: Color(0xFF00D9F5)),
                                      label: const Text('Scorecard', style: TextStyle(color: Color(0xFF00D9F5), fontSize: 11)),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: Color(0x6600D9F5)),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
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

  Widget _buildTournChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF00F5A0) : const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? const Color(0xFF00F5A0) : Colors.white24,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white70,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
