import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/mock_database.dart';
import '../../theme/neo_glass_theme.dart';
import '../../widgets/role_switcher_chip.dart';
import '../../widgets/app_animations.dart';
import '../scorer/scorer_screen.dart';
import '../scorer/fill_team_squad_dialog.dart';
import '../matches/match_detail_screen.dart';
import 'create_tournament_dialog.dart';

class TournamentHubScreen extends StatefulWidget {
  final String? initialTournamentId;

  const TournamentHubScreen({super.key, this.initialTournamentId});

  @override
  State<TournamentHubScreen> createState() => _TournamentHubScreenState();
}

class _TournamentHubScreenState extends State<TournamentHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedTournamentId;

  // Match sub-filter: 'all', 'live', 'upcoming', 'past'
  String _matchFilter = 'all';

  // Leaderboard category: 'runs', 'wickets', 'catches', 'boundaries', 'mvp'
  String _leaderboardFilter = 'runs';

  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  final dateFormat = DateFormat('EEE, dd MMM yyyy • hh:mm a');

  @override
  void initState() {
    super.initState();
    _selectedTournamentId = widget.initialTournamentId;
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final db = context.watch<MockDatabase>();

    final tournaments = db.tournaments;
    if (tournaments.isEmpty) {
      return Scaffold(
        backgroundColor: NeoGlassTheme.bgCanvas,
        appBar: AppBar(
          backgroundColor: NeoGlassTheme.bgSurface,
          elevation: 0,
          shape: const Border(bottom: BorderSide(color: Color(0x18FFFFFF))),
          title: const Text('Tournament Hub', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
          actions: const [
            RoleSwitcherChip(compact: true),
            SizedBox(width: 8),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.emoji_events, size: 54, color: Color(0xFF009270)),
                const SizedBox(height: 16),
                const Text('No Tournaments Created Yet', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text(
                  'Organize a tournament to set up your teams, schedule matches, and begin live ball-by-ball scoring.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => CreateTournamentDialog(db: db),
                    );
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Organize Tournament Now', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF009270),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final activeTourn = tournaments.where((t) => t.id == _selectedTournamentId).firstOrNull ??
        tournaments.first;

    final isCreator = db.createdTournamentIds.contains(activeTourn.id);
    final isUnlocked = db.authenticatedTournamentIds.contains(activeTourn.id);
    final canScore = isCreator || isUnlocked || db.canManageTournaments || db.canScoreMatches;

    return Scaffold(
      backgroundColor: NeoGlassTheme.bgCanvas,
      appBar: AppBar(
        backgroundColor: NeoGlassTheme.bgSurface,
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: Color(0x18FFFFFF))),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              activeTourn.name,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
            Row(
              children: [
                const Icon(Icons.location_on, size: 10, color: Colors.white70),
                const SizedBox(width: 3),
                Text(
                  '${activeTourn.location} • ${activeTourn.overs} Overs',
                  style: const TextStyle(fontSize: 10, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        actions: [
          const RoleSwitcherChip(compact: true),
          const SizedBox(width: 4),
          if (canScore)
            IconButton(
              tooltip: 'Edit Format & Tournament',
              icon: const Icon(Icons.tune, color: Colors.amberAccent, size: 20),
              onPressed: () => _showEditTournamentDialog(context, db, activeTourn),
            ),
          IconButton(
            tooltip: 'Organize New Tournament',
            icon: const Icon(Icons.add_circle, color: Colors.white, size: 22),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => CreateTournamentDialog(db: db),
              );
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Horizontal Tournament Switcher
                  _buildTournamentSwitcher(db, activeTourn),

                  // 2. Tournament Branding Banner & Stats Card
                  _buildTournamentBanner(context, db, activeTourn, isCreator, isUnlocked, canScore),

                  // 3. 4 CricHeroes Sub-Tabs Bar
                  Container(
                    color: NeoGlassTheme.bgSurface,
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: NeoGlassTheme.neonEmerald,
                      indicatorWeight: 3,
                      labelColor: NeoGlassTheme.neonEmerald,
                      unselectedLabelColor: Colors.white60,
                      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      tabs: const [
                        Tab(text: 'Matches', icon: Icon(Icons.sports_cricket, size: 16)),
                        Tab(text: 'Leaderboard', icon: Icon(Icons.leaderboard, size: 16)),
                        Tab(text: 'Points Table', icon: Icon(Icons.table_chart, size: 16)),
                        Tab(text: 'Teams', icon: Icon(Icons.groups, size: 16)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // TAB 1: Matches (Live, Upcoming, Past)
            _buildMatchesTab(context, db, activeTourn, canScore),

            // TAB 2: Leaderboard (Runs, Wickets, Catches, 4s & 6s, MVP)
            _buildLeaderboardTab(context, db, activeTourn),

            // TAB 3: Points Table (ICC compliant with NRR)
            _buildPointsTableTab(context, db, activeTourn),

            // TAB 4: Teams & Squads
            _buildTeamsTab(context, db, activeTourn),
          ],
        ),
      ),
      floatingActionButton: canScore
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFF009270),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Schedule Match', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              onPressed: () => _showScheduleMatchDialog(context, db, activeTourn),
            )
          : null,
    );
  }

  // =========================================================================
  // 1. TOURNAMENT SWITCHER
  // =========================================================================
  Widget _buildTournamentSwitcher(MockDatabase db, Tournament activeTourn) {
    return Container(
      color: const Color(0xFF1F2937),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ...db.tournaments.map((t) {
              final isSelected = t.id == activeTourn.id;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  selected: isSelected,
                  label: Text('${t.shortName} (${t.overs} Ov)'),
                  selectedColor: const Color(0xFF009270),
                  backgroundColor: const Color(0xFF111827),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _selectedTournamentId = t.id);
                  },
                ),
              );
            }),
            ActionChip(
              avatar: const Icon(Icons.add, size: 14, color: Color(0xFF34D399)),
              label: const Text('New Tournament', style: TextStyle(fontSize: 11, color: Color(0xFF34D399), fontWeight: FontWeight.bold)),
              backgroundColor: const Color(0xFF064E3B).withValues(alpha: 0.3),
              side: const BorderSide(color: Color(0xFF059669)),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => CreateTournamentDialog(db: db),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // 2. TOURNAMENT BRANDING BANNER
  // =========================================================================
  Widget _buildTournamentBanner(
    BuildContext context,
    MockDatabase db,
    Tournament activeTourn,
    bool isCreator,
    bool isUnlocked,
    bool canScore,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF064E3B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner Image & Title Area
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: Image.network(
                  activeTourn.bannerUrl,
                  height: 110,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 110,
                    color: const Color(0xFF064E3B),
                    child: const Center(child: Icon(Icons.emoji_events, size: 40, color: Color(0xFF34D399))),
                  ),
                ),
              ),
              Container(
                height: 110,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  gradient: LinearGradient(
                    colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent, Colors.black.withValues(alpha: 0.85)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Positioned(
                left: 14,
                bottom: 10,
                right: 14,
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF009270),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          activeTourn.shortName.length > 3 ? activeTourn.shortName.substring(0, 3) : activeTourn.shortName,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activeTourn.name,
                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${activeTourn.location} • Match Format: ${activeTourn.overs} Overs',
                            style: const TextStyle(color: Colors.white70, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF34D399)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.vpn_key, size: 10, color: Color(0xFF34D399)),
                      const SizedBox(width: 4),
                      Text(
                        'Room: ${activeTourn.roomId.isNotEmpty ? activeTourn.roomId : "TOURN-${activeTourn.shortName}"}',
                        style: const TextStyle(color: Color(0xFF34D399), fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '• PIN: ${activeTourn.passcode}',
                        style: const TextStyle(color: Colors.amberAccent, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Control Strip & Organizer Permission Status
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: canScore ? const Color(0xFF059669).withValues(alpha: 0.3) : Colors.white10,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: canScore ? const Color(0xFF34D399) : Colors.white30),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            canScore ? Icons.verified_user : Icons.visibility,
                            size: 12,
                            color: canScore ? const Color(0xFF34D399) : Colors.white70,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isCreator
                                ? 'Organized by You (Full Control)'
                                : canScore
                                    ? 'Scorer Access Authorized'
                                    : 'Public Spectator (View Only)',
                            style: TextStyle(
                              color: canScore ? const Color(0xFF34D399) : Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (!canScore)
                      ElevatedButton.icon(
                        onPressed: () => _showUnlockDialog(context, db, activeTourn),
                        icon: const Icon(Icons.vpn_key, size: 12),
                        label: const Text('Unlock Scorer Mode', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _showEditTournamentDialog(context, db, activeTourn),
                            icon: const Icon(Icons.tune, size: 11, color: Colors.amberAccent),
                            label: const Text('Edit Format', style: TextStyle(color: Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.amberAccent),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _showScheduleMatchDialog(context, db, activeTourn),
                            icon: const Icon(Icons.calendar_today, size: 11, color: Colors.white),
                            label: const Text('+ Match', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF34D399)),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _showAddTeamDialog(context, db, activeTourn),
                            icon: const Icon(Icons.group_add, size: 11, color: Colors.white),
                            label: const Text('+ Team', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white38),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            ),
                          ),
                        ],
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

  // =========================================================================
  // TAB 1: MATCHES (Live, Upcoming, Past)
  // =========================================================================
  Widget _buildMatchesTab(BuildContext context, MockDatabase db, Tournament tourn, bool canScore) {
    final tournMatches = db.matches.where((m) => m.tournamentId == tourn.id).toList();

    final filtered = tournMatches.where((m) {
      if (_matchFilter == 'live') return m.status == MatchStatus.live;
      if (_matchFilter == 'upcoming') return m.status == MatchStatus.scheduled || m.status == MatchStatus.toss;
      if (_matchFilter == 'past') return m.status == MatchStatus.completed;
      return true;
    }).toList();

    return Column(
      children: [
        // Sub-filter tabs (CricHeroes style: Live, Upcoming, Past)
        Container(
          color: const Color(0xFF1E293B),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              _buildFilterPill('All (${tournMatches.length})', 'all'),
              const SizedBox(width: 6),
              _buildFilterPill('Live (${tournMatches.where((m) => m.status == MatchStatus.live).length})', 'live'),
              const SizedBox(width: 6),
              _buildFilterPill('Upcoming (${tournMatches.where((m) => m.status == MatchStatus.scheduled || m.status == MatchStatus.toss).length})', 'upcoming'),
              const SizedBox(width: 6),
              _buildFilterPill('Past (${tournMatches.where((m) => m.status == MatchStatus.completed).length})', 'past'),
            ],
          ),
        ),

        // Matches list
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.event_busy, size: 42, color: Colors.white38),
                        const SizedBox(height: 10),
                        Text(
                          'No ${_matchFilter.toUpperCase()} matches found for ${tourn.shortName}',
                          style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        if (canScore)
                          ElevatedButton.icon(
                            onPressed: () => _showScheduleMatchDialog(context, db, tourn),
                            icon: const Icon(Icons.add, size: 14),
                            label: const Text('Schedule Match Now', style: TextStyle(fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF009270), foregroundColor: Colors.white),
                          ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, index) {
                    final m = filtered[index];
                    return _buildMatchCard(context, db, m, canScore);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterPill(String label, String value) {
    final isSelected = _matchFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _matchFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF009270) : const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? const Color(0xFF34D399) : Colors.white24),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildMatchCard(BuildContext context, MockDatabase db, MatchModel m, bool canScore) {
    final teamA = db.getTeam(m.teamAId) ?? MockDatabase.emptyTeam;
    final teamB = db.getTeam(m.teamBId) ?? MockDatabase.emptyTeam;
    final inn1 = db.inningsList.where((i) => i.matchId == m.id && i.inningsNumber == 1).firstOrNull;
    final inn2 = db.inningsList.where((i) => i.matchId == m.id && i.inningsNumber == 2).firstOrNull;

    final isLive = m.status == MatchStatus.live;
    final isCompleted = m.status == MatchStatus.completed;

    return Card(
      color: const Color(0xFF1F2937),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isLive ? const Color(0xFF10B981) : const Color(0xFF374151),
          width: isLive ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Stage & Status row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    m.stage,
                    style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isLive)
                  const PulsingLiveBadge(label: 'LIVE SCORING', color: Color(0xFFEF4444))
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? Colors.white10
                          : const Color(0xFF0284C7).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isCompleted
                            ? Colors.white30
                            : const Color(0xFF38BDF8),
                      ),
                    ),
                    child: Text(
                      isCompleted ? 'RESULT' : 'UPCOMING',
                      style: TextStyle(
                        color: isCompleted
                            ? Colors.white70
                            : const Color(0xFF38BDF8),
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Team A Row
            Row(
              children: [
                CircleAvatar(radius: 12, backgroundImage: NetworkImage(teamA.logoUrl)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    teamA.name,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
                if (inn1 != null)
                  Text(
                    '${inn1.totalRuns}/${inn1.wickets} (${inn1.oversStr} ov)',
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900),
                  ),
              ],
            ),
            const SizedBox(height: 6),

            // Team B Row
            Row(
              children: [
                CircleAvatar(radius: 12, backgroundImage: NetworkImage(teamB.logoUrl)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    teamB.name,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
                if (inn2 != null)
                  Text(
                    '${inn2.totalRuns}/${inn2.wickets} (${inn2.oversStr} ov)',
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Match Result / Timing info
            Text(
              isCompleted
                  ? (m.winMargin != null ? '${db.getTeam(m.winnerId ?? "")?.name ?? "Winner"} won by ${m.winMargin}' : 'Match Completed')
                  : isLive
                      ? 'Live ball-by-ball scoring active'
                      : dateFormat.format(m.dateTime),
              style: TextStyle(
                color: isCompleted ? Colors.amberAccent : (isLive ? const Color(0xFF34D399) : Colors.white54),
                fontSize: 11,
                fontWeight: isCompleted || isLive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 10),

            // Buttons
            Row(
              children: [
                // Ball-by-ball Scorer button for authorized user
                if (canScore) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (!db.areTeamsReadyForScoring(m.teamAId, m.teamBId)) {
                          showDialog(
                            context: context,
                            builder: (ctx) => FillTeamSquadDialog(
                              match: m,
                              db: db,
                              onSquadsSaved: () => setState(() {}),
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (ctx) => ScorerScreen(initialMatchId: m.id),
                            ),
                          );
                        }
                      },
                      icon: Icon(
                        !db.areTeamsReadyForScoring(m.teamAId, m.teamBId)
                            ? Icons.phonelink_lock
                            : Icons.radio_button_checked,
                        size: 14,
                      ),
                      label: Text(
                        !db.areTeamsReadyForScoring(m.teamAId, m.teamBId)
                            ? 'Fill Players to Score'
                            : (isLive ? '🔴 Live Scorer Console' : 'Start Scoring'),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: !db.areTeamsReadyForScoring(m.teamAId, m.teamBId)
                            ? Colors.amber.shade800
                            : const Color(0xFF009270),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                // Public Scorecard / Spectator Viewer
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (ctx) => MatchDetailScreen(matchId: m.id),
                        ),
                      );
                    },
                    icon: const Icon(Icons.scoreboard_outlined, size: 14),
                    label: const Text('View Scorecard', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white30),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // TAB 2: LEADERBOARD (Orange Cap, Purple Cap, Catches, 4s & 6s, MVP)
  // =========================================================================
  Widget _buildLeaderboardTab(BuildContext context, MockDatabase db, Tournament tourn) {
    return Column(
      children: [
        // Category Filter Chips (CricHeroes Style)
        Container(
          color: const Color(0xFF1E293B),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildLeaderboardChip('🏏 Most Runs (Orange Cap)', 'runs'),
                const SizedBox(width: 6),
                _buildLeaderboardChip('🎯 Most Wickets (Purple Cap)', 'wickets'),
                const SizedBox(width: 6),
                _buildLeaderboardChip('🧤 Most Catches', 'catches'),
                const SizedBox(width: 6),
                _buildLeaderboardChip('💥 4s & 6s Tracker', 'boundaries'),
                const SizedBox(width: 6),
                _buildLeaderboardChip('⭐ Tournament MVP', 'mvp'),
              ],
            ),
          ),
        ),

        // Leaderboard Content
        Expanded(
          child: Builder(
            builder: (ctx) {
              switch (_leaderboardFilter) {
                case 'runs':
                  return _buildBattersLeaderboard(db, tourn);
                case 'wickets':
                  return _buildBowlersLeaderboard(db, tourn);
                case 'catches':
                  return _buildFieldersLeaderboard(db, tourn);
                case 'boundaries':
                  return _buildBoundariesLeaderboard(db, tourn);
                case 'mvp':
                  return _buildMVPLeaderboard(db, tourn);
                default:
                  return _buildBattersLeaderboard(db, tourn);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardChip(String label, String value) {
    final isSelected = _leaderboardFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _leaderboardFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF009270) : const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? const Color(0xFF34D399) : Colors.white24),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // --- TOP BATTERS (ORANGE CAP) ---
  Widget _buildBattersLeaderboard(MockDatabase db, Tournament tourn) {
    final list = db.getTournamentTopBatters(tourn.id);
    if (list.isEmpty) {
      return _buildEmptyLeaderboardState('No batting statistics recorded yet for this tournament. Start ball-by-ball scoring to populate Orange Cap leaderboards!');
    }

    final leader = list.first;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // #1 Orange Cap Hero Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFEA580C), Color(0xFF9A3412)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFDBA74)),
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(radius: 28, backgroundImage: NetworkImage(leader.photoUrl)),
                  const Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 10,
                      backgroundColor: Colors.white,
                      child: Text('🧢', style: TextStyle(fontSize: 11)),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(4)),
                          child: const Text('ORANGE CAP LEADER', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
                        ),
                        const SizedBox(width: 6),
                        Text(leader.teamShortName, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(leader.playerName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 3),
                    Text(
                      'SR: ${leader.strikeRate.toStringAsFixed(1)} • 4s: ${leader.fours} • 6s: ${leader.sixes} • HS: ${leader.highScore}',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${leader.runs}', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                  const Text('RUNS', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Table Header
        _buildTableHeader(['Rank & Player', 'M/Inn', 'Runs', 'SR', '4s/6s']),

        // Leaderboard List
        ...list.asMap().entries.map((entry) {
          final rank = entry.key + 1;
          final b = entry.value;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: rank % 2 == 0 ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 22,
                  child: Text('$rank', style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                CircleAvatar(radius: 12, backgroundImage: NetworkImage(b.photoUrl)),
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(b.playerName, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                      Text(b.teamShortName, style: const TextStyle(color: Colors.white54, fontSize: 10)),
                    ],
                  ),
                ),
                Expanded(flex: 2, child: Text('${b.matches}/${b.innings}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 11))),
                Expanded(flex: 2, child: Text('${b.runs}', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF34D399), fontSize: 12, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text(b.strikeRate.toStringAsFixed(1), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 11))),
                Expanded(flex: 2, child: Text('${b.fours}/${b.sixes}', textAlign: TextAlign.right, style: const TextStyle(color: Colors.white70, fontSize: 11))),
              ],
            ),
          );
        }),
      ],
    );
  }

  // --- TOP BOWLERS (PURPLE CAP) ---
  Widget _buildBowlersLeaderboard(MockDatabase db, Tournament tourn) {
    final list = db.getTournamentTopBowlers(tourn.id);
    if (list.isEmpty) {
      return _buildEmptyLeaderboardState('No bowling statistics recorded yet for this tournament. Start ball-by-ball scoring to populate Purple Cap leaderboards!');
    }

    final leader = list.first;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // #1 Purple Cap Hero Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFC084FC)),
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(radius: 28, backgroundImage: NetworkImage(leader.photoUrl)),
                  const Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 10,
                      backgroundColor: Colors.white,
                      child: Text('🧢', style: TextStyle(fontSize: 11)),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(4)),
                          child: const Text('PURPLE CAP LEADER', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
                        ),
                        const SizedBox(width: 6),
                        Text(leader.teamShortName, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(leader.playerName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 3),
                    Text(
                      'Overs: ${leader.oversStr} • Econ: ${leader.economy.toStringAsFixed(1)} • BBI: ${leader.bestBowling}',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${leader.wickets}', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                  const Text('WICKETS', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Table Header
        _buildTableHeader(['Rank & Player', 'Overs', 'Wkts', 'Econ', 'Best']),

        // Leaderboard List
        ...list.asMap().entries.map((entry) {
          final rank = entry.key + 1;
          final bo = entry.value;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: rank % 2 == 0 ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 22,
                  child: Text('$rank', style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                CircleAvatar(radius: 12, backgroundImage: NetworkImage(bo.photoUrl)),
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(bo.playerName, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                      Text(bo.teamShortName, style: const TextStyle(color: Colors.white54, fontSize: 10)),
                    ],
                  ),
                ),
                Expanded(flex: 2, child: Text(bo.oversStr, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 11))),
                Expanded(flex: 2, child: Text('${bo.wickets}', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFC084FC), fontSize: 12, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text(bo.economy.toStringAsFixed(1), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 11))),
                Expanded(flex: 2, child: Text(bo.bestBowling, textAlign: TextAlign.right, style: const TextStyle(color: Colors.white70, fontSize: 11))),
              ],
            ),
          );
        }),
      ],
    );
  }

  // --- TOP FIELDERS (MOST CATCHES) ---
  Widget _buildFieldersLeaderboard(MockDatabase db, Tournament tourn) {
    final list = db.getTournamentTopFielders(tourn.id);
    if (list.isEmpty) {
      return _buildEmptyLeaderboardState('No fielding dismissals recorded yet. When a batsman is caught or stumped during scoring, fielding stats update here!');
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _buildTableHeader(['Rank & Fielder', 'Team', 'Catches', 'Stumpings', 'Total']),
        ...list.asMap().entries.map((entry) {
          final rank = entry.key + 1;
          final f = entry.value;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: rank % 2 == 0 ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                SizedBox(width: 22, child: Text('$rank', style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold))),
                CircleAvatar(radius: 12, backgroundImage: NetworkImage(f.photoUrl)),
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: Text(f.playerName, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                ),
                Expanded(flex: 2, child: Text(f.teamShortName, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 11))),
                Expanded(flex: 2, child: Text('${f.catches}', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('${f.stumpings}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 11))),
                Expanded(flex: 2, child: Text('${f.totalDismissals}', textAlign: TextAlign.right, style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold))),
              ],
            ),
          );
        }),
      ],
    );
  }

  // --- BOUNDARY TRACKER (4s & 6s) ---
  Widget _buildBoundariesLeaderboard(MockDatabase db, Tournament tourn) {
    final list = db.getTournamentBoundaryLeaders(tourn.id);
    if (list.isEmpty) {
      return _buildEmptyLeaderboardState('No boundaries hit yet. Boundaries hit during live scoring are tracked here automatically!');
    }

    final totalFours = list.fold<int>(0, (sum, b) => sum + b.fours);
    final totalSixes = list.fold<int>(0, (sum, b) => sum + b.sixes);

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Summary Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF374151)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCounter('TOTAL FOURS', '$totalFours', const Color(0xFF38BDF8)),
              Container(width: 1, height: 35, color: Colors.white24),
              _buildStatCounter('TOTAL SIXES', '$totalSixes', const Color(0xFFF59E0B)),
              Container(width: 1, height: 35, color: Colors.white24),
              _buildStatCounter('BOUNDARY RUNS', '${(totalFours * 4) + (totalSixes * 6)}', const Color(0xFF34D399)),
            ],
          ),
        ),
        const SizedBox(height: 14),

        _buildTableHeader(['Rank & Batter', 'Team', 'Fours (4s)', 'Sixes (6s)', 'Total']),
        ...list.asMap().entries.map((entry) {
          final rank = entry.key + 1;
          final b = entry.value;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: rank % 2 == 0 ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                SizedBox(width: 22, child: Text('$rank', style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold))),
                CircleAvatar(radius: 12, backgroundImage: NetworkImage(b.photoUrl)),
                const SizedBox(width: 8),
                Expanded(flex: 4, child: Text(b.playerName, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                Expanded(flex: 2, child: Text(b.teamShortName, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 11))),
                Expanded(flex: 2, child: Text('${b.fours}', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('${b.sixes}', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 11, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('${b.totalBoundaries}', textAlign: TextAlign.right, style: const TextStyle(color: Color(0xFF34D399), fontSize: 12, fontWeight: FontWeight.bold))),
              ],
            ),
          );
        }),
      ],
    );
  }

  // --- TOURNAMENT MVP ---
  Widget _buildMVPLeaderboard(MockDatabase db, Tournament tourn) {
    final list = db.getTournamentMVPList(tourn.id);
    if (list.isEmpty) {
      return _buildEmptyLeaderboardState('No player statistics available to compute MVP points.');
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _buildTableHeader(['Rank & Player', 'Role', 'Runs', 'Wkts', 'Pts']),
        ...list.asMap().entries.map((entry) {
          final rank = entry.key + 1;
          final m = entry.value;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: rank % 2 == 0 ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                SizedBox(width: 22, child: Text('$rank', style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold))),
                CircleAvatar(radius: 12, backgroundImage: NetworkImage(m.photoUrl)),
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.playerName, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                      Text(m.teamShortName, style: const TextStyle(color: Colors.white54, fontSize: 10)),
                    ],
                  ),
                ),
                Expanded(flex: 2, child: Text(m.roleString, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 10))),
                Expanded(flex: 2, child: Text('${m.runs}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 11))),
                Expanded(flex: 2, child: Text('${m.wickets}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 11))),
                Expanded(flex: 2, child: Text(m.points.toStringAsFixed(1), textAlign: TextAlign.right, style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.w900))),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTableHeader(List<String> titles) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 22),
          const SizedBox(width: 32),
          Expanded(flex: 4, child: Text(titles[0], style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text(titles[1], textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text(titles[2], textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text(titles[3], textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text(titles[4], textAlign: TextAlign.right, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildStatCounter(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildEmptyLeaderboardState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.analytics_outlined, size: 48, color: Colors.white38),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // TAB 3: ICC POINTS TABLE
  // =========================================================================
  Widget _buildPointsTableTab(BuildContext context, MockDatabase db, Tournament tourn) {
    final standings = db.getTournamentStandings(tourn.id);

    if (standings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white12),
                ),
                child: const Icon(Icons.leaderboard_outlined, size: 28, color: Colors.white38),
              ),
              const SizedBox(height: 14),
              const Text('No Standings Yet', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text(
                'Add teams in the Teams tab and schedule matches to compute tournament standings and Net Run Rate (NRR).',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Standings Card Table
        Card(
          color: const Color(0xFF1E293B),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFF0F172A),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: const Row(
                  children: [
                    Expanded(flex: 5, child: Text('Team', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold))),
                    Expanded(flex: 1, child: Text('P', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold))),
                    Expanded(flex: 1, child: Text('W', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold))),
                    Expanded(flex: 1, child: Text('L', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold))),
                    Expanded(flex: 2, child: Text('PTS', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold))),
                    Expanded(flex: 2, child: Text('NRR', textAlign: TextAlign.right, style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold))),
                  ],
                ),
              ),

              // Team Rows
              ...standings.asMap().entries.map((entry) {
                final rank = entry.key + 1;
                final s = entry.value;
                final isTop4 = rank <= 4;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isTop4 ? const Color(0xFF059669).withValues(alpha: 0.05) : Colors.transparent,
                    border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Row(
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: isTop4 ? const Color(0xFF009270) : Colors.white10,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Center(
                                child: Text(
                                  '$rank',
                                  style: TextStyle(
                                    color: isTop4 ? Colors.white : Colors.white60,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            CircleAvatar(radius: 11, backgroundImage: NetworkImage(s.teamLogoUrl)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                s.teamName,
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(flex: 1, child: Text('${s.matchesPlayed}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 11))),
                      Expanded(flex: 1, child: Text('${s.won}', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.bold))),
                      Expanded(flex: 1, child: Text('${s.lost}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent, fontSize: 11))),
                      Expanded(flex: 2, child: Text('${s.points}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold))),
                      Expanded(flex: 2, child: Text(s.netRunRate.toStringAsFixed(3), textAlign: TextAlign.right, style: const TextStyle(color: Colors.white70, fontSize: 11))),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ICC Points Table Legend Box
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('POINTS SYSTEM & QUALIFICATION RULES', style: TextStyle(color: Color(0xFF34D399), fontSize: 10, fontWeight: FontWeight.w900)),
              SizedBox(height: 6),
              Text('• Win: 2 points  • Tie / No Result: 1 point  • Loss: 0 points', style: TextStyle(color: Colors.white70, fontSize: 11)),
              SizedBox(height: 4),
              Text('• Standard ICC NRR = (Runs Scored / Overs Faced) - (Runs Conceded / Overs Bowled)', style: TextStyle(color: Colors.white54, fontSize: 10)),
              SizedBox(height: 4),
              Text('• Top 4 teams qualify for Playoffs / Semifinals', style: TextStyle(color: Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // TAB 4: TEAMS & SQUADS
  // =========================================================================
  Widget _buildTeamsTab(BuildContext context, MockDatabase db, Tournament tourn) {
    final tournTeams = db.teams.where((t) => t.tournamentId == tourn.id).toList();
    final canScore = db.hasTournamentScorerAccess(tourn.id);

    if (tournTeams.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.group_off, size: 48, color: Colors.white38),
              const SizedBox(height: 12),
              const Text('No teams added to this tournament yet.', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (canScore)
                ElevatedButton.icon(
                  onPressed: () => _showAddTeamDialog(context, db, tourn),
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('Add First Team', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF009270), foregroundColor: Colors.white),
                ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Teams Header Strip with Add Team Action
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: const Color(0xFF1E293B),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Tournament Teams (${tournTeams.length})',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
              if (canScore)
                ElevatedButton.icon(
                  onPressed: () => _showAddTeamDialog(context, db, tourn),
                  icon: const Icon(Icons.add, size: 13),
                  label: const Text('+ Add Team', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF009270),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  ),
                ),
            ],
          ),
        ),

        // Teams Grid with Edit/Delete & Squad Management
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.88,
            ),
            itemCount: tournTeams.length,
            itemBuilder: (ctx, index) {
              final t = tournTeams[index];
              final squad = db.players.where((p) => p.teamId == t.id).toList();
              final isReady = squad.length >= 2 && !squad.any((p) => p.fullName.trim().isEmpty || p.mobileNumber.trim().isEmpty);

              return Card(
                color: const Color(0xFF1E293B),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: t.primaryColor.withValues(alpha: 0.6), width: 1.5),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _showTeamSquadSheet(context, db, t, squad),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Card Top Row: Avatar & Edit/Delete Actions
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: t.primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  t.shortName.isNotEmpty ? t.shortName.substring(0, min(2, t.shortName.length)) : 'T',
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (canScore) ...[
                              InkWell(
                                onTap: () => _showEditTeamDialog(context, db, t),
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.amberAccent.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.edit, size: 13, color: Colors.amberAccent),
                                ),
                              ),
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: () => _confirmDeleteTeam(context, db, t),
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.delete_outline, size: 13, color: Colors.redAccent),
                                ),
                              ),
                            ],
                          ],
                        ),

                        // Center: Team Name & Short Name
                        Column(
                          children: [
                            Text(
                              t.name,
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              t.shortName,
                              style: const TextStyle(color: Colors.white54, fontSize: 11),
                            ),
                          ],
                        ),

                        // Bottom: Squad Status Badge & Action Prompt
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isReady
                                    ? const Color(0xFF009270).withValues(alpha: 0.2)
                                    : Colors.amber.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isReady ? const Color(0xFF34D399) : Colors.amber,
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                isReady ? 'Squad: ${squad.length} Players' : '⚠️ ${squad.length} Players (Need Phone)',
                                style: TextStyle(
                                  color: isReady ? const Color(0xFF34D399) : Colors.amberAccent,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Tap to View / Edit Squad',
                              style: TextStyle(color: Colors.white38, fontSize: 9),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // DIALOGS & BOTTOM SHEETS
  // =========================================================================

  void _showTeamSquadSheet(BuildContext context, MockDatabase db, Team team, List<Player> squad) {
    final canScore = db.hasTournamentScorerAccess(team.tournamentId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final currentSquad = db.players.where((p) => p.teamId == team.id).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Team Header
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(color: team.primaryColor, shape: BoxShape.circle),
                        child: Center(
                          child: Text(
                            team.shortName.isNotEmpty ? team.shortName.substring(0, min(2, team.shortName.length)) : 'T',
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(team.name, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                            Text('Squad Roster (${currentSquad.length} Players)', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                          ],
                        ),
                      ),
                      if (canScore)
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showAddPlayerDialog(context, db, team);
                          },
                          icon: const Icon(Icons.person_add, size: 12),
                          label: const Text('+ Player', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF009270),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          ),
                        ),
                      IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, color: Colors.white70)),
                    ],
                  ),
                  const Divider(color: Colors.white12),

                  // Player List
                  Expanded(
                    child: currentSquad.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.person_off, size: 40, color: Colors.white38),
                                const SizedBox(height: 8),
                                const Text(
                                  'No players added to this squad yet.',
                                  style: TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Each team needs at least 2 players with full name & mobile number before scoring.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white38, fontSize: 11),
                                ),
                                if (canScore) ...[
                                  const SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      _showAddPlayerDialog(context, db, team);
                                    },
                                    icon: const Icon(Icons.add, size: 14),
                                    label: const Text('Add First Player', style: TextStyle(fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF009270), foregroundColor: Colors.white),
                                  ),
                                ],
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: currentSquad.length,
                            separatorBuilder: (_, __) => const Divider(color: Colors.white10),
                            itemBuilder: (c, idx) {
                              final p = currentSquad[idx];
                              final hasPhone = p.mobileNumber.trim().isNotEmpty;

                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: const Color(0xFF0F172A),
                                  child: Icon(
                                    p.role == PlayerRole.bowler
                                        ? Icons.sports_baseball
                                        : (p.role == PlayerRole.wicketKeeper ? Icons.sports_handball : Icons.sports_cricket),
                                    size: 14,
                                    color: const Color(0xFF34D399),
                                  ),
                                ),
                                title: Text(
                                  p.fullName,
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                subtitle: Row(
                                  children: [
                                    Text(
                                      '${p.roleString} • ',
                                      style: const TextStyle(color: Colors.white54, fontSize: 10),
                                    ),
                                    Icon(
                                      Icons.phone,
                                      size: 10,
                                      color: hasPhone ? const Color(0xFF34D399) : Colors.amberAccent,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      hasPhone ? p.mobileNumber : 'Missing Phone *',
                                      style: TextStyle(
                                        color: hasPhone ? const Color(0xFF34D399) : Colors.amberAccent,
                                        fontSize: 10,
                                        fontWeight: hasPhone ? FontWeight.normal : FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: canScore
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit, size: 15, color: Colors.amberAccent),
                                            onPressed: () {
                                              Navigator.pop(ctx);
                                              _showEditPlayerDialog(context, db, p);
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, size: 15, color: Colors.redAccent),
                                            onPressed: () {
                                              db.deletePlayer(p.id);
                                              setSheetState(() {});
                                            },
                                          ),
                                        ],
                                      )
                                    : null,
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showEditTournamentDialog(BuildContext context, MockDatabase db, Tournament tourn) {
    final nameCtrl = TextEditingController(text: tourn.name);
    final shortCtrl = TextEditingController(text: tourn.shortName);
    final locCtrl = TextEditingController(text: tourn.location);
    final oversCtrl = TextEditingController(text: '${tourn.overs}');
    final roomCtrl = TextEditingController(text: tourn.roomId);
    final pinCtrl = TextEditingController(text: tourn.passcode);
    int selectedOvers = tourn.overs;
    final presetOvers = [6, 10, 15, 20, 30, 50];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlg) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: const [
                Icon(Icons.tune, color: Colors.amberAccent, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Edit Tournament Format',
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: 'Tournament Full Name',
                      labelStyle: TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: shortCtrl,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: const InputDecoration(
                            labelText: 'Short Code (e.g. BPL)',
                            labelStyle: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: locCtrl,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: const InputDecoration(
                            labelText: 'Ground / City',
                            labelStyle: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text('MATCH FORMAT (OVERS)', style: TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: presetOvers.map((ov) {
                      final isSel = selectedOvers == ov;
                      return ChoiceChip(
                        label: Text(ov == 50 ? 'ODI (50)' : 'T$ov ($ov Ov)', style: TextStyle(color: isSel ? Colors.black : Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                        selected: isSel,
                        selectedColor: Colors.amberAccent,
                        backgroundColor: const Color(0xFF0F172A),
                        onSelected: (_) {
                          setDlg(() {
                            selectedOvers = ov;
                            oversCtrl.text = '$ov';
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: oversCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: 'Custom Match Overs (type any number)',
                      labelStyle: TextStyle(color: Colors.white70),
                      prefixIcon: Icon(Icons.timer, size: 16, color: Colors.amberAccent),
                    ),
                    onChanged: (val) {
                      final parsed = int.tryParse(val.trim());
                      if (parsed != null && parsed > 0) {
                        setDlg(() => selectedOvers = parsed);
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  const Text('SCORER ACCESS CREDENTIALS', style: TextStyle(color: Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: roomCtrl,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: const InputDecoration(
                            labelText: 'Room ID',
                            labelStyle: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: pinCtrl,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: const InputDecoration(
                            labelText: 'Host PIN',
                            labelStyle: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
              ElevatedButton(
                onPressed: () {
                  final finalOvers = int.tryParse(oversCtrl.text.trim()) ?? selectedOvers;
                  if (finalOvers <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(backgroundColor: Colors.redAccent, content: Text('Please enter valid match overs (min 1)')),
                    );
                    return;
                  }

                  db.updateTournament(
                    tournamentId: tourn.id,
                    name: nameCtrl.text.trim(),
                    shortName: shortCtrl.text.trim(),
                    location: locCtrl.text.trim(),
                    overs: finalOvers,
                    roomId: roomCtrl.text.trim(),
                    passcode: pinCtrl.text.trim(),
                  );

                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF009270),
                      content: Text('Tournament format updated to $finalOvers Overs!'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent, foregroundColor: Colors.black),
                child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditTeamDialog(BuildContext context, MockDatabase db, Team team) {
    final nameCtrl = TextEditingController(text: team.name);
    final shortCtrl = TextEditingController(text: team.shortName);
    Color selectedColor = team.primaryColor;

    final palette = [
      const Color(0xFF009270),
      const Color(0xFF059669),
      const Color(0xFF2563EB),
      const Color(0xFF7C3AED),
      const Color(0xFFD97706),
      const Color(0xFFDC2626),
      const Color(0xFF0D9488),
      const Color(0xFF9333EA),
      const Color(0xFFEA580C),
      const Color(0xFF10B981),
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlg) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: selectedColor,
                  child: Text(
                    shortCtrl.text.isNotEmpty ? shortCtrl.text.substring(0, 1) : 'T',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Edit Team Details', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(labelText: 'Team Name', labelStyle: TextStyle(color: Colors.white70)),
                    onChanged: (val) {
                      if (val.trim().isNotEmpty && shortCtrl.text.isEmpty) {
                        final parts = val.trim().split(' ');
                        final autoShort = parts.length > 1
                            ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
                            : (val.length >= 3 ? val.substring(0, 3).toUpperCase() : val.toUpperCase());
                        setDlg(() => shortCtrl.text = autoShort);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: shortCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(labelText: 'Short Code (e.g. KKR)', labelStyle: TextStyle(color: Colors.white70)),
                  ),
                  const SizedBox(height: 14),
                  const Text('TEAM PRIMARY COLOR', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: palette.map((c) {
                      final isSelected = selectedColor.toARGB32() == c.toARGB32();
                      return GestureDetector(
                        onTap: () => setDlg(() => selectedColor = c),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.transparent,
                              width: 2.5,
                            ),
                            boxShadow: isSelected
                                ? [BoxShadow(color: c.withValues(alpha: 0.6), blurRadius: 8, spreadRadius: 1)]
                                : null,
                          ),
                          child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _confirmDeleteTeam(context, db, team);
                },
                child: const Text('Delete Team', style: TextStyle(color: Colors.redAccent)),
              ),
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
              ElevatedButton(
                onPressed: () {
                  if (nameCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(backgroundColor: Colors.redAccent, content: Text('Team name cannot be empty!')),
                    );
                    return;
                  }

                  db.updateTeam(
                    teamId: team.id,
                    name: nameCtrl.text.trim(),
                    shortName: shortCtrl.text.trim().isNotEmpty ? shortCtrl.text.trim() : 'TEAM',
                    primaryColor: selectedColor,
                  );

                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF009270),
                      content: Text('Team "${nameCtrl.text.trim()}" updated successfully!'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF34D399), foregroundColor: Colors.black),
                child: const Text('Save Team', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeleteTeam(BuildContext context, MockDatabase db, Team team) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 22),
            SizedBox(width: 8),
            Text('Delete Team?', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${team.name}"? All associated squad players will also be removed.',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            onPressed: () {
              db.deleteTeam(team.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.redAccent,
                  content: Text('Team "${team.name}" deleted.'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddPlayerDialog(BuildContext context, MockDatabase db, Team team) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    PlayerRole selectedRole = PlayerRole.batsman;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlg) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.person_add, color: Color(0xFF34D399), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Add Player to ${team.shortName}',
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: 'Player Full Name *',
                      labelStyle: TextStyle(color: Colors.white70),
                      hintText: 'e.g. Sourav Roy',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: 'Mobile Number * (Mandatory for Scoring)',
                      labelStyle: TextStyle(color: Colors.white70),
                      hintText: 'e.g. 9876543210',
                      prefixIcon: Icon(Icons.phone, size: 16, color: Color(0xFF34D399)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('PLAYER ROLE', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: [
                      PlayerRole.batsman,
                      PlayerRole.bowler,
                      PlayerRole.allRounder,
                      PlayerRole.wicketKeeper,
                    ].map((r) {
                      final isSel = selectedRole == r;
                      String label = 'Batter';
                      if (r == PlayerRole.bowler) label = 'Bowler';
                      if (r == PlayerRole.allRounder) label = 'All-Rounder';
                      if (r == PlayerRole.wicketKeeper) label = 'Wicketkeeper';

                      return ChoiceChip(
                        label: Text(label, style: TextStyle(color: isSel ? Colors.black : Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                        selected: isSel,
                        selectedColor: const Color(0xFF34D399),
                        backgroundColor: const Color(0xFF0F172A),
                        onSelected: (_) => setDlg(() => selectedRole = r),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
              ElevatedButton(
                onPressed: () {
                  final name = nameCtrl.text.trim();
                  final mobile = phoneCtrl.text.trim();
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(backgroundColor: Colors.redAccent, content: Text('Player name cannot be empty!')),
                    );
                    return;
                  }
                  if (mobile.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(backgroundColor: Colors.redAccent, content: Text('Mobile number is required for all squad players!')),
                    );
                    return;
                  }

                  db.addPlayerToTeam(
                    teamId: team.id,
                    fullName: name,
                    mobileNumber: mobile,
                    role: selectedRole,
                  );

                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF009270),
                      content: Text('Player "$name" added to ${team.name}!'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF34D399), foregroundColor: Colors.black),
                child: const Text('Add Player', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditPlayerDialog(BuildContext context, MockDatabase db, Player player) {
    final nameCtrl = TextEditingController(text: player.fullName);
    final phoneCtrl = TextEditingController(text: player.mobileNumber);
    PlayerRole selectedRole = player.role;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlg) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: const [
                Icon(Icons.edit, color: Colors.amberAccent, size: 20),
                SizedBox(width: 8),
                Text('Edit Player Details', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: 'Player Full Name *',
                      labelStyle: TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: 'Mobile Number *',
                      labelStyle: TextStyle(color: Colors.white70),
                      prefixIcon: Icon(Icons.phone, size: 16, color: Color(0xFF34D399)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('PLAYER ROLE', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: [
                      PlayerRole.batsman,
                      PlayerRole.bowler,
                      PlayerRole.allRounder,
                      PlayerRole.wicketKeeper,
                    ].map((r) {
                      final isSel = selectedRole == r;
                      String label = 'Batter';
                      if (r == PlayerRole.bowler) label = 'Bowler';
                      if (r == PlayerRole.allRounder) label = 'All-Rounder';
                      if (r == PlayerRole.wicketKeeper) label = 'Wicketkeeper';

                      return ChoiceChip(
                        label: Text(label, style: TextStyle(color: isSel ? Colors.black : Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                        selected: isSel,
                        selectedColor: Colors.amberAccent,
                        backgroundColor: const Color(0xFF0F172A),
                        onSelected: (_) => setDlg(() => selectedRole = r),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  db.deletePlayer(player.id);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.redAccent,
                      content: Text('Player "${player.fullName}" removed.'),
                    ),
                  );
                },
                child: const Text('Remove Player', style: TextStyle(color: Colors.redAccent)),
              ),
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
              ElevatedButton(
                onPressed: () {
                  final name = nameCtrl.text.trim();
                  final mobile = phoneCtrl.text.trim();
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(backgroundColor: Colors.redAccent, content: Text('Player name cannot be empty!')),
                    );
                    return;
                  }

                  db.updatePlayer(
                    playerId: player.id,
                    fullName: name,
                    mobileNumber: mobile,
                    role: selectedRole,
                  );

                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF009270),
                      content: Text('Player "$name" updated successfully!'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF34D399), foregroundColor: Colors.black),
                child: const Text('Save Player', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showScheduleMatchDialog(BuildContext context, MockDatabase db, Tournament tourn) {
    final tournTeams = db.teams.where((t) => t.tournamentId == tourn.id).toList();
    if (tournTeams.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFDC2626),
          content: Text('At least 2 teams are needed in the tournament to schedule a match.'),
        ),
      );
      return;
    }

    String teamAId = tournTeams[0].id;
    String teamBId = tournTeams[1].id;
    final stageController = TextEditingController(text: '${tourn.shortName} League Match');
    final venueController = TextEditingController(text: tourn.location);
    final oversController = TextEditingController(text: '${tourn.overs}');
    int matchOvers = tourn.overs;
    final presetOvers = [6, 10, 15, 20, 30, 50];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlg) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: const [
                Icon(Icons.calendar_month, color: Color(0xFF34D399), size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Schedule Tournament Match',
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    value: teamAId,
                    isExpanded: true,
                    isDense: true,
                    dropdownColor: const Color(0xFF0F172A),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(labelText: 'Team A', labelStyle: TextStyle(color: Colors.white70)),
                    items: tournTeams.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (val) => setDlg(() => teamAId = val!),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: teamBId,
                    isExpanded: true,
                    isDense: true,
                    dropdownColor: const Color(0xFF0F172A),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(labelText: 'Team B', labelStyle: TextStyle(color: Colors.white70)),
                    items: tournTeams.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (val) => setDlg(() => teamBId = val!),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: stageController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(labelText: 'Match Stage / Number', labelStyle: TextStyle(color: Colors.white70)),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: venueController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(labelText: 'Ground / Venue', labelStyle: TextStyle(color: Colors.white70)),
                  ),
                  const SizedBox(height: 12),
                  const Text('MATCH OVERS', style: TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: presetOvers.map((ov) {
                      final isSel = matchOvers == ov;
                      return ChoiceChip(
                        label: Text(ov == 50 ? 'ODI (50)' : 'T$ov ($ov Ov)', style: TextStyle(color: isSel ? Colors.black : Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                        selected: isSel,
                        selectedColor: Colors.amberAccent,
                        backgroundColor: const Color(0xFF0F172A),
                        onSelected: (_) {
                          setDlg(() {
                            matchOvers = ov;
                            oversController.text = '$ov';
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: oversController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: 'Custom Overs',
                      labelStyle: TextStyle(color: Colors.white70),
                      prefixIcon: Icon(Icons.timer, size: 16, color: Colors.amberAccent),
                    ),
                    onChanged: (val) {
                      final parsed = int.tryParse(val.trim());
                      if (parsed != null && parsed > 0) {
                        setDlg(() => matchOvers = parsed);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
              ElevatedButton(
                onPressed: () {
                  if (teamAId == teamBId) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(backgroundColor: Colors.redAccent, content: Text('Team A and Team B cannot be identical!')),
                    );
                    return;
                  }

                  final finalOvers = int.tryParse(oversController.text.trim()) ?? matchOvers;

                  db.scheduleMatchForTournament(
                    tournamentId: tourn.id,
                    teamAId: teamAId,
                    teamBId: teamBId,
                    venue: venueController.text,
                    dateTime: DateTime.now().add(const Duration(hours: 2)),
                    overs: finalOvers,
                    stage: stageController.text,
                  );

                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF009270),
                      content: Text('Match scheduled ($finalOvers Ov)! Scorer Room PIN: ${tourn.passcode}'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF34D399), foregroundColor: Colors.black),
                child: const Text('Schedule Match', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddTeamDialog(BuildContext context, MockDatabase db, Tournament tourn) {
    final nameCtrl = TextEditingController();
    final shortCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Team to Tournament', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(labelText: 'Team Full Name (e.g. Siliguri Strikers)', labelStyle: TextStyle(color: Colors.white70)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: shortCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(labelText: 'Short Code (e.g. SS)', labelStyle: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              db.addTeamToTournament(
                tournamentId: tourn.id,
                name: nameCtrl.text.trim(),
                shortName: shortCtrl.text.trim().isNotEmpty ? shortCtrl.text.trim() : 'TEAM',
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF009270),
                  content: Text('Team "${nameCtrl.text.trim()}" added to ${tourn.shortName}!'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF34D399), foregroundColor: Colors.black),
            child: const Text('Add Team', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showUnlockDialog(BuildContext context, MockDatabase db, Tournament tourn) {
    final roomController = TextEditingController(text: tourn.roomId.isNotEmpty ? tourn.roomId : tourn.id);
    final passController = TextEditingController();
    String? errorMessage;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            title: Row(
              children: const [
                Icon(Icons.vpn_key, color: Color(0xFF34D399), size: 20),
                SizedBox(width: 8),
                Text('Unlock Tournament Scorer Mode', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Enter the Tournament ID/Room ID and Passcode PIN set by the tournament organizer to unlock full ball-by-ball scoring control for all matches in ${tourn.name}.',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: roomController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Tournament / Room ID',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: passController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Host Passcode / PIN',
                    labelStyle: const TextStyle(color: Colors.white70),
                    hintText: 'e.g. ${tourn.passcode}',
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
              ElevatedButton(
                onPressed: () {
                  final ok = db.unlockTournamentScoring(
                    tournamentIdOrRoomId: roomController.text,
                    passcode: passController.text,
                  );
                  if (ok) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF009270),
                        content: Text('Scoring access unlocked for ${tourn.name}!'),
                      ),
                    );
                  } else {
                    setDialogState(() => errorMessage = 'Invalid Tournament ID or Passcode PIN.');
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF34D399), foregroundColor: Colors.black),
                child: const Text('Unlock Scoring', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }
}
