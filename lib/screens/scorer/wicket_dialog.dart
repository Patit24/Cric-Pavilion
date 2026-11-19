import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/cricket_rules_engine.dart';

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

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.close, color: Colors.red, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('WICKET DISMISSAL', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.red)),
                    Text(step == 1 ? 'Step 1: How Out?' : 'Step 2: Incoming Batter', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (step == 1) ...[
              // Out Player Choice
              const Text('Dismissed Batter:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: Text('★ ${widget.striker.displayName} (Striker)', style: const TextStyle(fontSize: 11)),
                      selected: dismissedBatterId == widget.striker.id,
                      onSelected: (val) {
                        setState(() => dismissedBatterId = widget.striker.id);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: Text('${widget.nonStriker.displayName} (Non-Striker)', style: const TextStyle(fontSize: 11)),
                      selected: dismissedBatterId == widget.nonStriker.id,
                      onSelected: (val) {
                        setState(() => dismissedBatterId = widget.nonStriker.id);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Dismissal Mode
              const Text('Dismissal Type:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: DismissalType.values.map((type) {
                  final isSelected = selectedType == type;
                  return ChoiceChip(
                    label: Text(type.name.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    selected: isSelected,
                    selectedColor: Colors.red.shade100,
                    onSelected: (val) {
                      setState(() => selectedType = type);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Fielder dropdown for caught/run-out/stumped
              if (selectedType == DismissalType.caught || selectedType == DismissalType.runOut || selectedType == DismissalType.stumped) ...[
                const Text('Fielder Involved:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  value: selectedFielderId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: widget.bowlingTeamPlayers.map((p) {
                    return DropdownMenuItem(value: p.id, child: Text(p.fullName, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis));
                  }).toList(),
                  onChanged: (val) => setState(() => selectedFielderId = val),
                ),
                const SizedBox(height: 12),
              ],

              // Next Button
              ElevatedButton(
                onPressed: () {
                  if (isAllOutAfterThis) {
                    // All out, confirm directly
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  isAllOutAfterThis ? 'Confirm Wicket (All Out)' : 'Next: Select Incoming Batter →',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ] else ...[
              // Step 2: Select incoming batter
              Text(
                'Select Incoming Batter (${availableDugout.length} in dugout):',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
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

                    return InkWell(
                      onTap: () => setState(() => nextBatterId = b.id),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFD1FAE5) : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? const Color(0xFF059669) : Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundImage: NetworkImage(b.photoUrl),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(b.fullName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  Text('${b.roleString} • ${b.battingStyle}', style: const TextStyle(fontSize: 10, color: Colors.black54)),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle, color: Color(0xFF059669), size: 18),
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
                    child: const Text('← Back'),
                  ),
                  const Spacer(),
                  ElevatedButton(
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Confirm Out & Bat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
