import 'package:flutter/material.dart';
import '../../models/models.dart';

class CreaseHudWidget extends StatelessWidget {
  final Innings innings;
  final Player? striker;
  final Player? nonStriker;
  final Player? bowler;
  final BattingScorecard strikerCard;
  final BattingScorecard nonStrikerCard;
  final BowlingScorecard bowlerCard;
  final VoidCallback? onSwapEnds;
  final VoidCallback? onChangeBowler;
  final VoidCallback? onChangeStriker;
  final VoidCallback? onChangeNonStriker;
  final VoidCallback? onChangeOpeningCrease;

  const CreaseHudWidget({
    super.key,
    required this.innings,
    required this.striker,
    required this.nonStriker,
    required this.bowler,
    required this.strikerCard,
    required this.nonStrikerCard,
    required this.bowlerCard,
    this.onSwapEnds,
    this.onChangeBowler,
    this.onChangeStriker,
    this.onChangeNonStriker,
    this.onChangeOpeningCrease,
  });

  String _playerName(Player? p, String fallback) {
    if (p == null) return fallback;
    final fn = p.fullName.trim();
    if (fn.isNotEmpty) return fn;
    final dn = p.displayName.trim();
    if (dn.isNotEmpty) return dn;
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // BATTERS TABLE CONTAINER
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF032219), // Deep cricket green-black
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF064E3B)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'BATTERS AT CREASE',
                    style: TextStyle(
                      color: Color(0xFF34D399),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onChangeOpeningCrease != null)
                        InkWell(
                          onTap: onChangeOpeningCrease,
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF064E3B),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF34D399).withValues(alpha: 0.5)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.edit, size: 11, color: Color(0xFF34D399)),
                                SizedBox(width: 4),
                                Text(
                                  'Change Openers',
                                  style: TextStyle(color: Color(0xFF34D399), fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (onSwapEnds != null)
                        InkWell(
                          onTap: onSwapEnds,
                          borderRadius: BorderRadius.circular(6),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: Row(
                              children: [
                                Icon(Icons.swap_horiz, size: 13, color: Colors.amber),
                                SizedBox(width: 4),
                                Text(
                                  'Swap Ends',
                                  style: TextStyle(
                                    color: Colors.amber,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Table Headers
              const Row(
                children: [
                  Expanded(flex: 5, child: Text('Batter', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text('R (B)', textAlign: TextAlign.right, style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold))),
                  Expanded(flex: 1, child: Text('4s', textAlign: TextAlign.right, style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold))),
                  Expanded(flex: 1, child: Text('6s', textAlign: TextAlign.right, style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text('SR', textAlign: TextAlign.right, style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold))),
                ],
              ),
              const Divider(color: Color(0xFF064E3B), height: 12),

              // STRIKER ROW
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF064E3B).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Row(
                        children: [
                          const Text('★ ', style: TextStyle(color: Colors.amber, fontSize: 12)),
                          Expanded(
                            child: Text(
                              _playerName(striker, 'Striker'),
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('STRIKE', style: TextStyle(color: Colors.amber, fontSize: 8, fontWeight: FontWeight.w900)),
                          ),
                          if (onChangeStriker != null && strikerCard.balls == 0) ...[
                            const SizedBox(width: 4),
                            InkWell(
                              onTap: onChangeStriker,
                              borderRadius: BorderRadius.circular(4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.white12,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text('Change', style: TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: RichText(
                        textAlign: TextAlign.right,
                        text: TextSpan(
                          children: [
                            TextSpan(text: '${strikerCard.runs} ', style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.w900)),
                            TextSpan(text: '(${strikerCard.balls})', style: const TextStyle(color: Colors.white60, fontSize: 10)),
                          ],
                        ),
                      ),
                    ),
                    Expanded(flex: 1, child: Text('${strikerCard.fours}', textAlign: TextAlign.right, style: const TextStyle(color: Colors.white, fontSize: 11))),
                    Expanded(flex: 1, child: Text('${strikerCard.sixes}', textAlign: TextAlign.right, style: const TextStyle(color: Colors.white, fontSize: 11))),
                    Expanded(flex: 2, child: Text(strikerCard.strikeRate.toStringAsFixed(1), textAlign: TextAlign.right, style: const TextStyle(color: Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
              const SizedBox(height: 4),

              // NON-STRIKER ROW
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Row(
                        children: [
                          const Text('• ', style: TextStyle(color: Colors.white30, fontSize: 12)),
                          Expanded(
                            child: Text(
                              _playerName(nonStriker, 'Non-Striker'),
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (onChangeNonStriker != null && nonStrikerCard.balls == 0) ...[
                            const SizedBox(width: 4),
                            InkWell(
                              onTap: onChangeNonStriker,
                              borderRadius: BorderRadius.circular(4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.white12,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text('Change', style: TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: RichText(
                        textAlign: TextAlign.right,
                        text: TextSpan(
                          children: [
                            TextSpan(text: '${nonStrikerCard.runs} ', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            TextSpan(text: '(${nonStrikerCard.balls})', style: const TextStyle(color: Colors.white54, fontSize: 10)),
                          ],
                        ),
                      ),
                    ),
                    Expanded(flex: 1, child: Text('${nonStrikerCard.fours}', textAlign: TextAlign.right, style: const TextStyle(color: Colors.white60, fontSize: 11))),
                    Expanded(flex: 1, child: Text('${nonStrikerCard.sixes}', textAlign: TextAlign.right, style: const TextStyle(color: Colors.white60, fontSize: 11))),
                    Expanded(flex: 2, child: Text(nonStrikerCard.strikeRate.toStringAsFixed(1), textAlign: TextAlign.right, style: const TextStyle(color: Colors.white60, fontSize: 11))),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // ACTIVE BOWLER CONTAINER
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bowler == null ? const Color(0xFF451A03) : const Color(0xFF032219),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: bowler == null ? Colors.amber : const Color(0xFF064E3B)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ACTIVE BOWLER',
                    style: TextStyle(
                      color: Color(0xFF34D399),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  if (onChangeBowler != null)
                    InkWell(
                      onTap: onChangeBowler,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: bowler == null ? Colors.amber : const Color(0xFF064E3B),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Text(
                              bowler == null ? 'Select Bowler' : 'Change',
                              style: TextStyle(
                                color: bowler == null ? Colors.black : Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              size: 12,
                              color: bowler == null ? Colors.black : Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),

              if (bowler != null) ...[
                // Bowler Table Headers
                const Row(
                  children: [
                    Expanded(flex: 5, child: Text('Bowler', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold))),
                    Expanded(flex: 2, child: Text('O', textAlign: TextAlign.right, style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold))),
                    Expanded(flex: 1, child: Text('M', textAlign: TextAlign.right, style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold))),
                    Expanded(flex: 1, child: Text('R', textAlign: TextAlign.right, style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold))),
                    Expanded(flex: 1, child: Text('W', textAlign: TextAlign.right, style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold))),
                    Expanded(flex: 2, child: Text('ECON', textAlign: TextAlign.right, style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold))),
                  ],
                ),
                const Divider(color: Color(0xFF064E3B), height: 10),

                // Bowler Row
                Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _playerName(bowler, 'Bowler'),
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            bowler!.bowlingStyle,
                            style: const TextStyle(color: Colors.white54, fontSize: 9),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Expanded(flex: 2, child: Text(bowlerCard.oversStr, textAlign: TextAlign.right, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
                    Expanded(flex: 1, child: Text('${bowlerCard.maidens}', textAlign: TextAlign.right, style: const TextStyle(color: Colors.white60, fontSize: 11))),
                    Expanded(flex: 1, child: Text('${bowlerCard.runsConceded}', textAlign: TextAlign.right, style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold))),
                    Expanded(flex: 1, child: Text('${bowlerCard.wickets}', textAlign: TextAlign.right, style: const TextStyle(color: Color(0xFF34D399), fontSize: 12, fontWeight: FontWeight.w900))),
                    Expanded(flex: 2, child: Text(bowlerCard.economy.toStringAsFixed(2), textAlign: TextAlign.right, style: const TextStyle(color: Colors.white70, fontSize: 11))),
                  ],
                ),
              ] else ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: Text(
                      '⚠️ Over Complete — Please pick next bowler to resume scoring',
                      style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
