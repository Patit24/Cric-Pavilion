import 'package:flutter/material.dart';
import '../../services/mock_database.dart';
import 'tournament_hub_screen.dart';

class CreateTournamentDialog extends StatefulWidget {
  final MockDatabase db;

  const CreateTournamentDialog({super.key, required this.db});

  @override
  State<CreateTournamentDialog> createState() => _CreateTournamentDialogState();
}

class _CreateTournamentDialogState extends State<CreateTournamentDialog> with SingleTickerProviderStateMixin {
  int currentStep = 1; // 1 = Tournament Details, 2 = Team & Player Details

  // Step 1 Controllers
  final nameController = TextEditingController(text: 'Bengal Premier League 2026');
  final shortController = TextEditingController(text: 'BPL 2026');
  final locationController = TextEditingController(text: 'Eden Gardens, Kolkata');
  final roomController = TextEditingController(text: 'TOURN-BPL-2026');
  final passController = TextEditingController(text: '1234');
  int selectedOvers = 20;
  int selectedTeamCount = 2; // Default 2 teams
  bool autoCreateAuction = false;

  // Step 2 Team & Player State
  int selectedTeamIndex = 0;
  late List<Map<String, dynamic>> customTeams;

  final defaultColors = [
    const Color(0xFF009270),
    const Color(0xFF0284C7),
    const Color(0xFF7C3AED),
    const Color(0xFFD97706),
    const Color(0xFFE11D48),
    const Color(0xFF2563EB),
    const Color(0xFF9333EA),
    const Color(0xFF0D9488),
  ];

  @override
  void initState() {
    super.initState();
    _initCustomTeams(selectedTeamCount);
  }

  void _initCustomTeams(int count) {
    customTeams = List.generate(count, (i) {
      final defaultName = i == 0 ? 'Barasat Blasters' : (i == 1 ? 'Howrah Hurricanes' : 'Team ${i + 1}');
      final defaultShort = i == 0 ? 'BBL' : (i == 1 ? 'HH' : 'T${i + 1}');
      return {
        'nameController': TextEditingController(text: defaultName),
        'shortController': TextEditingController(text: defaultShort),
        'color': defaultColors[i % defaultColors.length],
        'players': <Map<String, dynamic>>[],
      };
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    shortController.dispose();
    locationController.dispose();
    roomController.dispose();
    passController.dispose();
    for (final t in customTeams) {
      (t['nameController'] as TextEditingController).dispose();
      (t['shortController'] as TextEditingController).dispose();
      final pList = t['players'] as List<Map<String, dynamic>>;
      for (final p in pList) {
        (p['nameController'] as TextEditingController).dispose();
        (p['mobileController'] as TextEditingController).dispose();
      }
    }
    super.dispose();
  }

  void _addPlayerToTeam(int teamIdx, {String name = '', String mobile = '', String role = 'batter'}) {
    setState(() {
      final pList = customTeams[teamIdx]['players'] as List<Map<String, dynamic>>;
      pList.add({
        'nameController': TextEditingController(text: name),
        'mobileController': TextEditingController(text: mobile),
        'role': role,
      });
    });
  }

  void _autoFillSampleSquad(int teamIdx, String teamPrefix, String mobilePrefix) {
    final names = [
      'Rahul Das',
      'Amit Sharma',
      'Suman Biswas',
      'Subham Dey',
      'Debayan Paul',
      'Tanmoy Das',
      'Arjun Ghosh',
      'Vikram Sen',
      'Rohan Mukherjee',
      'Pankaj Roy',
      'Manoj Tiwary',
    ];

    setState(() {
      final pList = customTeams[teamIdx]['players'] as List<Map<String, dynamic>>;
      pList.clear();
      for (int i = 0; i < names.length; i++) {
        final role = i < 4 ? 'batter' : (i < 6 ? 'wicketkeeper' : (i < 8 ? 'allrounder' : 'bowler'));
        pList.add({
          'nameController': TextEditingController(text: '$teamPrefix ${names[i]}'),
          'mobileController': TextEditingController(text: '$mobilePrefix${1000 + i}'),
          'role': role,
        });
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
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with Step Indicator
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF009270).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.emoji_events, color: Color(0xFF34D399), size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentStep == 1 ? 'Organize New Tournament' : 'Team Details & Player Roster',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          currentStep == 1
                              ? 'Step 1 of 2: Tournament format, overs, and access PIN'
                              : 'Step 2 of 2: Teams & Players with mobile numbers (Can skip for now)',
                          style: const TextStyle(color: Colors.white60, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white54),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Content based on step
              Expanded(
                child: currentStep == 1 ? _buildStep1TournamentDetails() : _buildStep2TeamPlayerDetails(),
              ),

              const SizedBox(height: 12),

              // Bottom Action Buttons
              _buildBottomActions(),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // STEP 1: TOURNAMENT DETAILS
  // =========================================================================
  Widget _buildStep1TournamentDetails() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: nameController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              labelText: 'Tournament Name *',
              labelStyle: const TextStyle(color: Colors.white70),
              filled: true,
              fillColor: const Color(0xFF0F172A),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: shortController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Short Code *',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (val) {
                    if (val.trim().isNotEmpty) {
                      setState(() {
                        roomController.text = 'TOURN-${val.trim().toUpperCase().replaceAll(' ', '')}-2026';
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: selectedOvers,
                  dropdownColor: const Color(0xFF1E293B),
                  decoration: InputDecoration(
                    labelText: 'Match Format',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  items: const [
                    DropdownMenuItem(value: 20, child: Text('T20 (20 Overs)')),
                    DropdownMenuItem(value: 10, child: Text('T10 (10 Overs)')),
                    DropdownMenuItem(value: 15, child: Text('15 Overs')),
                    DropdownMenuItem(value: 50, child: Text('ODI (50 Overs)')),
                  ],
                  onChanged: (val) => setState(() => selectedOvers = val ?? 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 6,
                child: TextField(
                  controller: locationController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Location / Stadium *',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 4,
                child: DropdownButtonFormField<int>(
                  value: selectedTeamCount,
                  dropdownColor: const Color(0xFF1E293B),
                  decoration: InputDecoration(
                    labelText: 'Teams Count',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  items: const [
                    DropdownMenuItem(value: 2, child: Text('2 Teams')),
                    DropdownMenuItem(value: 4, child: Text('4 Teams')),
                    DropdownMenuItem(value: 6, child: Text('6 Teams')),
                    DropdownMenuItem(value: 8, child: Text('8 Teams')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        selectedTeamCount = val;
                        _initCustomTeams(val);
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Security Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF064E3B).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF059669)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.lock, size: 14, color: Color(0xFF34D399)),
                    SizedBox(width: 6),
                    Text(
                      'TOURNAMENT SCORER ACCESS (ROOM ID & PIN)',
                      style: TextStyle(color: Color(0xFF34D399), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: TextField(
                        controller: roomController,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        decoration: InputDecoration(
                          labelText: 'Room ID',
                          labelStyle: const TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 4,
                      child: TextField(
                        controller: passController,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        decoration: InputDecoration(
                          labelText: 'Host PIN',
                          labelStyle: const TextStyle(color: Colors.white70),
                          hintText: 'e.g. 1234',
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Create Linked Player Auction Draft', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            subtitle: const Text('Provision auction floor & team bidding consoles for this tournament', style: TextStyle(color: Colors.white54, fontSize: 10)),
            value: autoCreateAuction,
            activeColor: const Color(0xFF34D399),
            onChanged: (val) => setState(() => autoCreateAuction = val),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // STEP 2: TEAM DETAILS & PLAYER DETAILS (WITH MOBILE NUMBERS)
  // =========================================================================
  Widget _buildStep2TeamPlayerDetails() {
    final activeTeamData = customTeams[selectedTeamIndex];
    final teamNameCtrl = activeTeamData['nameController'] as TextEditingController;
    final teamShortCtrl = activeTeamData['shortController'] as TextEditingController;
    final pList = activeTeamData['players'] as List<Map<String, dynamic>>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Teams Selector Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: customTeams.asMap().entries.map((entry) {
              final idx = entry.key;
              final t = entry.value;
              final isSelected = selectedTeamIndex == idx;
              final name = (t['nameController'] as TextEditingController).text;
              final pCount = (t['players'] as List).length;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  selected: isSelected,
                  label: Text('$name ($pCount)'),
                  selectedColor: const Color(0xFF009270),
                  backgroundColor: const Color(0xFF0F172A),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => selectedTeamIndex = idx);
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 10),

        // Team Name & Short Code Inputs
        Row(
          children: [
            Expanded(
              flex: 7,
              child: TextField(
                controller: teamNameCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: InputDecoration(
                  labelText: 'Team ${selectedTeamIndex + 1} Name',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: TextField(
                controller: teamShortCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: InputDecoration(
                  labelText: 'Code',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Action bar for adding players
        Row(
          children: [
            Text(
              'Players with Mobile Numbers (${pList.length})',
              style: const TextStyle(color: Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _autoFillSampleSquad(selectedTeamIndex, teamShortCtrl.text, '9830${selectedTeamIndex + 1}'),
              icon: const Icon(Icons.flash_on, size: 12, color: Colors.amberAccent),
              label: const Text('Auto-Fill Squad', style: TextStyle(color: Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
            OutlinedButton.icon(
              onPressed: () => _addPlayerToTeam(selectedTeamIndex),
              icon: const Icon(Icons.add, size: 12, color: Color(0xFF34D399)),
              label: const Text('+ Player', style: TextStyle(color: Color(0xFF34D399), fontSize: 10, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF059669)),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Player Entries List
        Expanded(
          child: pList.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.group_add, color: Colors.white38, size: 32),
                      const SizedBox(height: 8),
                      const Text(
                        'No players added for this team yet.',
                        style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'You can add player names & mobile numbers now, or skip and add them before starting live scoring.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54, fontSize: 10.5),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: pList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (ctx, pIdx) {
                    final row = pList[pIdx];
                    final pNameCtrl = row['nameController'] as TextEditingController;
                    final pMobileCtrl = row['mobileController'] as TextEditingController;

                    return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 10,
                            backgroundColor: const Color(0xFF1E293B),
                            child: Text('${pIdx + 1}', style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            flex: 5,
                            child: TextField(
                              controller: pNameCtrl,
                              style: const TextStyle(color: Colors.white, fontSize: 11.5),
                              decoration: InputDecoration(
                                hintText: 'Player Name *',
                                hintStyle: const TextStyle(color: Colors.white38, fontSize: 10.5),
                                isDense: true,
                                filled: true,
                                fillColor: const Color(0xFF1E293B),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            flex: 4,
                            child: TextField(
                              controller: pMobileCtrl,
                              keyboardType: TextInputType.phone,
                              style: const TextStyle(color: Colors.white, fontSize: 11.5),
                              decoration: InputDecoration(
                                hintText: 'Mobile No *',
                                hintStyle: const TextStyle(color: Colors.white38, fontSize: 10.5),
                                isDense: true,
                                filled: true,
                                fillColor: const Color(0xFF1E293B),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 15, color: Colors.redAccent),
                            onPressed: () => setState(() => pList.removeAt(pIdx)),
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

  // =========================================================================
  // BOTTOM ACTIONS (INCLUDING PROMINENT SKIP BUTTON!)
  // =========================================================================
  Widget _buildBottomActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (currentStep == 1) ...[
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
              ),
              const Spacer(),
              // Skip directly from Step 1 option
              OutlinedButton(
                onPressed: () => _executeTournamentCreation(skipPlayers: true),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white38),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                child: const Text('⚡ Quick Create (Skip Players)', style: TextStyle(color: Colors.white70, fontSize: 11)),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {
                  if (nameController.text.trim().isEmpty || shortController.text.trim().isEmpty) return;
                  setState(() => currentStep = 2);
                },
                icon: const Icon(Icons.arrow_forward, size: 14),
                label: const Text('Next: Teams & Players', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF009270), foregroundColor: Colors.white),
              ),
            ],
          ),
        ] else ...[
          Row(
            children: [
              TextButton.icon(
                onPressed: () => setState(() => currentStep = 1),
                icon: const Icon(Icons.arrow_back, size: 14, color: Colors.white70),
                label: const Text('Back', style: TextStyle(color: Colors.white70)),
              ),
              const Spacer(),
              // User can skip adding players during tournament creation!
              OutlinedButton.icon(
                onPressed: () => _executeTournamentCreation(skipPlayers: true),
                icon: const Icon(Icons.skip_next, size: 14, color: Colors.amberAccent),
                label: const Text('Skip for Now', style: TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.amberAccent),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _executeTournamentCreation(skipPlayers: false),
                icon: const Icon(Icons.check, size: 14),
                label: const Text('Save & Create', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF009270), foregroundColor: Colors.white),
              ),
            ],
          ),
        ],
      ],
    );
  }

  void _executeTournamentCreation({required bool skipPlayers}) {
    if (nameController.text.trim().isEmpty || shortController.text.trim().isEmpty) return;

    List<Map<String, dynamic>>? formattedTeams;

    if (!skipPlayers) {
      formattedTeams = customTeams.map((t) {
        final tName = (t['nameController'] as TextEditingController).text.trim();
        final tShort = (t['shortController'] as TextEditingController).text.trim();
        final color = t['color'] as Color;
        final pList = t['players'] as List<Map<String, dynamic>>;

        final playerMaps = pList.map((p) {
          return {
            'name': (p['nameController'] as TextEditingController).text.trim(),
            'mobile': (p['mobileController'] as TextEditingController).text.trim(),
            'role': p['role'] as String,
          };
        }).where((p) => p['name']!.isNotEmpty).toList();

        return {
          'name': tName.isNotEmpty ? tName : 'Team',
          'shortName': tShort.isNotEmpty ? tShort : 'TM',
          'color': color,
          'players': playerMaps,
        };
      }).toList();
    } else {
      // User skipped players: save team names with empty squad list
      formattedTeams = customTeams.map((t) {
        final tName = (t['nameController'] as TextEditingController).text.trim();
        final tShort = (t['shortController'] as TextEditingController).text.trim();
        final color = t['color'] as Color;
        return {
          'name': tName.isNotEmpty ? tName : 'Team',
          'shortName': tShort.isNotEmpty ? tShort : 'TM',
          'color': color,
          'players': <Map<String, String>>[], // Empty players list!
        };
      }).toList();
    }

    final created = widget.db.createTournament(
      name: nameController.text.trim(),
      shortName: shortController.text.trim(),
      location: locationController.text.trim(),
      overs: selectedOvers,
      roomId: roomController.text.trim(),
      passcode: passController.text.trim(),
      totalTeams: selectedTeamCount,
      createAuction: autoCreateAuction,
      customTeamsWithPlayers: formattedTeams,
    );

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF009270),
        content: Text('Tournament "${created.name}" created! (PIN: ${created.passcode})'),
      ),
    );

    // Open dedicated tournament hub immediately!
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => TournamentHubScreen(initialTournamentId: created.id),
      ),
    );
  }
}
