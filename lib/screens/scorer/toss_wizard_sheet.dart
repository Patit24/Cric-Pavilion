import 'package:flutter/material.dart';
import '../../models/models.dart';

class TossWizardSheet extends StatefulWidget {
  final MatchModel match;
  final Team teamA;
  final Team teamB;
  final List<Player> teamAPlayers;
  final List<Player> teamBPlayers;
  final Function({
    required String tossWonBy,
    required String tossDecision,
    required String strikerId,
    required String nonStrikerId,
    required String bowlerId,
  }) onStartMatch;

  const TossWizardSheet({
    super.key,
    required this.match,
    required this.teamA,
    required this.teamB,
    required this.teamAPlayers,
    required this.teamBPlayers,
    required this.onStartMatch,
  });

  @override
  State<TossWizardSheet> createState() => _TossWizardSheetState();
}

class _TossWizardSheetState extends State<TossWizardSheet> {
  int currentStep = 1;

  // Toss choices
  late String tossWonById;
  String tossDecision = 'bat'; // 'bat' or 'bowl'

  // Crease choices
  String? strikerId;
  String? nonStrikerId;
  String? bowlerId;

  @override
  void initState() {
    super.initState();
    tossWonById = widget.teamA.id;
    _updateCreaseDefaults();
  }

  void _updateCreaseDefaults() {
    final battingTeamId = (tossDecision == 'bat')
        ? tossWonById
        : (tossWonById == widget.teamA.id ? widget.teamB.id : widget.teamA.id);

    final battingPlayers = battingTeamId == widget.teamA.id ? widget.teamAPlayers : widget.teamBPlayers;
    final bowlingPlayers = battingTeamId == widget.teamA.id ? widget.teamBPlayers : widget.teamAPlayers;

    if (battingPlayers.length >= 2) {
      strikerId = battingPlayers[0].id;
      nonStrikerId = battingPlayers[1].id;
    }
    if (bowlingPlayers.isNotEmpty) {
      // Pick first bowler
      final bowlerPlayer = bowlingPlayers.firstWhere(
        (p) => p.role == PlayerRole.bowler,
        orElse: () => bowlingPlayers.last,
      );
      bowlerId = bowlerPlayer.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final battingTeamId = (tossDecision == 'bat')
        ? tossWonById
        : (tossWonById == widget.teamA.id ? widget.teamB.id : widget.teamA.id);

    final battingTeam = battingTeamId == widget.teamA.id ? widget.teamA : widget.teamB;
    final bowlingTeam = battingTeamId == widget.teamA.id ? widget.teamB : widget.teamA;

    final battingPlayers = battingTeamId == widget.teamA.id ? widget.teamAPlayers : widget.teamBPlayers;
    final bowlingPlayers = battingTeamId == widget.teamA.id ? widget.teamBPlayers : widget.teamAPlayers;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),

            // Step Indicator Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STEP $currentStep OF 2 • ${currentStep == 1 ? "COIN TOSS" : "OPENING LINEUP"}',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF059669), letterSpacing: 1),
                    ),
                    Text(
                      widget.match.stage,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                  child: Text('${widget.match.overs} Overs T20', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const Divider(height: 24),

            if (currentStep == 1) ...[
              // STEP 1: COIN TOSS
              const Text('1. Which team won the coin toss?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          tossWonById = widget.teamA.id;
                          _updateCreaseDefaults();
                        });
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: tossWonById == widget.teamA.id ? const Color(0xFFD1FAE5) : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: tossWonById == widget.teamA.id ? const Color(0xFF059669) : Colors.grey.shade300, width: 2),
                        ),
                        child: Column(
                          children: [
                            Text(widget.teamA.shortName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: widget.teamA.primaryColor)),
                            const SizedBox(height: 4),
                            Text(widget.teamA.name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          tossWonById = widget.teamB.id;
                          _updateCreaseDefaults();
                        });
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: tossWonById == widget.teamB.id ? const Color(0xFFD1FAE5) : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: tossWonById == widget.teamB.id ? const Color(0xFF059669) : Colors.grey.shade300, width: 2),
                        ),
                        child: Column(
                          children: [
                            Text(widget.teamB.shortName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: widget.teamB.primaryColor)),
                            const SizedBox(height: 4),
                            Text(widget.teamB.name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              const Text('2. What did they elect to do?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.sports_cricket, size: 14),
                          SizedBox(width: 6),
                          Text('Elected to BAT', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      selected: tossDecision == 'bat',
                      selectedColor: const Color(0xFFD1FAE5),
                      onSelected: (val) {
                        setState(() {
                          tossDecision = 'bat';
                          _updateCreaseDefaults();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ChoiceChip(
                      label: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shield, size: 14),
                          SizedBox(width: 6),
                          Text('Elected to BOWL', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      selected: tossDecision == 'bowl',
                      selectedColor: const Color(0xFFD1FAE5),
                      onSelected: (val) {
                        setState(() {
                          tossDecision = 'bowl';
                          _updateCreaseDefaults();
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: () {
                  setState(() => currentStep = 2);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Next: Choose Opening Crease →', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ] else ...[
              // STEP 2: OPENING CREASE LINEUP
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '🏏 ${battingTeam.name} are BATTING FIRST • ${bowlingTeam.name} are BOWLING FIRST',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF065F46), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),

              // Opening Striker
              const Text('Opening Striker (* facing ball 0.1):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                value: strikerId,
                isExpanded: true,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: battingPlayers.map((p) {
                  return DropdownMenuItem(value: p.id, child: Text('${p.fullName} (${p.battingStyle})', style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis));
                }).toList(),
                onChanged: (val) => setState(() => strikerId = val),
              ),
              const SizedBox(height: 12),

              // Opening Non-Striker
              const Text('Opening Non-Striker (other end):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                value: nonStrikerId,
                isExpanded: true,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: battingPlayers.map((p) {
                  return DropdownMenuItem(value: p.id, child: Text('${p.fullName} (${p.battingStyle})', style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis));
                }).toList(),
                onChanged: (val) => setState(() => nonStrikerId = val),
              ),
              const SizedBox(height: 12),

              // Opening Bowler
              const Text('Opening Bowler (Over 1):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                value: bowlerId,
                isExpanded: true,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: bowlingPlayers.map((p) {
                  return DropdownMenuItem(value: p.id, child: Text('${p.fullName} (${p.bowlingStyle})', style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis));
                }).toList(),
                onChanged: (val) => setState(() => bowlerId = val),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  TextButton(
                    onPressed: () => setState(() => currentStep = 1),
                    child: const Text('← Back'),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: (strikerId != null && nonStrikerId != null && bowlerId != null && strikerId != nonStrikerId)
                        ? () {
                            Navigator.pop(context);
                            widget.onStartMatch(
                              tossWonBy: tossWonById,
                              tossDecision: tossDecision,
                              strikerId: strikerId!,
                              nonStrikerId: nonStrikerId!,
                              bowlerId: bowlerId!,
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Start Live Scoring 0.1 →', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
