import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../theme/neo_glass_theme.dart';

/// Modal dialog for retiring a batter mid-innings (Retired Hurt / Injured or Retired Out).
/// In cricket, retiring a batter does NOT count as a delivery/ball bowled!
class RetireBatterDialog extends StatefulWidget {
  final Player striker;
  final Player nonStriker;
  final List<Player> availableDugout;
  final Function({
    required String retiringPlayerId,
    required bool isHurt,
    required String replacementPlayerId,
  }) onConfirmRetire;

  const RetireBatterDialog({
    super.key,
    required this.striker,
    required this.nonStriker,
    required this.availableDugout,
    required this.onConfirmRetire,
  });

  static void show(
    BuildContext context, {
    required Player striker,
    required Player nonStriker,
    required List<Player> availableDugout,
    required Function({
      required String retiringPlayerId,
      required bool isHurt,
      required String replacementPlayerId,
    }) onConfirmRetire,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => RetireBatterDialog(
        striker: striker,
        nonStriker: nonStriker,
        availableDugout: availableDugout,
        onConfirmRetire: onConfirmRetire,
      ),
    );
  }

  @override
  State<RetireBatterDialog> createState() => _RetireBatterDialogState();
}

class _RetireBatterDialogState extends State<RetireBatterDialog> {
  late String _retiringPlayerId;
  bool _isHurt = true; // true = Retired Hurt (Injured), false = Retired Out
  String? _replacementPlayerId;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _retiringPlayerId = widget.striker.id;
    if (widget.availableDugout.isNotEmpty) {
      _replacementPlayerId = widget.availableDugout.first.id;
    }
  }

  String _name(Player p) {
    if (p.fullName.trim().isNotEmpty) return p.fullName.trim();
    if (p.displayName.trim().isNotEmpty) return p.displayName.trim();
    return 'Batter';
  }

  void _confirm() {
    if (_replacementPlayerId == null) {
      setState(() => _errorMessage = 'No replacement batter available in dugout.');
      return;
    }

    Navigator.of(context).pop();
    widget.onConfirmRetire(
      retiringPlayerId: _retiringPlayerId,
      isHurt: _isHurt,
      replacementPlayerId: _replacementPlayerId!,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0x3300F5A0), width: 1.2),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: SingleChildScrollView(
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
                        color: Colors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.healing, color: Colors.amber, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'RETIRE BATTER',
                            style: TextStyle(color: GlassTokens.inkPrimary, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.8),
                          ),
                          Text(
                            'Change injured / retiring batsman without counting a ball',
                            style: TextStyle(color: GlassTokens.inkSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: GlassTokens.inkSecondary, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Error
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.redAccent),
                    ),
                    child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 11)),
                  ),
                  const SizedBox(height: 12),
                ],

                // 1. Select Retiring Batter
                const Text('1. Which batter is retiring?', style: TextStyle(color: GlassTokens.inkSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: Text('★ ${_name(widget.striker)} (Striker)'),
                        selected: _retiringPlayerId == widget.striker.id,
                        selectedColor: const Color(0xFF00F5A0),
                        labelStyle: TextStyle(
                          color: _retiringPlayerId == widget.striker.id ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11.5,
                        ),
                        backgroundColor: GlassTokens.bgLightBlue,
                        onSelected: (val) {
                          if (val) setState(() => _retiringPlayerId = widget.striker.id);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: Text('${_name(widget.nonStriker)} (Non-Striker)'),
                        selected: _retiringPlayerId == widget.nonStriker.id,
                        selectedColor: const Color(0xFF00F5A0),
                        labelStyle: TextStyle(
                          color: _retiringPlayerId == widget.nonStriker.id ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11.5,
                        ),
                        backgroundColor: GlassTokens.bgLightBlue,
                        onSelected: (val) {
                          if (val) setState(() => _retiringPlayerId = widget.nonStriker.id);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 2. Select Reason (Retired Hurt vs Retired Out)
                const Text('2. Retirement Condition:', style: TextStyle(color: GlassTokens.inkSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _isHurt = true),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _isHurt ? const Color(0xFF009270).withValues(alpha: 0.25) : GlassTokens.bgLightBlue,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _isHurt ? const Color(0xFF00F5A0) : GlassTokens.glassHairline, width: _isHurt ? 1.5 : 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.healing, color: _isHurt ? const Color(0xFF00F5A0) : GlassTokens.inkSecondary, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Retired Hurt',
                                    style: TextStyle(
                                      color: _isHurt ? const Color(0xFF00F5A0) : Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              const Text('Injured / ill (Not Out). Wicket is NOT incremented.', style: TextStyle(color: GlassTokens.inkSecondary, fontSize: 10)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _isHurt = false),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: !_isHurt ? Colors.redAccent.withValues(alpha: 0.25) : GlassTokens.bgLightBlue,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: !_isHurt ? Colors.redAccent : GlassTokens.glassHairline, width: !_isHurt ? 1.5 : 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.exit_to_app, color: !_isHurt ? Colors.redAccent : GlassTokens.inkSecondary, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Retired Out',
                                    style: TextStyle(
                                      color: !_isHurt ? Colors.redAccent : Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              const Text('Voluntary exit. Counts as dismissal/wicket.', style: TextStyle(color: GlassTokens.inkSecondary, fontSize: 10)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 3. Select Replacement Batter from Dugout
                Text(
                  '3. Incoming Replacement Batter (${widget.availableDugout.length} in dugout):',
                  style: const TextStyle(color: GlassTokens.inkSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (widget.availableDugout.isEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                    child: const Text('No remaining batsmen in squad to replace!', style: TextStyle(color: Colors.redAccent, fontSize: 11)),
                  ),
                ] else ...[
                  DropdownButtonFormField<String>(
                    value: _replacementPlayerId,
                    items: widget.availableDugout.map((p) {
                      return DropdownMenuItem<String>(
                        value: p.id,
                        child: Text(
                          '${_name(p)} (${p.roleString})',
                          style: const TextStyle(color: GlassTokens.inkPrimary, fontSize: 12.5),
                        ),
                      );
                    }).toList(),
                    onChanged: (id) => setState(() {
                      _replacementPlayerId = id;
                      _errorMessage = null;
                    }),
                    dropdownColor: Colors.white,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: GlassTokens.bgLightBlue,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    ),
                  ),
                ],
                const SizedBox(height: 18),

                // Ball Not Counted Notice
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.lightBlueAccent, size: 14),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Per cricket rules, retirement happens between balls — no extra delivery or legal ball is consumed.',
                          style: TextStyle(color: GlassTokens.inkSecondary, fontSize: 10.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Action Button
                ElevatedButton(
                  onPressed: widget.availableDugout.isEmpty ? null : _confirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00F5A0),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    _isHurt ? 'Confirm Retired Hurt & Swap Batter 🏥' : 'Confirm Retired Out & Swap Batter 🚪',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
