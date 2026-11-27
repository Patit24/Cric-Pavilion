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
import 'auction/create_auction_dialog.dart';
import 'auction/auction_screen.dart';
import 'matches/match_detail_screen.dart';
import 'matches/create_direct_match_dialog.dart';
import '../../widgets/activity_audit_dialog.dart';
import 'public/join_auction_screen.dart';
import '../../widgets/organize_hub_modal.dart';
import '../../widgets/auth_modal_dialog.dart';
import '../../widgets/cloud_sync_dialog.dart';

class HomeScreen extends StatefulWidget {
  final Function(int) onTabChange;

  const HomeScreen({super.key, required this.onTabChange});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedFilter = 'featured'; // 'featured', 'live', 'upcoming', 'recent', 'auctions'
  final TextEditingController _tournamentSearchController = TextEditingController();
  String _selectedTournamentId = 'all';

  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  void dispose() {
    _tournamentSearchController.dispose();
    super.dispose();
  }

  String _getFilterTitle(MockDatabase db) {
    if (_selectedTournamentId != 'all') {
      final t = db.getTournament(_selectedTournamentId);
      if (t != null) return t.name;
    }
    final q = _tournamentSearchController.text.trim();
    if (q.isNotEmpty) {
      return 'Tournament "$q"';
    }
    return 'All Tournaments';
  }

  @override
  Widget build(BuildContext context) {
    final db = context.watch<MockDatabase>();

    final searchQuery = _tournamentSearchController.text.trim().toLowerCase();

    // 1. Gather all tournaments that have matches in the database
    final tournamentIdsWithMatches = db.matches.map((m) => m.tournamentId).toSet();
    final activeTournaments = db.tournaments.where((t) => tournamentIdsWithMatches.contains(t.id)).toList();

    // 2. Filter matches based on tournament search query & selected tournament chip
    final filteredMatches = db.matches.where((m) {
      if (_selectedTournamentId != 'all' && m.tournamentId != _selectedTournamentId) {
        return false;
      }
      if (searchQuery.isNotEmpty) {
        final tourn = db.getTournament(m.tournamentId);
        final tournName = tourn?.name.toLowerCase() ?? '';
        final tournShort = tourn?.shortName.toLowerCase() ?? '';
        final teamA = db.getTeam(m.teamAId)?.name.toLowerCase() ?? '';
        final teamB = db.getTeam(m.teamBId)?.name.toLowerCase() ?? '';
        final venue = m.venue.toLowerCase();
        final stage = m.stage.toLowerCase();

        final matchesTourn = tournName.contains(searchQuery) || tournShort.contains(searchQuery);
        final matchesTeam = teamA.contains(searchQuery) || teamB.contains(searchQuery);
        final matchesOther = venue.contains(searchQuery) || stage.contains(searchQuery);

        return matchesTourn || matchesTeam || matchesOther;
      }
      return true;
    }).toList();

    final liveMatches = filteredMatches.where((m) => m.status == MatchStatus.live).toList();
    final pastMatches = filteredMatches.where((m) => m.status == MatchStatus.completed).toList();
    final upcomingMatches = filteredMatches.where((m) => m.status == MatchStatus.scheduled || m.status == MatchStatus.toss).toList();

    // Active Auction
    final liveAuction = db.auctions.where((a) => a.status == AuctionStatus.live).firstOrNull ??
        (db.auctions.isNotEmpty ? db.auctions.first : null);
    final currentLot = liveAuction != null ? db.getLot(liveAuction.currentLotId) : null;
    final lotPlayer = currentLot != null ? db.getPlayer(currentLot.playerId) : null;
    final highBidder = liveAuction != null ? db.getTeam(liveAuction.highBidderTeamId) : null;
    final isAuctionHost = liveAuction != null && db.canManageAuctionFloor(liveAuction.id);
    final isTeamOwner = db.currentAuthenticatedTeam != null;
    final filterTitle = _getFilterTitle(db);

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
                'CRICPAVILION',
                style: TextStyle(
                  color: Color(0xFF009270),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
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
          // Multi-Device Cloud Sync
          IconButton(
            tooltip: 'Sync with Mobile / Central Server',
            icon: const Icon(Icons.cloud_sync, color: Color(0xFF00F5A0), size: 21),
            onPressed: () {
              CloudSyncDialog.show(context);
            },
          ),
          // Quick Match Launcher
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: ElevatedButton.icon(
              onPressed: () => _openQuickMatch(context, db),
              icon: const Icon(Icons.flash_on, color: Colors.black, size: 14),
              label: const Text(
                'QUICK MATCH',
                style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w900),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00F5A0),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
            ),
          ),
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
          const SizedBox(width: 4),
          const RoleSwitcherChip(compact: true),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 30),
        children: [
          // ==========================================
          // 1. TOURNAMENT SEARCH & FILTER BAR
          // ==========================================
          _buildTournamentSearchBar(context, db, activeTournaments),

          // ==========================================
          // QUICK MATCH BANNER
          // ==========================================
          _buildQuickMatchBanner(context, db),

          // ==========================================
          // 2. CRICBUZZ HORIZONTAL MATCHES CAROUSEL
          // ==========================================
          _buildFeaturedMatchesCarousel(context, db, filteredMatches),

          // ==========================================
          // 3. CRICBUZZ SUB-NAVIGATION TABS
          // ==========================================
          _buildCricbuzzSubTabs(liveMatches.length, upcomingMatches.length, pastMatches.length, db.auctions.length),

          const SizedBox(height: 12),

          // ==========================================
          // 4. TAB CONTENT FEED
          // ==========================================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: _buildFeedBody(
              context: context,
              db: db,
              liveMatches: liveMatches,
              liveAuction: liveAuction,
              currentLot: currentLot,
              lotPlayer: lotPlayer,
              highBidder: highBidder,
              isAuctionHost: isAuctionHost,
              isTeamOwner: isTeamOwner,
              pastMatches: pastMatches,
              upcomingMatches: upcomingMatches,
              searchQuery: searchQuery,
              filterTitle: filterTitle,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // QUICK MATCH BANNER
  // =========================================================================
  Widget _buildQuickMatchBanner(BuildContext context, MockDatabase db) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x6600F5A0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00F5A0).withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF00F5A0).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.flash_on, color: Color(0xFF00F5A0), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '⚡ Start a Quick Match',
                  style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 2),
                Text(
                  'Friendly 2-team match with custom overs & live scoring.',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _openQuickMatch(context, db),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00F5A0),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Play Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
          ),
        ],
      ),
    );
  }

  void _openFullScorecard(BuildContext context, MockDatabase db, MatchModel match) {
    if (!db.isAuthenticated) {
      showDialog(
        context: context,
        builder: (ctx) => AuthModalDialog(
          initialActionPrompt: 'Login Required: Please sign in to view the full scoreboard.',
          onAuthSuccess: () {
            if (!context.mounted) return;
            showDialog(
              context: context,
              builder: (ctx2) => FullScorecardDialog(match: match, db: db),
            );
          },
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => FullScorecardDialog(match: match, db: db),
    );
  }

  void _openQuickMatch(BuildContext context, MockDatabase db) {
    if (!db.isAuthenticated) {
      showDialog(
        context: context,
        builder: (ctx) => AuthModalDialog(
          initialActionPrompt: 'Login Required: Please sign in or register to score friendly matches.',
          onAuthSuccess: () {
            showDialog(
              context: context,
              builder: (ctx) => CreateDirectMatchDialog(db: db),
            );
          },
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => CreateDirectMatchDialog(db: db),
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
      height: 152,
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

          final activeInn = inn2 ?? inn1;
          final matchDeliveries = activeInn != null
              ? db.deliveries.where((d) => d.matchId == m.id && d.inningsId == activeInn.id && !d.isUndone).toList()
              : <Delivery>[];
          final recentBalls = matchDeliveries.reversed.take(4).toList().reversed.toList();

          String statusText;
          Color statusColor;

          if (isLive) {
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

                  // Result / Target Status String & Recent Balls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          statusText,
                          style: TextStyle(color: statusColor, fontSize: 10.5, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (recentBalls.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: recentBalls.map((d) {
                            final label = _getDeliveryLabel(d);
                            final isW = d.isWicket;
                            final isBdry = d.runsBatter == 4 || d.runsBatter == 6;
                            return Container(
                              margin: const EdgeInsets.only(left: 3),
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: isW
                                    ? const Color(0xFFDC2626)
                                    : (isBdry
                                        ? (d.runsBatter == 6 ? const Color(0xFF7C3AED) : const Color(0xFF0284C7))
                                        : const Color(0xFF374151)),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                label,
                                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
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
  // TOURNAMENT SEARCH & FILTER BAR
  // =========================================================================
  Widget _buildTournamentSearchBar(BuildContext context, MockDatabase db, List<Tournament> activeTournaments) {
    final query = _tournamentSearchController.text.trim();
    final hasFilter = query.isNotEmpty || _selectedTournamentId != 'all';

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search Input
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasFilter ? const Color(0xFF00F5A0) : const Color(0xFF374151),
                width: hasFilter ? 1.4 : 1,
              ),
              boxShadow: hasFilter
                  ? [
                      BoxShadow(
                        color: const Color(0xFF00F5A0).withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: TextField(
              controller: _tournamentSearchController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search live matches & results by tournament (e.g. BPL, IPL)...',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF00F5A0), size: 18),
                suffixIcon: hasFilter
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white60, size: 16),
                        tooltip: 'Clear filter',
                        onPressed: () {
                          setState(() {
                            _tournamentSearchController.clear();
                            _selectedTournamentId = 'all';
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          // Horizontal Tournament Filter Chips
          if (activeTournaments.isNotEmpty) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTournamentChip(
                    id: 'all',
                    name: 'All Tournaments',
                    matchCount: db.matches.length,
                    hasLive: db.matches.any((m) => m.status == MatchStatus.live),
                    isSelected: _selectedTournamentId == 'all' && query.isEmpty,
                    onTap: () {
                      setState(() {
                        _selectedTournamentId = 'all';
                        _tournamentSearchController.clear();
                      });
                    },
                  ),
                  ...activeTournaments.map((tourn) {
                    final tourMatches = db.matches.where((m) => m.tournamentId == tourn.id).toList();
                    final hasLive = tourMatches.any((m) => m.status == MatchStatus.live);
                    final isSelected = _selectedTournamentId == tourn.id;

                    return _buildTournamentChip(
                      id: tourn.id,
                      name: tourn.shortName.isNotEmpty ? tourn.shortName : tourn.name,
                      fullName: tourn.name,
                      matchCount: tourMatches.length,
                      hasLive: hasLive,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          _selectedTournamentId = isSelected ? 'all' : tourn.id;
                          _tournamentSearchController.clear();
                        });
                      },
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTournamentChip({
    required String id,
    required String name,
    String? fullName,
    required int matchCount,
    required bool hasLive,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF009270) : const Color(0xFF1F2937),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF00F5A0)
                  : (hasLive ? const Color(0xFFEF4444).withValues(alpha: 0.6) : const Color(0xFF374151)),
              width: hasLive || isSelected ? 1.2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF009270).withValues(alpha: 0.3),
                      blurRadius: 6,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasLive) ...[
                const PulsingLiveDot(color: Color(0xFFEF4444), size: 6.5),
                const SizedBox(width: 5),
              ],
              Text(
                name,
                style: TextStyle(
                  color: isSelected ? Colors.white : (hasLive ? Colors.white : Colors.white70),
                  fontSize: 11,
                  fontWeight: isSelected || hasLive ? FontWeight.bold : FontWeight.w500,
                ),
              ),
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withValues(alpha: 0.2) : Colors.black26,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  hasLive ? 'LIVE' : '$matchCount',
                  style: TextStyle(
                    color: isSelected ? Colors.white : (hasLive ? const Color(0xFFEF4444) : Colors.white54),
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // TAB BODY CONTENT
  // =========================================================================
  Widget _buildFeedBody({
    required BuildContext context,
    required MockDatabase db,
    required List<MatchModel> liveMatches,
    required Auction? liveAuction,
    required AuctionLot? currentLot,
    required Player? lotPlayer,
    required Team? highBidder,
    required bool isAuctionHost,
    required bool isTeamOwner,
    required List<MatchModel> pastMatches,
    required List<MatchModel> upcomingMatches,
    required String searchQuery,
    required String filterTitle,
  }) {
    final hasSearchFilter = searchQuery.isNotEmpty || _selectedTournamentId != 'all';

    if (selectedFilter == 'featured' || selectedFilter == 'live') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Live Matches Section (Handles multiple simultaneous live matches)
          if (liveMatches.isNotEmpty) ...[
            if (liveMatches.length > 1 || hasSearchFilter)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const PulsingLiveDot(color: Color(0xFFEF4444), size: 7.5),
                        const SizedBox(width: 6),
                        Text(
                          hasSearchFilter
                              ? '${liveMatches.length} LIVE IN $filterTitle'.toUpperCase()
                              : '${liveMatches.length} MATCHES LIVE NOW',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                    if (hasSearchFilter)
                      InkWell(
                        onTap: () {
                          setState(() {
                            _tournamentSearchController.clear();
                            _selectedTournamentId = 'all';
                          });
                        },
                        child: const Text(
                          'Show All Live',
                          style: TextStyle(color: Color(0xFF00F5A0), fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ),
            ...liveMatches.map((lm) {
              final inn1 = db.inningsList.where((i) => i.matchId == lm.id && i.inningsNumber == 1).firstOrNull;
              final inn2 = db.inningsList.where((i) => i.matchId == lm.id && i.inningsNumber == 2).firstOrNull;
              final activeInn = inn2 ?? inn1;
              final teamA = db.getTeam(lm.teamAId) ?? MockDatabase.emptyTeam;
              final teamB = db.getTeam(lm.teamBId) ?? MockDatabase.emptyTeam;
              final striker = activeInn != null ? db.getPlayer(activeInn.currentStrikerId) : null;
              final nonStriker = activeInn != null ? db.getPlayer(activeInn.currentNonStrikerId) : null;
              final bowler = activeInn != null ? db.getPlayer(activeInn.currentBowlerId) : null;

              final strikerCard = db.battingScorecards
                  .where((b) => b.inningsId == activeInn?.id && b.playerId == striker?.id)
                  .firstOrNull;
              final nonStrikerCard = db.battingScorecards
                  .where((b) => b.inningsId == activeInn?.id && b.playerId == nonStriker?.id)
                  .firstOrNull;
              final bowlerCard = db.bowlingScorecards
                  .where((b) => b.inningsId == activeInn?.id && b.playerId == bowler?.id)
                  .firstOrNull;

              if (activeInn == null) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _buildCricbuzzLiveScorecard(
                  context,
                  db,
                  lm,
                  activeInn,
                  teamA,
                  teamB,
                  striker,
                  nonStriker,
                  bowler,
                  strikerCard,
                  nonStrikerCard,
                  bowlerCard,
                ),
              );
            }),
          ] else if (selectedFilter == 'live') ...[
            _buildEmptyStateCard(
              title: hasSearchFilter ? 'No Live Matches for "$filterTitle"' : 'No Live Matches',
              subtitle: hasSearchFilter
                  ? 'There are currently no matches in progress for this tournament. Try clearing your search.'
                  : 'Start scoring an upcoming fixture with Room ID & PIN to broadcast live.',
              actionLabel: hasSearchFilter ? 'Show All Matches' : '+ Conduct Toss & Score',
              onAction: () {
                if (hasSearchFilter) {
                  setState(() {
                    _tournamentSearchController.clear();
                    _selectedTournamentId = 'all';
                  });
                } else {
                  widget.onTabChange(1);
                }
              },
            ),
            const SizedBox(height: 14),
          ],

          // Live Auction Spotlight
          if (liveAuction != null && !hasSearchFilter) ...[
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

          // Featured public feed: Show Match Results & Upcoming Fixtures
          if (selectedFilter == 'featured') ...[
            if (pastMatches.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      hasSearchFilter
                          ? 'MATCH RESULTS • ${filterTitle.toUpperCase()}'
                          : 'MATCH RESULTS',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    onTap: () => widget.onTabChange(2),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View All Results',
                          style: TextStyle(color: Color(0xFF00F5A0), fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 2),
                        Icon(Icons.chevron_right, size: 14, color: Color(0xFF00F5A0)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...pastMatches.take(5).map((pm) => _buildPastMatchCard(context, db, pm)),
              const SizedBox(height: 12),
            ] else if (hasSearchFilter && liveMatches.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2937),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'No completed matches yet for $filterTitle. See live match in progress above.',
                  style: const TextStyle(color: Colors.white60, fontSize: 11.5),
                ),
              ),
            ],

            if (upcomingMatches.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      hasSearchFilter
                          ? 'UPCOMING FIXTURES • ${filterTitle.toUpperCase()}'
                          : 'UPCOMING FIXTURES',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() => selectedFilter = 'upcoming');
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View All',
                          style: TextStyle(color: Color(0xFF00F5A0), fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 2),
                        Icon(Icons.chevron_right, size: 14, color: Color(0xFF00F5A0)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...upcomingMatches.take(2).map((um) => _buildUpcomingFixtureCard(context, db, um)),
            ],

            if (liveMatches.isEmpty && pastMatches.isEmpty && upcomingMatches.isEmpty) ...[
              if (hasSearchFilter)
                _buildEmptySearchResultsCard(context, searchQuery)
              else if (liveAuction == null)
                _buildEmptyStateCard(
                  title: 'Welcome to CricPavilion Pro',
                  subtitle: 'No live matches or auctions at this moment. Match results and active auctions will appear here automatically.',
                  actionLabel: 'Organize Match / Tournament',
                  onAction: () => OrganizeHubModal.show(context),
                ),
            ],
          ],
        ],
      );
    }

    if (selectedFilter == 'upcoming') {
      if (upcomingMatches.isEmpty) {
        return _buildEmptyStateCard(
          title: hasSearchFilter ? 'No Upcoming Fixtures for "$filterTitle"' : 'No Upcoming Fixtures',
          subtitle: hasSearchFilter
              ? 'No upcoming matches match your tournament filter.'
              : 'Create a tournament to automatically generate match schedules and fixtures.',
          actionLabel: hasSearchFilter ? 'Clear Filter' : '+ Create Tournament',
          onAction: () {
            if (hasSearchFilter) {
              setState(() {
                _tournamentSearchController.clear();
                _selectedTournamentId = 'all';
              });
            } else {
              showDialog(
                context: context,
                builder: (ctx) => CreateTournamentDialog(db: db),
              );
            }
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
          title: hasSearchFilter ? 'No Match Results for "$filterTitle"' : 'No Recent Matches',
          subtitle: hasSearchFilter
              ? 'No completed match results found for this tournament search.'
              : 'Matches that finish live scoring will display their official certified scorecards here.',
          actionLabel: hasSearchFilter ? 'Show All Results' : 'Go to Scorer',
          onAction: () {
            if (hasSearchFilter) {
              setState(() {
                _tournamentSearchController.clear();
                _selectedTournamentId = 'all';
              });
            } else {
              widget.onTabChange(1);
            }
          },
        );
      }
      return Column(
        children: pastMatches.map((pm) => _buildPastMatchCard(context, db, pm)).toList(),
      );
    }

    if (selectedFilter == 'auctions') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Quick Join with PIN bar
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const JoinAuctionScreen()),
              );
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.vpn_key, color: Colors.amberAccent, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Have a 6-digit PIN? Join live franchise auction here',
                      style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.amberAccent, size: 16),
                ],
              ),
            ),
          ),
          if (db.auctions.isEmpty)
            _buildEmptyStateCard(
              title: 'No Player Auctions Created',
              subtitle: 'Host an auction with 8 franchise teams, budget limits, player wheel spin, and live bidding.',
              actionLabel: '+ Host New Auction',
              onAction: () {
                showDialog(
                  context: context,
                  builder: (ctx) => CreateAuctionDialog(db: db),
                );
              },
            )
          else
            ...db.auctions.map((auc) => _buildAuctionDirectoryCard(context, db, auc)),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildEmptySearchResultsCard(BuildContext context, String query) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF374151)),
      ),
      child: Column(
        children: [
          const Icon(Icons.search_off, size: 44, color: Colors.amberAccent),
          const SizedBox(height: 12),
          Text(
            query.isNotEmpty ? 'No matches found for "$query"' : 'No matches found for selected tournament',
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            'Try searching for another tournament name like "BPL" or "IPL", or select "All Tournaments".',
            style: TextStyle(color: Colors.white60, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _tournamentSearchController.clear();
                _selectedTournamentId = 'all';
              });
            },
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Show All Tournaments & Matches'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF009270),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
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
    final tourn = db.getTournament(match.tournamentId);
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
                    if (tourn != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF009270).withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFF009270), width: 0.8),
                        ),
                        child: Text(
                          tourn.shortName.isNotEmpty ? tourn.shortName.toUpperCase() : tourn.name.toUpperCase(),
                          style: const TextStyle(color: Color(0xFF00F5A0), fontSize: 9.5, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                    Text(
                      '${match.stage.toUpperCase()} • LIVE',
                      style: const TextStyle(color: Color(0xFFEF4444), fontSize: 11, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                Flexible(
                  child: Text(
                    tourn != null ? '${tourn.name} • ${match.venue}' : match.venue,
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
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
                        onPressed: () => _openFullScorecard(context, db, match),
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
    final isLive = auction.status == AuctionStatus.live;
    final activePrice = currentLot?.currentBid ?? currentLot?.startingPrice ?? currentLot?.basePrice ?? 500000;
    final formattedPrice = currencyFormat.format(activePrice);
    final totalLots = auction.totalLots;
    final registeredTeams = auction.joinedTeamIds.length;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isLive ? Colors.amber.shade700 : const Color(0xFF374151),
          width: isLive ? 1.5 : 1,
        ),
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
                    Icon(
                      Icons.gavel,
                      size: 14,
                      color: isLive ? Colors.amberAccent : const Color(0xFF00F5A0),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      auction.title.toUpperCase(),
                      style: TextStyle(
                        color: isLive ? Colors.amberAccent : Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isLive
                        ? Colors.amber.withValues(alpha: 0.2)
                        : const Color(0xFF00F5A0).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isLive ? 'LIVE AUCTION' : 'UPCOMING AUCTION',
                    style: TextStyle(
                      color: isLive ? Colors.amberAccent : const Color(0xFF00F5A0),
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                if (isLive && player != null)
                  CircleAvatar(
                    radius: 26,
                    backgroundImage: NetworkImage(
                      player.photoUrl.isNotEmpty
                          ? player.photoUrl
                          : 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=256',
                    ),
                  )
                else
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFF111827),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                    ),
                    child: const Icon(Icons.gavel_rounded, color: Colors.amberAccent, size: 24),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isLive
                            ? (player?.fullName ?? 'Player Lot on Stage')
                            : 'Franchise Player Auction',
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isLive
                            ? '${player?.roleString ?? "Player"} • Base: ${currencyFormat.format(currentLot?.basePrice ?? 500000)}'
                            : '$registeredTeams Teams • $totalLots Player Lots • Purse: ${currencyFormat.format(auction.maxPursePerTeam)}',
                        style: const TextStyle(color: Colors.white60, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isLive
                            ? (highBidder != null
                                ? 'High Bid: $formattedPrice (${highBidder.name})'
                                : 'Opening Price: $formattedPrice • No bids yet')
                            : 'Room PIN Protected • Floor ready to host',
                        style: TextStyle(
                          color: isLive ? Colors.amberAccent : const Color(0xFF00F5A0),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AuctionScreen()),
                    );
                  },
                  icon: Icon(
                    isHost ? Icons.gavel : (isOwner ? Icons.vpn_key : Icons.visibility),
                    size: 13,
                    color: Colors.black,
                  ),
                  label: Text(
                    isHost ? 'Host Floor' : (isOwner ? 'Bid' : (isLive ? 'Watch Live' : 'Open Arena')),
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
    final tourn = db.getTournament(pm.tournamentId);

    final lastInn = inn2 ?? inn1;
    final pastDeliveries = lastInn != null
        ? db.deliveries.where((d) => d.matchId == pm.id && d.inningsId == lastInn.id && !d.isUndone).toList()
        : <Delivery>[];
    final closingBalls = pastDeliveries.reversed.take(6).toList().reversed.toList();

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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (tourn != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF009270).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFF009270), width: 0.8),
                      ),
                      child: Text(
                        tourn.shortName.isNotEmpty ? tourn.shortName.toUpperCase() : tourn.name.toUpperCase(),
                        style: const TextStyle(color: Color(0xFF00F5A0), fontSize: 9.5, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                  Text('${pm.stage} • RESULT', style: const TextStyle(color: Color(0xFF009270), fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
              Flexible(
                child: Text(
                  tourn != null ? '${tourn.name} • ${pm.venue}' : pm.venue,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
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
          if (closingBalls.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Recent Balls: ', style: TextStyle(color: Colors.white54, fontSize: 10.5, fontWeight: FontWeight.bold)),
                const SizedBox(width: 4),
                Wrap(
                  spacing: 4,
                  children: closingBalls.map((d) => _buildBallBadge(_getDeliveryLabel(d))).toList(),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _openFullScorecard(context, db, pm),
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
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AuctionScreen()),
                  );
                },
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
    if (d.extrasType == ExtrasType.noBall) {
      return d.runsBatter > 0 ? 'Nb+${d.runsBatter}' : '${d.totalRuns}Nb';
    }
    if (d.extrasType == ExtrasType.bye) return '${d.totalRuns}B';
    if (d.extrasType == ExtrasType.legBye) return '${d.totalRuns}Lb';
    return '${d.runsBatter}';
  }
}

