import 'package:flutter/material.dart';
import '../../services/mock_database.dart';
import '../../widgets/app_animations.dart';
import 'tournament_hub_screen.dart';

class CreateTournamentDialog extends StatefulWidget {
  final MockDatabase db;

  const CreateTournamentDialog({super.key, required this.db});

  @override
  State<CreateTournamentDialog> createState() => _CreateTournamentDialogState();
}

class _CreateTournamentDialogState extends State<CreateTournamentDialog> with SingleTickerProviderStateMixin {
  int currentStep = 1; // 1 = Tournament Details, 2 = Team & Player Details

  // Step 1 Controllers - CLEAN MANUAL ENTRY (NO DUMMY PLACEHOLDERS)
  final nameController = TextEditingController();
  final shortController = TextEditingController();
  final locationController = TextEditingController();
  final roomController = TextEditingController();
  final passController = TextEditingController();
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
      return {
        'nameController': TextEditingController(),
        'shortController': TextEditingController(),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogPadding = screenWidth < 400 ? 12.0 : 18.0;

    return Dialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
        child: Padding(
          padding: EdgeInsets.all(dialogPadding),
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
                      border: Border.all(color: const Color(0xFF34D399).withValues(alpha: 0.4)),
                    ),
                    child: const Icon(Icons.emoji_events, color: Color(0xFF34D399), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                currentStep == 1 ? 'Organize Tournament' : 'Team Roster Setup',
                                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF009270),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const PulsingLiveDot(color: Color(0xFF34D399), size: 5),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Step $currentStep/2',
                                    style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currentStep == 1
                              ? 'Format, overs, venue & scorer PIN'
                              : 'Teams & players with mobile numbers (Can skip)',
                          style: const TextStyle(color: Colors.white60, fontSize: 10.5),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Animated Transition between Step 1 and Step 2
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.04, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: currentStep == 1
                      ? KeyedSubtree(
                          key: const ValueKey(1),
                          child: _buildStep1TournamentDetails(),
                        )
                      : KeyedSubtree(
                          key: const ValueKey(2),
                          child: _buildStep2TeamPlayerDetails(),
                        ),
                ),
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
  // STEP 1: TOURNAMENT DETAILS (RESPONSIVE & CLEAN MANUAL INPUT)
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
              hintText: 'e.g. Bengal Premier League',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
              labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
              filled: true,
              fillColor: const Color(0xFF0F172A),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 10),

          // Short Code & Format (Responsive)
          LayoutBuilder(
            builder: (ctx, constraints) {
              if (constraints.maxWidth < 280) {
                return Column(
                  children: [
                    _buildShortCodeField(),
                    const SizedBox(height: 8),
                    _buildOversDropdown(),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: _buildShortCodeField()),
                  const SizedBox(width: 8),
                  Expanded(child: _buildOversDropdown()),
                ],
              );
            },
          ),
          const SizedBox(height: 10),

          // Location & Teams Count (Responsive)
          LayoutBuilder(
            builder: (ctx, constraints) {
              if (constraints.maxWidth < 280) {
                return Column(
                  children: [
                    _buildLocationField(),
                    const SizedBox(height: 8),
                    _buildTeamsCountDropdown(),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(flex: 6, child: _buildLocationField()),
                  const SizedBox(width: 8),
                  Expanded(flex: 4, child: _buildTeamsCountDropdown()),
                ],
              );
            },
          ),
          const SizedBox(height: 12),

          // Security Scorer Access Box (Header & Fields Fixed)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF064E3B).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.lock, size: 13, color: Color(0xFF34D399)),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'SCORER ACCESS (ROOM ID & PIN)',
                        style: TextStyle(color: Color(0xFF34D399), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.6),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (ctx, constraints) {
                    if (constraints.maxWidth < 260) {
                      return Column(
                        children: [
                          _buildRoomIdField(),
                          const SizedBox(height: 8),
                          _buildHostPinField(),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(flex: 6, child: _buildRoomIdField()),
                        const SizedBox(width: 8),
                        Expanded(flex: 4, child: _buildHostPinField()),
                      ],
                    );
                  },
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

  Widget _buildShortCodeField() {
    return TextField(
      controller: shortController,
      style: const TextStyle(color: Colors.white, fontSize: 12.5),
      decoration: InputDecoration(
        labelText: 'Short Code *',
        hintText: 'e.g. BPL',
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 11),
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 11.5),
        filled: true,
        fillColor: const Color(0xFF0F172A),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onChanged: (val) {
        if (val.trim().isNotEmpty && roomController.text.trim().isEmpty) {
          setState(() {
            roomController.text = 'TOURN-${val.trim().toUpperCase().replaceAll(' ', '')}-${DateTime.now().year}';
            if (passController.text.trim().isEmpty) {
              passController.text = '1234';
            }
          });
        }
      },
    );
  }

  Widget _buildOversDropdown() {
    return DropdownButtonFormField<int>(
      value: selectedOvers,
      isExpanded: true,
      dropdownColor: const Color(0xFF1E293B),
      decoration: InputDecoration(
        labelText: 'Format',
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 11.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        filled: true,
        fillColor: const Color(0xFF0F172A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      style: const TextStyle(color: Colors.white, fontSize: 12),
      items: const [
        DropdownMenuItem(value: 20, child: Text('T20 (20 Ov)', overflow: TextOverflow.ellipsis)),
        DropdownMenuItem(value: 10, child: Text('T10 (10 Ov)', overflow: TextOverflow.ellipsis)),
        DropdownMenuItem(value: 15, child: Text('15 Overs', overflow: TextOverflow.ellipsis)),
        DropdownMenuItem(value: 50, child: Text('ODI (50 Ov)', overflow: TextOverflow.ellipsis)),
      ],
      onChanged: (val) => setState(() => selectedOvers = val ?? 20),
    );
  }

  Widget _buildLocationField() {
    return TextField(
      controller: locationController,
      style: const TextStyle(color: Colors.white, fontSize: 12.5),
      decoration: InputDecoration(
        labelText: 'Venue / Stadium *',
        hintText: 'e.g. Eden Gardens, Kolkata',
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 11),
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 11.5),
        filled: true,
        fillColor: const Color(0xFF0F172A),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildTeamsCountDropdown() {
    return DropdownButtonFormField<int>(
      value: selectedTeamCount,
      isExpanded: true,
      dropdownColor: const Color(0xFF1E293B),
      decoration: InputDecoration(
        labelText: 'Teams',
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 11.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        filled: true,
        fillColor: const Color(0xFF0F172A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      style: const TextStyle(color: Colors.white, fontSize: 12),
      items: const [
        DropdownMenuItem(value: 2, child: Text('2 Teams', overflow: TextOverflow.ellipsis)),
        DropdownMenuItem(value: 4, child: Text('4 Teams', overflow: TextOverflow.ellipsis)),
        DropdownMenuItem(value: 6, child: Text('6 Teams', overflow: TextOverflow.ellipsis)),
        DropdownMenuItem(value: 8, child: Text('8 Teams', overflow: TextOverflow.ellipsis)),
      ],
      onChanged: (val) {
        if (val != null) {
          setState(() {
            selectedTeamCount = val;
            _initCustomTeams(val);
          });
        }
      },
    );
  }

  Widget _buildRoomIdField() {
    return TextField(
      controller: roomController,
      style: const TextStyle(color: Colors.white, fontSize: 12),
      decoration: InputDecoration(
        labelText: 'Room ID',
        hintText: 'e.g. TOURN-BPL-2026',
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 11),
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 11),
        filled: true,
        fillColor: const Color(0xFF0F172A),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildHostPinField() {
    return TextField(
      controller: passController,
      style: const TextStyle(color: Colors.white, fontSize: 12),
      decoration: InputDecoration(
        labelText: 'Host PIN',
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 11),
        hintText: '1234',
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 11),
        filled: true,
        fillColor: const Color(0xFF0F172A),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // =========================================================================
  // STEP 2: TEAM DETAILS & PLAYER DETAILS (WITH MOBILE NUMBERS)
  // =========================================================================
  Widget _buildStep2TeamPlayerDetails() {
    if (selectedTeamIndex >= customTeams.length) {
      selectedTeamIndex = 0;
    }
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
              final name = (t['nameController'] as TextEditingController).text.trim();
              final label = name.isNotEmpty ? name : 'Team ${idx + 1}';
              final pCount = (t['players'] as List).length;

              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  selected: isSelected,
                  label: Text('$label ($pCount)'),
                  selectedColor: const Color(0xFF009270),
                  backgroundColor: const Color(0xFF0F172A),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontSize: 10.5,
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

        // Team Name & Short Code Inputs (Responsive)
        Row(
          children: [
            Expanded(
              flex: 7,
              child: TextField(
                controller: teamNameCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: InputDecoration(
                  labelText: 'Team ${selectedTeamIndex + 1} Name *',
                  hintText: 'Enter team name',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 11),
                  labelStyle: const TextStyle(color: Colors.white70, fontSize: 11),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: TextField(
                controller: teamShortCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: InputDecoration(
                  labelText: 'Code *',
                  hintText: 'T${selectedTeamIndex + 1}',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 11),
                  labelStyle: const TextStyle(color: Colors.white70, fontSize: 11),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Player Actions Bar
        Row(
          children: [
            Text(
              'Roster (${pList.length} Players)',
              style: const TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () {
                final short = teamShortCtrl.text.trim().isNotEmpty ? teamShortCtrl.text.trim() : 'T${selectedTeamIndex + 1}';
                _autoFillSampleSquad(selectedTeamIndex, short, '987${selectedTeamIndex}0');
              },
              icon: const Icon(Icons.flash_on, size: 12, color: Colors.amberAccent),
              label: const Text('Auto-Fill 11', style: TextStyle(color: Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2)),
            ),
            const SizedBox(width: 4),
            ElevatedButton.icon(
              onPressed: () => _addPlayerToTeam(selectedTeamIndex),
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
        const SizedBox(height: 6),

        // Players List for Active Team
        Expanded(
          child: pList.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.person_add_alt, color: Colors.white38, size: 28),
                      SizedBox(height: 6),
                      Text(
                        'No players added yet for this team.',
                        style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'You can skip adding players now and fill squads before starting live scoring.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54, fontSize: 10),
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
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            flex: 5,
                            child: TextField(
                              controller: pMobileCtrl,
                              keyboardType: TextInputType.phone,
                              style: const TextStyle(color: Colors.white, fontSize: 11.5),
                              decoration: InputDecoration(
                                hintText: 'Mobile *',
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
                          // Compact Role Selector
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(6)),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: row['role'] as String,
                                dropdownColor: const Color(0xFF1E293B),
                                style: const TextStyle(color: Colors.white, fontSize: 10),
                                items: const [
                                  DropdownMenuItem(value: 'batter', child: Text('Bat')),
                                  DropdownMenuItem(value: 'bowler', child: Text('Bowl')),
                                  DropdownMenuItem(value: 'allrounder', child: Text('All')),
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
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 16),
                            onPressed: () {
                              setState(() {
                                pNameCtrl.dispose();
                                pMobileCtrl.dispose();
                                pList.removeAt(pIdx);
                              });
                            },
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
    );
  }

  // =========================================================================
  // BOTTOM ACTIONS (RESPONSIVE WRAP LAYOUT)
  // =========================================================================
  Widget _buildBottomActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (currentStep == 1) ...[
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
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _executeTournamentCreation(skipPlayers: true),
                    icon: const Icon(Icons.flash_on, size: 13, color: Colors.amberAccent),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.amberAccent),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    label: const Text(
                      '⚡ Quick Create (Skip Players)',
                      style: TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (nameController.text.trim().isEmpty || shortController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: Colors.redAccent,
                            content: Text('Please enter Tournament Name and Short Code'),
                          ),
                        );
                        return;
                      }
                      setState(() => currentStep = 2);
                    },
                    icon: const Icon(Icons.arrow_forward, size: 14),
                    label: const Text('Next: Teams & Players', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF009270),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ] else ...[
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              TextButton.icon(
                onPressed: () => setState(() => currentStep = 1),
                icon: const Icon(Icons.arrow_back, size: 14, color: Colors.white70),
                label: const Text('Back', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _executeTournamentCreation(skipPlayers: true),
                    icon: const Icon(Icons.skip_next, size: 14, color: Colors.amberAccent),
                    label: const Text('Skip for Now', style: TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.amberAccent),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _executeTournamentCreation(skipPlayers: false),
                    icon: const Icon(Icons.check, size: 14),
                    label: const Text('Save & Create', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF009270),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ],
    );
  }

  void _executeTournamentCreation({required bool skipPlayers}) {
    if (nameController.text.trim().isEmpty || shortController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('Please enter Tournament Name and Short Code'),
        ),
      );
      return;
    }

    List<Map<String, dynamic>>? formattedTeams;

    if (!skipPlayers) {
      formattedTeams = customTeams.asMap().entries.map((entry) {
        final idx = entry.key;
        final t = entry.value;
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
        }).where((p) => (p['name'] as String).isNotEmpty).toList();

        return {
          'name': tName.isNotEmpty ? tName : 'Team ${idx + 1}',
          'shortName': tShort.isNotEmpty ? tShort : 'T${idx + 1}',
          'color': color,
          'players': playerMaps,
        };
      }).toList();
    } else {
      // User skipped players: save team names with empty squad list
      formattedTeams = customTeams.asMap().entries.map((entry) {
        final idx = entry.key;
        final t = entry.value;
        final tName = (t['nameController'] as TextEditingController).text.trim();
        final tShort = (t['shortController'] as TextEditingController).text.trim();
        final color = t['color'] as Color;
        return {
          'name': tName.isNotEmpty ? tName : 'Team ${idx + 1}',
          'shortName': tShort.isNotEmpty ? tShort : 'T${idx + 1}',
          'color': color,
          'players': <Map<String, String>>[], // Empty players list!
        };
      }).toList();
    }

    final tournShort = shortController.text.trim().toUpperCase();
    final effectiveRoomId = roomController.text.trim().isNotEmpty
        ? roomController.text.trim()
        : 'TOURN-$tournShort-${DateTime.now().year}';
    final effectivePasscode = passController.text.trim().isNotEmpty
        ? passController.text.trim()
        : '1234';
    final effectiveLocation = locationController.text.trim().isNotEmpty
        ? locationController.text.trim()
        : 'Main Cricket Ground';

    final created = widget.db.createTournament(
      name: nameController.text.trim(),
      shortName: shortController.text.trim(),
      location: effectiveLocation,
      overs: selectedOvers,
      roomId: effectiveRoomId,
      passcode: effectivePasscode,
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
