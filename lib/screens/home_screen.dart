import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/mock_database.dart';
import 'scorer/scorer_screen.dart';
import 'scorer/full_scorecard_dialog.dart';

class HomeScreen extends StatefulWidget {
  final Function(int) onTabChange;

  const HomeScreen({super.key, required this.onTabChange});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String scorecardTab = 'live'; // 'live', 'past', 'upcoming'

  @override
  Widget build(BuildContext context) {
    final db = context.watch<MockDatabase>();

    final liveMatch = db.matches.where((m) => m.status == MatchStatus.live).firstOrNull;
    final pastMatches = db.matches.where((m) => m.status == MatchStatus.completed).toList();
    final upcomingMatches = db.matches.where((m) => m.status == MatchStatus.scheduled || m.status == MatchStatus.toss).toList();

    final liveInnings = db.inningsList.where((i) => i.matchId == liveMatch?.id).firstOrNull;
    final liveTeamA = db.teams.where((t) => t.id == liveMatch?.teamAId).firstOrNull;
    final liveTeamB = db.teams.where((t) => t.id == liveMatch?.teamBId).firstOrNull;

    // Live Crease details
    final liveStriker = db.players.where((p) => p.id == liveInnings?.currentStrikerId).firstOrNull;
    final liveNonStriker = db.players.where((p) => p.id == liveInnings?.currentNonStrikerId).firstOrNull;
    final liveBowler = db.players.where((p) => p.id == liveInnings?.currentBowlerId).firstOrNull;

    final strikerCard = db.battingScorecards.where((b) => b.inningsId == liveInnings?.id && b.playerId == liveStriker?.id).firstOrNull;
    final nonStrikerCard = db.battingScorecards.where((b) => b.inningsId == liveInnings?.id && b.playerId == liveNonStriker?.id).firstOrNull;
    final bowlerCard = db.bowlingScorecards.where((b) => b.inningsId == liveInnings?.id && b.playerId == liveBowler?.id).firstOrNull;

    // Auction Highlight
    final currentLot = db.auctionLots.where((l) => l.id == db.auction.currentLotId).firstOrNull;
    final lotPlayer = currentLot != null ? db.players.where((p) => p.id == currentLot.playerId).firstOrNull : null;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF059669), Color(0xFF10B981)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.sports_cricket, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            RichText(
              text: const TextSpan(
                children: [
                  TextSpan(text: 'CRIC', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                  TextSpan(text: 'PAVILION', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF34D399))),
                  TextSpan(text: ' PRO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // HERO BANNER
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF064E3B), Color(0xFF022C22)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF047857)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF10B981)),
                    ),
                    child: const Text('CRICKET APPS & FRANCHISE AUCTION', style: TextStyle(color: Color(0xFF34D399), fontSize: 9, fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Tournament Management, Live Scoring & Auctions',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, height: 1.2),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Record matches ball-by-ball, spin the player wheel, and track tournaments with CricHeroes level precision.',
                    style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.3),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => widget.onTabChange(1), // Go to Scorer
                        icon: const Icon(Icons.play_circle_fill, size: 14, color: Colors.black),
                        label: const Text('Live Scorer', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF34D399),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => widget.onTabChange(2), // Go to Auction
                        icon: const Icon(Icons.gavel, size: 14, color: Colors.amber),
                        label: const Text('Auction Stage', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber)),
                        style: ElevatedButton.styleFrom(
                          side: const BorderSide(color: Colors.amber),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ==========================================
            // COMPREHENSIVE SCORECARD CENTRE
            // ==========================================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'MATCH SCORECARD CENTRE',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
                TextButton(
                  onPressed: () => widget.onTabChange(3), // Go to Matches
                  child: const Text('All Fixtures →', style: TextStyle(color: Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Segmented Tabs: Live, Past, Upcoming
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  _buildTabButton('live', 'Live Scoring (${liveMatch != null ? 1 : 0})', Colors.red),
                  _buildTabButton('past', 'Past Matches (${pastMatches.length})', const Color(0xFF059669)),
                  _buildTabButton('upcoming', 'Upcoming (${upcomingMatches.length})', Colors.blue),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // TAB 1: LIVE SCORING VIEW
            if (scorecardTab == 'live') ...[
              if (liveMatch != null && liveInnings != null && liveTeamA != null && liveTeamB != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.red.shade400),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Status Bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 6),
                              Text('${liveMatch.stage.toUpperCase()} • LIVE', style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.w900)),
                            ],
                          ),
                          Text(liveMatch.venue, style: const TextStyle(color: Colors.white38, fontSize: 10)),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Scores
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(liveTeamA.name, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                          Text(
                            '${liveInnings.totalRuns}/${liveInnings.wickets} (${liveInnings.oversStr} ov)',
                            style: const TextStyle(color: Color(0xFF34D399), fontSize: 18, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(liveTeamB.name, style: const TextStyle(color: Colors.white60, fontSize: 13)),
                          Text('CRR: ${liveInnings.runRate.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                        ],
                      ),
                      const Divider(color: Color(0xFF334155), height: 18),

                      // Real-time Batters & Bowler Details
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('BATTERS AT CREASE', style: TextStyle(color: Color(0xFF34D399), fontSize: 9, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('★ ${liveStriker?.displayName ?? "Striker"}', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 11)),
                                Text('${strikerCard?.runs ?? 62}* (${strikerCard?.balls ?? 38}b) • SR ${strikerCard?.strikeRate.toStringAsFixed(1) ?? "163.2"}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('• ${liveNonStriker?.displayName ?? "Non-Striker"}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                                Text('${nonStrikerCard?.runs ?? 45}* (${nonStrikerCard?.balls ?? 31}b) • SR ${nonStrikerCard?.strikeRate.toStringAsFixed(1) ?? "145.2"}', style: const TextStyle(color: Colors.white60, fontSize: 11)),
                              ],
                            ),
                            const Divider(color: Color(0xFF1E293B), height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Bowler: ${liveBowler?.displayName ?? "Debayan Paul"}', style: const TextStyle(color: Colors.white70, fontSize: 10)),
                                Text('${bowlerCard?.oversStr ?? "2.4"}-${bowlerCard?.maidens ?? 0}-${bowlerCard?.runsConceded ?? 24}-${bowlerCard?.wickets ?? 1} (Econ: ${bowlerCard?.economy.toStringAsFixed(2) ?? "9.00"})', style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Actions
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => FullScorecardDialog(match: liveMatch, db: db),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white24),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('Scorecard', style: TextStyle(fontSize: 11)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => widget.onTabChange(1), // Go to Scorer
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF059669),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('Scorer Console', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: Text('No match live currently', style: TextStyle(color: Colors.white38))),
                ),
            ],

            // TAB 2: PAST MATCHES VIEW
            if (scorecardTab == 'past') ...[
              ...pastMatches.map((pm) {
                final inn1 = db.inningsList.where((i) => i.matchId == pm.id && i.inningsNumber == 1).firstOrNull;
                final inn2 = db.inningsList.where((i) => i.matchId == pm.id && i.inningsNumber == 2).firstOrNull;
                final teamA = db.teams.firstWhere((t) => t.id == pm.teamAId);
                final teamB = db.teams.firstWhere((t) => t.id == pm.teamBId);
                final winner = db.teams.firstWhere((t) => t.id == pm.winnerId);

                return Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF059669)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${pm.stage} • COMPLETED', style: const TextStyle(color: Color(0xFF34D399), fontSize: 10, fontWeight: FontWeight.bold)),
                          Text(pm.venue, style: const TextStyle(color: Colors.white38, fontSize: 10)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Winner Trophy Banner
                      Row(
                        children: [
                          const Icon(Icons.emoji_events, size: 16, color: Colors.amber),
                          const SizedBox(width: 6),
                          Text('${winner.name} won by ${pm.winMargin}', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Innings 1 & 2
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${teamA.name} (1st Inn):', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                                Text('${inn1?.totalRuns}/${inn1?.wickets} (${inn1?.oversStr} ov)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${teamB.name} (2nd Inn):', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                                Text('${inn2?.totalRuns}/${inn2?.wickets} (${inn2?.oversStr} ov)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      ElevatedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => FullScorecardDialog(match: pm, db: db),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('View Certified Full Scorecard', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              }),
            ],

            // TAB 3: UPCOMING FIXTURES VIEW
            if (scorecardTab == 'upcoming') ...[
              ...upcomingMatches.map((um) {
                final teamA = db.teams.firstWhere((t) => t.id == um.teamAId);
                final teamB = db.teams.firstWhere((t) => t.id == um.teamBId);

                return Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(um.stage, style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(4)),
                            child: const Text('SCHEDULED', style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('${teamA.name} vs ${teamB.name}', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text('📍 ${um.venue} • ${um.overs} Overs T20', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (ctx) => ScorerScreen(initialMatchId: um.id)),
                          );
                        },
                        icon: const Icon(Icons.monetization_on, size: 14, color: Colors.black),
                        label: const Text('Conduct Coin Toss & Start Scoring →', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 11)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF34D399),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],

            const SizedBox(height: 20),

            // LIVE AUCTION PREVIEW HIGHLIGHT
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber.shade600),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: NetworkImage(lotPlayer?.photoUrl ?? 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=256'),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('LIVE MEGA AUCTION', style: TextStyle(color: Colors.amber, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                        Text(lotPlayer?.fullName ?? 'Anustup Majumdar', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                        Text('Current Bid: ₹4,50,000 (Barasat)', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => widget.onTabChange(2), // Go to Auction
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Bid Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String id, String label, Color indicatorColor) {
    final isSelected = scorecardTab == id;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => scorecardTab = id),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0F172A) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isSelected ? Border.all(color: indicatorColor.withValues(alpha: 0.5)) : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white54,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
