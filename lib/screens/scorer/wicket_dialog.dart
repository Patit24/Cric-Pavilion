import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/cricket_rules_engine.dart';
import '../../theme/neo_glass_theme.dart';

class WicketDialog extends StatefulWidget {
  final Player striker;
  final Player nonStriker;
  final List<Player> battingTeamPlayers;
  final List<Player> bowlingTeamPlayers;
  final List<Delivery> deliveries;
  final String inningsId;
  final int currentWickets;
  final Function({
    required DismissalType dismissalType,
    required String dismissedPlayerId,
    String? fielderId,
    String? nextBatterId,
  }) onConfirmWicket;

  const WicketDialog({
    super.key,
    required this.striker,
    required this.nonStriker,
    required this.battingTeamPlayers,
    required this.bowlingTeamPlayers,
    required this.deliveries,
    required this.inningsId,
    required this.currentWickets,
    required this.onConfirmWicket,
  });

  @override
  State<WicketDialog> createState() => _WicketDialogState();
}

class _WicketDialogState extends State<WicketDialog> {
  int step = 1; // 1 = dismissal details, 2 = select incoming batter
  DismissalType selectedType = DismissalType.caught;
  late String dismissedBatterId;
  String? selectedFielderId;
  String? nextBatterId;

  @override
  void initState() {
    super.initState();
    dismissedBatterId = widget.striker.id;
    if (widget.bowlingTeamPlayers.isNotEmpty) {
      selectedFielderId = widget.bowlingTeamPlayers.first.id;
    }
  }

  String _playerName(Player p) {
    final fn = p.fullName.trim();
    if (fn.isNotEmpty) return fn;
    final dn = p.displayName.trim();
    if (dn.isNotEmpty) return dn;
    return 'Batter';
  }

  @override
  Widget build(BuildContext context) {
    final availableDugout = CricketRulesEngine.getAvailableIncomingBatsmen(
      teamPlayers: widget.battingTeamPlayers,
      deliveries: widget.deliveries,
      inningsId: widget.inningsId,
      currentStrikerId: widget.striker.id,
      currentNonStrikerId: widget.nonStriker.id,
      dismissedPlayerId: dismissedBatterId,
    );

    final isAllOutAfterThis = widget.currentWickets + 1 >= 10 || availableDugout.isEmpty;

    return NeoGlassDialog(
      glowColor: NeoGlassTheme.neonRose,
      padding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.82,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: NeoGlassTheme.neonRose.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: NeoGlassTheme.neonRose.withValues(alpha: 0.5)),
                  ),
                  child: const Icon(Icons.sports_cricket, color: NeoGlassTheme.neonRose, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'WICKET DISMISSAL',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: NeoGlassTheme.neonRose,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Text(
                      step == 1 ? 'Step 1: How Out?' : 'Step 2: Incoming Batter',
                      style: const TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (step == 1) ...[
              // Out Player Choice
              const Text('Dismissed Batter:', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white70)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: Text(
                        '★ ${_playerName(widget.striker)} (Striker)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: dismissedBatterId == widget.striker.id ? Colors.black : Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      selected: dismissedBatterId == widget.striker.id,
                      selectedColor: NeoGlassTheme.neonEmerald,
                      backgroundColor: const Color(0xFF0F172A),
                      onSelected: (val) {
                        setState(() => dismissedBatterId = widget.striker.id);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: Text(
                        '• ${_playerName(widget.nonStriker)} (Non-Striker)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: dismissedBatterId == widget.nonStriker.id ? Colors.black : Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      selected: dismissedBatterId == widget.nonStriker.id,
                      selectedColor: NeoGlassTheme.neonEmerald,
                      backgroundColor: const Color(0xFF0F172A),
                      onSelected: (val) {
                        setState(() => dismissedBatterId = widget.nonStriker.id);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Dismissal Mode
              const Text('Dismissal Type:', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white70)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: DismissalType.values.map((type) {
                  final isSelected = selectedType == type;
                  return ChoiceChip(
                    label: Text(
                      type.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.white70,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: NeoGlassTheme.neonRose,
                    backgroundColor: const Color(0xFF0F172A),
                    onSelected: (val) {
                      setState(() => selectedType = type);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Fielder dropdown for caught/run-out/stumped
              if (selectedType == DismissalType.caught || selectedType == DismissalType.runOut || selectedType == DismissalType.stumped) ...[
                const Text('Fielder Involved:', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white70)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: selectedFielderId,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF0F172A),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white24)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white24)),
                  ),
                  items: widget.bowlingTeamPlayers.map((p) {
                    final name = p.fullName.isNotEmpty ? p.fullName : p.displayName;
                    return DropdownMenuItem(value: p.id, child: Text(name, overflow: TextOverflow.ellipsis));
                  }).toList(),
                  onChanged: (val) => setState(() => selectedFielderId = val),
                ),
                const SizedBox(height: 12),
              ],

              // Next Button
              NeoGlassButton(
                onPressed: () {
                  if (isAllOutAfterThis) {
                    Navigator.pop(context);
                    widget.onConfirmWicket(
                      dismissalType: selectedType,
                      dismissedPlayerId: dismissedBatterId,
                      fielderId: selectedFielderId,
                      nextBatterId: null,
                    );
                  } else {
                    setState(() {
                      if (availableDugout.isNotEmpty) {
                        nextBatterId = availableDugout.first.id;
                      }
                      step = 2;
                    });
                  }
                },
                gradient: NeoGlassTheme.neonGradient,
                child: Text(
                  isAllOutAfterThis ? 'Confirm Wicket (All Out)' : 'Next: Select Incoming Batter →',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ] else ...[
              // Step 2: Select incoming batter
              Text(
                'Select Incoming Batter (${availableDugout.length} in dugout):',
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white70),
              ),
              const SizedBox(height: 10),

              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: availableDugout.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final b = availableDugout[index];
                    final isSelected = nextBatterId == b.id;
                    final bName = b.fullName.isNotEmpty ? b.fullName : b.displayName;

                    return InkWell(
                      onTap: () => setState(() => nextBatterId = b.id),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0x3310B981) : const Color(0x330F172A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? NeoGlassTheme.neonEmerald : Colors.white12,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                          boxShadow: [
                            NeoGlassTheme.neoDarkShadow,
                            if (isSelected)
                              NeoGlassTheme.neoGlowShadow(NeoGlassTheme.neonEmerald, opacity: 0.2),
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundImage: NetworkImage(b.photoUrl),
                              backgroundColor: const Color(0xFF1E293B),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    bName,
                                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${b.roleString} • ${b.battingStyle}',
                                    style: const TextStyle(fontSize: 10, color: Colors.white60),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle, color: NeoGlassTheme.neonEmerald, size: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  TextButton(
                    onPressed: () => setState(() => step = 1),
                    child: const Text('← Back', style: TextStyle(color: Colors.white70)),
                  ),
                  const Spacer(),
                  NeoGlassButton(
                    onPressed: nextBatterId == null
                        ? null
                        : () {
                            Navigator.pop(context);
                            widget.onConfirmWicket(
                              dismissalType: selectedType,
                              dismissedPlayerId: dismissedBatterId,
                              fielderId: selectedFielderId,
                              nextBatterId: nextBatterId,
                            );
                          },
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                    ),
                    child: const Text(
                      'Confirm Out & Bat 🏏',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
