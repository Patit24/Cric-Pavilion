import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/cricket_rules_engine.dart';
import '../../theme/neo_glass_theme.dart';

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
    return NeoGlassDialog(
      glowColor: NeoGlassTheme.neonEmerald,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 14),
              decoration: BoxDecoration(
                gradient: NeoGlassTheme.neonGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  NeoGlassTheme.neoGlowShadow(NeoGlassTheme.neonEmerald, opacity: 0.35),
                ],
              ),
              child: Text(
                'OVER $completedOverNumber COMPLETED',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Select Next Bowler',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ends swap automatically. Same bowler cannot bowl consecutive overs (ICC Law 17.8).',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, color: Colors.white60),
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
                      color: isLocked
                          ? const Color(0x221E293B)
                          : const Color(0x3310B981),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isLocked
                            ? Colors.white12
                            : NeoGlassTheme.neonEmerald.withValues(alpha: 0.6),
                        width: isLocked ? 1 : 1.4,
                      ),
                      boxShadow: [
                        NeoGlassTheme.neoDarkShadow,
                        if (!isLocked)
                          NeoGlassTheme.neoGlowShadow(NeoGlassTheme.neonEmerald, opacity: 0.15),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isLocked ? Colors.white24 : NeoGlassTheme.neonEmerald,
                              width: 1.5,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 18,
                            backgroundImage: NetworkImage(p.photoUrl),
                            backgroundColor: const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.fullName.isNotEmpty ? p.fullName : p.displayName,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isLocked ? Colors.white54 : Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${p.bowlingStyle} • ${eligibility.oversStr} ov bowled',
                                style: const TextStyle(fontSize: 10.5, color: Colors.white60),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (isLocked && eligibility.reason != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 3),
                                  child: Text(
                                    '⚠️ ${eligibility.reason}',
                                    style: const TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFF87171),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isLocked)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0x33EF4444),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0x66EF4444)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.lock, size: 11, color: Color(0xFFF87171)),
                                SizedBox(width: 4),
                                Text(
                                  'Locked',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFF87171),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              gradient: NeoGlassTheme.neonGradient,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                NeoGlassTheme.neoGlowShadow(NeoGlassTheme.neonEmerald, opacity: 0.3),
                              ],
                            ),
                            child: const Text(
                              'Bowl →',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
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
    );
  }
}
