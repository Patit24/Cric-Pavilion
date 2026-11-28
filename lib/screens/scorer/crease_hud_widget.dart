import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../theme/neo_glass_theme.dart';

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
        // BATTERS TABLE CONTAINER (Neo-Glass Card with Tactile Shadows)
        NeoGlassCard(
          padding: const EdgeInsets.all(12),
          borderRadius: 18,
          borderColor: NeoGlassTheme.glassBorder,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 12,
                        decoration: BoxDecoration(
                          color: NeoGlassTheme.neonEmerald,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'BATTERS AT CREASE',
                        style: TextStyle(
                          color: NeoGlassTheme.neonEmerald,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
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
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: const Color(0x3300F5A0),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: NeoGlassTheme.neonEmerald.withValues(alpha: 0.5)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.edit, size: 11, color: NeoGlassTheme.neonEmerald),
                                SizedBox(width: 4),
                                Text(
                                  'Change Openers',
                                  style: TextStyle(color: NeoGlassTheme.neonEmerald, fontSize: 10, fontWeight: FontWeight.bold),
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
                                Icon(Icons.swap_horiz, size: 14, color: Colors.amber),
                                SizedBox(width: 4),
                                Text(
                                  'Swap Ends',
                                  style: TextStyle(
                                    color: Colors.amber,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
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
                  Expanded(flex: 8, child: Text('Batter', style: TextStyle(color: GlassTokens.inkSecondary, fontSize: 10, fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text('R (B)', textAlign: TextAlign.right, style: TextStyle(color: GlassTokens.inkSecondary, fontSize: 10, fontWeight: FontWeight.bold))),
                  Expanded(flex: 1, child: Text('4s', textAlign: TextAlign.right, style: TextStyle(color: GlassTokens.inkSecondary, fontSize: 10, fontWeight: FontWeight.bold))),
                  Expanded(flex: 1, child: Text('6s', textAlign: TextAlign.right, style: TextStyle(color: GlassTokens.inkSecondary, fontSize: 10, fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text('SR', textAlign: TextAlign.right, style: TextStyle(color: GlassTokens.inkSecondary, fontSize: 10, fontWeight: FontWeight.bold))),
                ],
              ),
              const Divider(color: GlassTokens.glassHairline, height: 12),

              // STRIKER ROW
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0x3300F5A0), Color(0x1100D9F5)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: NeoGlassTheme.neonEmerald.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 8,
                      child: Row(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.amber.withValues(alpha: 0.6)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('★', style: TextStyle(color: Colors.amber, fontSize: 9, fontWeight: FontWeight.w900)),
                                SizedBox(width: 2),
                                Text('STRIKE', style: TextStyle(color: Colors.amber, fontSize: 8, fontWeight: FontWeight.w900)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Text(
                              _playerName(striker, 'Striker'),
                              style: const TextStyle(color: GlassTokens.inkPrimary, fontSize: 12.5, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
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
                            TextSpan(text: '(${strikerCard.balls})', style: const TextStyle(color: GlassTokens.inkSecondary, fontSize: 10)),
                          ],
                        ),
                      ),
                    ),
                    Expanded(flex: 1, child: Text('${strikerCard.fours}', textAlign: TextAlign.right, style: const TextStyle(color: GlassTokens.inkPrimary, fontSize: 11))),
                    Expanded(flex: 1, child: Text('${strikerCard.sixes}', textAlign: TextAlign.right, style: const TextStyle(color: GlassTokens.inkPrimary, fontSize: 11))),
                    Expanded(flex: 2, child: Text(strikerCard.strikeRate.toStringAsFixed(1), textAlign: TextAlign.right, style: const TextStyle(color: NeoGlassTheme.neonEmerald, fontSize: 11, fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
              const SizedBox(height: 4),

              // NON-STRIKER ROW
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 8,
                      child: Row(
                        children: [
                          const Text('• ', style: TextStyle(color: GlassTokens.inkMuted, fontSize: 13, fontWeight: FontWeight.bold)),
                          Expanded(
                            child: Text(
                              _playerName(nonStriker, 'Non-Striker'),
                              style: const TextStyle(color: GlassTokens.inkSecondary, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: RichText(
                        textAlign: TextAlign.right,
                        text: TextSpan(
                          children: [
                            TextSpan(text: '${nonStrikerCard.runs} ', style: const TextStyle(color: GlassTokens.inkPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                            TextSpan(text: '(${nonStrikerCard.balls})', style: const TextStyle(color: GlassTokens.inkSecondary, fontSize: 10)),
                          ],
                        ),
                      ),
                    ),
                    Expanded(flex: 1, child: Text('${nonStrikerCard.fours}', textAlign: TextAlign.right, style: const TextStyle(color: GlassTokens.inkSecondary, fontSize: 11))),
                    Expanded(flex: 1, child: Text('${nonStrikerCard.sixes}', textAlign: TextAlign.right, style: const TextStyle(color: GlassTokens.inkSecondary, fontSize: 11))),
                    Expanded(flex: 2, child: Text(nonStrikerCard.strikeRate.toStringAsFixed(1), textAlign: TextAlign.right, style: const TextStyle(color: GlassTokens.inkSecondary, fontSize: 11))),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // ACTIVE BOWLER CONTAINER (Neo-Glass Tactile Card)
        NeoGlassCard(
          padding: const EdgeInsets.all(12),
          borderRadius: 18,
          borderColor: bowler == null ? Colors.amber.withValues(alpha: 0.6) : NeoGlassTheme.glassBorder,
          glowColor: bowler == null ? Colors.amber : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: NeoGlassTheme.neonCyan,
                          borderRadius: BorderRadius.all(Radius.circular(2)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'ACTIVE BOWLER',
                        style: TextStyle(
                          color: NeoGlassTheme.neonCyan,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  if (onChangeBowler != null)
                    InkWell(
                      onTap: onChangeBowler,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          gradient: bowler == null ? NeoGlassTheme.amberGoldGradient : null,
                          color: bowler == null ? null : GlassTokens.bgLightBlue,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: bowler == null ? Colors.transparent : GlassTokens.glassHairline,
                          ),
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
                    Expanded(flex: 8, child: Text('Bowler', style: TextStyle(color: GlassTokens.inkSecondary, fontSize: 10, fontWeight: FontWeight.bold))),
                    Expanded(flex: 2, child: Text('O', textAlign: TextAlign.right, style: TextStyle(color: GlassTokens.inkSecondary, fontSize: 10, fontWeight: FontWeight.bold))),
                    Expanded(flex: 1, child: Text('M', textAlign: TextAlign.right, style: TextStyle(color: GlassTokens.inkSecondary, fontSize: 10, fontWeight: FontWeight.bold))),
                    Expanded(flex: 1, child: Text('R', textAlign: TextAlign.right, style: TextStyle(color: GlassTokens.inkSecondary, fontSize: 10, fontWeight: FontWeight.bold))),
                    Expanded(flex: 1, child: Text('W', textAlign: TextAlign.right, style: TextStyle(color: GlassTokens.inkSecondary, fontSize: 10, fontWeight: FontWeight.bold))),
                    Expanded(flex: 2, child: Text('ECON', textAlign: TextAlign.right, style: TextStyle(color: GlassTokens.inkSecondary, fontSize: 10, fontWeight: FontWeight.bold))),
                  ],
                ),
                const Divider(color: GlassTokens.glassHairline, height: 10),

                // Bowler Row
                Row(
                  children: [
                    Expanded(
                      flex: 8,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _playerName(bowler, 'Bowler'),
                            style: const TextStyle(color: GlassTokens.inkPrimary, fontSize: 12.5, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            bowler!.bowlingStyle,
                            style: const TextStyle(color: GlassTokens.inkSecondary, fontSize: 9.5),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Expanded(flex: 2, child: Text(bowlerCard.oversStr, textAlign: TextAlign.right, style: const TextStyle(color: GlassTokens.inkPrimary, fontSize: 12, fontWeight: FontWeight.bold))),
                    Expanded(flex: 1, child: Text('${bowlerCard.maidens}', textAlign: TextAlign.right, style: const TextStyle(color: GlassTokens.inkSecondary, fontSize: 11))),
                    Expanded(flex: 1, child: Text('${bowlerCard.runsConceded}', textAlign: TextAlign.right, style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold))),
                    Expanded(flex: 1, child: Text('${bowlerCard.wickets}', textAlign: TextAlign.right, style: const TextStyle(color: NeoGlassTheme.neonEmerald, fontSize: 12, fontWeight: FontWeight.w900))),
                    Expanded(flex: 2, child: Text(bowlerCard.economy.toStringAsFixed(2), textAlign: TextAlign.right, style: const TextStyle(color: GlassTokens.inkSecondary, fontSize: 11))),
                  ],
                ),
              ] else ...[
                InkWell(
                  onTap: onChangeBowler,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.touch_app, size: 16, color: Color(0xFFD97706)),
                        SizedBox(width: 8),
                        Text(
                          'Over Complete — Tap here to Select Next Bowler',
                          style: TextStyle(color: Color(0xFFD97706), fontSize: 11.5, fontWeight: FontWeight.bold),
                        ),
                      ],
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
