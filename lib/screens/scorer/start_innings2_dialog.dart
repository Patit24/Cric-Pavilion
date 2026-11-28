import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../theme/neo_glass_theme.dart';

/// Modal dialog presented when Innings 1 concludes, prompting the scorer
/// to select the Opening Striker, Non-Striker, and Opening Bowler for Innings 2.
class StartInnings2Dialog extends StatefulWidget {
  final MatchModel match;
  final Innings inn1;
  final Team chasingTeam;
  final Team defendingTeam;
  final List<Player> chasingPlayers;
  final List<Player> defendingPlayers;
  final Function({
    required String strikerId,
    required String nonStrikerId,
    required String bowlerId,
  }) onConfirmLineup;

  const StartInnings2Dialog({
    super.key,
    required this.match,
    required this.inn1,
    required this.chasingTeam,
    required this.defendingTeam,
    required this.chasingPlayers,
    required this.defendingPlayers,
    required this.onConfirmLineup,
  });

  @override
  State<StartInnings2Dialog> createState() => _StartInnings2DialogState();
}

class _StartInnings2DialogState extends State<StartInnings2Dialog> {
  String? _selectedStrikerId;
  String? _selectedNonStrikerId;
  String? _selectedBowlerId;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.chasingPlayers.isNotEmpty) {
      _selectedStrikerId = widget.chasingPlayers.first.id;
      if (widget.chasingPlayers.length > 1) {
        _selectedNonStrikerId = widget.chasingPlayers[1].id;
      } else {
        _selectedNonStrikerId = widget.chasingPlayers.first.id;
      }
    }
    if (widget.defendingPlayers.isNotEmpty) {
      final bowler = widget.defendingPlayers.firstWhere(
        (p) => p.role == PlayerRole.bowler,
        orElse: () => widget.defendingPlayers.first,
      );
      _selectedBowlerId = bowler.id;
    }
  }

  String _name(Player p) {
    if (p.fullName.trim().isNotEmpty) return p.fullName.trim();
    if (p.displayName.trim().isNotEmpty) return p.displayName.trim();
    return 'Player';
  }

  void _confirm() {
    if (_selectedStrikerId == null || _selectedNonStrikerId == null) {
      setState(() => _errorMessage = 'Please select both opening batsmen.');
      return;
    }
    if (widget.chasingPlayers.length > 1 && _selectedStrikerId == _selectedNonStrikerId) {
      setState(() => _errorMessage = 'Striker and Non-Striker must be two different players.');
      return;
    }
    if (_selectedBowlerId == null) {
      setState(() => _errorMessage = 'Please select the opening bowler.');
      return;
    }

    Navigator.of(context).pop();
    widget.onConfirmLineup(
      strikerId: _selectedStrikerId!,
      nonStrikerId: _selectedNonStrikerId!,
      bowlerId: _selectedBowlerId!,
    );
  }

  @override
  Widget build(BuildContext context) {
    final targetRuns = widget.inn1.totalRuns + 1;
    final rrr = widget.match.overs > 0 ? (targetRuns / widget.match.overs).toStringAsFixed(1) : '0.0';

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0x4400F5A0), width: 1.5),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
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
                      color: const Color(0xFF00F5A0).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.sports_cricket, color: Color(0xFF00F5A0), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'INNINGS 1 CONCLUDED 🏁',
                          style: TextStyle(color: Color(0xFF00F5A0), fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                        ),
                        Text(
                          'Set 2nd Innings Crease Lineup (${widget.chasingTeam.name} Chase)',
                          style: const TextStyle(color: GlassTokens.inkSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Target Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [GlassTokens.bgLightBlue, Color(0xFF1E3A5F)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.defendingTeam.name}: ${widget.inn1.totalRuns}/${widget.inn1.wickets} (${widget.inn1.oversStr} ov)',
                          style: const TextStyle(color: GlassTokens.inkSecondary, fontSize: 11),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'TARGET: $targetRuns RUNS',
                          style: const TextStyle(color: Color(0xFFD97706), fontSize: 15, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Req RR: $rrr',
                        style: const TextStyle(color: GlassTokens.inkPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Error display
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.redAccent),
                  ),
                  child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 10),
              ],

              // Scrollable Pickers
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Opening Striker
                      _buildPlayerSelector(
                        title: '1. Opening Striker (${widget.chasingTeam.name}) ★',
                        icon: Icons.star,
                        iconColor: Colors.amber,
                        players: widget.chasingPlayers,
                        selectedId: _selectedStrikerId,
                        onChanged: (id) => setState(() {
                          _selectedStrikerId = id;
                          _errorMessage = null;
                        }),
                      ),
                      const SizedBox(height: 14),

                      // 2. Opening Non-Striker
                      _buildPlayerSelector(
                        title: '2. Opening Non-Striker (${widget.chasingTeam.name})',
                        icon: Icons.person_outline,
                        iconColor: const Color(0xFF00F5A0),
                        players: widget.chasingPlayers,
                        selectedId: _selectedNonStrikerId,
                        onChanged: (id) => setState(() {
                          _selectedNonStrikerId = id;
                          _errorMessage = null;
                        }),
                      ),
                      const SizedBox(height: 14),

                      // 3. Opening Bowler
                      _buildPlayerSelector(
                        title: '3. Opening Bowler (${widget.defendingTeam.name}) ⚡',
                        icon: Icons.sports_baseball,
                        iconColor: Colors.lightBlueAccent,
                        players: widget.defendingPlayers,
                        selectedId: _selectedBowlerId,
                        onChanged: (id) => setState(() {
                          _selectedBowlerId = id;
                          _errorMessage = null;
                        }),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: GlassTokens.glassHairline),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Cancel / Later', style: TextStyle(color: GlassTokens.inkSecondary, fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _confirm,
                      icon: const Icon(Icons.flash_on, color: Colors.black, size: 18),
                      label: const Text(
                        'Start 2nd Innings Scoring ⚡',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00F5A0),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerSelector({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Player> players,
    required String? selectedId,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GlassTokens.bgLightBlue,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GlassTokens.glassHairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 6),
              Text(title, style: TextStyle(color: iconColor, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: selectedId,
            items: players.map((p) {
              return DropdownMenuItem<String>(
                value: p.id,
                child: Text(
                  '${_name(p)} (${p.roleString})',
                  style: const TextStyle(color: GlassTokens.inkPrimary, fontSize: 12.5),
                ),
              );
            }).toList(),
            onChanged: onChanged,
            dropdownColor: Colors.white,
            decoration: InputDecoration(
              filled: true,
              fillColor: GlassTokens.bgIcyWhite,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }
}
