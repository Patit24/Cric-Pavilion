import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/cricket_rules_engine.dart';

class OverCompleteDialog extends StatelessWidget {
  final int completedOverNumber;
  final List<Player> bowlingTeamPlayers;
  final List<Delivery> deliveries;
  final String inningsId;
  final String? previousOverBowlerId;
  final int maxOversPerBowler;
  final Function(String) onSelectBowler;

  const OverCompleteDialog({
    super.key,
    required this.completedOverNumber,
    required this.bowlingTeamPlayers,
    required this.deliveries,
    required this.inningsId,
    required this.previousOverBowlerId,
    required this.maxOversPerBowler,
    required this.onSelectBowler,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFD1FAE5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'OVER $completedOverNumber COMPLETED',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF065F46),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Select Next Bowler',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 4),
            const Text(
              'Ends swap automatically. Same bowler cannot bowl consecutive overs (ICC Law 17.8).',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.black54),
            ),
            const SizedBox(height: 16),

            // Bowler List
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: bowlingTeamPlayers.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final p = bowlingTeamPlayers[index];
                  final eligibility = CricketRulesEngine.validateBowler(
                    bowlerId: p.id,
                    previousOverBowlerId: previousOverBowlerId,
                    deliveries: deliveries,
                    inningsId: inningsId,
                    maxOversPerBowler: maxOversPerBowler,
                  );

                  final isLocked = !eligibility.isEligible;

                  return InkWell(
                    onTap: isLocked
                        ? null
                        : () {
                            Navigator.pop(context);
                            onSelectBowler(p.id);
                          },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isLocked ? Colors.grey.shade100 : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isLocked ? Colors.grey.shade300 : const Color(0xFF059669),
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundImage: NetworkImage(p.photoUrl),
                            backgroundColor: Colors.grey.shade200,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.fullName.isNotEmpty ? p.fullName : p.displayName,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isLocked ? Colors.grey.shade600 : Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  '${p.bowlingStyle} • ${eligibility.oversStr} ov bowled',
                                  style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (isLocked && eligibility.reason != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      '⚠️ ${eligibility.reason}',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isLocked)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.lock, size: 10, color: Colors.red.shade700),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Locked',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF059669).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Bowl →',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF059669),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
