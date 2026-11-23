import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/mock_database.dart';
import '../scorer/full_scorecard_dialog.dart';

class PlayerProfileScreen extends StatefulWidget {
  final String playerId;
  final bool isMyProfile;
  final VoidCallback? onSearchTap;

  const PlayerProfileScreen({
    super.key,
    required this.playerId,
    this.isMyProfile = false,
    this.onSearchTap,
  });

  @override
  State<PlayerProfileScreen> createState() => _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends State<PlayerProfileScreen> {
  String _selectedFilter = 'all'; // 'all', '2026', '2025'

  @override
  Widget build(BuildContext context) {
    final db = context.watch<MockDatabase>();
    final player = db.players.where((p) => p.id == widget.playerId).firstOrNull;

    if (player == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF070B14),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F172A),
          title: const Text('Player Profile'),
        ),
        body: const Center(
          child: Text('Player not found', style: TextStyle(color: Colors.white70)),
        ),
      );
    }

    final currentTeam = player.teamId != null ? db.getTeam(player.teamId!) : null;
    int? yearFilter;
    if (_selectedFilter == '2026') yearFilter = 2026;
    if (_selectedFilter == '2025') yearFilter = 2025;

    final stats = db.getPlayerCareerStats(player.id, year: yearFilter);
    final matchLogs = db.getPlayerMatchLogs(player.id);

    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                widget.isMyProfile ? 'My Profile & Stats' : player.fullName,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (widget.isMyProfile) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF00F5A0).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('YOU', style: TextStyle(color: Color(0xFF00F5A0), fontSize: 9.5, fontWeight: FontWeight.w900)),
              ),
            ],
          ],
        ),
        actions: [
          if (widget.onSearchTap != null)
            IconButton(
              icon: const Icon(Icons.search, color: Color(0xFF00F5A0), size: 20),
              tooltip: 'Search Players Directory',
              onPressed: widget.onSearchTap,
            ),
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF00F5A0).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF00F5A0), width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.badge, color: Color(0xFF00F5A0), size: 14),
                const SizedBox(width: 4),
                Text(
                  player.permanentPlayerCode,
                  style: const TextStyle(color: Color(0xFF00F5A0), fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.onSearchTap != null) ...[
              InkWell(
                onTap: widget.onSearchTap,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF00F5A0).withValues(alpha: 0.35)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.search, color: Color(0xFF00F5A0), size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Search player directory (Name, ID e.g. PLY-2026, or mobile)...',
                          style: TextStyle(color: Colors.white70, fontSize: 12.5),
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, color: Color(0xFF00F5A0), size: 12),
                    ],
                  ),
                ),
              ),
            ],
            // 1. Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 10),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundImage: NetworkImage(player.photoUrl),
                          ),
                          if (player.isMobileVerified)
                            const Positioned(
                              bottom: 0,
                              right: 0,
                              child: CircleAvatar(
                                radius: 10,
                                backgroundColor: Color(0xFF070B14),
                                child: Icon(Icons.verified, color: Color(0xFF00F5A0), size: 16),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              player.fullName,
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${player.roleString} • ${player.battingStyle}',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            Text(
                              player.bowlingStyle,
                              style: const TextStyle(color: Colors.white54, fontSize: 11),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    currentTeam?.name ?? 'Free Agent',
                                    style: const TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                if (player.mobileNumber.isNotEmpty)
                                  Text(
                                    '📱 •••• ${player.mobileNumber.length >= 4 ? player.mobileNumber.substring(player.mobileNumber.length - 4) : player.mobileNumber}',
                                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (player.teamHistory.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(color: Colors.white12),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Career Teams: ',
                          style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        Expanded(
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: player.teamHistory.map((th) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${th.teamName} (${th.year})',
                                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Timeline Filter Pills
            Row(
              children: [
                _buildFilterChip('all', 'All-Time Career'),
                const SizedBox(width: 8),
                _buildFilterChip('2026', 'Season 2026'),
                const SizedBox(width: 8),
                _buildFilterChip('2025', 'Season 2025'),
              ],
            ),
            const SizedBox(height: 16),

            // 3. Batting Statistics Card
            _buildStatSection(
              title: 'Batting Career Record',
              icon: Icons.sports_cricket,
              iconColor: const Color(0xFF00F5A0),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildStatTile('Matches', '${stats.matches}'),
                      _buildStatTile('Innings', '${stats.innings}'),
                      _buildStatTile('Runs', '${stats.runs}', isHighlight: true),
                      _buildStatTile('High Score', '${stats.highestScore}${stats.isHighestScoreNotOut ? "*" : ""}'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildStatTile('Average', stats.battingAverage.toStringAsFixed(1)),
                      _buildStatTile('Strike Rate', stats.battingStrikeRate.toStringAsFixed(1)),
                      _buildStatTile('50s / 100s', '${stats.fifties} / ${stats.hundreds}'),
                      _buildStatTile('4s / 6s', '${stats.fours} / ${stats.sixes}'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 4. Bowling Statistics Card
            _buildStatSection(
              title: 'Bowling Career Record',
              icon: Icons.sports_baseball,
              iconColor: const Color(0xFF00D9F5),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildStatTile('Overs', stats.oversFormatted),
                      _buildStatTile('Maidens', '${stats.maidens}'),
                      _buildStatTile('Runs', '${stats.runsConceded}'),
                      _buildStatTile('Wickets', '${stats.wickets}', isHighlight: true),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildStatTile('Economy', stats.economyRate.toStringAsFixed(2)),
                      _buildStatTile('Average', stats.bowlingAverage.toStringAsFixed(1)),
                      _buildStatTile('Strike Rate', stats.bowlingStrikeRate.toStringAsFixed(1)),
                      _buildStatTile('Best Figures', stats.bestBowlingInnings),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 5. Fielding Card
            _buildStatSection(
              title: 'Fielding Record',
              icon: Icons.pan_tool,
              iconColor: Colors.amberAccent,
              child: Row(
                children: [
                  _buildStatTile('Catches', '${stats.catches}'),
                  _buildStatTile('Run Outs', '${stats.runOuts}'),
                  _buildStatTile('Stumpings', '${stats.stumpings}'),
                  _buildStatTile('Total Dismissals', '${stats.catches + stats.runOuts + stats.stumpings}', isHighlight: true),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 6. Match-by-Match History
            Row(
              children: [
                const Icon(Icons.history, color: Colors.white70, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'Match Performance Log',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const Spacer(),
                Text(
                  '${matchLogs.length} Match(es)',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (matchLogs.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'No completed match performances recorded yet.',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
              )
            else
              ...matchLogs.map((log) => _buildMatchLogCard(context, db, log)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00F5A0).withValues(alpha: 0.2) : const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF00F5A0) : Colors.white12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF00F5A0) : Colors.white70,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildStatSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildStatTile(String label, String value, {bool isHighlight = false}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: isHighlight ? const Color(0xFF00F5A0) : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: Colors.white60, fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchLogCard(BuildContext context, MockDatabase db, PlayerMatchLog log) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: InkWell(
        onTap: () {
          final match = db.matches.where((m) => m.id == log.matchId).firstOrNull;
          if (match != null) {
            showDialog(
              context: context,
              builder: (ctx) => FullScorecardDialog(match: match, db: db),
            );
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${log.date.day}/${log.date.month}/${log.date.year}',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
                const SizedBox(width: 8),
                Text(
                  log.matchName,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: log.isWin ? const Color(0x3300F5A0) : Colors.white10,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    log.matchResult,
                    style: TextStyle(
                      color: log.isWin ? const Color(0xFF00F5A0) : Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'vs ${log.opponentTeamName}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (log.runsScored > 0 || log.ballsFaced > 0)
                  Text(
                    '🏏 ${log.runsScored} (${log.ballsFaced}b) • ${log.dismissalInfo}   ',
                    style: const TextStyle(color: Color(0xFF00F5A0), fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                if (log.oversBowled != '0.0')
                  Text(
                    '⚾ ${log.wicketsTaken}/${log.runsConceded} (${log.oversBowled} ov)   ',
                    style: const TextStyle(color: Color(0xFF00D9F5), fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                if (log.catches > 0)
                  Text(
                    '🧤 ${log.catches} catch   ',
                    style: const TextStyle(color: Colors.amberAccent, fontSize: 11),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
