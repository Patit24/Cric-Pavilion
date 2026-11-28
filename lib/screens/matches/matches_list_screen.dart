import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/mock_database.dart';
import '../../theme/neo_glass_theme.dart';
import '../../widgets/role_switcher_chip.dart';
import '../../widgets/app_animations.dart';
import 'match_detail_screen.dart';
import '../scorer/scorer_screen.dart';
import '../tournaments/tournament_hub_screen.dart';
import '../tournaments/create_tournament_dialog.dart';

class MatchesListScreen extends StatefulWidget {
  const MatchesListScreen({super.key});

  @override
  State<MatchesListScreen> createState() => _MatchesListScreenState();
}

class _MatchesListScreenState extends State<MatchesListScreen> {
  String filter = 'all'; // 'all', 'live', 'completed', 'scheduled'
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final db = context.watch<MockDatabase>();
    final query = _searchController.text.trim().toLowerCase();

    final filteredMatches = db.matches.where((m) {
      if (filter == 'live' && m.status != MatchStatus.live) return false;
      if (filter == 'completed' && m.status != MatchStatus.completed) return false;
      if (filter == 'scheduled' && m.status != MatchStatus.scheduled && m.status != MatchStatus.toss) return false;

      if (query.isNotEmpty) {
        final teamA = db.getTeam(m.teamAId)?.name.toLowerCase() ?? '';
        final teamB = db.getTeam(m.teamBId)?.name.toLowerCase() ?? '';
        final tourn = db.getTournament(m.tournamentId);
        final tournName = tourn?.name.toLowerCase() ?? '';
        final tournShort = tourn?.shortName.toLowerCase() ?? '';
        final venue = m.venue.toLowerCase();
        final stage = m.stage.toLowerCase();

        return tournName.contains(query) ||
            tournShort.contains(query) ||
            teamA.contains(query) ||
            teamB.contains(query) ||
            venue.contains(query) ||
            stage.contains(query);
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: GlassTokens.bgIcyWhite,
      appBar: AppBar(
        backgroundColor: GlassTokens.bgIcyWhite,
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: GlassTokens.bgLightBlue)),
        title: const Text('Match Centre', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: GlassTokens.inkPrimary)),
        actions: const [
          RoleSwitcherChip(compact: true),
          SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Tournament Search Bar
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            decoration: const BoxDecoration(
              color: GlassTokens.bgIcyWhite,
              border: Border(bottom: BorderSide(color: Color(0x18FFFFFF))),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: GlassTokens.inkPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search by tournament (e.g. BPL), team, venue...',
                hintStyle: const TextStyle(color: GlassTokens.inkMuted, fontSize: 12),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF00F5A0), size: 18),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: GlassTokens.inkSecondary, size: 16),
                        onPressed: () => setState(() => _searchController.clear()),
                      )
                    : null,
                filled: true,
                fillColor: GlassTokens.bgLightBlue,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          // Filter Pills (Scrollable, Overflow-Proof)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: NeoGlassTheme.bgSurface,
              border: Border(bottom: BorderSide(color: Color(0x18FFFFFF))),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['all', 'live', 'completed', 'scheduled'].map((f) {
                  final isSelected = filter == f;
                  final label = f == 'all' ? 'All (${db.matches.length})' : f.toUpperCase();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => setState(() => filter = f),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: isSelected ? NeoGlassTheme.neonGradient : null,
                          color: isSelected ? null : const Color(0x18FFFFFF),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? Colors.transparent : NeoGlassTheme.glassBorder,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: NeoGlassTheme.neonEmerald.withValues(alpha: 0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                            color: isSelected ? Colors.black : GlassTokens.inkSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Matches List or Clean Empty State
          Expanded(
            child: filteredMatches.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: const Color(0xFF009270).withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.sports_cricket, size: 48, color: Color(0xFF34D399)),
                          ),
                          const SizedBox(height: 16),
                          const Text('No Matches Found', style: TextStyle(color: GlassTokens.inkPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(
                            filter == 'all'
                                ? 'Create a tournament and schedule matches to start scoring live.'
                                : 'No ${filter.toUpperCase()} matches right now in this category.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: GlassTokens.inkSecondary, fontSize: 12),
                          ),
                          const SizedBox(height: 20),
                          if (db.tournaments.isNotEmpty)
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (ctx) => TournamentHubScreen(initialTournamentId: db.tournaments.first.id)),
                                );
                              },
                              icon: const Icon(Icons.calendar_month, size: 16),
                              label: const Text('Schedule Match in Tournament', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF009270),
                                foregroundColor: Colors.white,
                              ),
                            )
                          else
                            ElevatedButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => CreateTournamentDialog(db: db),
                                );
                              },
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Create Tournament', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF009270),
                                foregroundColor: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredMatches.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) {
                      final m = filteredMatches[i];
                      final teamA = db.getTeam(m.teamAId) ?? MockDatabase.emptyTeam;
                      final teamB = db.getTeam(m.teamBId) ?? MockDatabase.emptyTeam;
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
                        child: NeoGlassCard(
                          glowColor: isLive ? NeoGlassTheme.neonRose : null,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Card Header
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(m.stage, style: const TextStyle(color: GlassTokens.inkSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                                  if (isLive)
                                    const PulsingLiveBadge(label: 'LIVE', color: Colors.redAccent)
                                  else
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isCompleted ? const Color(0xFF059669) : GlassTokens.glassHairline,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        m.status.name.toUpperCase(),
                                        style: const TextStyle(color: GlassTokens.inkPrimary, fontSize: 9, fontWeight: FontWeight.w900),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Team A
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        CircleAvatar(radius: 12, backgroundColor: teamA.primaryColor, child: Text(teamA.shortName, style: const TextStyle(fontSize: 8, color: GlassTokens.inkPrimary, fontWeight: FontWeight.bold))),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            teamA.name,
                                            style: const TextStyle(color: GlassTokens.inkPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (inn1 != null)
                                    Text('${inn1.totalRuns}/${inn1.wickets} (${inn1.oversStr} ov)', style: const TextStyle(color: GlassTokens.inkPrimary, fontWeight: FontWeight.bold, fontSize: 13))
                                  else
                                    const Text('Ready', style: TextStyle(color: GlassTokens.inkMuted, fontSize: 11)),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Team B
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        CircleAvatar(radius: 12, backgroundColor: teamB.primaryColor, child: Text(teamB.shortName, style: const TextStyle(fontSize: 8, color: GlassTokens.inkPrimary, fontWeight: FontWeight.bold))),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            teamB.name,
                                            style: const TextStyle(color: GlassTokens.inkPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (inn2 != null)
                                    Text('${inn2.totalRuns}/${inn2.wickets} (${inn2.oversStr} ov)', style: const TextStyle(color: GlassTokens.inkPrimary, fontWeight: FontWeight.bold, fontSize: 13))
                                  else
                                    const Text('Ready', style: TextStyle(color: GlassTokens.inkMuted, fontSize: 11)),
                                ],
                              ),

                              // Result or Action Footer
                              const Divider(color: Color(0xFF334155), height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      m.venue,
                                      style: const TextStyle(color: GlassTokens.inkMuted, fontSize: 11),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
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
                                    Flexible(
                                      child: Text(
                                        '${db.getTeam(m.winnerId)?.name ?? "Team"} won by ${m.winMargin ?? "runs"}',
                                        style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold, fontSize: 11),
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.right,
                                      ),
                                    )
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
