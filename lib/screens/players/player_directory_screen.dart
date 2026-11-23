import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/mock_database.dart';
import '../../widgets/auth_modal_dialog.dart';
import 'player_profile_screen.dart';

class PlayerDirectoryScreen extends StatefulWidget {
  const PlayerDirectoryScreen({super.key});

  @override
  State<PlayerDirectoryScreen> createState() => _PlayerDirectoryScreenState();
}

class _PlayerDirectoryScreenState extends State<PlayerDirectoryScreen> {
  final _searchController = TextEditingController();
  PlayerRole? _selectedRoleFilter;
  bool _showSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final db = context.watch<MockDatabase>();

    // 1. If user is logged in and not searching, replace with his personal Player Profile & Stats
    if (db.isAuthenticated && !_showSearch) {
      final myPlayer = db.currentPlayer;
      if (myPlayer != null) {
        return PlayerProfileScreen(
          playerId: myPlayer.id,
          isMyProfile: true,
          onSearchTap: () => setState(() => _showSearch = true),
        );
      }
    }

    // 2. Otherwise (or when user activates search), show searchable player directory
    final query = _searchController.text.trim().toLowerCase();

    final filteredPlayers = db.players.where((p) {
      if (_selectedRoleFilter != null && p.role != _selectedRoleFilter) {
        return false;
      }
      if (query.isNotEmpty) {
        final matchesName = p.fullName.toLowerCase().contains(query);
        final matchesCode = p.permanentPlayerCode.toLowerCase().contains(query);
        final matchesMobile = p.mobileNumber.contains(query);
        return matchesName || matchesCode || matchesMobile;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: db.isAuthenticated
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                tooltip: 'Back to My Profile',
                onPressed: () => setState(() => _showSearch = false),
              )
            : null,
        title: Text(
          db.isAuthenticated ? 'Search Players' : 'Player Directory',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          if (db.isAuthenticated)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: () => setState(() => _showSearch = false),
                icon: const Icon(Icons.person, color: Color(0xFF00F5A0), size: 16),
                label: const Text(
                  'My Profile',
                  style: TextStyle(color: Color(0xFF00F5A0), fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            )
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Text(
                  '${filteredPlayers.length} Registered',
                  style: const TextStyle(color: Color(0xFF00F5A0), fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Public Sign-in Banner (Only when not logged in)
          if (!db.isAuthenticated)
            Container(
              margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF00F5A0).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_circle_outlined, color: Color(0xFF00F5A0), size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Log in to view your verified Player Profile & career stats.',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton(
                    onPressed: () {
                      showDialog(context: context, builder: (_) => const AuthModalDialog());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00F5A0),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: const Text('Login', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

          // Search & Filter Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              border: Border(bottom: BorderSide(color: Colors.white12)),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  autofocus: db.isAuthenticated && _showSearch,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search player name, ID (e.g. PLY-2026), or mobile...',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF00F5A0), size: 18),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white54, size: 16),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                              });
                            },
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
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildRoleFilterChip(null, 'All Roles'),
                      const SizedBox(width: 6),
                      _buildRoleFilterChip(PlayerRole.batsman, 'Batters'),
                      const SizedBox(width: 6),
                      _buildRoleFilterChip(PlayerRole.bowler, 'Bowlers'),
                      const SizedBox(width: 6),
                      _buildRoleFilterChip(PlayerRole.allRounder, 'All-Rounders'),
                      const SizedBox(width: 6),
                      _buildRoleFilterChip(PlayerRole.wicketKeeper, 'Wicketkeepers'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Player List
          Expanded(
            child: filteredPlayers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.person_search, color: Colors.white24, size: 48),
                        const SizedBox(height: 12),
                        const Text(
                          'No registered players match your search',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          query.isNotEmpty ? 'Try searching another name or ID' : 'Players will appear once registered',
                          style: const TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filteredPlayers.length,
                    itemBuilder: (context, index) {
                      final p = filteredPlayers[index];
                      final team = p.teamId != null ? db.getTeam(p.teamId!) : null;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          leading: Stack(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundImage: NetworkImage(p.photoUrl),
                              ),
                              if (p.isMobileVerified)
                                const Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Icon(Icons.verified, color: Color(0xFF00F5A0), size: 14),
                                ),
                            ],
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  p.fullName,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00F5A0).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  p.permanentPlayerCode,
                                  style: const TextStyle(color: Color(0xFF00F5A0), fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 2),
                              Text(
                                '${p.roleString} • ${p.battingStyle}',
                                style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    team?.name ?? 'Free Agent',
                                    style: const TextStyle(color: Colors.amberAccent, fontSize: 10.5, fontWeight: FontWeight.w600),
                                  ),
                                  if (p.runs > 0 || p.wickets > 0) ...[
                                    const Text(' • ', style: TextStyle(color: Colors.white38)),
                                    Text(
                                      '${p.runs} runs, ${p.wickets} wkts (${p.matches} mat)',
                                      style: const TextStyle(color: Colors.white54, fontSize: 10),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_right, color: Colors.white38, size: 20),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PlayerProfileScreen(playerId: p.id),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleFilterChip(PlayerRole? role, String label) {
    final isSelected = _selectedRoleFilter == role;
    return InkWell(
      onTap: () => setState(() => _selectedRoleFilter = role),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00F5A0).withValues(alpha: 0.2) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? const Color(0xFF00F5A0) : Colors.white12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF00F5A0) : Colors.white70,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
