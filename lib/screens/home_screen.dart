import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/mock_database.dart';
import '../../widgets/role_switcher_chip.dart';
import '../../widgets/app_animations.dart';
import 'scorer/scorer_screen.dart';
import 'scorer/full_scorecard_dialog.dart';
import 'tournaments/create_tournament_dialog.dart';
import 'tournaments/tournament_hub_screen.dart';
import 'auction/create_auction_dialog.dart';
import 'matches/match_detail_screen.dart';
import '../../widgets/activity_audit_dialog.dart';

class HomeScreen extends StatefulWidget {
  final Function(int) onTabChange;

  const HomeScreen({super.key, required this.onTabChange});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedFilter = 'featured'; // 'featured', 'live', 'upcoming', 'recent', 'auctions'

  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final db = context.watch<MockDatabase>();

    final liveMatches = db.matches.where((m) => m.status == MatchStatus.live).toList();
    final pastMatches = db.matches.where((m) => m.status == MatchStatus.completed).toList();
    final upcomingMatches = db.matches.where((m) => m.status == MatchStatus.scheduled || m.status == MatchStatus.toss).toList();
    final allMatches = db.matches;

    final liveMatch = liveMatches.firstOrNull;
    final liveInnings = db.inningsList.where((i) => i.matchId == liveMatch?.id).firstOrNull;
    final liveTeamA = liveMatch != null ? (db.getTeam(liveMatch.teamAId) ?? MockDatabase.emptyTeam) : null;
    final liveTeamB = liveMatch != null ? (db.getTeam(liveMatch.teamBId) ?? MockDatabase.emptyTeam) : null;

    // Live Crease details
    final liveStriker = liveInnings != null ? db.getPlayer(liveInnings.currentStrikerId) : null;
    final liveNonStriker = liveInnings != null ? db.getPlayer(liveInnings.currentNonStrikerId) : null;
    final liveBowler = liveInnings != null ? db.getPlayer(liveInnings.currentBowlerId) : null;

    final strikerCard = db.battingScorecards.where((b) => b.inningsId == liveInnings?.id && b.playerId == liveStriker?.id).firstOrNull;
    final nonStrikerCard = db.battingScorecards.where((b) => b.inningsId == liveInnings?.id && b.playerId == liveNonStriker?.id).firstOrNull;
    final bowlerCard = db.bowlingScorecards.where((b) => b.inningsId == liveInnings?.id && b.playerId == liveBowler?.id).firstOrNull;

    // Active Auction
    final liveAuction = db.auctions.where((a) => a.status == AuctionStatus.live).firstOrNull ??
        (db.auctions.isNotEmpty ? db.auctions.first : null);
    final currentLot = liveAuction != null ? db.getLot(liveAuction.currentLotId) : null;
    final lotPlayer = currentLot != null ? db.getPlayer(currentLot.playerId) : null;
    final highBidder = liveAuction != null ? db.getTeam(liveAuction.highBidderTeamId) : null;
    final isAuctionHost = liveAuction != null && db.canManageAuctionFloor(liveAuction.id);
    final isTeamOwner = db.currentAuthenticatedTeam != null;

    return Scaffold(
      backgroundColor: const Color(0xFF111827), // Cricbuzz Dark Slate
      appBar: AppBar(
        backgroundColor: const Color(0xFF009270), // Cricbuzz Signature Green
        elevation: 1,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'cricbuzz',
                style: TextStyle(
                  color: Color(0xFF009270),
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'PRO',
              style: TextStyle(
                color: Colors.amberAccent,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        actions: [
          // Activity & Audit Log Access
          IconButton(
            tooltip: 'System Audit Log',
            icon: const Icon(Icons.receipt_long, color: Colors.white, size: 20),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => ActivityAuditDialog(db: db),
              );
            },
          ),
          const RoleSwitcherChip(compact: true),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Create Tournament',
            icon: const Icon(Icons.add_circle, color: Colors.white, size: 22),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => CreateTournamentDialog(db: db),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 30),
        children: [
          // ==========================================
          // 0. CRICHEROES "ORGANIZE TOURNAMENT" HERO CARD
          // ==========================================
          _buildOrganizeTournamentHeroCard(context, db),

          // ==========================================
          // 1. CRICBUZZ HORIZONTAL MATCHES CAROUSEL
          // ==========================================
          _buildFeaturedMatchesCarousel(context, db, allMatches),

          // ==========================================
          // 2. CRICBUZZ SUB-NAVIGATION TABS
          // ==========================================
          _buildCricbuzzSubTabs(liveMatches.length, upcomingMatches.length, pastMatches.length, db.auctions.length),

          const SizedBox(height: 12),

          // ==========================================
          // 3. TAB CONTENT FEED
          // ==========================================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: _buildFeedBody(
              context,
              db,
              liveMatch,
              liveInnings,
              liveTeamA,
              liveTeamB,
              liveStriker,
              liveNonStriker,
              liveBowler,
              strikerCard,
              nonStrikerCard,
              bowlerCard,
              liveAuction,
              currentLot,
              lotPlayer,
              highBidder,
              isAuctionHost,
              isTeamOwner,
              pastMatches,
              upcomingMatches,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // CRICHEROES "ORGANIZE TOURNAMENT" HERO BANNER
  // =========================================================================
  Widget _buildOrganizeTournamentHeroCard(BuildContext context, MockDatabase db) {
    final activeTourn = db.tournaments.isNotEmpty ? db.tournaments.first : db.tournament;
    final myCreatedTournaments = db.tournaments.where((t) => db.createdTournamentIds.contains(t.id)).toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF064E3B), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF059669), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF34D399)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.emoji_events, size: 12, color: Color(0xFF34D399)),
                    SizedBox(width: 4),
                    Text(
                      'CRICHEROES TOURNAMENT ENGINE',
                      style: TextStyle(color: Color(0xFF34D399), fontSize: 9.5, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${db.tournaments.length} Tournament(s)',
                  style: const TextStyle(color: Colors.amberAccent, fontSize: 9.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          const Text(
            'Organize Cricket Tournament Free',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          const Text(
            'Get a dedicated Tournament Page with custom branding, ball-by-ball updates, Orange & Purple Cap leaderboards, ICC-compliant points table & auction draft.',
            style: TextStyle(color: Colors.white70, fontSize: 11),
          ),
          const SizedBox(height: 10),

          // Feature Highlights Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: const [
                _BenefitBadge(icon: Icons.web, text: 'Dedicated Page'),
                SizedBox(width: 6),
                _BenefitBadge(icon: Icons.radio_button_checked, text: 'Ball-by-Ball'),
                SizedBox(width: 6),
                _BenefitBadge(icon: Icons.military_tech, text: 'Orange/Purple Cap'),
                SizedBox(width: 6),
                _BenefitBadge(icon: Icons.table_chart, text: 'ICC Points Table'),
                SizedBox(width: 6),
                _BenefitBadge(icon: Icons.gavel, text: 'Franchise Auction'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Action Buttons
          Row(
            children: [
              Expanded(
                flex: 5,
                child: ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => CreateTournamentDialog(db: db),
                    );
                  },
                  icon: const Icon(Icons.add_circle, size: 15),
                  label: const Text('Organize Tournament', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF009270),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 5,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (ctx) => TournamentHubScreen(initialTournamentId: activeTourn.id),
                      ),
                    );
                  },
                  icon: const Icon(Icons.open_in_new, size: 14, color: Colors.amberAccent),
                  label: const Text(
                    'Dedicated Page',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.amberAccent),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),

          // User Organized Tournaments quick pill if any
          if (myCreatedTournaments.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF34D399).withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified, size: 12, color: Color(0xFF34D399)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'You organized: ${myCreatedTournaments.first.name} (PIN: ${myCreatedTournaments.first.passcode})',
                      style: const TextStyle(color: Color(0xFF34D399), fontSize: 10, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (ctx) => TournamentHubScreen(initialTournamentId: myCreatedTournaments.first.id),
                        ),
                      );
                    },
                    child: const Text(
                      'Open Hub →',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // =========================================================================
  // CRICBUZZ HORIZONTAL MATCHES CAROUSEL
  // =========================================================================
  Widget _buildFeaturedMatchesCarousel(BuildContext context, MockDatabase db, List<MatchModel> allMatches) {
    if (allMatches.isEmpty) {
      return Container(
        height: 135,
        margin: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1F2937),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF374151)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sports_cricket, size: 28, color: Color(0xFF009270)),
            const SizedBox(height: 6),
            const Text(
              'No matches scheduled yet',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Organize a tournament to schedule fixtures, conduct toss, and broadcast live scoring.',
              style: TextStyle(color: Colors.white60, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      height: 145,
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        itemCount: allMatches.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final m = allMatches[index];
          final teamA = db.getTeam(m.teamAId) ?? MockDatabase.emptyTeam;
          final teamB = db.getTeam(m.teamBId) ?? MockDatabase.emptyTeam;
          final inn1 = db.inningsList.where((i) => i.matchId == m.id && i.inningsNumber == 1).firstOrNull;
          final inn2 = db.inningsList.where((i) => i.matchId == m.id && i.inningsNumber == 2).firstOrNull;
          final tourn = db.getTournament(m.tournamentId);

          final isLive = m.status == MatchStatus.live;
          final isCompleted = m.status == MatchStatus.completed;

          String statusText;
          Color statusColor;

          if (isLive) {
            final activeInn = inn2 ?? inn1;
            statusText = activeInn != null
                ? 'CRR: ${activeInn.runRate.toStringAsFixed(1)} • ${activeInn.oversStr} ov'
                : 'Match in progress';
            statusColor = const Color(0xFF10B981);
          } else if (isCompleted) {
            statusText = m.winnerId != null
                ? '${db.getTeam(m.winnerId)?.shortName ?? "Winner"} won by ${m.winMargin ?? "runs"}'
                : 'Match Completed';
            statusColor = Colors.amberAccent;
          } else {
            statusText = '${m.venue} • Starts soon';
            statusColor = Colors.white60;
          }

          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (ctx) => MatchDetailScreen(matchId: m.id)),
              );
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 300,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1F2937),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isLive ? const Color(0xFFEF4444) : const Color(0xFF374151),
                  width: isLive ? 1.5 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Row: Series & State Pill
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${tourn?.shortName ?? "CRICKET"} • ${m.stage.toUpperCase()}',
                        style: const TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isLive)
                        const PulsingLiveBadge(label: 'LIVE', color: Color(0xFFEF4444))
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isCompleted ? const Color(0xFF009270) : const Color(0xFF374151),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isCompleted ? 'RESULT' : 'UPCOMING',
                            style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w900),
                          ),
                        ),
                    ],
                  ),

                  // Team A Score Row
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: teamA.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          teamA.name,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        inn1 != null ? '${inn1.totalRuns}/${inn1.wickets} (${inn1.oversStr})' : '--',
                        style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),

                  // Team B Score Row
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: teamB.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          teamB.name,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        inn2 != null ? '${inn2.totalRuns}/${inn2.wickets} (${inn2.oversStr})' : '--',
                        style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),

                  // Result / Target Status String
                  Text(
                    statusText,
                    style: TextStyle(color: statusColor, fontSize: 10.5, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // =========================================================================
  // CRICBUZZ SUB-TABS
  // =========================================================================
  Widget _buildCricbuzzSubTabs(int liveCount, int upcomingCount, int recentCount, int auctionCount) {
    return Container(
      color: const Color(0xFF1F2937),
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        children: [
          _buildPillTab('featured', 'Featured'),
          _buildPillTab('live', 'Live ($liveCount)'),
          _buildPillTab('upcoming', 'Upcoming ($upcomingCount)'),
          _buildPillTab('recent', 'Recent ($recentCount)'),
          _buildPillTab('auctions', 'Auctions ($auctionCount)'),
        ],
      ),
    );
  }

  Widget _buildPillTab(String id, String label) {
    final isSelected = selectedFilter == id;
    return InkWell(
      onTap: () => setState(() => selectedFilter = id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? const Color(0xFF009270) : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white60,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // TAB BODY CONTENT
  // =========================================================================
  Widget _buildFeedBody(
    BuildContext context,
    MockDatabase db,
    MatchModel? liveMatch,
    Innings? liveInnings,
    Team? liveTeamA,
    Team? liveTeamB,
    Player? liveStriker,
    Player? liveNonStriker,
    Player? liveBowler,
    BattingScorecard? strikerCard,
    BattingScorecard? nonStrikerCard,
    BowlingScorecard? bowlerCard,
    Auction? liveAuction,
    AuctionLot? currentLot,
    Player? lotPlayer,
    Team? highBidder,
    bool isAuctionHost,
    bool isTeamOwner,
    List<MatchModel> pastMatches,
    List<MatchModel> upcomingMatches,
  ) {
    if (selectedFilter == 'featured' || selectedFilter == 'live') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (selectedFilter == 'featured') ...[
            _buildProductionMetricsSection(context, db),
            _buildPendingTasksSection(context, db),
          ],

          // Live Match Centre Card
          if (liveMatch != null && liveInnings != null && liveTeamA != null && liveTeamB != null) ...[
            _buildCricbuzzLiveScorecard(
              context,
              db,
              liveMatch,
              liveInnings,
              liveTeamA,
              liveTeamB,
              liveStriker,
              liveNonStriker,
              liveBowler,
              strikerCard,
              nonStrikerCard,
              bowlerCard,
            ),
            const SizedBox(height: 14),
          ] else if (selectedFilter == 'live') ...[
            _buildEmptyStateCard(
              title: 'No Live Matches',
              subtitle: 'Start scoring an upcoming fixture with Room ID & PIN to broadcast live.',
              actionLabel: '+ Conduct Toss & Score',
              onAction: () => widget.onTabChange(1),
            ),
            const SizedBox(height: 14),
          ],

          // Live Auction Spotlight (Cricbuzz Style)
          if (liveAuction != null) ...[
            _buildCricbuzzAuctionSpotlight(
              context,
              db,
              liveAuction,
              currentLot,
              lotPlayer,
              highBidder,
              isAuctionHost,
              isTeamOwner,
            ),
            const SizedBox(height: 14),
          ],

          if (selectedFilter == 'featured') ...[
            _buildTournamentLifecycleWorkflowCard(context, db),
            _buildRecentAuditLogStrip(context, db),
          ],

          // Role Command Banner
          _buildRoleStatusStrip(context, db),
        ],
      );
    }

    if (selectedFilter == 'upcoming') {
      if (upcomingMatches.isEmpty) {
        return _buildEmptyStateCard(
          title: 'No Upcoming Fixtures',
          subtitle: 'Create a tournament to automatically generate match schedules and fixtures.',
          actionLabel: '+ Create Tournament',
          onAction: () {
            showDialog(
              context: context,
              builder: (ctx) => CreateTournamentDialog(db: db),
            );
          },
        );
      }
      return Column(
        children: upcomingMatches.map((um) => _buildUpcomingFixtureCard(context, db, um)).toList(),
      );
    }

    if (selectedFilter == 'recent') {
      if (pastMatches.isEmpty) {
        return _buildEmptyStateCard(
          title: 'No Recent Matches',
          subtitle: 'Matches that finish live scoring will display their official certified scorecards here.',
          actionLabel: 'Go to Scorer',
          onAction: () => widget.onTabChange(1),
        );
      }
      return Column(
        children: pastMatches.map((pm) => _buildPastMatchCard(context, db, pm)).toList(),
      );
    }

    if (selectedFilter == 'auctions') {
      if (db.auctions.isEmpty) {
        return _buildEmptyStateCard(
          title: 'No Player Auctions Created',
          subtitle: 'Host an auction with 8 franchise teams, budget limits, player wheel spin, and live bidding.',
          actionLabel: '+ Host New Auction',
          onAction: () {
            showDialog(
              context: context,
              builder: (ctx) => CreateAuctionDialog(db: db),
            );
          },
        );
      }
      return Column(
        children: db.auctions.map((auc) => _buildAuctionDirectoryCard(context, db, auc)).toList(),
      );
    }

    return const SizedBox.shrink();
  }

  // =========================================================================
  // CRICBUZZ LIVE SCORECARD WIDGET
  // =========================================================================
  Widget _buildCricbuzzLiveScorecard(
    BuildContext context,
    MockDatabase db,
    MatchModel match,
    Innings innings,
    Team teamA,
    Team teamB,
    Player? striker,
    Player? nonStriker,
    Player? bowler,
    BattingScorecard? strikerCard,
    BattingScorecard? nonStrikerCard,
    BowlingScorecard? bowlerCard,
  ) {
    final canScore = db.isScoringUnlockedForMatch(match.id);
    final recentDeliveries = db.deliveries
        .where((d) => d.matchId == match.id && d.inningsId == innings.id && !d.isUndone)
        .toList();
    final recent6 = recentDeliveries.reversed.take(6).toList().reversed.toList();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF374151)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF111827),
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const PulsingLiveDot(color: Color(0xFFEF4444), size: 7.5),
                    const SizedBox(width: 6),
                    Text(
                      '${match.stage.toUpperCase()} • LIVE',
                      style: const TextStyle(color: Color(0xFFEF4444), fontSize: 11, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                Text(match.venue, style: const TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Live Teams & Overs
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(teamA.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        ScoreNumberTicker(
                          text: '${innings.totalRuns}/${innings.wickets} ',
                          style: const TextStyle(color: Color(0xFF10B981), fontSize: 20, fontWeight: FontWeight.w900),
                        ),
                        Text(
                          '(${innings.oversStr} ov)',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(teamB.name, style: const TextStyle(color: Colors.white60, fontSize: 13)),
                    Text(
                      'CRR: ${innings.runRate.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),

                const Divider(color: Color(0xFF374151), height: 18),

                // CRICBUZZ RECENT BALLS STRIP
                Row(
                  children: [
                    const Text('Recent: ', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 6),
                    if (recent6.isEmpty)
                      const Text('First over in progress...', style: TextStyle(color: Colors.white38, fontSize: 11))
                    else
                      Wrap(
                        spacing: 5,
                        children: recent6.map((d) => _buildBallBadge(_getDeliveryLabel(d))).toList(),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                // CRICBUZZ BATTERS TABLE
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      // Table Header
                      Row(
                        children: const [
                          Expanded(flex: 4, child: Text('Batter', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold))),
                          Expanded(flex: 1, child: Text('R', textAlign: TextAlign.right, style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold))),
                          Expanded(flex: 1, child: Text('B', textAlign: TextAlign.right, style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold))),
                          Expanded(flex: 1, child: Text('4s', textAlign: TextAlign.right, style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold))),
                          Expanded(flex: 1, child: Text('6s', textAlign: TextAlign.right, style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold))),
                          Expanded(flex: 2, child: Text('SR', textAlign: TextAlign.right, style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold))),
                        ],
                      ),
                      const Divider(color: Color(0xFF1F2937), height: 8),
                      // Striker
                      Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: Text(
                              '${striker?.fullName ?? "Striker"} *',
                              style: const TextStyle(color: Colors.amberAccent, fontSize: 11.5, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(flex: 1, child: Text('${strikerCard?.runs ?? 0}', textAlign: TextAlign.right, style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold))),
                          Expanded(flex: 1, child: Text('${strikerCard?.balls ?? 0}', textAlign: TextAlign.right, style: const TextStyle(color: Colors.white70, fontSize: 11.5))),
                          Expanded(flex: 1, child: Text('${strikerCard?.fours ?? 0}', textAlign: TextAlign.right, style: const TextStyle(color: Colors.white70, fontSize: 11.5))),
                          Expanded(flex: 1, child: Text('${strikerCard?.sixes ?? 0}', textAlign: TextAlign.right, style: const TextStyle(color: Colors.white70, fontSize: 11.5))),
                          Expanded(flex: 2, child: Text((strikerCard?.strikeRate ?? 0).toStringAsFixed(1), textAlign: TextAlign.right, style: const TextStyle(color: Colors.white70, fontSize: 11.5))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Non-Striker
                      Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: Text(
                              nonStriker?.fullName ?? "Non-Striker",
                              style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(flex: 1, child: Text('${nonStrikerCard?.runs ?? 0}', textAlign: TextAlign.right, style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold))),
                          Expanded(flex: 1, child: Text('${nonStrikerCard?.balls ?? 0}', textAlign: TextAlign.right, style: const TextStyle(color: Colors.white70, fontSize: 11.5))),
                          Expanded(flex: 1, child: Text('${nonStrikerCard?.fours ?? 0}', textAlign: TextAlign.right, style: const TextStyle(color: Colors.white70, fontSize: 11.5))),
                          Expanded(flex: 1, child: Text('${nonStrikerCard?.sixes ?? 0}', textAlign: TextAlign.right, style: const TextStyle(color: Colors.white70, fontSize: 11.5))),
                          Expanded(flex: 2, child: Text((nonStrikerCard?.strikeRate ?? 0).toStringAsFixed(1), textAlign: TextAlign.right, style: const TextStyle(color: Colors.white70, fontSize: 11.5))),
                        ],
                      ),

                      const Divider(color: Color(0xFF1F2937), height: 10),

                      // Bowler Row
                      Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: Text(
                              'Bowler: ${bowler?.fullName ?? "Debayan Paul"}',
                              style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            flex: 6,
                            child: Text(
                              '${bowlerCard?.oversStr ?? "0.0"}-${bowlerCard?.maidens ?? 0}-${bowlerCard?.runsConceded ?? 0}-${bowlerCard?.wickets ?? 0} (Eco: ${(bowlerCard?.economy ?? 0).toStringAsFixed(2)})',
                              textAlign: TextAlign.right,
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Scorer Console vs Scorecard Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => FullScorecardDialog(match: match, db: db),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFF374151)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                        ),
                        child: const Text('Full Scorecard', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (ctx) => ScorerScreen(initialMatchId: match.id)),
                          );
                        },
                        icon: Icon(canScore ? Icons.sports_score : Icons.visibility, size: 14, color: Colors.white),
                        label: Text(
                          canScore ? 'Scorer Pad' : 'Live Centre',
                          style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canScore ? const Color(0xFF009270) : const Color(0xFF2563EB),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Circular Ball Badge helper
  Widget _buildBallBadge(String label) {
    Color bg = const Color(0xFF374151);
    Color fg = Colors.white;

    if (label == '4') {
      bg = const Color(0xFF2563EB); // boundary blue
    } else if (label == '6') {
      bg = const Color(0xFF7C3AED); // six purple
    } else if (label.contains('W') || label == 'OUT') {
      bg = const Color(0xFFDC2626); // wicket red
    } else if (label.contains('Wd') || label.contains('Nb')) {
      bg = const Color(0xFFD97706); // extra amber
    }

    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 9.5, fontWeight: FontWeight.bold),
      ),
    );
  }

  // =========================================================================
  // CRICBUZZ AUCTION SPOTLIGHT WIDGET
  // =========================================================================
  Widget _buildCricbuzzAuctionSpotlight(
    BuildContext context,
    MockDatabase db,
    Auction auction,
    AuctionLot? currentLot,
    Player? player,
    Team? highBidder,
    bool isHost,
    bool isOwner,
  ) {
    final activePrice = currentLot?.currentBid ?? currentLot?.startingPrice ?? currentLot?.basePrice ?? 500000;
    final formattedPrice = currencyFormat.format(activePrice);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.shade700, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: const BoxDecoration(
              color: Color(0xFF111827),
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.gavel, size: 14, color: Colors.amberAccent),
                    const SizedBox(width: 6),
                    Text(
                      auction.title.toUpperCase(),
                      style: const TextStyle(color: Colors.amberAccent, fontSize: 10.5, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    auction.status.name.toUpperCase(),
                    style: const TextStyle(color: Colors.amberAccent, fontSize: 8.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundImage: NetworkImage(player?.photoUrl ?? 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=256'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player?.fullName ?? 'Player Lot on Stage',
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${player?.roleString ?? "Player"} • Base: ${currencyFormat.format(currentLot?.basePrice ?? 500000)}',
                        style: const TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        highBidder != null
                            ? 'High Bid: $formattedPrice (${highBidder.name})'
                            : 'Opening Price: $formattedPrice • No bids yet',
                        style: const TextStyle(color: Colors.amberAccent, fontSize: 11.5, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => widget.onTabChange(2), // Go to Auction tab
                  icon: Icon(
                    isHost ? Icons.gavel : (isOwner ? Icons.vpn_key : Icons.visibility),
                    size: 13,
                    color: Colors.black,
                  ),
                  label: Text(
                    isHost ? 'Host Floor' : (isOwner ? 'Bid' : 'Watch Live'),
                    style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amberAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // ROLE STATUS STRIP
  // =========================================================================
  Widget _buildRoleStatusStrip(BuildContext context, MockDatabase db) {
    final role = db.currentRole;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF374151)),
      ),
      child: Row(
        children: [
          Icon(role.icon, size: 16, color: role.color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${role.displayName.toUpperCase()} • ${role.badgeLabel}',
                  style: TextStyle(color: role.color, fontSize: 9.5, fontWeight: FontWeight.w900),
                ),
                Text(
                  role == AppUserRole.viewer
                      ? (db.createdTournamentIds.isNotEmpty
                          ? 'You created ${db.createdTournamentIds.length} tournament(s) with full scoring & auction controls.'
                          : 'Viewer mode: Watch scores and live auction. Tap "+ Tournament" above to host your own!')
                      : role.description,
                  style: const TextStyle(color: Colors.white70, fontSize: 10.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductionMetricsSection(BuildContext context, MockDatabase db) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'LIVE PLATFORM METRICS',
                style: TextStyle(
                  color: Color(0xFF34D399),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                'Production Verified',
                style: TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildMetricCard('Tournaments', '${db.tournaments.length}', Icons.emoji_events_outlined, const Color(0xFF059669)),
              const SizedBox(width: 8),
              _buildMetricCard('Teams', '${db.teams.length}', Icons.groups_outlined, const Color(0xFF0284C7)),
              const SizedBox(width: 8),
              _buildMetricCard('Players', '${db.players.length}', Icons.person_search_outlined, const Color(0xFFF59E0B)),
              const SizedBox(width: 8),
              _buildMetricCard('Matches', '${db.matches.length}', Icons.sports_cricket_outlined, const Color(0xFFA855F7)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTournamentLifecycleWorkflowCard(BuildContext context, MockDatabase db) {
    final hasTourn = db.tournaments.isNotEmpty;
    final hasTeams = db.teams.isNotEmpty;
    final hasPlayers = db.players.isNotEmpty;
    final hasAuction = db.auctions.isNotEmpty;
    final hasMatches = db.matches.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.timeline, size: 16, color: Color(0xFF34D399)),
                  SizedBox(width: 6),
                  Text(
                    'TOURNAMENT LIFECYCLE WORKFLOW',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  hasTourn ? 'Active' : 'Get Started',
                  style: const TextStyle(color: Color(0xFF34D399), fontSize: 9.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _buildWorkflowStepRow(
            step: 1,
            title: '1. Create Tournament & Formats',
            subtitle: hasTourn ? '${db.tournaments.first.name} (${db.tournaments.first.overs} Ov)' : 'Configure tournament overs, venue & scorer PIN',
            isComplete: hasTourn,
            onTap: () {
              if (hasTourn) {
                widget.onTabChange(4);
              } else {
                showDialog(context: context, builder: (ctx) => CreateTournamentDialog(db: db));
              }
            },
          ),
          const Divider(color: Colors.white10, height: 16),

          _buildWorkflowStepRow(
            step: 2,
            title: '2. Setup Teams & Owner Codes',
            subtitle: hasTeams ? '${db.teams.length} participating franchises registered' : 'Register competing teams and owner phone numbers',
            isComplete: hasTeams,
            onTap: () => widget.onTabChange(4),
          ),
          const Divider(color: Colors.white10, height: 16),

          _buildWorkflowStepRow(
            step: 3,
            title: '3. Register Player Pool',
            subtitle: hasPlayers ? '${db.players.length} registered players across categories' : 'Add batters, bowlers, keepers and base prices',
            isComplete: hasPlayers,
            onTap: () => widget.onTabChange(4),
          ),
          const Divider(color: Colors.white10, height: 16),

          _buildWorkflowStepRow(
            step: 4,
            title: '4. Player Auction / Squad Draft',
            subtitle: hasAuction ? 'Live auction floor provisioned' : 'Spin wheel, live bidding & auto squad updates',
            isComplete: hasAuction,
            onTap: () => widget.onTabChange(2),
          ),
          const Divider(color: Colors.white10, height: 16),

          _buildWorkflowStepRow(
            step: 5,
            title: '5. Match Scheduling & Live Scoring',
            subtitle: hasMatches ? '${db.matches.length} fixtures scheduled with live ball-by-ball' : 'Toss, crease selection, balls & ICC NRR tables',
            isComplete: hasMatches,
            onTap: () => widget.onTabChange(1),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkflowStepRow({
    required int step,
    required String title,
    required String subtitle,
    required bool isComplete,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isComplete ? const Color(0xFF059669) : const Color(0xFF0F172A),
                shape: BoxShape.circle,
                border: Border.all(color: isComplete ? const Color(0xFF34D399) : Colors.white24),
              ),
              child: Icon(
                isComplete ? Icons.check : Icons.circle_outlined,
                size: 13,
                color: isComplete ? Colors.white : Colors.white38,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isComplete ? Colors.white : Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white38, fontSize: 10.5),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 16, color: Colors.white38),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingTasksSection(BuildContext context, MockDatabase db) {
    final tasks = <Map<String, dynamic>>[];

    if (db.tournaments.isEmpty) {
      tasks.add({
        'title': 'Organize Inaugural Tournament',
        'desc': 'Set match overs, venue, and host access PIN to get started.',
        'actionLabel': '+ Create Tournament',
        'action': () => showDialog(context: context, builder: (ctx) => CreateTournamentDialog(db: db)),
        'color': const Color(0xFF059669),
      });
    } else {
      final activeTourn = db.tournaments.first;
      if (db.teams.isEmpty) {
        tasks.add({
          'title': 'Add Participating Teams',
          'desc': 'Register at least 2 teams for ${activeTourn.shortName}.',
          'actionLabel': 'Add Teams →',
          'action': () => widget.onTabChange(4),
          'color': const Color(0xFF0284C7),
        });
      }

      final scheduledMatches = db.matches.where((m) => m.status == MatchStatus.scheduled || m.status == MatchStatus.toss).toList();
      if (scheduledMatches.isNotEmpty) {
        final nextMatch = scheduledMatches.first;
        tasks.add({
          'title': 'Conduct Coin Toss & Score',
          'desc': '${nextMatch.stage} at ${nextMatch.venue}.',
          'actionLabel': 'Open Scorer →',
          'action': () => widget.onTabChange(1),
          'color': const Color(0xFFF59E0B),
        });
      }

      if (db.auctions.isNotEmpty && db.auctions.any((a) => a.status == AuctionStatus.live)) {
        final activeAuc = db.auctions.firstWhere((a) => a.status == AuctionStatus.live);
        tasks.add({
          'title': 'Active Auction Floor',
          'desc': '${activeAuc.title} is live and awaiting bids.',
          'actionLabel': 'Enter Auction →',
          'action': () => widget.onTabChange(2),
          'color': Colors.amber,
        });
      }
    }

    if (tasks.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.assignment_outlined, size: 14, color: Colors.amberAccent),
              SizedBox(width: 6),
              Text(
                'IMPORTANT PENDING TASKS',
                style: TextStyle(
                  color: Colors.amberAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...tasks.map((task) {
            final tColor = task['color'] as Color;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: tColor.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task['title'] as String,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          task['desc'] as String,
                          style: const TextStyle(color: Colors.white60, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: task['action'] as VoidCallback,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(task['actionLabel'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRecentAuditLogStrip(BuildContext context, MockDatabase db) {
    final recentLogs = db.auditLogs.take(3).toList();
    if (recentLogs.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.history, size: 14, color: Color(0xFF34D399)),
                  SizedBox(width: 6),
                  Text(
                    'RECENT SYSTEM ACTIVITY',
                    style: TextStyle(
                      color: Color(0xFF34D399),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  showDialog(context: context, builder: (ctx) => ActivityAuditDialog(db: db));
                },
                child: const Text('View All →', style: TextStyle(color: Color(0xFF34D399), fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...recentLogs.map((log) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF34D399)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${log.action}: ${log.details}',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // =========================================================================
  // UPCOMING FIXTURE CARD
  // =========================================================================
  Widget _buildUpcomingFixtureCard(BuildContext context, MockDatabase db, MatchModel m) {
    final teamA = db.getTeam(m.teamAId) ?? MockDatabase.emptyTeam;
    final teamB = db.getTeam(m.teamBId) ?? MockDatabase.emptyTeam;
    final canScore = db.isScoringUnlockedForMatch(m.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF374151)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(m.stage, style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFF374151), borderRadius: BorderRadius.circular(4)),
                child: const Text('SCHEDULED', style: TextStyle(color: Colors.white70, fontSize: 8.5, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('${teamA.name} vs ${teamB.name}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text('📍 ${m.venue} • ${m.overs} Overs Format', style: const TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (canScore)
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (ctx) => ScorerScreen(initialMatchId: m.id)),
                    );
                  },
                  icon: const Icon(Icons.sports_score, size: 14, color: Colors.black),
                  label: const Text('🪙 Conduct Toss & Score', style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF009270),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                )
              else
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (ctx) => ScorerScreen(initialMatchId: m.id)),
                    );
                  },
                  icon: const Icon(Icons.visibility, size: 14, color: Color(0xFF009270)),
                  label: const Text('Match Centre (Viewer)', style: TextStyle(color: Color(0xFF009270), fontSize: 11, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF009270)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // PAST MATCH RESULT CARD
  // =========================================================================
  Widget _buildPastMatchCard(BuildContext context, MockDatabase db, MatchModel pm) {
    final teamA = db.getTeam(pm.teamAId) ?? MockDatabase.emptyTeam;
    final teamB = db.getTeam(pm.teamBId) ?? MockDatabase.emptyTeam;
    final inn1 = db.inningsList.where((i) => i.matchId == pm.id && i.inningsNumber == 1).firstOrNull;
    final inn2 = db.inningsList.where((i) => i.matchId == pm.id && i.inningsNumber == 2).firstOrNull;
    final winner = db.getTeam(pm.winnerId);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF374151)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${pm.stage} • RESULT', style: const TextStyle(color: Color(0xFF009270), fontSize: 11, fontWeight: FontWeight.bold)),
              Text(pm.venue, style: const TextStyle(color: Colors.white54, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            winner != null ? '${winner.name} won by ${pm.winMargin ?? "runs"}' : 'Match Completed',
            style: const TextStyle(color: Colors.amberAccent, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFF111827), borderRadius: BorderRadius.circular(6)),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(teamA.name, style: const TextStyle(color: Colors.white70, fontSize: 11.5)),
                    Text('${inn1?.totalRuns ?? 0}/${inn1?.wickets ?? 0} (${inn1?.oversStr ?? "0.0"} ov)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11.5)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(teamB.name, style: const TextStyle(color: Colors.white70, fontSize: 11.5)),
                    Text('${inn2?.totalRuns ?? 0}/${inn2?.wickets ?? 0} (${inn2?.oversStr ?? "0.0"} ov)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11.5)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => FullScorecardDialog(match: pm, db: db),
                );
              },
              icon: const Icon(Icons.table_chart, size: 14, color: Color(0xFF009270)),
              label: const Text('View Full Scorecard →', style: TextStyle(color: Color(0xFF009270), fontSize: 11.5, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // AUCTION DIRECTORY CARD
  // =========================================================================
  Widget _buildAuctionDirectoryCard(BuildContext context, MockDatabase db, Auction auc) {
    final tourn = db.getTournament(auc.tournamentId);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF374151)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(auc.title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: auc.status == AuctionStatus.live ? const Color(0xFFEF4444) : Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  auc.status.name.toUpperCase(),
                  style: TextStyle(
                    color: auc.status == AuctionStatus.live ? Colors.white : Colors.amberAccent,
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Tournament: ${tourn?.name ?? "Franchise Cricket"} • ${auc.requiredTeamsCount} Teams • Purse: ₹${(auc.maxPursePerTeam / 10000000).toStringAsFixed(1)} Cr',
            style: const TextStyle(color: Colors.white60, fontSize: 11),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: () => widget.onTabChange(2),
                icon: const Icon(Icons.gavel, size: 14, color: Colors.black),
                label: const Text('Enter Auction Arena', style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amberAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // EMPTY STATE HELPER
  // =========================================================================
  Widget _buildEmptyStateCard({
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF374151)),
      ),
      child: Column(
        children: [
          const Icon(Icons.sports_cricket, size: 36, color: Color(0xFF009270)),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 11.5), textAlign: TextAlign.center),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: onAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF009270),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(actionLabel, style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _getDeliveryLabel(Delivery d) {
    if (d.isWicket) return 'W';
    if (d.extrasType == ExtrasType.wide) return '${d.totalRuns}Wd';
    if (d.extrasType == ExtrasType.noBall) return '${d.totalRuns}Nb';
    if (d.extrasType == ExtrasType.bye) return '${d.totalRuns}B';
    if (d.extrasType == ExtrasType.legBye) return '${d.totalRuns}Lb';
    return '${d.runsBatter}';
  }
}

class _BenefitBadge extends StatelessWidget {
  final IconData icon;
  final String text;

  const _BenefitBadge({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: const Color(0xFF34D399)),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

