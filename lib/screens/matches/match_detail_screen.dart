import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/firestore_database_service.dart';
import '../../services/mock_database.dart';
import '../../theme/neo_glass_theme.dart';
import '../../utils/web_share_helper.dart';
import '../../widgets/app_animations.dart';

/// Public Read-Only Live Match Centre (Cricbuzz / CricHeroes style).
/// Completely separate from ScorerScreen — never exposes scoring, edit, or admin controls.
class MatchDetailScreen extends StatefulWidget {
  final String matchId;

  const MatchDetailScreen({super.key, required this.matchId});

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<int> _expandedOvers = {};
  int? _latestSeenOverKey;

  // Light Glassmorphism 2026 palette
  static const Color _bgPage = GlassTokens.bgIcyWhite;
  static const Color _bgCard = GlassTokens.glassFillHigh;
  static const Color _border = GlassTokens.glassHairline;
  static const Color _inkPrimary = GlassTokens.inkPrimary;
  static const Color _inkSecondary = GlassTokens.inkSecondary;
  static const Color _inkMuted = GlassTokens.inkMuted;
  static const Color _emerald = GlassTokens.mintGreen;
  static const Color _emeraldDark = Color(0xFF0F766E);
  static const Color _liveRed = GlassTokens.coral;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _buildPublicMatchUrl(MatchModel match) {
    final origin = Uri.base.origin;
    final base = (kIsWeb && origin.isNotEmpty && !origin.startsWith('file://'))
        ? origin
        : 'https://cricpavilion-750c5.web.app';
    return '$base/match/${match.id}/live';
  }

  void _copyMatchLink(BuildContext context, MatchModel match) {
    final url = _buildPublicMatchUrl(match);
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Match link copied: $url'),
        backgroundColor: _emerald,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _shareMatch(
    BuildContext context,
    MatchModel match,
    Team teamA,
    Team teamB,
    Tournament? tournament,
    Innings? activeInn,
  ) async {
    final url = _buildPublicMatchUrl(match);
    final scorePart = activeInn != null
        ? ' (${activeInn.totalRuns}/${activeInn.wickets} in ${activeInn.oversStr} ov)'
        : '';
    final tournPart = (tournament != null && !match.isStandalone)
        ? '${tournament.name} • '
        : '';
    final shareText =
        '🏏 $tournPart${teamA.name} vs ${teamB.name}$scorePart — Watch live ball-by-ball on CricPavilion Pro: $url';

    final usedNative = await tryNativeWebShare(
      title: '${teamA.name} vs ${teamB.name} • Live Match Centre',
      text: shareText,
      url: url,
    );
    if (usedNative || !context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.share, color: _emerald, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Share Live Match',
                      style: TextStyle(
                        color: _inkPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: _inkMuted),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _bgPage,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _border),
                ),
                child: SelectableText(
                  url,
                  style: const TextStyle(color: _inkSecondary, fontSize: 12),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _copyMatchLink(context, match);
                      },
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy Link'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _inkPrimary,
                        side: const BorderSide(color: _border),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final waUrl =
                            'https://wa.me/?text=${Uri.encodeComponent(shareText)}';
                        openExternalShareUrl(waUrl);
                        Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.chat, size: 16),
                      label: const Text('WhatsApp'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: shareText));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Match summary & link copied for Instagram / Social!'),
                      backgroundColor: _emerald,
                    ),
                  );
                },
                icon: const Icon(Icons.content_paste, size: 16),
                label: const Text('Copy Summary for Instagram / Social'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _emeraldDark,
                  side: const BorderSide(color: _emerald),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = context.watch<MockDatabase>();
    final match = db.matches.where((m) => m.id == widget.matchId).firstOrNull;

    if (match == null) {
      return _buildLoadingOrNotFound(context, db);
    }

    final tournament = match.isStandalone ? null : db.getTournament(match.tournamentId);
    final teamA = db.getTeam(match.teamAId) ?? MockDatabase.emptyTeam;
    final teamB = db.getTeam(match.teamBId) ?? MockDatabase.emptyTeam;

    if (kIsWeb) {
      final tName = tournament != null ? ' • ${tournament.shortName}' : '';
      setWebDocumentTitle('${teamA.shortName} vs ${teamB.shortName}$tName • CricPavilion Live');
    }

    final matchInnings = db.inningsList.where((i) => i.matchId == match.id).toList()
      ..sort((a, b) => a.inningsNumber.compareTo(b.inningsNumber));
    final inn1 = matchInnings.where((i) => i.inningsNumber == 1).firstOrNull;
    final inn2 = matchInnings.where((i) => i.inningsNumber == 2).firstOrNull;
    final currentInnings = (match.currentInningsNumber == 2 && inn2 != null)
        ? inn2
        : (inn1 ?? matchInnings.firstOrNull);

    final deliveries = db.deliveries
        .where((d) => d.matchId == match.id && !d.isUndone)
        .toList()
      ..sort((a, b) => a.deliverySequence.compareTo(b.deliverySequence));

    return Scaffold(
      backgroundColor: _bgPage,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _inkPrimary,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to Matches',
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/');
            }
          },
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            _TournamentBadge(tournament: tournament),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tournament != null ? tournament.name : 'CricPavilion Match Centre',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _inkPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${match.stage} • ${match.overs} Overs',
                    style: const TextStyle(fontSize: 11, color: _inkMuted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.link, size: 20),
            tooltip: 'Copy Public Match Link',
            onPressed: () => _copyMatchLink(context, match),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 20),
            tooltip: 'Share Match',
            onPressed: () => _shareMatch(context, match, teamA, teamB, tournament, currentInnings),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: _border),
                bottom: BorderSide(color: _border),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: _emerald,
              indicatorWeight: 3,
              labelColor: _emeraldDark,
              unselectedLabelColor: _inkMuted,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Scorecard'),
                Tab(text: 'Commentary'),
                Tab(text: 'Teams'),
                Tab(text: 'Info'),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildSyncStatusBar(db),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(
                      context,
                      db,
                      match,
                      tournament,
                      teamA,
                      teamB,
                      inn1,
                      inn2,
                      currentInnings,
                      deliveries,
                    ),
                    _buildScorecardTab(
                      context,
                      db,
                      match,
                      teamA,
                      teamB,
                      inn1,
                      inn2,
                      deliveries,
                    ),
                    _buildCommentaryTab(
                      context,
                      db,
                      match,
                      currentInnings,
                      deliveries,
                    ),
                    _buildTeamsTab(context, db, match, teamA, teamB),
                    _buildInfoTab(context, db, match, tournament, teamA, teamB),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOrNotFound(BuildContext context, MockDatabase db) {
    final isLoading = FirestoreDatabaseService.isSyncingInitial ||
        !FirestoreDatabaseService.isInitialized;
    return Scaffold(
      backgroundColor: _bgPage,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _inkPrimary,
        elevation: 0,
        title: const Text('Live Match Centre', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/');
            }
          },
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: isLoading
              ? const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: _emerald),
                    SizedBox(height: 16),
                    Text(
                      'Loading Live Match Centre...',
                      style: TextStyle(
                        color: _inkPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Connecting to real-time match stream',
                      style: TextStyle(color: _inkMuted, fontSize: 12),
                    ),
                  ],
                )
              : Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _border),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.sports_cricket_outlined, size: 44, color: _inkMuted),
                      const SizedBox(height: 12),
                      const Text(
                        'Match Not Found',
                        style: TextStyle(
                          color: _inkPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'This match may not have synced yet or the link is invalid.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _inkSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => FirestoreDatabaseService.reconnect(db),
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Retry Sync'),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _emerald,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('All Matches'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSyncStatusBar(MockDatabase db) {
    final hasError = FirestoreDatabaseService.hasConnectionError;
    final lastTime = FirestoreDatabaseService.lastCloudSyncTime;
    final timeStr = lastTime != null ? DateFormat('h:mm:ss a').format(lastTime) : 'Syncing...';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: hasError ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Row(
            children: [
              Icon(
                hasError ? Icons.wifi_off : Icons.wifi_tethering,
                size: 14,
                color: hasError ? _liveRed : _emeraldDark,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  hasError
                      ? 'Live connection interrupted • Tap Retry to reconnect'
                      : 'Real-time updates active • Last updated $timeStr',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: hasError ? _liveRed : _emeraldDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (hasError)
                InkWell(
                  onTap: () => FirestoreDatabaseService.reconnect(db),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Text(
                      'Retry',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: _liveRed,
                        decoration: TextDecoration.underline,
                      ),
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
  // TAB 1: OVERVIEW (RESPONSIVE MOBILE + DESKTOP)
  // =========================================================================
  Widget _buildOverviewTab(
    BuildContext context,
    MockDatabase db,
    MatchModel match,
    Tournament? tournament,
    Team teamA,
    Team teamB,
    Innings? inn1,
    Innings? inn2,
    Innings? activeInn,
    List<Delivery> allDeliveries,
  ) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    final activeDeliveries = activeInn == null
        ? <Delivery>[]
        : allDeliveries.where((d) => d.inningsId == activeInn.id).toList();

    final mainColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildMatchHeaderCard(match, tournament, teamA, teamB, inn1, inn2, activeInn),
        const SizedBox(height: 12),
        if (activeInn != null &&
            (match.status == MatchStatus.live ||
                match.status == MatchStatus.inningsBreak ||
                match.status == MatchStatus.completed)) ...[
          _buildBattingAndBowlingCards(db, activeInn),
          const SizedBox(height: 12),
          _buildRecentBallsCard(activeDeliveries),
        ] else
          _buildUpcomingPreviewCard(match, teamA, teamB),
      ],
    );

    final sideColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildLatestCommentaryPreviewCard(db, activeDeliveries),
        const SizedBox(height: 12),
        _buildQuickMatchFactsCard(match, tournament, teamA, teamB),
      ],
    );

    if (isWide) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 7, child: mainColumn),
            const SizedBox(width: 16),
            Expanded(flex: 5, child: sideColumn),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          mainColumn,
          const SizedBox(height: 12),
          _buildLatestCommentaryPreviewCard(db, activeDeliveries),
        ],
      ),
    );
  }

  Widget _buildMatchHeaderCard(
    MatchModel match,
    Tournament? tournament,
    Team teamA,
    Team teamB,
    Innings? inn1,
    Innings? inn2,
    Innings? activeInn,
  ) {
    final dateStr = DateFormat('EEE, d MMM yyyy • h:mm a').format(match.dateTime);
    final statusInfo = _statusPresentation(match.status);
    final batTeam = activeInn != null
        ? (activeInn.battingTeamId == teamA.id ? teamA : teamB)
        : teamA;

    // Match situation calculation (only from real DB fields)
    String? situationText;
    String? rrrText;
    if (match.status == MatchStatus.completed && match.winnerId != null) {
      final winner = match.winnerId == teamA.id ? teamA : teamB;
      situationText = '${winner.name} won ${match.winMargin ?? ""}'.trim();
    } else if (match.status == MatchStatus.abandoned) {
      situationText = 'Match abandoned / No result';
    } else if (match.status == MatchStatus.inningsBreak && inn1 != null) {
      situationText =
          'Innings Break • ${batTeam.shortName} posted ${inn1.totalRuns}/${inn1.wickets} (Target: ${inn1.totalRuns + 1})';
    } else if (activeInn != null &&
        activeInn.inningsNumber == 2 &&
        activeInn.targetRuns != null) {
      final runsNeeded = activeInn.targetRuns! - activeInn.totalRuns;
      final ballsRemaining = (match.overs * 6) - activeInn.legalBalls;
      if (runsNeeded <= 0) {
        situationText = '${batTeam.name} reached the target';
      } else if (ballsRemaining > 0) {
        final rrr = (runsNeeded / (ballsRemaining / 6.0));
        rrrText = rrr.toStringAsFixed(2);
        situationText =
            '${batTeam.shortName} need $runsNeeded runs in $ballsRemaining balls';
      }
    } else if (match.tossWonBy != null) {
      final tossTeam = match.tossWonBy == teamA.id ? teamA : teamB;
      situationText =
          '${tossTeam.name} won the toss and elected to ${match.tossDecision ?? "bat"}';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top meta row: Match info + Status Badge
          Row(
            children: [
              Expanded(
                child: Text(
                  '${tournament != null ? "${tournament.shortName} • " : ""}${match.stage} • ${match.venue}',
                  style: const TextStyle(
                    color: _inkMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusInfo.bgColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusInfo.borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (match.status == MatchStatus.live) ...[
                      const PulsingLiveDot(color: _liveRed, size: 7),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      statusInfo.label,
                      style: TextStyle(
                        color: statusInfo.textColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            dateStr,
            style: const TextStyle(color: _inkMuted, fontSize: 11),
          ),
          const SizedBox(height: 14),

          // Team A & Team B Score Rows
          _buildTeamScoreRow(
            team: teamA,
            innings: inn1 != null && inn1.battingTeamId == teamA.id
                ? inn1
                : (inn2 != null && inn2.battingTeamId == teamA.id ? inn2 : null),
            isCurrentlyBatting:
                match.status == MatchStatus.live && activeInn?.battingTeamId == teamA.id,
          ),
          const SizedBox(height: 10),
          _buildTeamScoreRow(
            team: teamB,
            innings: inn1 != null && inn1.battingTeamId == teamB.id
                ? inn1
                : (inn2 != null && inn2.battingTeamId == teamB.id ? inn2 : null),
            isCurrentlyBatting:
                match.status == MatchStatus.live && activeInn?.battingTeamId == teamB.id,
          ),

          if (activeInn != null) ...[
            const SizedBox(height: 12),
            const Divider(color: _border, height: 1),
            const SizedBox(height: 10),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                _metricChip('CRR', activeInn.runRate.toStringAsFixed(2)),
                if (activeInn.targetRuns != null)
                  _metricChip('TARGET', '${activeInn.targetRuns}'),
                if (rrrText != null) _metricChip('RRR', rrrText),
                _metricChip('EXTRAS', '${activeInn.totalExtras}'),
              ],
            ),
          ],

          if (situationText != null && situationText.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: match.status == MatchStatus.completed
                    ? const Color(0xFFECFDF5)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: match.status == MatchStatus.completed
                      ? const Color(0xFFA7F3D0)
                      : _border,
                ),
              ),
              child: Text(
                situationText,
                style: TextStyle(
                  color: match.status == MatchStatus.completed ? _emeraldDark : _inkPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],

          if (match.status == MatchStatus.completed &&
              (match.playerOfTheMatchName ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.emoji_events, size: 15, color: Color(0xFFD97706)),
                const SizedBox(width: 6),
                Text(
                  'Player of the Match: ${match.playerOfTheMatchName}',
                  style: const TextStyle(
                    color: _inkSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTeamScoreRow({
    required Team team,
    required Innings? innings,
    required bool isCurrentlyBatting,
  }) {
    return Row(
      children: [
        _TeamAvatar(team: team, size: 34),
        const SizedBox(width: 10),
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  team.name,
                  style: TextStyle(
                    color: _inkPrimary,
                    fontSize: 15,
                    fontWeight: isCurrentlyBatting ? FontWeight.w800 : FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isCurrentlyBatting) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'BATTING',
                    style: TextStyle(
                      color: _emeraldDark,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (innings != null)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Text(
              '${innings.totalRuns}/${innings.wickets} (${innings.oversStr})',
              key: ValueKey('${innings.id}_${innings.totalRuns}_${innings.wickets}_${innings.legalBalls}'),
              style: TextStyle(
                color: isCurrentlyBatting ? _inkPrimary : _inkSecondary,
                fontSize: isCurrentlyBatting ? 19 : 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          )
        else
          const Text(
            'Yet to bat',
            style: TextStyle(color: _inkMuted, fontSize: 12.5, fontWeight: FontWeight.w500),
          ),
      ],
    );
  }

  Widget _metricChip(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            color: _inkMuted,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: _inkPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildBattingAndBowlingCards(MockDatabase db, Innings inn) {
    final striker = inn.currentStrikerId != null
        ? db.players.where((p) => p.id == inn.currentStrikerId).firstOrNull
        : null;
    final nonStriker = inn.currentNonStrikerId != null
        ? db.players.where((p) => p.id == inn.currentNonStrikerId).firstOrNull
        : null;
    final bowler = inn.currentBowlerId != null
        ? db.players.where((p) => p.id == inn.currentBowlerId).firstOrNull
        : null;

    final strikerCard = striker != null
        ? db.battingScorecards
            .where((b) => b.inningsId == inn.id && b.playerId == striker.id)
            .firstOrNull
        : null;
    final nonStrikerCard = nonStriker != null
        ? db.battingScorecards
            .where((b) => b.inningsId == inn.id && b.playerId == nonStriker.id)
            .firstOrNull
        : null;
    final bowlerCard = bowler != null
        ? db.bowlingScorecards
            .where((b) => b.inningsId == inn.id && b.playerId == bowler.id)
            .firstOrNull
        : null;

    return Container(
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Batting table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
              border: Border(bottom: BorderSide(color: _border)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 5, child: Text('Batter', style: _tableHeaderStyle)),
                Expanded(flex: 1, child: Text('R', textAlign: TextAlign.right, style: _tableHeaderStyle)),
                Expanded(flex: 1, child: Text('B', textAlign: TextAlign.right, style: _tableHeaderStyle)),
                Expanded(flex: 1, child: Text('4s', textAlign: TextAlign.right, style: _tableHeaderStyle)),
                Expanded(flex: 1, child: Text('6s', textAlign: TextAlign.right, style: _tableHeaderStyle)),
                Expanded(flex: 2, child: Text('SR', textAlign: TextAlign.right, style: _tableHeaderStyle)),
              ],
            ),
          ),
          if (striker == null && nonStriker == null)
            const Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                'Waiting for batters to take crease...',
                style: TextStyle(color: _inkMuted, fontSize: 12),
              ),
            )
          else ...[
            if (striker != null)
              _buildActiveBatterRow(
                name: striker.fullName,
                card: strikerCard,
                isStriker: true,
              ),
            if (nonStriker != null) ...[
              const Divider(color: _border, height: 1),
              _buildActiveBatterRow(
                name: nonStriker.fullName,
                card: nonStrikerCard,
                isStriker: false,
              ),
            ],
          ],

          // Bowling table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(
                top: BorderSide(color: _border),
                bottom: BorderSide(color: _border),
              ),
            ),
            child: const Row(
              children: [
                Expanded(flex: 5, child: Text('Bowler', style: _tableHeaderStyle)),
                Expanded(flex: 1, child: Text('O', textAlign: TextAlign.right, style: _tableHeaderStyle)),
                Expanded(flex: 1, child: Text('M', textAlign: TextAlign.right, style: _tableHeaderStyle)),
                Expanded(flex: 1, child: Text('R', textAlign: TextAlign.right, style: _tableHeaderStyle)),
                Expanded(flex: 1, child: Text('W', textAlign: TextAlign.right, style: _tableHeaderStyle)),
                Expanded(flex: 2, child: Text('Econ', textAlign: TextAlign.right, style: _tableHeaderStyle)),
              ],
            ),
          ),
          if (bowler == null)
            const Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                'Waiting for next bowler...',
                style: TextStyle(color: _inkMuted, fontSize: 12),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(
                      bowler.fullName,
                      style: const TextStyle(
                        color: _inkPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      bowlerCard?.oversStr ?? '0.0',
                      textAlign: TextAlign.right,
                      style: _tableCellStyle,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      '${bowlerCard?.maidens ?? 0}',
                      textAlign: TextAlign.right,
                      style: _tableCellStyle,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      '${bowlerCard?.runsConceded ?? 0}',
                      textAlign: TextAlign.right,
                      style: _tableCellStyle,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      '${bowlerCard?.wickets ?? 0}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: _inkPrimary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      (bowlerCard?.economy ?? 0.0).toStringAsFixed(2),
                      textAlign: TextAlign.right,
                      style: _tableCellStyle,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActiveBatterRow({
    required String name,
    required BattingScorecard? card,
    required bool isStriker,
  }) {
    final runs = card?.runs ?? 0;
    final balls = card?.balls ?? 0;
    final fours = card?.fours ?? 0;
    final sixes = card?.sixes ?? 0;
    final sr = card?.strikeRate ?? 0.0;

    return Container(
      color: isStriker ? const Color(0xFFF0FDF4) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Row(
              children: [
                if (isStriker)
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: const BoxDecoration(
                      color: _emerald,
                      shape: BoxShape.circle,
                    ),
                  ),
                Flexible(
                  child: Text(
                    '$name${isStriker ? " *" : ""}',
                    style: TextStyle(
                      color: isStriker ? _emeraldDark : _inkPrimary,
                      fontSize: 13,
                      fontWeight: isStriker ? FontWeight.w800 : FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '$runs',
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: _inkPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(flex: 1, child: Text('$balls', textAlign: TextAlign.right, style: _tableCellStyle)),
          Expanded(flex: 1, child: Text('$fours', textAlign: TextAlign.right, style: _tableCellStyle)),
          Expanded(flex: 1, child: Text('$sixes', textAlign: TextAlign.right, style: _tableCellStyle)),
          Expanded(
            flex: 2,
            child: Text(
              sr.toStringAsFixed(2),
              textAlign: TextAlign.right,
              style: _tableCellStyle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentBallsCard(List<Delivery> deliveries) {
    final recent = deliveries.reversed.take(12).toList().reversed.toList();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RECENT BALLS',
            style: TextStyle(
              color: _inkMuted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 10),
          if (recent.isEmpty)
            const Text(
              'No deliveries bowled yet in this innings.',
              style: TextStyle(color: _inkMuted, fontSize: 12),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: recent.map((d) => _DeliveryPill(delivery: d)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildUpcomingPreviewCard(MatchModel match, Team teamA, Team teamB) {
    final dateStr = DateFormat('EEE, d MMM yyyy • h:mm a').format(match.dateTime);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MATCH PREVIEW',
            style: TextStyle(
              color: _inkMuted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${teamA.name} vs ${teamB.name}',
            style: const TextStyle(
              color: _inkPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Scheduled Start: $dateStr',
            style: const TextStyle(color: _inkSecondary, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            'Venue: ${match.venue} • Format: ${match.overs} Overs',
            style: const TextStyle(color: _inkSecondary, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Text(
            match.tossWonBy != null
                ? 'Toss completed — waiting for first ball.'
                : 'Toss has not been conducted yet. Live scoring will appear here automatically once play begins.',
            style: const TextStyle(color: _inkMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildLatestCommentaryPreviewCard(MockDatabase db, List<Delivery> deliveries) {
    final latest = deliveries.reversed.take(5).toList();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'LIVE BALL-BY-BALL',
                style: TextStyle(
                  color: _inkMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
              TextButton(
                onPressed: () => _tabController.animateTo(2),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 24),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Full Commentary →',
                  style: TextStyle(color: _emerald, fontSize: 11.5, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (latest.isEmpty)
            const Text(
              'Live ball-by-ball commentary will appear here as deliveries are bowled.',
              style: TextStyle(color: _inkMuted, fontSize: 12),
            )
          else
            ...latest.asMap().entries.map((entry) {
              final d = entry.value;
              final isNewest = entry.key == 0;
              return _DeliveryCommentaryRow(
                delivery: d,
                db: db,
                highlight: isNewest,
              );
            }),
        ],
      ),
    );
  }

  Widget _buildQuickMatchFactsCard(
    MatchModel match,
    Tournament? tournament,
    Team teamA,
    Team teamB,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MATCH FACTS',
            style: TextStyle(
              color: _inkMuted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 10),
          _infoRow('Match', '${teamA.shortName} vs ${teamB.shortName} (${match.stage})'),
          if (tournament != null) _infoRow('Tournament', tournament.name),
          _infoRow('Venue', match.venue),
          _infoRow('Format', '${match.overs} Overs'),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 2: FULL SCORECARD (BATTING, BOWLING, EXTRAS, FOW, PARTNERSHIPS)
  // =========================================================================
  Widget _buildScorecardTab(
    BuildContext context,
    MockDatabase db,
    MatchModel match,
    Team teamA,
    Team teamB,
    Innings? inn1,
    Innings? inn2,
    List<Delivery> allDeliveries,
  ) {
    if (inn1 == null && inn2 == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Scorecard will appear once the match starts.',
            style: TextStyle(color: _inkMuted, fontSize: 13),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (inn1 != null)
            _buildInningsFullCard(db, match, inn1, '1st Innings', allDeliveries),
          if (inn2 != null) ...[
            const SizedBox(height: 20),
            _buildInningsFullCard(
              db,
              match,
              inn2,
              '2nd Innings${inn2.targetRuns != null ? " • Target ${inn2.targetRuns}" : ""}',
              allDeliveries,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInningsFullCard(
    MockDatabase db,
    MatchModel match,
    Innings inn,
    String subtitle,
    List<Delivery> allDeliveries,
  ) {
    final batTeam = db.getTeam(inn.battingTeamId) ?? MockDatabase.emptyTeam;
    final batCards = db.battingScorecards.where((b) => b.inningsId == inn.id).toList();
    final bowlCards = db.bowlingScorecards.where((b) => b.inningsId == inn.id).toList();
    final innDeliveries = allDeliveries.where((d) => d.inningsId == inn.id).toList();

    final xi = inn.battingTeamId == match.teamAId ? match.playingXIA : match.playingXIB;
    final battedIds = batCards.map((b) => b.playerId).toSet();
    final didNotBat = xi
        .where((pid) => !battedIds.contains(pid))
        .map((pid) => db.players.where((p) => p.id == pid).firstOrNull?.fullName)
        .whereType<String>()
        .toList();

    final fowList = _computeFallOfWickets(db, innDeliveries);
    final partnerships = _computePartnerships(db, innDeliveries);

    return Container(
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Innings Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        batTeam.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${inn.totalRuns}/${inn.wickets} (${inn.oversStr} Ov)',
                  style: const TextStyle(
                    color: Color(0xFF34D399),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),

          // Batting Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: const Color(0xFFF8FAFC),
            child: const Row(
              children: [
                Expanded(flex: 4, child: Text('Batter', style: _tableHeaderStyle)),
                Expanded(flex: 3, child: Text('Dismissal', style: _tableHeaderStyle)),
                Expanded(flex: 1, child: Text('R', textAlign: TextAlign.right, style: _tableHeaderStyle)),
                Expanded(flex: 1, child: Text('B', textAlign: TextAlign.right, style: _tableHeaderStyle)),
                Expanded(flex: 1, child: Text('4s', textAlign: TextAlign.right, style: _tableHeaderStyle)),
                Expanded(flex: 1, child: Text('6s', textAlign: TextAlign.right, style: _tableHeaderStyle)),
                Expanded(flex: 2, child: Text('SR', textAlign: TextAlign.right, style: _tableHeaderStyle)),
              ],
            ),
          ),
          const Divider(color: _border, height: 1),

          if (batCards.isEmpty)
            const Padding(
              padding: EdgeInsets.all(14),
              child: Text('No batting entries yet.', style: TextStyle(color: _inkMuted, fontSize: 12)),
            )
          else
            ...batCards.map((b) {
              final isActive = b.playerId == inn.currentStrikerId ||
                  b.playerId == inn.currentNonStrikerId;
              return Container(
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFFF0FDF4) : Colors.white,
                  border: const Border(bottom: BorderSide(color: _border)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(
                        '${b.playerName}${b.playerId == inn.currentStrikerId ? " *" : ""}',
                        style: TextStyle(
                          color: isActive ? _emeraldDark : _inkPrimary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        b.dismissalText,
                        style: const TextStyle(color: _inkMuted, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        '${b.runs}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: _inkPrimary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Expanded(flex: 1, child: Text('${b.balls}', textAlign: TextAlign.right, style: _tableCellStyle)),
                    Expanded(flex: 1, child: Text('${b.fours}', textAlign: TextAlign.right, style: _tableCellStyle)),
                    Expanded(flex: 1, child: Text('${b.sixes}', textAlign: TextAlign.right, style: _tableCellStyle)),
                    Expanded(
                      flex: 2,
                      child: Text(
                        b.strikeRate.toStringAsFixed(1),
                        textAlign: TextAlign.right,
                        style: _tableCellStyle,
                      ),
                    ),
                  ],
                ),
              );
            }),

          // Extras & Total
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Extras', style: TextStyle(color: _inkSecondary, fontSize: 12, fontWeight: FontWeight.w700)),
                    Text(
                      '${inn.totalExtras} (wd ${inn.extrasWides}, nb ${inn.extrasNoBalls}, b ${inn.extrasByes}, lb ${inn.extrasLegByes})',
                      style: const TextStyle(color: _inkPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total', style: TextStyle(color: _inkPrimary, fontSize: 13, fontWeight: FontWeight.w800)),
                    Text(
                      '${inn.totalRuns}/${inn.wickets} (${inn.oversStr} Ov, RR: ${inn.runRate.toStringAsFixed(2)})',
                      style: const TextStyle(color: _inkPrimary, fontSize: 13, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                if (didNotBat.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Did not bat: ${didNotBat.join(", ")}',
                    style: const TextStyle(color: _inkMuted, fontSize: 11.5),
                  ),
                ],
              ],
            ),
          ),

          // Fall of Wickets
          if (fowList.isNotEmpty) ...[
            const Divider(color: _border, height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'FALL OF WICKETS',
                    style: TextStyle(
                      color: _inkMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    children: fowList
                        .map((fow) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _bgPage,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: _border),
                              ),
                              child: Text(
                                fow,
                                style: const TextStyle(color: _inkPrimary, fontSize: 11.5, fontWeight: FontWeight.w600),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ],

          // Partnerships
          if (partnerships.isNotEmpty) ...[
            const Divider(color: _border, height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PARTNERSHIPS',
                    style: TextStyle(
                      color: _inkMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...partnerships.map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              p.label,
                              style: const TextStyle(color: _inkSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${p.runs} (${p.balls})',
                            style: const TextStyle(color: _inkPrimary, fontSize: 12, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Bowling Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(
                top: BorderSide(color: _border),
                bottom: BorderSide(color: _border),
              ),
            ),
            child: const Row(
              children: [
                Expanded(flex: 5, child: Text('Bowler', style: _tableHeaderStyle)),
                Expanded(flex: 1, child: Text('O', textAlign: TextAlign.right, style: _tableHeaderStyle)),
                Expanded(flex: 1, child: Text('M', textAlign: TextAlign.right, style: _tableHeaderStyle)),
                Expanded(flex: 1, child: Text('R', textAlign: TextAlign.right, style: _tableHeaderStyle)),
                Expanded(flex: 1, child: Text('W', textAlign: TextAlign.right, style: _tableHeaderStyle)),
                Expanded(flex: 2, child: Text('Econ', textAlign: TextAlign.right, style: _tableHeaderStyle)),
              ],
            ),
          ),
          if (bowlCards.isEmpty)
            const Padding(
              padding: EdgeInsets.all(14),
              child: Text('No bowling entries yet.', style: TextStyle(color: _inkMuted, fontSize: 12)),
            )
          else
            ...bowlCards.map((bw) {
              final isBowling = bw.playerId == inn.currentBowlerId;
              return Container(
                decoration: BoxDecoration(
                  color: isBowling ? const Color(0xFFF0FDF4) : Colors.white,
                  border: const Border(bottom: BorderSide(color: _border)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Text(
                        bw.playerName,
                        style: TextStyle(
                          color: isBowling ? _emeraldDark : _inkPrimary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(flex: 1, child: Text(bw.oversStr, textAlign: TextAlign.right, style: _tableCellStyle)),
                    Expanded(flex: 1, child: Text('${bw.maidens}', textAlign: TextAlign.right, style: _tableCellStyle)),
                    Expanded(flex: 1, child: Text('${bw.runsConceded}', textAlign: TextAlign.right, style: _tableCellStyle)),
                    Expanded(
                      flex: 1,
                      child: Text(
                        '${bw.wickets}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(color: _inkPrimary, fontSize: 12.5, fontWeight: FontWeight.w800),
                      ),
                    ),
                    Expanded(flex: 2, child: Text(bw.economy.toStringAsFixed(2), textAlign: TextAlign.right, style: _tableCellStyle)),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  List<String> _computeFallOfWickets(MockDatabase db, List<Delivery> innDeliveries) {
    final result = <String>[];
    int runningRuns = 0;
    int runningWickets = 0;
    for (final d in innDeliveries) {
      runningRuns += d.totalRuns;
      if (d.isWicket) {
        runningWickets++;
        final outId = d.dismissedPlayerId ?? d.strikerId;
        final outName =
            db.players.where((p) => p.id == outId).firstOrNull?.fullName ?? 'Batter';
        result.add('$runningRuns-$runningWickets ($outName, ${d.overNumber}.${d.ballInOver})');
      }
    }
    return result;
  }

  List<_PartnershipInfo> _computePartnerships(MockDatabase db, List<Delivery> innDeliveries) {
    if (innDeliveries.isEmpty) return [];
    final list = <_PartnershipInfo>[];
    int runs = 0;
    int balls = 0;
    String? p1;
    String? p2;

    for (final d in innDeliveries) {
      p1 ??= d.strikerId;
      p2 ??= d.nonStrikerId;
      runs += d.totalRuns;
      if (d.isLegal) balls++;
      if (d.isWicket) {
        final n1 = db.players.where((p) => p.id == p1).firstOrNull?.fullName ?? 'Batter 1';
        final n2 = db.players.where((p) => p.id == p2).firstOrNull?.fullName ?? 'Batter 2';
        list.add(_PartnershipInfo(label: '$n1 & $n2', runs: runs, balls: balls));
        runs = 0;
        balls = 0;
        p1 = null;
        p2 = null;
      }
    }
    if (runs > 0 || balls > 0) {
      final n1 = db.players.where((p) => p.id == p1).firstOrNull?.fullName ?? 'Batter 1';
      final n2 = db.players.where((p) => p.id == p2).firstOrNull?.fullName ?? 'Batter 2';
      list.add(_PartnershipInfo(label: '$n1 & $n2 *', runs: runs, balls: balls));
    }
    return list;
  }

  // =========================================================================
  // TAB 3: BALL-BY-BALL COMMENTARY (OVER-WISE COLLAPSIBLE, LATEST FIRST)
  // =========================================================================
  Widget _buildCommentaryTab(
    BuildContext context,
    MockDatabase db,
    MatchModel match,
    Innings? activeInn,
    List<Delivery> allDeliveries,
  ) {
    if (allDeliveries.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No deliveries recorded yet. Ball-by-ball commentary will stream automatically.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _inkMuted, fontSize: 13),
          ),
        ),
      );
    }

    // Group by (inningsId, overNumber) while preserving chronological totals
    final Map<String, List<Delivery>> byOver = {};
    final Map<String, int> scoreAfterOver = {};
    final Map<String, int> wktsAfterOver = {};
    final Map<String, int> inningsNumberByKey = {};

    final matchInnings = db.inningsList.where((i) => i.matchId == match.id).toList();
    final innNumMap = {for (final i in matchInnings) i.id: i.inningsNumber};

    final Map<String, int> runningInnRuns = {};
    final Map<String, int> runningInnWkts = {};
    final orderedKeys = <String>[];

    for (final d in allDeliveries) {
      final key = '${d.inningsId}_over_${d.overNumber}';
      if (!byOver.containsKey(key)) {
        byOver[key] = [];
        orderedKeys.add(key);
        inningsNumberByKey[key] = innNumMap[d.inningsId] ?? 1;
      }
      byOver[key]!.add(d);
      runningInnRuns[d.inningsId] = (runningInnRuns[d.inningsId] ?? 0) + d.totalRuns;
      if (d.isWicket) {
        runningInnWkts[d.inningsId] = (runningInnWkts[d.inningsId] ?? 0) + 1;
      }
      scoreAfterOver[key] = runningInnRuns[d.inningsId] ?? 0;
      wktsAfterOver[key] = runningInnWkts[d.inningsId] ?? 0;
    }

    final reversedKeys = orderedKeys.reversed.toList();
    final latestOverHash = reversedKeys.first.hashCode;
    if (_latestSeenOverKey != latestOverHash) {
      _latestSeenOverKey = latestOverHash;
      _expandedOvers.add(latestOverHash);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: reversedKeys.length,
      itemBuilder: (context, idx) {
        final key = reversedKeys[idx];
        final overDeliveries = byOver[key]!.reversed.toList(); // Latest ball first
        final overNum = overDeliveries.first.overNumber;
        final innNum = inningsNumberByKey[key] ?? 1;
        final overRuns = overDeliveries.fold<int>(0, (s, d) => s + d.totalRuns);
        final overWkts = overDeliveries.where((d) => d.isWicket).length;
        final totalScore = scoreAfterOver[key] ?? 0;
        final totalWkts = wktsAfterOver[key] ?? 0;
        final isExpanded = _expandedOvers.contains(key.hashCode);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: _bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: idx == 0 ? _emerald.withValues(alpha: 0.4) : _border),
          ),
          child: Column(
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    if (isExpanded) {
                      _expandedOvers.remove(key.hashCode);
                    } else {
                      _expandedOvers.add(key.hashCode);
                    }
                  });
                },
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: idx == 0 ? _emerald : const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'OVER ${overNum + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Inn $innNum • $overRuns runs${overWkts > 0 ? ", $overWkts wkt" : ""} • Score: $totalScore/$totalWkts',
                          style: const TextStyle(
                            color: _inkPrimary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: _inkMuted,
                      ),
                    ],
                  ),
                ),
              ),
              if (isExpanded) ...[
                const Divider(color: _border, height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                  child: Column(
                    children: overDeliveries.asMap().entries.map((entry) {
                      final isLatestBall = idx == 0 && entry.key == 0;
                      return _DeliveryCommentaryRow(
                        delivery: entry.value,
                        db: db,
                        highlight: isLatestBall,
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // =========================================================================
  // TAB 4: TEAMS & SQUADS
  // =========================================================================
  Widget _buildTeamsTab(
    BuildContext context,
    MockDatabase db,
    MatchModel match,
    Team teamA,
    Team teamB,
  ) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    final cardA = _buildSquadCard(db, teamA, match.playingXIA, match.captainAId, match.keeperAId);
    final cardB = _buildSquadCard(db, teamB, match.playingXIB, match.captainBId, match.keeperBId);

    if (isWide) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: cardA),
            const SizedBox(width: 16),
            Expanded(child: cardB),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          cardA,
          const SizedBox(height: 14),
          cardB,
        ],
      ),
    );
  }

  Widget _buildSquadCard(
    MockDatabase db,
    Team team,
    List<String> playingXIIds,
    String? captainId,
    String? keeperId,
  ) {
    final xiPlayers = playingXIIds
        .map((id) => db.players.where((p) => p.id == id).firstOrNull)
        .whereType<Player>()
        .toList();
    final squadExtras = db.players
        .where((p) => p.teamId == team.id && !playingXIIds.contains(p.id))
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _TeamAvatar(team: team, size: 32),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    team.name,
                    style: const TextStyle(
                      color: _inkPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  'Playing XI (${xiPlayers.length})',
                  style: const TextStyle(color: _inkMuted, fontSize: 11.5, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const Divider(color: _border, height: 1),
          if (xiPlayers.isEmpty && squadExtras.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Playing XI not announced yet.',
                style: TextStyle(color: _inkMuted, fontSize: 12),
              ),
            )
          else ...[
            ...xiPlayers.map((p) => _buildPlayerTile(p, captainId, keeperId, isXi: true)),
            if (squadExtras.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                color: _bgPage,
                child: const Text(
                  'BENCH / SQUAD',
                  style: TextStyle(
                    color: _inkMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              ...squadExtras.map((p) => _buildPlayerTile(p, captainId, keeperId, isXi: false)),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildPlayerTile(
    Player player,
    String? captainId,
    String? keeperId, {
    required bool isXi,
  }) {
    final badges = <String>[];
    if (player.id == captainId) badges.add('C');
    if (player.id == keeperId) badges.add('WK');
    final badgeSuffix = badges.isNotEmpty ? ' (${badges.join(", ")})' : '';

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: isXi ? const Color(0xFFECFDF5) : _bgPage,
            backgroundImage:
                player.photoUrl.isNotEmpty ? NetworkImage(player.photoUrl) : null,
            child: player.photoUrl.isEmpty
                ? Text(
                    player.fullName.isNotEmpty ? player.fullName[0].toUpperCase() : 'P',
                    style: TextStyle(
                      color: isXi ? _emeraldDark : _inkMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${player.fullName}$badgeSuffix',
                  style: const TextStyle(
                    color: _inkPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${_formatPlayerRole(player.role)} • ${player.battingStyle}',
                  style: const TextStyle(color: _inkMuted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 5: MATCH INFO
  // =========================================================================
  Widget _buildInfoTab(
    BuildContext context,
    MockDatabase db,
    MatchModel match,
    Tournament? tournament,
    Team teamA,
    Team teamB,
  ) {
    final tossTeam = match.tossWonBy != null
        ? (match.tossWonBy == teamA.id ? teamA.name : teamB.name)
        : null;
    final dateStr = DateFormat('EEEE, d MMMM yyyy • h:mm a').format(match.dateTime);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'MATCH INFORMATION',
              style: TextStyle(
                color: _inkMuted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 12),
            _infoRow('Match', '${teamA.name} vs ${teamB.name}'),
            _infoRow('Stage / Number', match.stage),
            _infoRow('Tournament', tournament?.name ?? 'Friendly / Direct Match'),
            if (tournament != null && tournament.location.isNotEmpty)
              _infoRow('Tournament City', tournament.location),
            _infoRow('Date & Time', dateStr),
            _infoRow('Venue', match.venue),
            _infoRow('Format', '${match.overs} Overs'),
            _infoRow(
              'Toss',
              tossTeam != null
                  ? '$tossTeam won the toss & chose to ${match.tossDecision ?? "bat"}'
                  : 'Toss pending',
            ),
            _infoRow('Status', _statusPresentation(match.status).label),
            if ((match.playerOfTheMatchName ?? '').isNotEmpty)
              _infoRow('Player of the Match', match.playerOfTheMatchName!),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(color: _inkMuted, fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: _inkPrimary, fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPlayerRole(PlayerRole role) {
    switch (role) {
      case PlayerRole.batsman:
        return 'Batter';
      case PlayerRole.bowler:
        return 'Bowler';
      case PlayerRole.allRounder:
        return 'All-Rounder';
      case PlayerRole.wicketKeeper:
        return 'Wicketkeeper';
    }
  }

  _StatusStyle _statusPresentation(MatchStatus status) {
    switch (status) {
      case MatchStatus.live:
        return const _StatusStyle(
          label: 'LIVE',
          bgColor: Color(0xFFFEF2F2),
          borderColor: Color(0xFFFECACA),
          textColor: _liveRed,
        );
      case MatchStatus.inningsBreak:
        return const _StatusStyle(
          label: 'INNINGS BREAK',
          bgColor: Color(0xFFFFFBEB),
          borderColor: Color(0xFFFDE68A),
          textColor: Color(0xFFB45309),
        );
      case MatchStatus.completed:
        return const _StatusStyle(
          label: 'COMPLETED',
          bgColor: Color(0xFFECFDF5),
          borderColor: Color(0xFFA7F3D0),
          textColor: _emeraldDark,
        );
      case MatchStatus.abandoned:
        return const _StatusStyle(
          label: 'NO RESULT',
          bgColor: Color(0xFFF1F5F9),
          borderColor: Color(0xFFCBD5E1),
          textColor: _inkSecondary,
        );
      case MatchStatus.scheduled:
      case MatchStatus.toss:
        return const _StatusStyle(
          label: 'UPCOMING',
          bgColor: Color(0xFFEFF6FF),
          borderColor: Color(0xFFBFDBFE),
          textColor: Color(0xFF1D4ED8),
        );
    }
  }

  static const TextStyle _tableHeaderStyle = TextStyle(
    color: _inkMuted,
    fontSize: 11,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle _tableCellStyle = TextStyle(
    color: _inkSecondary,
    fontSize: 12.5,
    fontWeight: FontWeight.w600,
  );
}

class _StatusStyle {
  final String label;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;

  const _StatusStyle({
    required this.label,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
  });
}

class _PartnershipInfo {
  final String label;
  final int runs;
  final int balls;

  const _PartnershipInfo({
    required this.label,
    required this.runs,
    required this.balls,
  });
}

class _TournamentBadge extends StatelessWidget {
  final Tournament? tournament;

  const _TournamentBadge({required this.tournament});

  @override
  Widget build(BuildContext context) {
    final url = tournament?.bannerUrl ?? '';
    if (url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          url,
          width: 32,
          height: 32,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallbackIcon(),
        ),
      );
    }
    return _fallbackIcon();
  }

  Widget _fallbackIcon() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: const Icon(Icons.sports_cricket, size: 18, color: Color(0xFF009270)),
    );
  }
}

class _TeamAvatar extends StatelessWidget {
  final Team team;
  final double size;

  const _TeamAvatar({required this.team, required this.size});

  @override
  Widget build(BuildContext context) {
    if (team.logoUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          team.logoUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _initialsCircle(),
        ),
      );
    }
    return _initialsCircle();
  }

  Widget _initialsCircle() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: team.primaryColor.withValues(alpha: 0.14),
        shape: BoxShape.circle,
        border: Border.all(color: team.primaryColor.withValues(alpha: 0.5)),
      ),
      alignment: Alignment.center,
      child: Text(
        team.shortName.isNotEmpty ? team.shortName[0].toUpperCase() : 'T',
        style: TextStyle(
          color: const Color(0xFF0F172A),
          fontSize: size * 0.42,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DeliveryPill extends StatelessWidget {
  final Delivery delivery;

  const _DeliveryPill({required this.delivery});

  @override
  Widget build(BuildContext context) {
    final style = _deliveryVisual(delivery);
    return Container(
      constraints: const BoxConstraints(minWidth: 32),
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: style.border),
      ),
      alignment: Alignment.center,
      child: Text(
        style.shortLabel,
        style: TextStyle(
          color: style.fg,
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DeliveryCommentaryRow extends StatelessWidget {
  final Delivery delivery;
  final MockDatabase db;
  final bool highlight;

  const _DeliveryCommentaryRow({
    required this.delivery,
    required this.db,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = _deliveryVisual(delivery);
    final bowler = db.players.where((p) => p.id == delivery.bowlerId).firstOrNull;
    final batter = db.players.where((p) => p.id == delivery.strikerId).firstOrNull;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlight ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 42,
            child: Text(
              '${delivery.overNumber}.${delivery.ballInOver}',
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _DeliveryPill(delivery: delivery),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: style.bg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        style.eventLabel,
                        style: TextStyle(
                          color: style.fg,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (bowler != null || batter != null) ...[
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${bowler?.fullName ?? "Bowler"} to ${batter?.fullName ?? "Batter"}',
                          style: const TextStyle(
                            color: Color(0xFF475569),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  delivery.commentaryText,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryStyle {
  final String shortLabel;
  final String eventLabel;
  final Color bg;
  final Color fg;
  final Color border;

  const _DeliveryStyle({
    required this.shortLabel,
    required this.eventLabel,
    required this.bg,
    required this.fg,
    required this.border,
  });
}

_DeliveryStyle _deliveryVisual(Delivery d) {
  if (d.isWicket) {
    return const _DeliveryStyle(
      shortLabel: 'W',
      eventLabel: 'WICKET',
      bg: Color(0xFFDC2626),
      fg: Colors.white,
      border: Color(0xFFB91C1C),
    );
  }
  if (d.extrasType == ExtrasType.wide) {
    final label = d.totalRuns > 1 ? '${d.totalRuns}wd' : 'wd';
    return _DeliveryStyle(
      shortLabel: label,
      eventLabel: 'WIDE (+${d.totalRuns})',
      bg: const Color(0xFFFEF3C7),
      fg: const Color(0xFFB45309),
      border: const Color(0xFFFCD34D),
    );
  }
  if (d.extrasType == ExtrasType.noBall) {
    final label = d.totalRuns > 1 ? '${d.totalRuns}nb' : 'nb';
    return _DeliveryStyle(
      shortLabel: label,
      eventLabel: 'NO BALL (+${d.totalRuns})',
      bg: const Color(0xFFFFEDD5),
      fg: const Color(0xFFC2410C),
      border: const Color(0xFFFDBA74),
    );
  }
  if (d.extrasType == ExtrasType.bye) {
    return _DeliveryStyle(
      shortLabel: '${d.totalRuns}b',
      eventLabel: 'BYE (${d.totalRuns})',
      bg: const Color(0xFFF1F5F9),
      fg: const Color(0xFF334155),
      border: const Color(0xFFCBD5E1),
    );
  }
  if (d.extrasType == ExtrasType.legBye) {
    return _DeliveryStyle(
      shortLabel: '${d.totalRuns}lb',
      eventLabel: 'LEG BYE (${d.totalRuns})',
      bg: const Color(0xFFF1F5F9),
      fg: const Color(0xFF334155),
      border: const Color(0xFFCBD5E1),
    );
  }
  if (d.runsBatter == 4) {
    return const _DeliveryStyle(
      shortLabel: '4',
      eventLabel: 'FOUR',
      bg: Color(0xFF2563EB),
      fg: Colors.white,
      border: Color(0xFF1D4ED8),
    );
  }
  if (d.runsBatter == 6) {
    return const _DeliveryStyle(
      shortLabel: '6',
      eventLabel: 'SIX',
      bg: Color(0xFF7C3AED),
      fg: Colors.white,
      border: Color(0xFF6D28D9),
    );
  }
  if (d.totalRuns == 0) {
    return const _DeliveryStyle(
      shortLabel: '•',
      eventLabel: 'DOT BALL',
      bg: Color(0xFFF1F5F9),
      fg: Color(0xFF64748B),
      border: Color(0xFFCBD5E1),
    );
  }
  return _DeliveryStyle(
    shortLabel: '${d.totalRuns}',
    eventLabel: '${d.totalRuns} ${d.totalRuns == 1 ? "RUN" : "RUNS"}',
    bg: const Color(0xFFECFDF5),
    fg: const Color(0xFF065F46),
    border: const Color(0xFFA7F3D0),
  );
}
