import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/mock_database.dart';

class FullScorecardDialog extends StatelessWidget {
  final MatchModel match;
  final MockDatabase db;

  const FullScorecardDialog({
    super.key,
    required this.match,
    required this.db,
  });

  @override
  Widget build(BuildContext context) {
    final matchInnings = db.inningsList.where((i) => i.matchId == match.id).toList();
    final inn1 = matchInnings.where((i) => i.inningsNumber == 1).firstOrNull;
    final inn2 = matchInnings.where((i) => i.inningsNumber == 2).firstOrNull;

    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: Text('${match.stage} • Official Scorecard'),
          backgroundColor: const Color(0xFF0F172A),
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (inn1 != null) _buildInningsScorecard(context, inn1, '1st Innings'),
              if (inn2 != null) ...[
                const SizedBox(height: 24),
                _buildInningsScorecard(context, inn2, '2nd Innings (Target: ${inn2.targetRuns ?? "-"})'),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInningsScorecard(BuildContext context, Innings inn, String title) {
    final batTeam = db.teams.firstWhere((t) => t.id == inn.battingTeamId);
    final bowlTeam = db.teams.firstWhere((t) => t.id == inn.bowlingTeamId);
    final batCards = db.battingScorecards.where((b) => b.inningsId == inn.id).toList();
    final bowlCards = db.bowlingScorecards.where((b) => b.inningsId == inn.id).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Innings Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(batTeam.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(title, style: const TextStyle(color: Colors.white60, fontSize: 10)),
                ],
              ),
              Text(
                '${inn.totalRuns}/${inn.wickets} (${inn.oversStr} Ov)',
                style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Batting Card Table
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: Colors.grey.shade100,
                child: const Row(
                  children: [
                    Expanded(flex: 4, child: Text('Batter', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black54))),
                    Expanded(flex: 3, child: Text('Dismissal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black54))),
                    Expanded(flex: 1, child: Text('R', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black54))),
                    Expanded(flex: 1, child: Text('B', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black54))),
                    Expanded(flex: 1, child: Text('4s', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black54))),
                    Expanded(flex: 1, child: Text('6s', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black54))),
                    Expanded(flex: 2, child: Text('SR', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black54))),
                  ],
                ),
              ),
              ...batCards.map((b) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(flex: 4, child: Text(b.playerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                      Expanded(flex: 3, child: Text(b.dismissalText, style: const TextStyle(fontSize: 10, color: Colors.black54))),
                      Expanded(flex: 1, child: Text('${b.runs}', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11))),
                      Expanded(flex: 1, child: Text('${b.balls}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 11))),
                      Expanded(flex: 1, child: Text('${b.fours}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 11))),
                      Expanded(flex: 1, child: Text('${b.sixes}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 11))),
                      Expanded(flex: 2, child: Text(b.strikeRate.toStringAsFixed(1), textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669)))),
                    ],
                  ),
                );
              }),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Extras: ${inn.totalExtras} (w ${inn.extrasWides}, nb ${inn.extrasNoBalls}, b ${inn.extrasByes}, lb ${inn.extrasLegByes})', style: const TextStyle(fontSize: 10, color: Colors.black54)),
                    Text('Total: ${inn.totalRuns}/${inn.wickets}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Bowling Card Table
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: Colors.grey.shade100,
                child: Row(
                  children: [
                    Expanded(flex: 5, child: Text('${bowlTeam.name} Bowlers', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black54))),
                    const Expanded(flex: 1, child: Text('O', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black54))),
                    const Expanded(flex: 1, child: Text('M', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black54))),
                    const Expanded(flex: 1, child: Text('R', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black54))),
                    const Expanded(flex: 1, child: Text('W', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black54))),
                    const Expanded(flex: 1, child: Text('Dots', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black54))),
                    const Expanded(flex: 2, child: Text('Econ', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black54))),
                  ],
                ),
              ),
              ...bowlCards.map((bowl) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(flex: 5, child: Text(bowl.playerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                      Expanded(flex: 1, child: Text(bowl.oversStr, textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                      Expanded(flex: 1, child: Text('${bowl.maidens}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 11))),
                      Expanded(flex: 1, child: Text('${bowl.runsConceded}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                      Expanded(flex: 1, child: Text('${bowl.wickets}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF059669)))),
                      Expanded(flex: 1, child: Text('${bowl.dots}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 11))),
                      Expanded(flex: 2, child: Text(bowl.economy.toStringAsFixed(2), textAlign: TextAlign.right, style: const TextStyle(fontSize: 11))),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}
