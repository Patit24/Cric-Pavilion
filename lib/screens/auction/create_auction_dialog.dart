import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/mock_database.dart';
import '../../theme/neo_glass_theme.dart';

class CreateAuctionDialog extends StatefulWidget {
  final MockDatabase db;

  const CreateAuctionDialog({super.key, required this.db});

  @override
  State<CreateAuctionDialog> createState() => _CreateAuctionDialogState();
}

class _CreateAuctionDialogState extends State<CreateAuctionDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Clean Manual Entry Controllers (NO DUMMY PRE-FILLED PLACEHOLDERS)
  final titleController = TextEditingController();
  final adminPassController = TextEditingController();
  final purseController = TextEditingController(text: '50000');
  final minBidController = TextEditingController(text: '500');

  // Teams entered by Host - starts with 4 clean empty slots (Name + Owner Mobile)
  final List<TextEditingController> teamNameControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  final List<TextEditingController> teamMobileControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];

  // Players entered by Host - starts with 2 clean empty slots
  final List<Map<String, dynamic>> playerEntries = [
    {'nameController': TextEditingController(), 'role': PlayerRole.batsman, 'priceController': TextEditingController(text: '500')},
    {'nameController': TextEditingController(), 'role': PlayerRole.bowler, 'priceController': TextEditingController(text: '500')},
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
    for (final c in teamMobileControllers) {
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
      teamNameControllers.add(TextEditingController());
      teamMobileControllers.add(TextEditingController());
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
      final removedName = teamNameControllers.removeAt(index);
      removedName.dispose();
      if (index < teamMobileControllers.length) {
        final removedMob = teamMobileControllers.removeAt(index);
        removedMob.dispose();
      }
    });
  }

  void _addPlayerField() {
    setState(() {
      playerEntries.add({
        'nameController': TextEditingController(),
        'role': PlayerRole.batsman,
        'priceController': TextEditingController(text: '500'),
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
      while (teamMobileControllers.length > count) {
        teamMobileControllers.removeLast().dispose();
      }
      while (teamNameControllers.length < count) {
        teamNameControllers.add(TextEditingController());
      }
      while (teamMobileControllers.length < count) {
        teamMobileControllers.add(TextEditingController());
      }
    });
  }

  void _quickFillSample() {
    setState(() {
      titleController.text = 'BPL 2026 Mega Auction';
      adminPassController.text = 'admin123';
      purseController.text = '50000';
      minBidController.text = '500';

      final sampleTeams = [
        {'name': 'Barasat Blasters', 'mobile': '9876543201'},
        {'name': 'Howrah Hurricanes', 'mobile': '9876543202'},
        {'name': 'Kolkata Kings', 'mobile': '9876543203'},
        {'name': 'Hooghly Heroes', 'mobile': '9876543204'},
      ];
      while (teamNameControllers.length < sampleTeams.length) {
        teamNameControllers.add(TextEditingController());
      }
      while (teamMobileControllers.length < sampleTeams.length) {
        teamMobileControllers.add(TextEditingController());
      }
      for (int i = 0; i < sampleTeams.length; i++) {
        teamNameControllers[i].text = sampleTeams[i]['name']!;
        teamMobileControllers[i].text = sampleTeams[i]['mobile']!;
      }

      final samplePlayers = [
        {'name': 'Rahul Das', 'role': PlayerRole.batsman, 'price': '800'},
        {'name': 'Suman Biswas', 'role': PlayerRole.bowler, 'price': '650'},
        {'name': 'Tanmoy Das', 'role': PlayerRole.allRounder, 'price': '900'},
        {'name': 'Debayan Paul', 'role': PlayerRole.wicketKeeper, 'price': '500'},
      ];
      playerEntries.clear();
      for (final sp in samplePlayers) {
        playerEntries.add({
          'nameController': TextEditingController(text: sp['name'] as String),
          'role': sp['role'] as PlayerRole,
          'priceController': TextEditingController(text: sp['price'] as String),
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return NeoGlassDialog(
      glowColor: NeoGlassTheme.neonAmber,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      padding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 720),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.gavel, color: Colors.black, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Host New Player Auction',
                          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Draft setup, team budgets & player pool',
                          style: TextStyle(color: Colors.white54, fontSize: 10.5),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: _quickFillSample,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.flash_on, size: 11, color: Colors.amberAccent),
                          SizedBox(width: 4),
                          Text('Sample', style: TextStyle(color: Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54, size: 18),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
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
                  labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  tabs: [
                    const Tab(icon: Icon(Icons.tune, size: 14), text: '1. Rules'),
                    Tab(icon: const Icon(Icons.groups, size: 14), text: '2. Teams (${teamNameControllers.length})'),
                    Tab(icon: const Icon(Icons.sports_cricket, size: 14), text: '3. Players (${playerEntries.length})'),
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
                              labelText: 'Auction Title *',
                              labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
                              hintText: 'e.g. Bengal Premier League Auction 2026',
                              hintStyle: const TextStyle(color: Colors.white38, fontSize: 11.5),
                              filled: true,
                              fillColor: const Color(0xFF0F172A),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 10),
                          LayoutBuilder(
                            builder: (ctx, constraints) {
                              if (constraints.maxWidth < 280) {
                                return Column(
                                  children: [
                                    _buildPurseField(),
                                    const SizedBox(height: 8),
                                    _buildMinBidField(),
                                  ],
                                );
                              }
                              return Row(
                                children: [
                                  Expanded(child: _buildPurseField()),
                                  const SizedBox(width: 8),
                                  Expanded(child: _buildMinBidField()),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: adminPassController,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(
                              labelText: 'Host Auctioneer Security PIN *',
                              labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
                              hintText: 'e.g. admin123',
                              hintStyle: const TextStyle(color: Colors.white38, fontSize: 11.5),
                              prefixIcon: const Icon(Icons.security, color: Colors.amber, size: 18),
                              filled: true,
                              fillColor: const Color(0xFF0F172A),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF059669).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.check_circle_outline, color: Color(0xFF34D399), size: 18),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Fresh Isolation: This auction starts with clean budgets and 0 acquired players. Only the teams and players you configure will be auctioned.',
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
                    // TAB 2: ENTER TEAMS (Name + Owner Mobile)
                    // ==========================================
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              const Text('Preset:', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 6),
                              ...[2, 4, 6, 8].map((n) {
                                final isSelected = teamNameControllers.length == n;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: InkWell(
                                    onTap: () => _setTeamCountPreset(n),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                      decoration: BoxDecoration(
                                        color: isSelected ? Colors.amber : const Color(0xFF0F172A),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: isSelected ? Colors.amber : Colors.white24),
                                      ),
                                      child: Text(
                                        '$n Teams',
                                        style: TextStyle(
                                          color: isSelected ? Colors.black : Colors.white70,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                              ElevatedButton.icon(
                                onPressed: _addTeamField,
                                icon: const Icon(Icons.add, size: 12),
                                label: const Text('+ Team', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF009270),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.separated(
                            itemCount: teamNameControllers.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (ctx, idx) {
                              return Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 10,
                                          backgroundColor: Colors.amberAccent.withValues(alpha: 0.2),
                                          child: Text('${idx + 1}', style: const TextStyle(color: Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: TextField(
                                            controller: teamNameControllers[idx],
                                            style: const TextStyle(color: Colors.white, fontSize: 12),
                                            decoration: InputDecoration(
                                              hintText: 'Enter Team ${idx + 1} Name *',
                                              hintStyle: const TextStyle(color: Colors.white38, fontSize: 11),
                                              isDense: true,
                                              border: InputBorder.none,
                                              contentPadding: const EdgeInsets.symmetric(vertical: 4),
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                                          onPressed: () => _removeTeamField(idx),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                    const Divider(color: Colors.white10, height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.phone, size: 13, color: Color(0xFF34D399)),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: TextField(
                                            controller: idx < teamMobileControllers.length ? teamMobileControllers[idx] : null,
                                            keyboardType: TextInputType.phone,
                                            style: const TextStyle(color: Colors.white, fontSize: 12),
                                            decoration: const InputDecoration(
                                              hintText: 'Owner Mobile * (for team owner login to bid)',
                                              hintStyle: TextStyle(color: Colors.white38, fontSize: 10.5),
                                              isDense: true,
                                              border: InputBorder.none,
                                              contentPadding: EdgeInsets.symmetric(vertical: 4),
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
                    ),

                    // ==========================================
                    // TAB 3: ENTER PLAYERS
                    // ==========================================
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Player Pool (${playerEntries.length} Lots)',
                              style: const TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            ElevatedButton.icon(
                              onPressed: _addPlayerField,
                              icon: const Icon(Icons.add, size: 12),
                              label: const Text('+ Player', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF009270),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.separated(
                            itemCount: playerEntries.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 6),
                            itemBuilder: (ctx, idx) {
                              final p = playerEntries[idx];
                              final nameCtrl = p['nameController'] as TextEditingController;
                              final priceCtrl = p['priceController'] as TextEditingController;

                              return Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 11,
                                      backgroundColor: Colors.amber.withValues(alpha: 0.2),
                                      child: Text('${idx + 1}', style: const TextStyle(color: Colors.amber, fontSize: 9.5, fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(width: 6),
                                    // Player Name
                                    Expanded(
                                      flex: 5,
                                      child: TextField(
                                        controller: nameCtrl,
                                        style: const TextStyle(color: Colors.white, fontSize: 11.5),
                                        decoration: InputDecoration(
                                          hintText: 'Player Name *',
                                          hintStyle: const TextStyle(color: Colors.white38, fontSize: 10.5),
                                          isDense: true,
                                          filled: true,
                                          fillColor: const Color(0xFF1E293B),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    // Base Price
                                    Expanded(
                                      flex: 4,
                                      child: TextField(
                                        controller: priceCtrl,
                                        keyboardType: TextInputType.number,
                                        style: const TextStyle(color: Colors.amberAccent, fontSize: 11.5, fontWeight: FontWeight.bold),
                                        decoration: InputDecoration(
                                          prefixText: '₹',
                                          prefixStyle: const TextStyle(color: Colors.amberAccent, fontSize: 10),
                                          hintText: '500',
                                          hintStyle: const TextStyle(color: Colors.white38, fontSize: 10.5),
                                          isDense: true,
                                          filled: true,
                                          fillColor: const Color(0xFF1E293B),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    // Role Dropdown
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(6)),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<PlayerRole>(
                                          value: p['role'] as PlayerRole,
                                          dropdownColor: const Color(0xFF1E293B),
                                          style: const TextStyle(color: Colors.white, fontSize: 10),
                                          items: const [
                                            DropdownMenuItem(value: PlayerRole.batsman, child: Text('Bat')),
                                            DropdownMenuItem(value: PlayerRole.bowler, child: Text('Bowl')),
                                            DropdownMenuItem(value: PlayerRole.allRounder, child: Text('All')),
                                            DropdownMenuItem(value: PlayerRole.wicketKeeper, child: Text('WK')),
                                          ],
                                          onChanged: (val) {
                                            if (val != null) {
                                              setState(() => p['role'] = val);
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 16),
                                      onPressed: () => _removePlayerField(idx),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
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
              const SizedBox(height: 12),

              // Bottom Actions (Responsive Wrap)
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  ),
                  NeoGlassButton(
                    onPressed: _validateAndCreateAuction,
                    icon: Icons.rocket_launch,
                    gradient: NeoGlassTheme.amberGoldGradient,
                    child: const Text('Create & Launch Auction', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
  }

  Widget _buildPurseField() {
    return TextField(
      controller: purseController,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white, fontSize: 12.5),
      decoration: InputDecoration(
        labelText: 'Purse Budget (₹)',
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 11),
        hintText: '50000',
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 11),
        filled: true,
        fillColor: const Color(0xFF0F172A),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildMinBidField() {
    return TextField(
      controller: minBidController,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white, fontSize: 12.5),
      decoration: InputDecoration(
        labelText: 'Min Bid (₹)',
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 11),
        hintText: '500',
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 11),
        filled: true,
        fillColor: const Color(0xFF0F172A),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _validateAndCreateAuction() {
    if (titleController.text.trim().isEmpty) {
      _tabController.animateTo(0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.redAccent, content: Text('Please enter an Auction Title.')),
      );
      return;
    }

    final purse = int.tryParse(purseController.text.trim()) ?? 50000;
    final minBid = int.tryParse(minBidController.text.trim()) ?? 500;
    final adminPass = adminPassController.text.trim().isNotEmpty ? adminPassController.text.trim() : 'admin123';

    // Extract entered team names and owner mobile numbers
    final enteredTeams = <Map<String, String>>[];
    for (int i = 0; i < teamNameControllers.length; i++) {
      final name = teamNameControllers[i].text.trim();
      final mob = (i < teamMobileControllers.length) ? teamMobileControllers[i].text.trim() : '';
      if (name.isNotEmpty) {
        enteredTeams.add({
          'name': name,
          'mobile': mob.isNotEmpty ? mob : '987654320${i + 1}',
        });
      }
    }

    if (enteredTeams.length < 2) {
      _tabController.animateTo(1);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.redAccent, content: Text('Please enter at least 2 team names in Tab 2.')),
      );
      return;
    }

    // Extract entered player entries
    final enteredPlayers = <Map<String, dynamic>>[];
    for (final p in playerEntries) {
      final name = (p['nameController'] as TextEditingController).text.trim();
      final price = int.tryParse((p['priceController'] as TextEditingController).text.trim()) ?? 500;
      if (name.isNotEmpty) {
        enteredPlayers.add({
          'name': name,
          'role': p['role'] as PlayerRole,
          'price': price,
        });
      }
    }

    // Create Tournament first
    final title = titleController.text.trim();
    final shortCode = title.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(3).join().toUpperCase();
    final createdTourn = widget.db.createTournament(
      name: title,
      shortName: shortCode.isNotEmpty ? shortCode : 'AUC',
      location: 'Home Stadium',
      overs: 20,
      roomId: 'TOURN-${DateTime.now().millisecondsSinceEpoch % 10000}',
      passcode: '1234',
      createAuction: false,
    );

    // Create isolated Auction with host's exact entered teams & players
    final createdAuc = widget.db.createAuction(
      tournamentId: createdTourn.id,
      title: '$title Player Auction',
      adminPasscode: adminPass,
      maxPursePerTeam: purse,
      minBidIncrement: minBid,
      requiredTeamsCount: enteredTeams.length,
      customTeamsWithDetails: enteredTeams,
      customPlayers: enteredPlayers,
    );

    Navigator.pop(context, createdAuc);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF009270),
        content: Text('Auction "${createdAuc.title}" created with ${enteredTeams.length} Teams!'),
      ),
    );
  }
}
