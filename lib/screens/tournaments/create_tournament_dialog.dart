import 'package:flutter/material.dart';
import '../../services/mock_database.dart';
import '../../theme/neo_glass_theme.dart';
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

  // FORMAT IS EDITABLE: Controller for custom overs + quick presets
  final oversController = TextEditingController(text: '20');
  int selectedOvers = 20;

  // TEAMS COUNT IS EDITABLE: Stepper / editable text + dynamic teams list
  final teamsCountController = TextEditingController(text: '2');
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

  void _addNewTeam() {
    setState(() {
      final i = customTeams.length;
      customTeams.add({
        'nameController': TextEditingController(),
        'shortController': TextEditingController(),
        'color': defaultColors[i % defaultColors.length],
        'players': <Map<String, dynamic>>[],
      });
      selectedTeamCount = customTeams.length;
      teamsCountController.text = '${customTeams.length}';
      selectedTeamIndex = i;
    });
  }

  void _removeTeam(int index) {
    if (customTeams.length <= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A tournament requires at least 2 teams.')),
      );
      return;
    }
    setState(() {
      final removed = customTeams.removeAt(index);
      (removed['nameController'] as TextEditingController).dispose();
      (removed['shortController'] as TextEditingController).dispose();
      final pList = removed['players'] as List<Map<String, dynamic>>;
      for (final p in pList) {
        (p['nameController'] as TextEditingController).dispose();
        (p['mobileController'] as TextEditingController).dispose();
      }
      selectedTeamCount = customTeams.length;
      teamsCountController.text = '${customTeams.length}';
      if (selectedTeamIndex >= customTeams.length) {
        selectedTeamIndex = customTeams.length - 1;
      }
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    shortController.dispose();
    locationController.dispose();
    roomController.dispose();
    passController.dispose();
    oversController.dispose();
    teamsCountController.dispose();
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

    return NeoGlassDialog(
      glowColor: NeoGlassTheme.neonEmerald,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      padding: EdgeInsets.all(dialogPadding),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with Step Indicator
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: NeoGlassTheme.neonEmerald.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: NeoGlassTheme.neonEmerald.withValues(alpha: 0.4)),
                    boxShadow: [
                      NeoGlassTheme.neoLightHighlight,
                    ],
                  ),
                  child: const Icon(Icons.emoji_events, color: NeoGlassTheme.neonEmerald, size: 20),
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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              gradient: NeoGlassTheme.neonGradient,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(color: NeoGlassTheme.neonEmerald.withValues(alpha: 0.4), blurRadius: 6),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const PulsingLiveDot(color: Colors.black, size: 5),
                                const SizedBox(width: 4),
                                Text(
                                  'Step $currentStep/2',
                                  style: const TextStyle(color: Colors.black, fontSize: 9.5, fontWeight: FontWeight.w900),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currentStep == 1
                            ? 'Format & overs are editable • Configure venue & scorer PIN'
                            : 'Teams & players are fully editable • Add/remove teams',
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
    );
  }

  // =========================================================================
  // STEP 1: TOURNAMENT DETAILS (FORMAT & TEAMS EDITABLE)
  // =========================================================================
  Widget _buildStep1TournamentDetails() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: nameController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: NeoGlassTheme.inputDecoration(
              labelText: 'Tournament Name *',
              hintText: 'e.g. Bengal Premier League',
              prefixIcon: Icons.emoji_events_outlined,
              iconColor: NeoGlassTheme.neonEmerald,
            ),
          ),
          const SizedBox(height: 10),

          // Short Code & Format (EDITABLE OVERS)
          LayoutBuilder(
            builder: (ctx, constraints) {
              if (constraints.maxWidth < 420) {
                return Column(
                  children: [
                    _buildShortCodeField(),
                    const SizedBox(height: 8),
                    _buildEditableFormatField(),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: _buildShortCodeField()),
                  const SizedBox(width: 8),
                  Expanded(child: _buildEditableFormatField()),
                ],
              );
            },
          ),

          // Quick Format Preset Chips
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text('Format Presets: ', style: TextStyle(color: Colors.white54, fontSize: 10)),
                _buildFormatChip('T6', 6),
                _buildFormatChip('T10', 10),
                _buildFormatChip('15 Ov', 15),
                _buildFormatChip('T20', 20),
                _buildFormatChip('30 Ov', 30),
                _buildFormatChip('ODI (50)', 50),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Location & Teams Count (EDITABLE TEAMS COUNT)
          LayoutBuilder(
            builder: (ctx, constraints) {
              if (constraints.maxWidth < 420) {
                return Column(
                  children: [
                    _buildLocationField(),
                    const SizedBox(height: 8),
                    _buildEditableTeamsCountField(),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(flex: 6, child: _buildLocationField()),
                  const SizedBox(width: 8),
                  Expanded(flex: 4, child: _buildEditableTeamsCountField()),
                ],
              );
            },
          ),
          const SizedBox(height: 12),

          // Security Scorer Access Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0x1800F5A0),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: NeoGlassTheme.neonEmerald.withValues(alpha: 0.4)),
              boxShadow: [
                NeoGlassTheme.neoDarkShadow,
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lock, size: 13, color: NeoGlassTheme.neonEmerald),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'SCORER ACCESS (ROOM ID & PIN)',
                        style: TextStyle(color: NeoGlassTheme.neonEmerald, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.6),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (ctx, constraints) {
                    if (constraints.maxWidth < 420) {
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
            activeColor: NeoGlassTheme.neonEmerald,
            onChanged: (val) => setState(() => autoCreateAuction = val),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatChip(String label, int overs) {
    final isSelected = selectedOvers == overs;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () {
          setState(() {
            selectedOvers = overs;
            oversController.text = '$overs';
          });
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected ? NeoGlassTheme.neonEmerald.withValues(alpha: 0.22) : const Color(0x18FFFFFF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? NeoGlassTheme.neonEmerald : NeoGlassTheme.glassBorder,
              width: isSelected ? 1.5 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(color: NeoGlassTheme.neonEmerald.withValues(alpha: 0.35), blurRadius: 8),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontSize: 10.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShortCodeField() {
    return TextField(
      controller: shortController,
      style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold),
      decoration: NeoGlassTheme.inputDecoration(
        labelText: 'Short Code *',
        hintText: 'e.g. BPL',
        prefixIcon: Icons.tag,
        iconColor: NeoGlassTheme.neonCyan,
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

  // 100% EDITABLE MATCH FORMAT (OVERS)
  Widget _buildEditableFormatField() {
    return TextField(
      controller: oversController,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold),
      decoration: NeoGlassTheme.inputDecoration(
        labelText: 'Match Overs (Format) *',
        hintText: '20',
        suffixIcon: const Padding(
          padding: EdgeInsets.all(12),
          child: Text('Ov', style: TextStyle(color: NeoGlassTheme.neonEmerald, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
      ),
      onChanged: (val) {
        final parsed = int.tryParse(val.trim());
        if (parsed != null && parsed > 0) {
          setState(() => selectedOvers = parsed);
        }
      },
    );
  }

  Widget _buildLocationField() {
    return TextField(
      controller: locationController,
      style: const TextStyle(color: Colors.white, fontSize: 12.5),
      decoration: NeoGlassTheme.inputDecoration(
        labelText: 'Venue / Stadium *',
        hintText: 'e.g. Eden Gardens, Kolkata',
        prefixIcon: Icons.location_on_outlined,
        iconColor: NeoGlassTheme.neonViolet,
      ),
    );
  }

  // 100% EDITABLE TEAMS COUNT
  Widget _buildEditableTeamsCountField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0x33000000),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: NeoGlassTheme.glassBorder),
        boxShadow: [
          NeoGlassTheme.neoDarkShadow,
          NeoGlassTheme.neoLightHighlight,
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: Colors.white60, size: 18),
            onPressed: () {
              if (selectedTeamCount > 2) {
                setState(() {
                  selectedTeamCount--;
                  teamsCountController.text = '$selectedTeamCount';
                  _initCustomTeams(selectedTeamCount);
                });
              }
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 36),
          ),
          Expanded(
            child: TextField(
              controller: teamsCountController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(color: NeoGlassTheme.neonAmber, fontSize: 13, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (val) {
                final parsed = int.tryParse(val.trim());
                if (parsed != null && parsed >= 2 && parsed <= 24) {
                  setState(() {
                    selectedTeamCount = parsed;
                    _initCustomTeams(parsed);
                  });
                }
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: NeoGlassTheme.neonEmerald, size: 18),
            onPressed: () {
              if (selectedTeamCount < 24) {
                setState(() {
                  selectedTeamCount++;
                  teamsCountController.text = '$selectedTeamCount';
                  _initCustomTeams(selectedTeamCount);
                });
              }
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 36),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomIdField() {
    return TextField(
      controller: roomController,
      style: const TextStyle(color: Colors.white, fontSize: 12),
      decoration: NeoGlassTheme.inputDecoration(
        labelText: 'Room ID',
        hintText: 'e.g. TOURN-BPL-2026',
      ),
    );
  }

  Widget _buildHostPinField() {
    return TextField(
      controller: passController,
      style: const TextStyle(color: Colors.white, fontSize: 12),
      decoration: NeoGlassTheme.inputDecoration(
        labelText: 'Host PIN',
        hintText: '1234',
      ),
    );
  }

  // =========================================================================
  // STEP 2: TEAM DETAILS & PLAYER DETAILS (USER-FRIENDLY & RESPONSIVE)
  // =========================================================================

  void _showColorPickerModal(int teamIdx) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Choose Team Jersey Color', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: defaultColors.map((col) {
                  final isCurrent = (customTeams[teamIdx]['color'] as Color).toARGB32() == col.toARGB32();
                  return InkWell(
                    onTap: () {
                      setState(() => customTeams[teamIdx]['color'] = col);
                      Navigator.pop(ctx);
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: col,
                        shape: BoxShape.circle,
                        border: Border.all(color: isCurrent ? Colors.white : Colors.transparent, width: 3),
                        boxShadow: [
                          if (isCurrent)
                            BoxShadow(color: col.withValues(alpha: 0.6), blurRadius: 10, spreadRadius: 2),
                        ],
                      ),
                      child: isCurrent ? const Icon(Icons.check, color: Colors.white, size: 22) : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showPasteRosterDialog(int teamIdx) {
    final pasteController = TextEditingController();
    final teamName = (customTeams[teamIdx]['nameController'] as TextEditingController).text.trim();
    final displayName = teamName.isNotEmpty ? teamName : 'Team ${teamIdx + 1}';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.content_paste, color: Color(0xFF34D399), size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Paste WhatsApp / Text Roster',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Paste your squad list for "$displayName" below. Each line can contain player name and mobile number:',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Text(
                  'Example:\n1. Rohit Sharma - 9876543201 (Batter)\n2. Jasprit Bumrah - 9876543202 (Bowler)\n3. KL Rahul - 9876543203 (WK)',
                  style: TextStyle(color: Colors.white38, fontSize: 10, fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pasteController,
                maxLines: 8,
                minLines: 5,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace'),
                decoration: InputDecoration(
                  hintText: 'Paste player list here...',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 11),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              final text = pasteController.text.trim();
              if (text.isEmpty) return;

              final lines = text.split('\n');
              final pList = customTeams[teamIdx]['players'] as List<Map<String, dynamic>>;
              int imported = 0;

              setState(() {
                for (final line in lines) {
                  final cleanLine = line.trim();
                  if (cleanLine.isEmpty) continue;

                  var processed = cleanLine.replaceFirst(RegExp(r'^\s*(\d+[\.\)]|\-|\*)\s*'), '');

                  String role = 'batter';
                  final lower = processed.toLowerCase();
                  if (lower.contains('wk') || lower.contains('keeper') || lower.contains('wicket')) {
                    role = 'wicketkeeper';
                  } else if (lower.contains('bowl') || lower.contains('pacer') || lower.contains('spin') || lower.contains('fast')) {
                    role = 'bowler';
                  } else if (lower.contains('all') || lower.contains('ar')) {
                    role = 'allrounder';
                  }

                  String mobile = '';
                  final phoneMatch = RegExp(r'\b[6-9]\d{9}\b').firstMatch(processed);
                  if (phoneMatch != null) {
                    mobile = phoneMatch.group(0)!;
                    processed = processed.replaceAll(mobile, '');
                  }

                  var name = processed
                      .replaceAll(RegExp(r'\((batter|batsman|bowler|allrounder|all-rounder|wk|wicketkeeper|c|vc)\)', caseSensitive: false), '')
                      .replaceAll(RegExp(r'[\-\:\,\;]'), ' ')
                      .replaceAll(RegExp(r'\s+'), ' ')
                      .trim();

                  if (name.isNotEmpty) {
                    pList.add({
                      'nameController': TextEditingController(text: name),
                      'mobileController': TextEditingController(text: mobile),
                      'role': role,
                    });
                    imported++;
                  }
                }
              });

              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF009270),
                  content: Text('🎉 Successfully imported $imported players into $displayName!'),
                ),
              );
            },
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Import Roster', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF009270),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleChip(Map<String, dynamic> row, int pIdx) {
    final role = row['role'] as String;
    Color chipColor;
    String label;
    IconData icon;

    switch (role) {
      case 'bowler':
        chipColor = const Color(0xFF0284C7);
        label = 'Bowl';
        icon = Icons.sports_baseball_outlined;
        break;
      case 'allrounder':
        chipColor = const Color(0xFF059669);
        label = 'All';
        icon = Icons.flash_on;
        break;
      case 'wicketkeeper':
        chipColor = const Color(0xFF7C3AED);
        label = 'WK';
        icon = Icons.sports_handball;
        break;
      case 'batter':
      default:
        chipColor = const Color(0xFFD97706);
        label = 'Bat';
        icon = Icons.sports_cricket_outlined;
        break;
    }

    return PopupMenuButton<String>(
      tooltip: 'Change Role',
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (val) {
        setState(() => row['role'] = val);
      },
      itemBuilder: (ctx) => [
        const PopupMenuItem(
          value: 'batter',
          child: Row(
            children: [
              Icon(Icons.sports_cricket_outlined, color: Color(0xFFD97706), size: 16),
              SizedBox(width: 8),
              Text('Batter', style: TextStyle(color: Colors.white, fontSize: 12)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'bowler',
          child: Row(
            children: [
              Icon(Icons.sports_baseball_outlined, color: Color(0xFF0284C7), size: 16),
              SizedBox(width: 8),
              Text('Bowler', style: TextStyle(color: Colors.white, fontSize: 12)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'allrounder',
          child: Row(
            children: [
              Icon(Icons.flash_on, color: Color(0xFF059669), size: 16),
              SizedBox(width: 8),
              Text('All-Rounder', style: TextStyle(color: Colors.white, fontSize: 12)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'wicketkeeper',
          child: Row(
            children: [
              Icon(Icons.sports_handball, color: Color(0xFF7C3AED), size: 16),
              SizedBox(width: 8),
              Text('Wicketkeeper', style: TextStyle(color: Colors.white, fontSize: 12)),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
        decoration: BoxDecoration(
          color: chipColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: chipColor.withValues(alpha: 0.6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: chipColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(color: chipColor, fontSize: 11, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 2),
            Icon(Icons.arrow_drop_down, size: 14, color: chipColor),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2TeamPlayerDetails() {
    if (selectedTeamIndex >= customTeams.length) {
      selectedTeamIndex = customTeams.isNotEmpty ? customTeams.length - 1 : 0;
    }
    final activeTeamData = customTeams[selectedTeamIndex];
    final activeColor = activeTeamData['color'] as Color;
    final teamNameCtrl = activeTeamData['nameController'] as TextEditingController;
    final teamShortCtrl = activeTeamData['shortController'] as TextEditingController;
    final pList = activeTeamData['players'] as List<Map<String, dynamic>>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Teams Selector Capsule Bar
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...customTeams.asMap().entries.map((entry) {
                final idx = entry.key;
                final t = entry.value;
                final isSelected = selectedTeamIndex == idx;
                final tColor = t['color'] as Color;
                final name = (t['nameController'] as TextEditingController).text.trim();
                final label = name.isNotEmpty ? name : 'Team ${idx + 1}';
                final pCount = (t['players'] as List).length;

                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    onTap: () => setState(() => selectedTeamIndex = idx),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? tColor.withValues(alpha: 0.28)
                            : const Color(0x18FFFFFF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? tColor : NeoGlassTheme.glassBorder,
                          width: isSelected ? 1.6 : 1.0,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(color: tColor.withValues(alpha: 0.45), blurRadius: 8),
                                NeoGlassTheme.neoLightHighlight,
                              ]
                            : [
                                NeoGlassTheme.neoDarkShadow,
                              ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: tColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: tColor.withValues(alpha: 0.5), blurRadius: 4),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${idx + 1}',
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            label,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: pCount >= 11
                                  ? const Color(0x3300F5A0)
                                  : (pCount > 0 ? const Color(0x33FBBF24) : Colors.white10),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              pCount >= 11 ? '✓ 11' : '$pCount',
                              style: TextStyle(
                                color: pCount >= 11
                                    ? NeoGlassTheme.neonEmerald
                                    : (pCount > 0 ? NeoGlassTheme.neonAmber : Colors.white60),
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              InkWell(
                onTap: _addNewTeam,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: NeoGlassTheme.neonEmerald.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: NeoGlassTheme.neonEmerald.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.add, size: 14, color: NeoGlassTheme.neonEmerald),
                      SizedBox(width: 4),
                      Text('+ Add Team', style: TextStyle(color: NeoGlassTheme.neonEmerald, fontSize: 10.5, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // 2. Active Team Settings Card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xE60B1120),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: activeColor.withValues(alpha: 0.5), width: 1.2),
            boxShadow: [
              NeoGlassTheme.neoDarkShadow,
              NeoGlassTheme.neoLightHighlight,
              BoxShadow(color: activeColor.withValues(alpha: 0.25), blurRadius: 10),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Team Inputs Row
              Row(
                children: [
                  InkWell(
                    onTap: () => _showColorPickerModal(selectedTeamIndex),
                    borderRadius: BorderRadius.circular(16),
                    child: Tooltip(
                      message: 'Change Team Color',
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: activeColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: activeColor.withValues(alpha: 0.5),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.palette, color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 6,
                    child: TextField(
                      controller: teamNameCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      decoration: NeoGlassTheme.inputDecoration(
                        labelText: 'Team ${selectedTeamIndex + 1} Name *',
                        hintText: 'e.g. Kolkata Tigers',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: teamShortCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      decoration: NeoGlassTheme.inputDecoration(
                        labelText: 'Code *',
                        hintText: 'KT',
                      ),
                    ),
                  ),
                  if (customTeams.length > 2) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: 'Delete Team',
                      icon: const Icon(Icons.delete_outline, color: NeoGlassTheme.neonRose, size: 20),
                      onPressed: () => _removeTeam(selectedTeamIndex),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              // Squad Progress & Actions (Never Overflows)
              if (pList.isEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'Squad: 0/11 Players',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Roster Empty',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: const LinearProgressIndicator(
                    value: 0.0,
                    backgroundColor: Colors.white12,
                    minHeight: 4,
                  ),
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Squad: ${pList.length}/11',
                                style: TextStyle(
                                  color: pList.length >= 11 ? NeoGlassTheme.neonEmerald : Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (pList.length >= 11) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.check_circle, size: 12, color: NeoGlassTheme.neonEmerald),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (pList.length / 11.0).clamp(0.0, 1.0),
                              backgroundColor: Colors.white12,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                pList.length >= 11 ? NeoGlassTheme.neonEmerald : activeColor,
                              ),
                              minHeight: 4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _showPasteRosterDialog(selectedTeamIndex),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0x18FFFFFF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: NeoGlassTheme.glassBorder),
                        ),
                        child: const Text('Paste', style: TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 5),
                    InkWell(
                      onTap: () => _addPlayerToTeam(selectedTeamIndex),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: NeoGlassTheme.neonGradient,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.add, size: 12, color: Colors.black),
                            SizedBox(width: 2),
                            Text('Add', style: TextStyle(color: Colors.black, fontSize: 10.5, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),

        // 3. Players Roster Cards List
        Expanded(
          child: pList.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(20),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: activeColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.sports_cricket, color: activeColor, size: 32),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'No Players Added Yet',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Add your playing XI players, paste your WhatsApp roster, or click Auto-Fill 11.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _addPlayerToTeam(selectedTeamIndex),
                            icon: const Icon(Icons.add, size: 14, color: Colors.black),
                            label: const Text('Add First Player', style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF34D399),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              final short = teamShortCtrl.text.trim().isNotEmpty ? teamShortCtrl.text.trim() : 'T${selectedTeamIndex + 1}';
                              _autoFillSampleSquad(selectedTeamIndex, short, '987${selectedTeamIndex}0');
                            },
                            icon: const Icon(Icons.flash_on, size: 14, color: Colors.amberAccent),
                            label: const Text('Auto-Fill 11', style: TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.amberAccent),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _showPasteRosterDialog(selectedTeamIndex),
                            icon: const Icon(Icons.content_paste, size: 14, color: Colors.white70),
                            label: const Text('Paste Roster', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white24),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: pList.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, pIdx) {
                    if (pIdx == pList.length) {
                      return OutlinedButton.icon(
                        onPressed: () => _addPlayerToTeam(selectedTeamIndex),
                        icon: const Icon(Icons.add, size: 14, color: Color(0xFF34D399)),
                        label: const Text('Add Another Player', style: TextStyle(color: Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF059669), style: BorderStyle.solid),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    }

                    final row = pList[pIdx];
                    final pNameCtrl = row['nameController'] as TextEditingController;
                    final pMobileCtrl = row['mobileController'] as TextEditingController;

                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Top Line: Jersey Badge + Full Name Input + Role Chip + Delete Button
                          Row(
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: activeColor.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(7),
                                  border: Border.all(color: activeColor.withValues(alpha: 0.5)),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '#${pIdx + 1}',
                                  style: TextStyle(color: activeColor, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: pNameCtrl,
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                  decoration: const InputDecoration(
                                    hintText: 'Player Full Name *',
                                    hintStyle: TextStyle(color: Colors.white38, fontSize: 12),
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              _buildRoleChip(row, pIdx),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.white38, size: 18),
                                tooltip: 'Remove Player',
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
                          const Divider(color: Colors.white10, height: 1),
                          const SizedBox(height: 4),
                          // Bottom Line: Mobile Phone Input
                          Row(
                            children: [
                              const Icon(Icons.phone_outlined, size: 14, color: Color(0xFF34D399)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: TextField(
                                  controller: pMobileCtrl,
                                  keyboardType: TextInputType.phone,
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                  decoration: const InputDecoration(
                                    hintText: 'Mobile Number (e.g. 9876543210)',
                                    hintStyle: TextStyle(color: Colors.white38, fontSize: 11),
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                                    border: InputBorder.none,
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

  // =========================================================================
  // BOTTOM ACTIONS (RESPONSIVE WRAP LAYOUT WITH SKIP TIP)
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
                  NeoGlassButton(
                    onPressed: () => _executeTournamentCreation(skipPlayers: true),
                    icon: Icons.flash_on,
                    gradient: NeoGlassTheme.amberGoldGradient,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    child: const Text(
                      '⚡ Quick Create',
                      style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  NeoGlassButton(
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
                    icon: Icons.arrow_forward,
                    gradient: NeoGlassTheme.neonGradient,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    child: const Text(
                      'Next: Teams & Players',
                      style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: const Color(0x22FBBF24),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: NeoGlassTheme.neonAmber.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: const [
                Icon(Icons.info_outline, size: 13, color: NeoGlassTheme.neonAmber),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Tip: You can tap "Skip for Now" to create tournament now and add squad players later before match scoring.',
                    style: TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
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
                  NeoGlassButton(
                    onPressed: () => _executeTournamentCreation(skipPlayers: true),
                    icon: Icons.skip_next,
                    isSecondary: true,
                    color: const Color(0x33FBBF24),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    child: const Text(
                      'Skip for Now',
                      style: TextStyle(color: NeoGlassTheme.neonAmber, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  NeoGlassButton(
                    onPressed: () => _executeTournamentCreation(skipPlayers: false),
                    icon: Icons.check,
                    gradient: NeoGlassTheme.neonGradient,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    child: const Text(
                      'Save & Create',
                      style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold),
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

    final effectiveOvers = int.tryParse(oversController.text.trim()) ?? selectedOvers;

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
      overs: effectiveOvers,
      roomId: effectiveRoomId,
      passcode: effectivePasscode,
      totalTeams: customTeams.length,
      createAuction: autoCreateAuction,
      customTeamsWithPlayers: formattedTeams,
    );

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF009270),
        content: Text('Tournament "${created.name}" created (${created.overs} Ov)! (PIN: ${created.passcode})'),
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
