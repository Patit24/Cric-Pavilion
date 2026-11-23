import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../theme/neo_glass_theme.dart';

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
      decoration: BoxDecoration(
        color: const Color(0xF50B1120),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: NeoGlassTheme.glassBorder, width: 1.2),
        boxShadow: [
          NeoGlassTheme.neoDarkShadow,
          NeoGlassTheme.neoLightHighlight,
        ],
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
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
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
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        color: NeoGlassTheme.neonEmerald,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.match.stage,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: NeoGlassTheme.neonEmerald.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: NeoGlassTheme.neonEmerald.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    '${widget.match.overs} Overs T20',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: NeoGlassTheme.neonEmerald,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white12, height: 24),

            if (currentStep == 1) ...[
              // STEP 1: COIN TOSS
              const Text(
                '1. Which team won the coin toss?',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 10),
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
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: tossWonById == widget.teamA.id
                              ? const LinearGradient(
                                  colors: [Color(0x3300F5A0), Color(0x1100D9F5)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: tossWonById == widget.teamA.id ? null : const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: tossWonById == widget.teamA.id
                                ? NeoGlassTheme.neonEmerald
                                : Colors.white12,
                            width: tossWonById == widget.teamA.id ? 2 : 1,
                          ),
                          boxShadow: [
                            NeoGlassTheme.neoDarkShadow,
                            if (tossWonById == widget.teamA.id)
                              NeoGlassTheme.neoGlowShadow(NeoGlassTheme.neonEmerald, opacity: 0.25),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              widget.teamA.shortName,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: tossWonById == widget.teamA.id
                                    ? NeoGlassTheme.neonEmerald
                                    : Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.teamA.name,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: tossWonById == widget.teamA.id ? Colors.white : Colors.white70,
                              ),
                            ),
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
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: tossWonById == widget.teamB.id
                              ? const LinearGradient(
                                  colors: [Color(0x3300D9F5), Color(0x1100F5A0)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: tossWonById == widget.teamB.id ? null : const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: tossWonById == widget.teamB.id
                                ? NeoGlassTheme.neonCyan
                                : Colors.white12,
                            width: tossWonById == widget.teamB.id ? 2 : 1,
                          ),
                          boxShadow: [
                            NeoGlassTheme.neoDarkShadow,
                            if (tossWonById == widget.teamB.id)
                              NeoGlassTheme.neoGlowShadow(NeoGlassTheme.neonCyan, opacity: 0.25),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              widget.teamB.shortName,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: tossWonById == widget.teamB.id
                                    ? NeoGlassTheme.neonCyan
                                    : Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.teamB.name,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: tossWonById == widget.teamB.id ? Colors.white : Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              const Text(
                '2. What did they elect to do?',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
              ),
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
                      selectedColor: NeoGlassTheme.neonEmerald,
                      backgroundColor: const Color(0xFF0F172A),
                      labelStyle: TextStyle(
                        color: tossDecision == 'bat' ? Colors.black : Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
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
                      selectedColor: NeoGlassTheme.neonCyan,
                      backgroundColor: const Color(0xFF0F172A),
                      labelStyle: TextStyle(
                        color: tossDecision == 'bowl' ? Colors.black : Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
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

              NeoGlassButton(
                onPressed: () {
                  setState(() => currentStep = 2);
                },
                gradient: NeoGlassTheme.neonGradient,
                child: const Text(
                  'Next: Choose Opening Crease →',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                ),
              ),
            ] else ...[
              // STEP 2: OPENING CREASE LINEUP (STRIKER, NON-STRIKER & BOWLER)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0x3300F5A0), Color(0x180B1120)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: NeoGlassTheme.neonEmerald.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.sports_cricket, color: NeoGlassTheme.neonEmerald, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Batting First: ${battingTeam.name}',
                            style: const TextStyle(color: NeoGlassTheme.neonEmerald, fontSize: 12.5, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Bowling First: ${bowlingTeam.name}',
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // STRIKER SELECTION CARD
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.5), width: 1.5),
                  boxShadow: [NeoGlassTheme.neoDarkShadow],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Text('★', style: TextStyle(color: Colors.amber, fontSize: 14, fontWeight: FontWeight.bold)),
                        SizedBox(width: 6),
                        Text(
                          '1. Opening Striker (* Facing Ball 0.1)',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                        Spacer(),
                        Text(
                          'ON STRIKE',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.amberAccent),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'This batsman will face the very first ball of the match.',
                      style: TextStyle(fontSize: 10.5, color: Colors.white60),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: strikerId,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF1E293B),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        filled: true,
                        fillColor: const Color(0xFF1E293B),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white24)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white24)),
                      ),
                      items: battingPlayers.map((p) {
                        final isSelected = p.id == strikerId;
                        return DropdownMenuItem(
                          value: p.id,
                          child: Row(
                            children: [
                              Text(
                                p.fullName.isNotEmpty ? p.fullName : p.displayName,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white12,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  p.battingStyle,
                                  style: const TextStyle(fontSize: 9.5, color: Colors.white70),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => strikerId = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // NON-STRIKER SELECTION CARD
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white24),
                  boxShadow: [NeoGlassTheme.neoDarkShadow],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Text('•', style: TextStyle(color: NeoGlassTheme.neonEmerald, fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(width: 6),
                        Text(
                          '2. Opening Non-Striker (Runner at Crease)',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                        Spacer(),
                        Text(
                          'BOWLER END',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white60),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Partner batsman standing at the non-striker bowling end.',
                      style: TextStyle(fontSize: 10.5, color: Colors.white60),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: nonStrikerId,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF1E293B),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        filled: true,
                        fillColor: const Color(0xFF1E293B),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white24)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white24)),
                      ),
                      items: battingPlayers.map((p) {
                        final isSelected = p.id == nonStrikerId;
                        return DropdownMenuItem(
                          value: p.id,
                          child: Row(
                            children: [
                              Text(
                                p.fullName.isNotEmpty ? p.fullName : p.displayName,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white12,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  p.battingStyle,
                                  style: const TextStyle(fontSize: 9.5, color: Colors.white70),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => nonStrikerId = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // STRIKER VS NON-STRIKER DUPLICATE WARNING
              if (strikerId != null && nonStrikerId != null && strikerId == nonStrikerId) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade900.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.redAccent),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.error_outline, size: 16, color: Colors.redAccent),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Striker and Non-Striker cannot be the same player. Please select two different opening batsmen.',
                          style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // OPENING BOWLER SELECTION CARD
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: NeoGlassTheme.neonEmerald.withValues(alpha: 0.6)),
                  boxShadow: [NeoGlassTheme.neoDarkShadow],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.sports_baseball, color: NeoGlassTheme.neonEmerald, size: 16),
                        const SizedBox(width: 6),
                        const Text(
                          '3. Opening Bowler (Over 1)',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                        const Spacer(),
                        Text(
                          bowlingTeam.shortName,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: bowlingTeam.primaryColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Will bowl the first over of the match for ${bowlingTeam.name}.',
                      style: const TextStyle(fontSize: 10.5, color: Colors.white60),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: bowlerId,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF1E293B),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        filled: true,
                        fillColor: const Color(0xFF1E293B),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white24)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white24)),
                      ),
                      items: bowlingPlayers.map((p) {
                        final isSelected = p.id == bowlerId;
                        return DropdownMenuItem(
                          value: p.id,
                          child: Row(
                            children: [
                              Text(
                                p.fullName.isNotEmpty ? p.fullName : p.displayName,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white12,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  p.bowlingStyle,
                                  style: const TextStyle(fontSize: 9.5, color: Colors.white70),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => bowlerId = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // LIVE OPENING MATCHUP SUMMARY BANNER
              Builder(builder: (ctx) {
                final strikerP = battingPlayers.where((p) => p.id == strikerId).firstOrNull;
                final nonStrikerP = battingPlayers.where((p) => p.id == nonStrikerId).firstOrNull;
                final bowlerP = bowlingPlayers.where((p) => p.id == bowlerId).firstOrNull;

                if (strikerP != null && bowlerP != null) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0x3300F5A0), Color(0x1100D9F5)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: NeoGlassTheme.neonEmerald),
                      boxShadow: [
                        NeoGlassTheme.neoDarkShadow,
                        NeoGlassTheme.neoGlowShadow(NeoGlassTheme.neonEmerald, opacity: 0.15),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'OPENING CREASE LINEUP PREVIEW',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: NeoGlassTheme.neonEmerald, fontSize: 9.5, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text('★ ', style: TextStyle(color: Colors.amber, fontSize: 11)),
                                      Expanded(
                                        child: Text(
                                          strikerP.fullName.isNotEmpty ? strikerP.fullName : strikerP.displayName,
                                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (nonStrikerP != null) ...[
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Text('• ', style: TextStyle(color: Colors.white54, fontSize: 11)),
                                        Expanded(
                                          child: Text(
                                            nonStrikerP.fullName.isNotEmpty ? nonStrikerP.fullName : nonStrikerP.displayName,
                                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF064E3B),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('vs', style: TextStyle(color: NeoGlassTheme.neonEmerald, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      const Icon(Icons.sports_baseball, color: NeoGlassTheme.neonEmerald, size: 12),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          bowlerP.fullName.isNotEmpty ? bowlerP.fullName : bowlerP.displayName,
                                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${bowlingTeam.name} (Over 1)',
                                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
              const SizedBox(height: 20),

              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => setState(() => currentStep = 1),
                    icon: const Icon(Icons.arrow_back, size: 14, color: Colors.white70),
                    label: const Text('Toss', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                  ),
                  const Spacer(),
                  NeoGlassButton(
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
                    gradient: NeoGlassTheme.neonGradient,
                    child: const Text(
                      'Confirm Lineup & Start Match (0.1) 🚀',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5),
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
