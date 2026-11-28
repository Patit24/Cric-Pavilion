import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/mock_database.dart';
import '../../theme/neo_glass_theme.dart';
import '../../widgets/add_existing_player_dialog.dart';

class FillTeamSquadDialog extends StatefulWidget {
  final MatchModel match;
  final MockDatabase db;
  final VoidCallback? onSquadsSaved;

  const FillTeamSquadDialog({
    super.key,
    required this.match,
    required this.db,
    this.onSquadsSaved,
  });

  @override
  State<FillTeamSquadDialog> createState() => _FillTeamSquadDialogState();
}

class _FillTeamSquadDialogState extends State<FillTeamSquadDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Controllers for Team A
  final List<Map<String, dynamic>> teamAPlayers = [];

  // Controllers for Team B
  final List<Map<String, dynamic>> teamBPlayers = [];

  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _loadExistingPlayers(widget.match.teamAId, teamAPlayers);
    _loadExistingPlayers(widget.match.teamBId, teamBPlayers);

    // If completely empty, seed at least 2 default entry rows per team
    if (teamAPlayers.isEmpty) {
      _addEmptyRow(teamAPlayers, defaultRole: 'batter');
      _addEmptyRow(teamAPlayers, defaultRole: 'bowler');
    }
    if (teamBPlayers.isEmpty) {
      _addEmptyRow(teamBPlayers, defaultRole: 'batter');
      _addEmptyRow(teamBPlayers, defaultRole: 'bowler');
    }
  }

  void _loadExistingPlayers(String teamId, List<Map<String, dynamic>> targetList) {
    final existing = widget.db.getTeamPlayers(teamId);
    for (final p in existing) {
      targetList.add({
        'nameController': TextEditingController(text: p.fullName),
        'mobileController': TextEditingController(text: p.mobileNumber),
        'role': p.roleString.toLowerCase(),
      });
    }
  }

  void _addEmptyRow(List<Map<String, dynamic>> targetList, {String defaultRole = 'batter'}) {
    setState(() {
      targetList.add({
        'nameController': TextEditingController(),
        'mobileController': TextEditingController(),
        'role': defaultRole,
      });
    });
  }

  void _autoFillSampleSquad(List<Map<String, dynamic>> targetList, int teamIndex, String baseMobilePrefix) {
    final namesA = [
      'Rahul Sharma',
      'Amit Verma',
      'Suman Das',
      'Pankaj Roy',
      'Vikram Sen',
      'Rohan Mukherjee',
      'Debayan Paul',
      'Tanmoy Bose',
      'Arjun Ghosh',
      'Deepak Yadav',
      'Manoj Tiwary',
    ];

    final namesB = [
      'Sourav Mondal',
      'Rohit Banerjee',
      'Suraj Singh',
      'Ankit Gupta',
      'Pradeep Kumar',
      'Kunal Ghosh',
      'Sanjay Dutt',
      'Rajesh Mondal',
      'Subir Roy',
      'Avik Mukherjee',
      'Gopal Das',
    ];

    final names = teamIndex == 0 ? namesA : namesB;

    setState(() {
      targetList.clear();
      for (int i = 0; i < names.length; i++) {
        final role = i < 4 ? 'batter' : (i < 6 ? 'wicketkeeper' : (i < 8 ? 'allrounder' : 'bowler'));
        targetList.add({
          'nameController': TextEditingController(text: names[i]),
          'mobileController': TextEditingController(text: '${baseMobilePrefix}00${(i + 1).toString().padLeft(2, "0")}'),
          'role': role,
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final row in [...teamAPlayers, ...teamBPlayers]) {
      (row['nameController'] as TextEditingController).dispose();
      (row['mobileController'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teamA = widget.db.getTeam(widget.match.teamAId) ?? MockDatabase.emptyTeam;
    final teamB = widget.db.getTeam(widget.match.teamBId) ?? MockDatabase.emptyTeam;

    return NeoGlassDialog(
      glowColor: NeoGlassTheme.neonEmerald,
      padding: const EdgeInsets.all(18),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: NeoGlassTheme.neonEmerald.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: NeoGlassTheme.neonEmerald.withValues(alpha: 0.5)),
                  ),
                  child: const Icon(Icons.phonelink_lock, color: NeoGlassTheme.neonEmerald, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Required: Player Names & Mobile',
                        style: TextStyle(color: GlassTokens.inkPrimary, fontSize: 15, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Both teams must register player names with mobile numbers before scoring.',
                        style: TextStyle(color: GlassTokens.inkSecondary, fontSize: 10.5),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: GlassTokens.inkSecondary, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Tabs for Team A and Team B
            Container(
              decoration: BoxDecoration(
                color: GlassTokens.inkPrimary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: GlassTokens.glassHairline),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: NeoGlassTheme.neonEmerald,
                indicatorWeight: 3,
                labelColor: NeoGlassTheme.neonEmerald,
                unselectedLabelColor: GlassTokens.inkSecondary,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(radius: 8, backgroundImage: NetworkImage(teamA.logoUrl)),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            teamA.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text('(${teamAPlayers.length})', style: const TextStyle(fontSize: 10, color: GlassTokens.inkSecondary)),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(radius: 8, backgroundImage: NetworkImage(teamB.logoUrl)),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            teamB.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text('(${teamBPlayers.length})', style: const TextStyle(fontSize: 10, color: GlassTokens.inkSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
              const SizedBox(height: 10),

              // Error banner if any
              if (errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.redAccent),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, size: 16, color: Colors.redAccent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          errorMessage!,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // Tab contents
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTeamEditor(teamA, teamAPlayers, 'A', '98301'),
                    _buildTeamEditor(teamB, teamBPlayers, 'B', '98302'),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Action Buttons (Overflow-proof responsive layout)
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: GlassTokens.glassHairline),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Cancel', style: TextStyle(color: GlassTokens.inkSecondary, fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 7,
                    child: ElevatedButton.icon(
                      onPressed: _validateAndSaveSquads,
                      icon: const Icon(Icons.check_circle, size: 16),
                      label: const Text(
                        'Save & Unlock Live Scoring',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00F5A0),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
  }

  Widget _buildTeamEditor(Team team, List<Map<String, dynamic>> playerList, String teamLetter, String mockPrefix) {
    final teamIndex = teamLetter == 'A' ? 0 : 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Action Bar for this team (2-line responsive layout, 100% overflow proof)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                '${team.name} Squad (${playerList.length} Players)',
                style: const TextStyle(color: GlassTokens.inkSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AddExistingPlayerDialog(
                      teamId: team.id,
                      tournamentId: widget.match.tournamentId,
                      onPlayerAdded: (newP) {
                        setState(() {
                          if (!playerList.any((r) => (r['nameController'] as TextEditingController).text == newP.fullName)) {
                            playerList.add({
                              'nameController': TextEditingController(text: newP.fullName),
                              'mobileController': TextEditingController(text: newP.mobileNumber),
                              'role': newP.roleString.toLowerCase(),
                            });
                          }
                        });
                      },
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D9F5).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF00D9F5)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.person_search, size: 12, color: Color(0xFF00D9F5)),
                      SizedBox(width: 4),
                      Text('Find Mobile', style: TextStyle(color: Color(0xFF00D9F5), fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: InkWell(
                onTap: () => _autoFillSampleSquad(playerList, teamIndex, mockPrefix),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.flash_on, size: 12, color: Color(0xFFD97706)),
                      SizedBox(width: 4),
                      Text('Auto 11', style: TextStyle(color: Color(0xFFD97706), fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: InkWell(
                onTap: () => _addEmptyRow(playerList),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF009270).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF059669)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.add, size: 12, color: Color(0xFF34D399)),
                      SizedBox(width: 4),
                      Text('+ Player', style: TextStyle(color: Color(0xFF34D399), fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Player rows list (2-line responsive cards: never overflows)
        Expanded(
          child: ListView.separated(
            itemCount: playerList.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, index) {
              final row = playerList[index];
              final nameCtrl = row['nameController'] as TextEditingController;
              final mobileCtrl = row['mobileController'] as TextEditingController;
              final role = row['role'] as String;

              return Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: GlassTokens.inkPrimary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: GlassTokens.glassHairline),
                ),
                child: Column(
                  children: [
                    // Line 1: Index + Name + Role Dropdown + Delete
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: GlassTokens.bgLightBlue,
                          child: Text('${index + 1}', style: const TextStyle(color: GlassTokens.inkSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: nameCtrl,
                            style: const TextStyle(color: GlassTokens.inkPrimary, fontSize: 12),
                            decoration: const InputDecoration(
                              hintText: 'Player Name *',
                              hintStyle: TextStyle(color: GlassTokens.inkMuted, fontSize: 11),
                              isDense: true,
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 4),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: GlassTokens.bgLightBlue,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: GlassTokens.glassHairline),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: role,
                              dropdownColor: GlassTokens.bgLightBlue,
                              isDense: true,
                              icon: const Icon(Icons.arrow_drop_down, color: GlassTokens.inkSecondary, size: 16),
                              style: const TextStyle(color: Color(0xFF34D399), fontSize: 10.5, fontWeight: FontWeight.bold),
                              items: const [
                                DropdownMenuItem(value: 'batter', child: Text('Bat')),
                                DropdownMenuItem(value: 'bowler', child: Text('Bowl')),
                                DropdownMenuItem(value: 'allrounder', child: Text('All-R')),
                                DropdownMenuItem(value: 'wicketkeeper', child: Text('WK')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => row['role'] = val);
                                }
                              },
                            ),
                          ),
                        ),
                        if (playerList.length > 2) ...[
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                            onPressed: () {
                              setState(() => playerList.removeAt(index));
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ],
                    ),
                    const Divider(color: GlassTokens.glassHairline, height: 8),
                    // Line 2: Phone Icon + Mobile Input
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 12, color: Color(0xFF34D399)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: TextField(
                            controller: mobileCtrl,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(color: GlassTokens.inkPrimary, fontSize: 11.5),
                            decoration: const InputDecoration(
                              hintText: '10-digit Mobile Number *',
                              hintStyle: TextStyle(color: GlassTokens.inkMuted, fontSize: 10.5),
                              isDense: true,
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _validateAndSaveSquads() {
    // Validate Team A
    if (teamAPlayers.length < 2) {
      setState(() => errorMessage = 'Team A must have at least 2 players to start a match.');
      return;
    }
    for (int i = 0; i < teamAPlayers.length; i++) {
      final name = (teamAPlayers[i]['nameController'] as TextEditingController).text.trim();
      final mobile = (teamAPlayers[i]['mobileController'] as TextEditingController).text.trim();
      if (name.isEmpty) {
        setState(() => errorMessage = 'Please enter name for Player #${i + 1} in Team A.');
        _tabController.animateTo(0);
        return;
      }
      if (mobile.isEmpty) {
        setState(() => errorMessage = 'Mobile number is required for Player "$name" in Team A.');
        _tabController.animateTo(0);
        return;
      }
    }

    // Validate Team B
    if (teamBPlayers.length < 2) {
      setState(() => errorMessage = 'Team B must have at least 2 players to start a match.');
      return;
    }
    for (int i = 0; i < teamBPlayers.length; i++) {
      final name = (teamBPlayers[i]['nameController'] as TextEditingController).text.trim();
      final mobile = (teamBPlayers[i]['mobileController'] as TextEditingController).text.trim();
      if (name.isEmpty) {
        setState(() => errorMessage = 'Please enter name for Player #${i + 1} in Team B.');
        _tabController.animateTo(1);
        return;
      }
      if (mobile.isEmpty) {
        setState(() => errorMessage = 'Mobile number is required for Player "$name" in Team B.');
        _tabController.animateTo(1);
        return;
      }
    }

    // Save Team A
    final entriesA = teamAPlayers.map((row) {
      return {
        'name': (row['nameController'] as TextEditingController).text.trim(),
        'mobile': (row['mobileController'] as TextEditingController).text.trim(),
        'role': row['role'] as String,
      };
    }).toList();
    widget.db.saveTeamSquadWithMobileNumbers(teamId: widget.match.teamAId, playerEntries: entriesA);

    // Save Team B
    final entriesB = teamBPlayers.map((row) {
      return {
        'name': (row['nameController'] as TextEditingController).text.trim(),
        'mobile': (row['mobileController'] as TextEditingController).text.trim(),
        'role': row['role'] as String,
      };
    }).toList();
    widget.db.saveTeamSquadWithMobileNumbers(teamId: widget.match.teamBId, playerEntries: entriesB);

    // Auto-setup first innings if not yet set up
    final inn1 = widget.db.inningsList.where((i) => i.matchId == widget.match.id && i.inningsNumber == 1).firstOrNull;
    if (inn1 != null && (inn1.currentStrikerId == null || inn1.currentBowlerId == null)) {
      final pA = widget.db.getTeamPlayers(inn1.battingTeamId);
      final pB = widget.db.getTeamPlayers(inn1.bowlingTeamId);
      if (pA.isNotEmpty) inn1.currentStrikerId = pA.first.id;
      if (pA.length > 1) inn1.currentNonStrikerId = pA[1].id;
      if (pB.isNotEmpty) inn1.currentBowlerId = pB.first.id;
    }

    widget.onSquadsSaved?.call();
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF009270),
        content: Text('Both team squads with mobile numbers saved! Scoring is now unlocked.'),
      ),
    );
  }
}
