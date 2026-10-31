import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/mock_database.dart';

class CreateAuctionDialog extends StatefulWidget {
  final MockDatabase db;

  const CreateAuctionDialog({super.key, required this.db});

  @override
  State<CreateAuctionDialog> createState() => _CreateAuctionDialogState();
}

class _CreateAuctionDialogState extends State<CreateAuctionDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final titleController = TextEditingController(text: 'Winter Super League Auction 2026');
  final adminPassController = TextEditingController(text: 'admin123');
  final purseController = TextEditingController(text: '10000000'); // ₹1 Crore
  final minBidController = TextEditingController(text: '50000'); // ₹50,000

  // Teams entered by Host
  final List<TextEditingController> teamNameControllers = [
    TextEditingController(text: 'Royal Strikers'),
    TextEditingController(text: 'Thunder Warriors'),
    TextEditingController(text: 'City Champions'),
    TextEditingController(text: 'Falcon Superstars'),
    TextEditingController(text: 'Titan Gladiators'),
    TextEditingController(text: 'Panther Riders'),
    TextEditingController(text: 'Golden Eagles'),
    TextEditingController(text: 'Diamond Dynamos'),
  ];

  // Players entered by Host
  final List<Map<String, dynamic>> playerEntries = [
    {'nameController': TextEditingController(text: 'Amitav Roy'), 'role': PlayerRole.batsman, 'priceController': TextEditingController(text: '800000')},
    {'nameController': TextEditingController(text: 'Bikash Paul'), 'role': PlayerRole.bowler, 'priceController': TextEditingController(text: '650000')},
    {'nameController': TextEditingController(text: 'Chandan Sen'), 'role': PlayerRole.allRounder, 'priceController': TextEditingController(text: '900000')},
    {'nameController': TextEditingController(text: 'Debjit Saha'), 'role': PlayerRole.wicketKeeper, 'priceController': TextEditingController(text: '500000')},
    {'nameController': TextEditingController(text: 'Emon Chakraborty'), 'role': PlayerRole.batsman, 'priceController': TextEditingController(text: '400000')},
    {'nameController': TextEditingController(text: 'Farhan Sheikh'), 'role': PlayerRole.bowler, 'priceController': TextEditingController(text: '450000')},
    {'nameController': TextEditingController(text: 'Goutam Ghosh'), 'role': PlayerRole.allRounder, 'priceController': TextEditingController(text: '550000')},
    {'nameController': TextEditingController(text: 'Harsh Vardhan'), 'role': PlayerRole.batsman, 'priceController': TextEditingController(text: '700000')},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    titleController.dispose();
    adminPassController.dispose();
    purseController.dispose();
    minBidController.dispose();
    for (final c in teamNameControllers) {
      c.dispose();
    }
    for (final p in playerEntries) {
      (p['nameController'] as TextEditingController).dispose();
      (p['priceController'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  void _addTeamField() {
    setState(() {
      teamNameControllers.add(TextEditingController(text: 'Franchise Team ${teamNameControllers.length + 1}'));
    });
  }

  void _removeTeamField(int index) {
    if (teamNameControllers.length <= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Auction requires at least 2 teams.')),
      );
      return;
    }
    setState(() {
      final removed = teamNameControllers.removeAt(index);
      removed.dispose();
    });
  }

  void _addPlayerField() {
    setState(() {
      playerEntries.add({
        'nameController': TextEditingController(text: 'Player ${playerEntries.length + 1}'),
        'role': PlayerRole.batsman,
        'priceController': TextEditingController(text: '300000'),
      });
    });
  }

  void _removePlayerField(int index) {
    setState(() {
      final removed = playerEntries.removeAt(index);
      (removed['nameController'] as TextEditingController).dispose();
      (removed['priceController'] as TextEditingController).dispose();
    });
  }

  void _setTeamCountPreset(int count) {
    setState(() {
      while (teamNameControllers.length > count) {
        teamNameControllers.removeLast().dispose();
      }
      final defaultNames = [
        'Royal Strikers', 'Thunder Warriors', 'City Champions', 'Falcon Superstars',
        'Titan Gladiators', 'Panther Riders', 'Golden Eagles', 'Diamond Dynamos'
      ];
      while (teamNameControllers.length < count) {
        final i = teamNameControllers.length;
        teamNameControllers.add(TextEditingController(text: defaultNames[i % defaultNames.length]));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.gavel, color: Colors.amber, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Host New Auction & Tournament', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                        Text('Everything is a fresh entry: Host sets Teams & Players manually', style: TextStyle(color: Colors.white54, fontSize: 11)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Tab Bar
              Container(
                decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(12)),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.amber,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.amber,
                  unselectedLabelColor: Colors.white60,
                  labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  tabs: [
                    const Tab(icon: Icon(Icons.tune, size: 16), text: '1. Setup Rules'),
                    Tab(icon: const Icon(Icons.groups, size: 16), text: '2. Teams (${teamNameControllers.length})'),
                    Tab(icon: const Icon(Icons.sports_cricket, size: 16), text: '3. Players (${playerEntries.length})'),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Tab View Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // ==========================================
                    // TAB 1: AUCTION & RULES SETUP
                    // ==========================================
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: titleController,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(
                              labelText: 'Auction & Tournament Title',
                              labelStyle: const TextStyle(color: Colors.white70),
                              hintText: 'e.g. Gully Cricket Premier League 2026',
                              filled: true,
                              fillColor: const Color(0xFF0F172A),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: purseController,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                  decoration: InputDecoration(
                                    labelText: 'Team Purse Budget (₹)',
                                    labelStyle: const TextStyle(color: Colors.white70),
                                    hintText: '10000000',
                                    filled: true,
                                    fillColor: const Color(0xFF0F172A),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: minBidController,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                  decoration: InputDecoration(
                                    labelText: 'Min Bid Inc (₹)',
                                    labelStyle: const TextStyle(color: Colors.white70),
                                    hintText: '50000',
                                    filled: true,
                                    fillColor: const Color(0xFF0F172A),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: adminPassController,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(
                              labelText: 'Host Auctioneer Security PIN',
                              labelStyle: const TextStyle(color: Colors.white70),
                              hintText: 'e.g. admin123',
                              prefixIcon: const Icon(Icons.security, color: Colors.amber, size: 18),
                              filled: true,
                              fillColor: const Color(0xFF0F172A),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF059669).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.check_circle_outline, color: Color(0xFF34D399), size: 20),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    '100% Fresh Isolation: This auction starts with 0 acquired players and full purse. Only the teams and players you enter in Tabs 2 & 3 will be shown.',
                                    style: TextStyle(color: Color(0xFF34D399), fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ==========================================
                    // TAB 2: ENTER TEAMS
                    // ==========================================
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Text('Quick Presets:', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Wrap(
                              spacing: 6,
                              children: [2, 4, 6, 8].map((n) {
                                final isSelected = teamNameControllers.length == n;
                                return InkWell(
                                  onTap: () => _setTeamCountPreset(n),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isSelected ? Colors.amber : const Color(0xFF0F172A),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: isSelected ? Colors.amber : Colors.white24),
                                    ),
                                    child: Text(
                                      '$n Teams',
                                      style: TextStyle(
                                        color: isSelected ? Colors.black : Colors.white70,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: _addTeamField,
                              icon: const Icon(Icons.add, size: 14, color: Colors.amber),
                              label: const Text('Add Team', style: TextStyle(color: Colors.amber, fontSize: 11)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.separated(
                            itemCount: teamNameControllers.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, i) {
                              return Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.amber.withValues(alpha: 0.2),
                                    radius: 14,
                                    child: Text('${i + 1}', style: const TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: teamNameControllers[i],
                                      style: const TextStyle(color: Colors.white, fontSize: 13),
                                      decoration: InputDecoration(
                                        labelText: 'Team ${i + 1} Name',
                                        labelStyle: const TextStyle(color: Colors.white54, fontSize: 11),
                                        filled: true,
                                        fillColor: const Color(0xFF0F172A),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 18),
                                    tooltip: 'Remove Team',
                                    onPressed: () => _removeTeamField(i),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    // ==========================================
                    // TAB 3: ENTER PLAYERS
                    // ==========================================
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Text('Add Players for Auction:', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: _addPlayerField,
                              icon: const Icon(Icons.person_add, size: 14, color: Color(0xFF34D399)),
                              label: const Text('+ Add Player', style: TextStyle(color: Color(0xFF34D399), fontSize: 11)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.separated(
                            itemCount: playerEntries.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, i) {
                              final p = playerEntries[i];
                              final nameCtrl = p['nameController'] as TextEditingController;
                              final priceCtrl = p['priceController'] as TextEditingController;
                              final role = p['role'] as PlayerRole;

                              return Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: const Color(0xFF34D399).withValues(alpha: 0.2),
                                      radius: 12,
                                      child: Text('${i + 1}', style: const TextStyle(color: Color(0xFF34D399), fontSize: 9, fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(width: 8),
                                    // Player Name
                                    Expanded(
                                      flex: 3,
                                      child: TextField(
                                        controller: nameCtrl,
                                        style: const TextStyle(color: Colors.white, fontSize: 12),
                                        decoration: InputDecoration(
                                          labelText: 'Player Name',
                                          labelStyle: const TextStyle(color: Colors.white54, fontSize: 10),
                                          isDense: true,
                                          filled: true,
                                          fillColor: const Color(0xFF1E293B),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    // Role Dropdown
                                    Expanded(
                                      flex: 2,
                                      child: DropdownButtonFormField<PlayerRole>(
                                        value: role,
                                        dropdownColor: const Color(0xFF1E293B),
                                        isDense: true,
                                        style: const TextStyle(color: Colors.white, fontSize: 11),
                                        decoration: InputDecoration(
                                          labelText: 'Role',
                                          labelStyle: const TextStyle(color: Colors.white54, fontSize: 10),
                                          isDense: true,
                                          filled: true,
                                          fillColor: const Color(0xFF1E293B),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        items: const [
                                          DropdownMenuItem(value: PlayerRole.batsman, child: Text('Batter')),
                                          DropdownMenuItem(value: PlayerRole.bowler, child: Text('Bowler')),
                                          DropdownMenuItem(value: PlayerRole.allRounder, child: Text('All-Round')),
                                          DropdownMenuItem(value: PlayerRole.wicketKeeper, child: Text('Keeper')),
                                        ],
                                        onChanged: (val) {
                                          if (val != null) setState(() => p['role'] = val);
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    // Base Price
                                    Expanded(
                                      flex: 2,
                                      child: TextField(
                                        controller: priceCtrl,
                                        keyboardType: TextInputType.number,
                                        style: const TextStyle(color: Colors.white, fontSize: 12),
                                        decoration: InputDecoration(
                                          labelText: 'Base (₹)',
                                          labelStyle: const TextStyle(color: Colors.white54, fontSize: 10),
                                          isDense: true,
                                          filled: true,
                                          fillColor: const Color(0xFF1E293B),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.white38, size: 16),
                                      tooltip: 'Remove',
                                      onPressed: () => _removePlayerField(i),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Bottom Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (titleController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter an auction title.')),
                        );
                        return;
                      }

                      final purse = int.tryParse(purseController.text.trim()) ?? 10000000;
                      final minBid = int.tryParse(minBidController.text.trim()) ?? 50000;

                      // Extract entered team names
                      final enteredTeamNames = teamNameControllers
                          .map((c) => c.text.trim())
                          .where((name) => name.isNotEmpty)
                          .toList();

                      if (enteredTeamNames.length < 2) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter at least 2 team names.')),
                        );
                        return;
                      }

                      // Extract entered player entries
                      final enteredPlayers = <Map<String, dynamic>>[];
                      for (final p in playerEntries) {
                        final name = (p['nameController'] as TextEditingController).text.trim();
                        final price = int.tryParse((p['priceController'] as TextEditingController).text.trim()) ?? 300000;
                        if (name.isNotEmpty) {
                          enteredPlayers.add({
                            'name': name,
                            'role': p['role'] as PlayerRole,
                            'price': price,
                          });
                        }
                      }

                      // Create Tournament first
                      final createdTourn = widget.db.createTournament(
                        name: titleController.text.trim(),
                        shortName: titleController.text.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(3).join().toUpperCase(),
                        location: 'Home Stadium',
                        overs: 20,
                        roomId: 'TOURN-${DateTime.now().millisecondsSinceEpoch % 10000}',
                        passcode: '1234',
                        createAuction: false, // We will create the custom auction directly
                      );

                      // Create isolated Auction with host's exact entered teams & players
                      final createdAuc = widget.db.createAuction(
                        tournamentId: createdTourn.id,
                        title: '${titleController.text.trim()} Player Auction',
                        adminPasscode: adminPassController.text.trim(),
                        maxPursePerTeam: purse,
                        minBidIncrement: minBid,
                        requiredTeamsCount: enteredTeamNames.length,
                        customTeamNames: enteredTeamNames,
                        customPlayers: enteredPlayers,
                      );

                      Navigator.pop(context, createdAuc);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF059669),
                          content: Text('Auction "${createdAuc.title}" created with ${enteredTeamNames.length} Teams and ${enteredPlayers.length} Players!'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.rocket_launch, size: 16),
                    label: const Text('Create & Launch Auction', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
