import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../theme/neo_glass_theme.dart';

/// Interactive modal sheet allowing the scorer to record No-Balls with batsman runs,
/// Wide balls with additional runs, Byes, and Leg-Byes with exact run attribution.
class ExtrasScoringSheet extends StatefulWidget {
  final Innings innings;
  final Player? striker;
  final Player? nonStriker;
  final Player? bowler;
  final Function({
    required ExtrasType extrasType,
    required int extrasRuns,
    required int runsBatter,
  }) onConfirmExtras;

  const ExtrasScoringSheet({
    super.key,
    required this.innings,
    this.striker,
    this.nonStriker,
    this.bowler,
    required this.onConfirmExtras,
  });

  static void show(
    BuildContext context, {
    required Innings innings,
    Player? striker,
    Player? nonStriker,
    Player? bowler,
    required Function({
      required ExtrasType extrasType,
      required int extrasRuns,
      required int runsBatter,
    }) onConfirmExtras,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ExtrasScoringSheet(
        innings: innings,
        striker: striker,
        nonStriker: nonStriker,
        bowler: bowler,
        onConfirmExtras: onConfirmExtras,
      ),
    );
  }

  @override
  State<ExtrasScoringSheet> createState() => _ExtrasScoringSheetState();
}

class _ExtrasScoringSheetState extends State<ExtrasScoringSheet> {
  ExtrasType _selectedType = ExtrasType.noBall;
  int _batRuns = 0; // Runs off the bat for No-Ball
  int _additionalRanRuns = 0; // Extra runs ran for Wide (0, 1, 2, 3, 4)
  int _byeRuns = 1; // 1, 2, 3, 4 for Bye / Leg-Bye

  @override
  Widget build(BuildContext context) {
    final strikerName = widget.striker?.fullName.isNotEmpty == true ? widget.striker!.fullName : 'Striker';

    int totalRuns = 0;
    int calculatedExtrasRuns = 0;
    int calculatedBatRuns = 0;
    String breakdownText = '';

    switch (_selectedType) {
      case ExtrasType.noBall:
        calculatedExtrasRuns = 1;
        calculatedBatRuns = _batRuns;
        totalRuns = 1 + _batRuns;
        breakdownText = _batRuns > 0
            ? '1 NB (Extra) + $_batRuns Off Bat ($strikerName) = $totalRuns Runs Total • Free Hit Awarded'
            : '1 NB (Extra) • Free Hit Awarded • 0 Runs off bat';
        break;
      case ExtrasType.wide:
        calculatedExtrasRuns = 1 + _additionalRanRuns;
        calculatedBatRuns = 0;
        totalRuns = calculatedExtrasRuns;
        breakdownText = _additionalRanRuns > 0
            ? '1 Wide Penalty + $_additionalRanRuns Additional = $totalRuns Wides Total'
            : '1 Wide Penalty (Not a legal delivery)';
        break;
      case ExtrasType.bye:
        calculatedExtrasRuns = _byeRuns;
        calculatedBatRuns = 0;
        totalRuns = _byeRuns;
        breakdownText = '$_byeRuns Bye(s) • Legal Delivery • Not charged to bowler';
        break;
      case ExtrasType.legBye:
        calculatedExtrasRuns = _byeRuns;
        calculatedBatRuns = 0;
        totalRuns = _byeRuns;
        breakdownText = '$_byeRuns Leg-Bye(s) • Legal Delivery • Not charged to bowler';
        break;
      case ExtrasType.penalty:
        calculatedExtrasRuns = 5;
        calculatedBatRuns = 0;
        totalRuns = 5;
        breakdownText = '5 Penalty Runs awarded to batting team';
        break;
      default:
        break;
    }

    return Container(
      padding: EdgeInsets.only(
        top: 18,
        left: 18,
        right: 18,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: GlassTokens.inkPrimary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Color(0xFF00F5A0), width: 1.5)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: GlassTokens.glassHairline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Header Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.flash_on, color: Colors.amber, size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RECORD EXTRAS & BATSMAN RUNS',
                        style: TextStyle(color: GlassTokens.inkPrimary, fontWeight: FontWeight.w900, fontSize: 13.5, letterSpacing: 0.8),
                      ),
                      Text(
                        'Select extra type and any runs scored off the delivery',
                        style: TextStyle(color: GlassTokens.inkSecondary, fontSize: 10.5),
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

            // Extra Type Selector Tabs
            Row(
              children: [
                _buildTypeTab(ExtrasType.noBall, 'No-Ball (NB)', Colors.redAccent),
                const SizedBox(width: 6),
                _buildTypeTab(ExtrasType.wide, 'Wide (WD)', Colors.amber),
                const SizedBox(width: 6),
                _buildTypeTab(ExtrasType.bye, 'Bye (B)', Colors.blueAccent),
                const SizedBox(width: 6),
                _buildTypeTab(ExtrasType.legBye, 'Leg-Bye (LB)', const Color(0xFF00F5A0)),
              ],
            ),
            const SizedBox(height: 16),

            // Sub-Selection based on type
            if (_selectedType == ExtrasType.noBall) ...[
              // No-Ball Options
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: GlassTokens.bgLightBlue,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.sports_cricket, color: Colors.redAccent, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Runs Scored off Bat by $strikerName:',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildRunChip(0, '0 (No Run)', _batRuns == 0, () => setState(() => _batRuns = 0)),
                        const SizedBox(width: 6),
                        _buildRunChip(1, '1 Run', _batRuns == 1, () => setState(() => _batRuns = 1)),
                        const SizedBox(width: 6),
                        _buildRunChip(2, '2 Runs', _batRuns == 2, () => setState(() => _batRuns = 2)),
                        const SizedBox(width: 6),
                        _buildRunChip(3, '3 Runs', _batRuns == 3, () => setState(() => _batRuns = 3)),
                        const SizedBox(width: 6),
                        _buildRunChip(4, '4 (Four ⚡)', _batRuns == 4, () => setState(() => _batRuns = 4)),
                        const SizedBox(width: 6),
                        _buildRunChip(6, '6 (Six 🚀)', _batRuns == 6, () => setState(() => _batRuns = 6)),
                      ],
                    ),
                  ],
                ),
              ),
            ] else if (_selectedType == ExtrasType.wide) ...[
              // Wide Ball Options
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: GlassTokens.bgLightBlue,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.arrow_forward, color: Colors.amber, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Additional Runs Ran / Fumble to Boundary:',
                          style: TextStyle(color: GlassTokens.inkPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildRunChip(0, '+0 (1 Wd Total)', _additionalRanRuns == 0, () => setState(() => _additionalRanRuns = 0)),
                        const SizedBox(width: 6),
                        _buildRunChip(1, '+1 (2 Wd Total)', _additionalRanRuns == 1, () => setState(() => _additionalRanRuns = 1)),
                        const SizedBox(width: 6),
                        _buildRunChip(2, '+2 (3 Wd Total)', _additionalRanRuns == 2, () => setState(() => _additionalRanRuns = 2)),
                        const SizedBox(width: 6),
                        _buildRunChip(3, '+3 (4 Wd Total)', _additionalRanRuns == 3, () => setState(() => _additionalRanRuns = 3)),
                        const SizedBox(width: 6),
                        _buildRunChip(4, '+4 (5 Wd Boundary)', _additionalRanRuns == 4, () => setState(() => _additionalRanRuns = 4)),
                      ],
                    ),
                  ],
                ),
              ),
            ] else if (_selectedType == ExtrasType.bye || _selectedType == ExtrasType.legBye) ...[
              // Byes & Leg-Byes Options
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: GlassTokens.bgLightBlue,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF00F5A0).withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.directions_run, color: Color(0xFF00F5A0), size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '${_selectedType == ExtrasType.bye ? "Byes" : "Leg-Byes"} Runs Ran:',
                          style: const TextStyle(color: GlassTokens.inkPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildRunChip(1, '1 Run', _byeRuns == 1, () => setState(() => _byeRuns = 1)),
                        const SizedBox(width: 8),
                        _buildRunChip(2, '2 Runs', _byeRuns == 2, () => setState(() => _byeRuns = 2)),
                        const SizedBox(width: 8),
                        _buildRunChip(3, '3 Runs', _byeRuns == 3, () => setState(() => _byeRuns = 3)),
                        const SizedBox(width: 8),
                        _buildRunChip(4, '4 (Boundary ⚡)', _byeRuns == 4, () => setState(() => _byeRuns = 4)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),

            // Live Calculation Breakdown Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: GlassTokens.bgIcyWhite,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF00F5A0).withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('TOTAL BALL SCORE:', style: TextStyle(color: GlassTokens.inkSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                      Text(
                        '+$totalRuns RUNS',
                        style: const TextStyle(color: Color(0xFF00F5A0), fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    breakdownText,
                    style: const TextStyle(color: GlassTokens.inkSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Confirm Button
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onConfirmExtras(
                  extrasType: _selectedType,
                  extrasRuns: calculatedExtrasRuns,
                  runsBatter: calculatedBatRuns,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00F5A0),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Record Extras Delivery (+$totalRuns Runs) ⚡',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeTab(ExtrasType type, String label, Color color) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() {
          _selectedType = type;
        }),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.25) : GlassTokens.bgLightBlue,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? color : GlassTokens.glassHairline, width: isSelected ? 1.5 : 1),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? color : GlassTokens.inkSecondary,
              fontSize: 10.5,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildRunChip(int run, String label, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF00F5A0) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? const Color(0xFF00F5A0) : GlassTokens.glassHairline),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
