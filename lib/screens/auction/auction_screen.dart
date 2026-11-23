import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/mock_database.dart';
import '../../theme/neo_glass_theme.dart';
import '../../widgets/app_animations.dart';
import 'create_auction_dialog.dart';
import 'add_player_dialog.dart';
import 'auction_projector_screen.dart';

class AuctionScreen extends StatefulWidget {
  final String? initialAuctionId;

  const AuctionScreen({super.key, this.initialAuctionId});

  @override
  State<AuctionScreen> createState() => _AuctionScreenState();
}

class _AuctionScreenState extends State<AuctionScreen> with SingleTickerProviderStateMixin {
  String? selectedAuctionId;
  String? selectedTeamIdForSquadView;

  late AnimationController _wheelController;
  late Animation<double> _wheelAnimation;
  double _currentAngle = 0.0;
  bool _isSpinning = false;
  Timer? _auctionTimer;

  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    selectedAuctionId = widget.initialAuctionId;
    _wheelController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _auctionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (selectedAuctionId != null && mounted) {
        final db = Provider.of<MockDatabase>(context, listen: false);
        final auc = db.auctions.where((a) => a.id == selectedAuctionId).firstOrNull;
        if (auc != null && auc.isTimerRunning) {
          db.tickAuctionTimer(auc.id);
        }
      }
    });
  }

  @override
  void dispose() {
    _auctionTimer?.cancel();
    _wheelController.dispose();
    super.dispose();
  }

  void _spinWheel(MockDatabase db, Auction auction) {
    if (_isSpinning) return;
    if (!db.canSpinPlayer(auction.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access Denied: Only the assigned Auctioneer can spin and reveal the next player!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    if (!auction.isReadyToStart) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Auction cannot start until all 8 franchise teams enter the room!')),
      );
      return;
    }

    final eligibleLots = db.auctionLots
        .where((l) => l.auctionId == auction.id && l.status == LotStatus.pending && l.isSelectedForSpin)
        .toList();

    if (eligibleLots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No eligible players selected for spin! Check Host Player Pool.')),
      );
      return;
    }

    setState(() => _isSpinning = true);

    final randomExtraSpins = 4 + Random().nextInt(4);
    final targetAngle = _currentAngle + (2 * pi * randomExtraSpins) + (Random().nextDouble() * 2 * pi);

    _wheelAnimation = Tween<double>(begin: _currentAngle, end: targetAngle).animate(
      CurvedAnimation(parent: _wheelController, curve: Curves.decelerate),
    )..addListener(() {
        setState(() {});
      });

    _wheelController.forward(from: 0.0).then((_) {
      _currentAngle = targetAngle % (2 * pi);
      setState(() => _isSpinning = false);
      db.spinToRandomEligibleLot(auction.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final db = context.watch<MockDatabase>();

    if (db.auctions.isEmpty) {
      return _buildEmptyAuctionDirectory(context, db);
    }

    if (selectedAuctionId == null) {
      return _buildAuctionDirectory(context, db);
    }

    final auction = db.auctions.where((a) => a.id == selectedAuctionId).firstOrNull;
    if (auction == null) {
      return _buildAuctionDirectory(context, db);
    }

    return _buildAuctionArena(context, db, auction);
  }

  Widget _buildEmptyAuctionDirectory(BuildContext context, MockDatabase db) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1120),
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: Color(0xFF1E293B))),
        title: const Text('Franchise Auctions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        actions: const [SizedBox(width: 8)],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.gavel_outlined, size: 52, color: Colors.amberAccent),
              ),
              const SizedBox(height: 20),
              const Text('No Player Auctions Created', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              const Text(
                'Host a live player auction with franchise budgets, player wheel spin, and owner bidding.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  final created = await showDialog<Auction>(
                    context: context,
                    builder: (ctx) => CreateAuctionDialog(db: db),
                  );
                  if (created != null) {
                    setState(() {
                      selectedAuctionId = created.id;
                      selectedTeamIdForSquadView = null;
                    });
                  }
                },
                icon: const Icon(Icons.add, size: 16, color: Colors.black),
                label: const Text('Host New Auction', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 1. AUCTION DIRECTORY / HUB (BPL, PSL, IPL Auctions)
  // =========================================================================
  Widget _buildAuctionDirectory(BuildContext context, MockDatabase db) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1120),
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: Color(0xFF1E293B))),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.gavel, size: 15, color: Colors.black),
            ),
            const SizedBox(width: 10),
            const Flexible(
              child: Text(
                'Auctions Arena',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Host New Auction',
            icon: const Icon(Icons.add_circle, color: Colors.amber, size: 22),
            onPressed: () async {
              final created = await showDialog<Auction>(
                context: context,
                builder: (ctx) => CreateAuctionDialog(db: db),
              );
              if (created != null) {
                setState(() {
                  selectedAuctionId = created.id;
                  selectedTeamIdForSquadView = null;
                });
              }
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner with Owner Login & Host New Auction
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('OFFICIAL CRICKET DRAFT ARENA', style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                const SizedBox(height: 6),
                const Text('Live Player Auctions & Franchise Purses', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                const Text(
                  'Select an auction to view live player lots, franchise waiting rooms, spinning wheel reveals, and team bidding.',
                  style: TextStyle(color: Colors.white60, fontSize: 11),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _showTeamOwnerGlobalLoginDialog(context, db),
                      icon: const Icon(Icons.vpn_key, size: 14, color: Colors.black),
                      label: const Text('Enter as Team Owner', style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final created = await showDialog<Auction>(
                          context: context,
                          builder: (ctx) => CreateAuctionDialog(db: db),
                        );
                        if (created != null) {
                          setState(() {
                            selectedAuctionId = created.id;
                            selectedTeamIdForSquadView = null;
                          });
                        }
                      },
                      icon: const Icon(Icons.add_circle_outline, size: 14, color: Colors.white),
                      label: const Text('Host New Auction', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white30),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'ACTIVE & UPCOMING AUCTIONS',
            style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
          const SizedBox(height: 10),

          ...db.auctions.map((auc) {
            final tourn = db.tournaments.where((t) => t.id == auc.tournamentId).firstOrNull ?? db.tournament;
            final isLive = auc.status == AuctionStatus.live;
            final ready = auc.isReadyToStart;

            return InkWell(
              onTap: () => setState(() => selectedAuctionId = auc.id),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: isLive ? const Color(0xFF059669) : const Color(0xFF1E293B), width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (isLive && ready)
                          const PulsingLiveBadge(label: 'LIVE BIDDING', color: Color(0xFF34D399))
                        else if (isLive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF064E3B),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time, size: 9, color: Color(0xFF34D399)),
                                const SizedBox(width: 5),
                                Text(
                                  'WAITING ROOM (${auc.requiredTeamsCount} TEAMS)',
                                  style: const TextStyle(
                                    color: Color(0xFF34D399),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'PREVIEW',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        Text(
                          '${auc.joinedTeamIds.length}/${auc.requiredTeamsCount} Teams Ready',
                          style: TextStyle(
                            color: ready ? const Color(0xFF34D399) : Colors.amber,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(auc.title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text('${tourn.name} • ${tourn.location}', style: const TextStyle(color: Colors.white60, fontSize: 11)),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _buildStatChip(Icons.monetization_on, 'Purse: ${currencyFormat.format(auc.maxPursePerTeam)}'),
                              _buildStatChip(Icons.gavel, 'Min: ${currencyFormat.format(auc.minBidIncrement)}'),
                              _buildStatChip(Icons.groups, '${auc.requiredTeamsCount} Teams'),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white54),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.amber),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 9.5, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // =========================================================================
  // 2. AUCTION ARENA (LIVE STAGE, SPIN WHEEL, BIDDING & SQUADS)
  // =========================================================================
  Widget _buildAuctionArena(BuildContext context, MockDatabase db, Auction auction) {
    final currentLot = db.auctionLots.where((l) => l.id == auction.currentLotId).firstOrNull;
    final currentPlayer = currentLot != null
        ? db.players.where((p) => p.id == currentLot.playerId).firstOrNull
        : null;
    final highBidderTeam = db.teams.where((t) => t.id == auction.highBidderTeamId).firstOrNull;

    final isAdmin = db.canManageAuctionFloor(auction.id);
    final myTeam = db.currentAuthenticatedTeam;
    final isUnlocked = isAdmin || myTeam != null;

    // Strict Tournament Isolation: Only teams belonging to this auction's tournament
    final safe8Teams = db.teams.where((t) => t.tournamentId == auction.tournamentId).toList();

    // Default squad view team
    selectedTeamIdForSquadView ??= myTeam?.id ?? (safe8Teams.isNotEmpty ? safe8Teams.first.id : null);
    final squadViewTeam = safe8Teams.where((t) => t.id == selectedTeamIdForSquadView).firstOrNull ??
        (safe8Teams.isNotEmpty ? safe8Teams.first : null);
    final squadPlayers = squadViewTeam != null
        ? db.players.where((p) => p.teamId == squadViewTeam.id).toList()
        : <Player>[];

    final eligibleSpinCount = db.auctionLots.where((l) => l.auctionId == auction.id && l.status == LotStatus.pending && l.isSelectedForSpin).length;
    final totalPendingCount = db.auctionLots.where((l) => l.auctionId == auction.id && l.status == LotStatus.pending).length;
    final unsoldLotsCount = db.auctionLots.where((l) => l.auctionId == auction.id && l.status == LotStatus.unsold).length;

    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1120),
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: Color(0xFF1E293B))),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          tooltip: 'All Auctions',
          onPressed: () => setState(() => selectedAuctionId = null),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              auction.title,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900),
              overflow: TextOverflow.ellipsis,
            ),
            Row(
              children: [
                Icon(
                  isUnlocked ? (isAdmin ? Icons.shield : Icons.check_circle) : Icons.visibility,
                  size: 11,
                  color: isUnlocked ? (isAdmin ? Colors.amber : const Color(0xFF34D399)) : Colors.white54,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    isUnlocked
                        ? (isAdmin ? 'Host Auctioneer' : (myTeam?.shortName ?? 'Owner'))
                        : 'Spectator Mode',
                    style: TextStyle(
                      color: isUnlocked ? (isAdmin ? Colors.amber : const Color(0xFF34D399)) : Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'TV Mode',
            icon: const Icon(Icons.tv, color: Colors.amber, size: 20),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => AuctionProjectorScreen(auctionId: auction.id),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
            tooltip: 'Auction Menu',
            color: const Color(0xFF1E293B),
            onSelected: (val) {
              if (val == 'hub') {
                _showPlayersHubDialog(context, db, auction);
              } else if (val == 'reports') {
                _showAuctionReportsDialog(context, db, auction);
              } else if (val == 'whatsapp') {
                _showWhatsAppNotificationsDialog(context, db, auction);
              } else if (val == 'audit') {
                _showAuditTrailDialog(context, db, auction);
              } else if (val == 'bulk') {
                _showBulkImportCsvDialog(context, db, auction);
              } else if (val == 'edit') {
                _showEditAuctionDialog(context, db, auction);
              } else if (val == 'pool') {
                _showHostPlayerPoolManagerDialog(context, db, auction);
              } else if (val == 'player') {
                showDialog(
                  context: context,
                  builder: (ctx) => AddPlayerDialog(db: db, auctionId: auction.id),
                );
              } else if (val == 'approvals') {
                _showHostFranchiseApprovalsDialog(context, db, auction, safe8Teams);
              } else if (val == 'team') {
                _showAddTeamDialog(context, db, auction);
              } else if (val == 'enter_room') {
                _showEnterAuctionRoomDialog(context, db, auction, safe8Teams);
              } else if (val == 'exit_spectator') {
                db.exitAuctionRoom();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Returned to Spectator Broadcast.')),
                );
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'hub',
                child: Row(
                  children: [
                    Icon(Icons.people_alt, color: Color(0xFF34D399), size: 16),
                    SizedBox(width: 8),
                    Text('Players Hub (Available / Sold / Unsold)', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reports',
                child: Row(
                  children: [
                    Icon(Icons.assessment, color: Colors.amber, size: 16),
                    SizedBox(width: 8),
                    Text('Auction Reports & CSV Export', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'whatsapp',
                child: Row(
                  children: [
                    Icon(Icons.chat_bubble, color: Color(0xFF22C55E), size: 16),
                    SizedBox(width: 8),
                    Text('WhatsApp Notifications Log', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'audit',
                child: Row(
                  children: [
                    Icon(Icons.history, color: Colors.cyanAccent, size: 16),
                    SizedBox(width: 8),
                    Text('Immutable Audit Trail', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
              if (isAdmin) ...[
                const PopupMenuDivider(height: 8),
                const PopupMenuItem(
                  value: 'bulk',
                  child: Row(
                    children: [
                      Icon(Icons.file_upload, color: Color(0xFF38BDF8), size: 16),
                      SizedBox(width: 8),
                      Text('Bulk Import Players (CSV)', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_note, color: Colors.amber, size: 16),
                      SizedBox(width: 8),
                      Text('Edit Auction Rules', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'pool',
                  child: Row(
                    children: [
                      const Icon(Icons.manage_accounts, color: Colors.amber, size: 16),
                      const SizedBox(width: 8),
                      Text('Spin Pool ($eligibleSpinCount/$totalPendingCount)', style: const TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'player',
                  child: Row(
                    children: [
                      Icon(Icons.person_add, color: Color(0xFF34D399), size: 16),
                      SizedBox(width: 8),
                      Text('Add Player to Auction', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'approvals',
                  child: Row(
                    children: [
                      Icon(Icons.badge, color: Color(0xFF38BDF8), size: 16),
                      SizedBox(width: 8),
                      Text('Franchise PINs & Access', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'team',
                  child: Row(
                    children: [
                      Icon(Icons.group_add, color: Colors.amber, size: 16),
                      SizedBox(width: 8),
                      Text('Add Franchise Team', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
              ],
              const PopupMenuDivider(height: 8),
              if (!isUnlocked)
                const PopupMenuItem(
                  value: 'enter_room',
                  child: Row(
                    children: [
                      Icon(Icons.vpn_key, color: Colors.amber, size: 16),
                      SizedBox(width: 8),
                      Text('Enter with Franchise PIN', style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              else
                const PopupMenuItem(
                  value: 'exit_spectator',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.redAccent, size: 16),
                      SizedBox(width: 8),
                      Text('Exit to Spectator', style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // =========================================================
            // DEDICATED REGISTERED PLAYER PERSONA DASHBOARD
            // =========================================================
            if (db.isPlayerPersona) ...[
              _buildPlayerPersonaDashboard(context, db, auction),
              const SizedBox(height: 12),
            ],

            // =========================================================
            // DEDICATED TEAM OWNER DESK BANNER (IF AUTHENTICATED)
            // =========================================================
            if (myTeam != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      myTeam.primaryColor.withValues(alpha: 0.35),
                      const Color(0xFF0F172A),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: myTeam.primaryColor.withValues(alpha: 0.8), width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: myTeam.primaryColor,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            myTeam.shortName,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      myTeam.name,
                                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF059669),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'YOUR FRANCHISE TABLE',
                                      style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Owner: ${myTeam.ownerName.isNotEmpty ? myTeam.ownerName : "Authorized Owner"} • Mobile: ${myTeam.ownerMobileNumber.isNotEmpty ? myTeam.ownerMobileNumber : myTeam.uniqueTeamCode}',
                                style: const TextStyle(color: Colors.white70, fontSize: 10.5),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Exit Desk',
                          icon: const Icon(Icons.logout, size: 18, color: Colors.white60),
                          onPressed: () {
                            db.exitAuctionRoom();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Returned to spectator mode.')),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Remaining Purse: ₹${currencyFormat.format(myTeam.purseRemaining)}',
                            style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Squad: ${myTeam.squadCount}/${myTeam.maxSquadLimit} players',
                            style: const TextStyle(color: Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF064E3B),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, size: 11, color: Color(0xFF34D399)),
                              SizedBox(width: 4),
                              Text(
                                'Live Bidding Active',
                                style: TextStyle(color: Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else if (isAdmin) ...[
              // HOST / ORGANIZER COCKPIT BANNER
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.6)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.admin_panel_settings, color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'HOST / ORGANIZER COCKPIT',
                            style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.w900),
                          ),
                          Text(
                            'Manage auction rules, player lots, spin wheel, and floor hammer.',
                            style: TextStyle(color: Colors.white60, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _showEditAuctionDialog(context, db, auction),
                          icon: const Icon(Icons.edit, size: 12, color: Colors.amber),
                          label: const Text('Edit', style: TextStyle(color: Colors.amber, fontSize: 10.5, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.amber),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AddPlayerDialog(db: db, auctionId: auction.id),
                            );
                          },
                          icon: const Icon(Icons.add, size: 12, color: Colors.black),
                          label: const Text('Add Player', style: TextStyle(color: Colors.black, fontSize: 10.5, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF34D399),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else if (!isUnlocked) ...[
              // SPECTATOR / VIEWING BROADCAST BANNER
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.visibility, color: Colors.white70, size: 20),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Spectator Mode (Viewing Live)',
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'You are viewing live bids, wheel reveals, and team squads.',
                            style: TextStyle(color: Colors.white60, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showEnterAuctionRoomDialog(context, db, auction, safe8Teams),
                      icon: const Icon(Icons.vpn_key, size: 13, color: Colors.black),
                      label: const Text('Owner Login', style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // =========================================================
            // REAL-TIME FLOOR STATUS ALERT BANNER (Going once / Twice / Paused)
            // =========================================================
            _buildFloorStatusBanner(auction, highBidderTeam),
            const SizedBox(height: 12),

            // =========================================================
            // 8-TEAM WAITING ROOM LOBBY BANNER
            // =========================================================
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: auction.isReadyToStart ? const Color(0xFF064E3B) : const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: auction.isReadyToStart ? const Color(0xFF34D399) : Colors.amber.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            auction.isReadyToStart ? Icons.verified : Icons.hourglass_top,
                            size: 16,
                            color: auction.isReadyToStart ? const Color(0xFF34D399) : Colors.amber,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            auction.isReadyToStart
                                ? 'ALL 8 FRANCHISE TEAMS CONNECTED'
                                : 'WAITING ROOM: 8 TEAMS REQUIRED',
                            style: TextStyle(
                              color: auction.isReadyToStart ? const Color(0xFF34D399) : Colors.amber,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${auction.joinedTeamIds.length}/8 Ready',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    auction.isReadyToStart
                        ? 'Auction is LIVE! Host spins wheel to reveal players and only authenticated team owners place bids.'
                        : 'Until all 8 teams enter the auction room with their unique Team ID & PIN, bidding and wheel spinning are locked.',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  const SizedBox(height: 10),

                  // 8-Team Connected Status Chips
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: safe8Teams.map((t) {
                      final isConnected = auction.joinedTeamIds.contains(t.id);
                      return InkWell(
                        onTap: () {
                          if (isAdmin && !isConnected) {
                            db.checkInTeamToAuction(auction.id, t.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${t.name} approved to bid by Host!')),
                            );
                          } else if (!isAdmin && !isConnected) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${t.name} is waiting for team owner to enter with Code & PIN.')),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isConnected ? const Color(0xFF047857) : Colors.white10,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isConnected ? const Color(0xFF34D399) : Colors.white24),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isConnected ? Icons.check_circle : Icons.radio_button_unchecked,
                                size: 10,
                                color: isConnected ? Colors.white : Colors.white38,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                t.shortName,
                                style: TextStyle(
                                  color: isConnected ? Colors.white : Colors.white60,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  if (isAdmin) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showHostFranchiseApprovalsDialog(context, db, auction, safe8Teams),
                            icon: const Icon(Icons.badge, size: 14, color: Colors.amber),
                            label: const Text('Franchise Permissions & PINs', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.amber),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                        if (!auction.isReadyToStart) ...[
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              db.checkInAllTeamsToAuction(auction.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('All 8 teams approved & entered! Auction unlocked.')),
                              );
                            },
                            icon: const Icon(Icons.flash_on, size: 14),
                            label: const Text('Approve All 8', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // =========================================================
            // SPINNING WHEEL BANNER (HOST CONTROLLED FROM SELECTED POOL)
            // =========================================================
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '🎡 PLAYER SELECTION WHEEL',
                        style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                      ),
                      if (isAdmin)
                        InkWell(
                          onTap: () => _showHostPlayerPoolManagerDialog(context, db, auction),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.amber),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.settings, size: 10, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text(
                                  'Wheel Pool: $eligibleSpinCount/$totalPendingCount',
                                  style: const TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Animated Wheel Graphics
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Wheel Canvas
                      Transform.rotate(
                        angle: _isSpinning ? _wheelAnimation.value : _currentAngle,
                        child: CustomPaint(
                          size: const Size(190, 190),
                          painter: AuctionWheelPainter(itemsCount: max(4, min(8, eligibleSpinCount))),
                        ),
                      ),
                      // Center Spin Hub
                      GestureDetector(
                        onTap: () {
                          if (!auction.isReadyToStart) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Cannot spin wheel until all 8 teams enter the room!')),
                            );
                            return;
                          }
                          final canSpin = db.canSpinPlayer(auction.id);
                          if (!canSpin) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Access Denied: Only the assigned Auctioneer (${auction.assignedAuctioneerName.isNotEmpty ? auction.assignedAuctioneerName : "Auctioneer"}) can spin and reveal players!',
                                ),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                            return;
                          }
                          _spinWheel(db, auction);
                        },
                        child: Container(
                          width: 66,
                          height: 66,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: auction.isReadyToStart && db.canSpinPlayer(auction.id)
                                  ? [const Color(0xFFFDE68A), const Color(0xFFF59E0B), const Color(0xFFB45309)]
                                  : [const Color(0xFF334155), const Color(0xFF1E293B), const Color(0xFF0F172A)],
                            ),
                            border: Border.all(
                              color: auction.isReadyToStart && db.canSpinPlayer(auction.id) ? Colors.amberAccent : Colors.white24,
                              width: 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (auction.isReadyToStart && db.canSpinPlayer(auction.id) ? Colors.amber : Colors.black).withValues(alpha: 0.5),
                                blurRadius: 18,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isSpinning
                                    ? Icons.sync
                                    : (!auction.isReadyToStart
                                        ? Icons.lock
                                        : (db.canSpinPlayer(auction.id) ? Icons.gavel : Icons.lock_outline)),
                                size: 16,
                                color: auction.isReadyToStart && db.canSpinPlayer(auction.id) ? Colors.black87 : Colors.white70,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _isSpinning
                                    ? '...'
                                    : (!auction.isReadyToStart
                                        ? '8 TEAMS'
                                        : (db.canSpinPlayer(auction.id) ? 'SPIN' : 'LOCKED')),
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                  color: auction.isReadyToStart && db.canSpinPlayer(auction.id) ? Colors.black87 : Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Top Pointer Indicator
                      const Positioned(
                        top: 2,
                        child: Icon(Icons.arrow_drop_down, size: 36, color: Color(0xFFF59E0B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isSpinning
                        ? 'Revealing next player lot on all franchise boards...'
                        : (!auction.isReadyToStart
                            ? 'Wheel locked: Waiting for 8 teams to check in'
                            : (isAdmin
                                ? 'Host: Tap SPIN to randomly draw from the $eligibleSpinCount selected players'
                                : 'Wheel operated exclusively by Auctioneer Host')),
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // =========================================================
            // CURRENT LOT STAGE CARD (REVEALED ON ALL BOARDS)
            // =========================================================
            if (currentLot != null && currentPlayer != null)
              NeoGlassCard(
                glowColor: NeoGlassTheme.neonCyan,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Player Header Row
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            currentPlayer.photoUrl,
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => Container(
                              width: 72,
                              height: 72,
                              color: Colors.grey.shade800,
                              child: const Icon(Icons.person, color: Colors.white54, size: 36),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  // Role chip
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0x3300F5A0),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: NeoGlassTheme.neonEmerald.withValues(alpha: 0.5)),
                                    ),
                                    child: Text(
                                      currentPlayer.roleString.toUpperCase(),
                                      style: const TextStyle(color: NeoGlassTheme.neonEmerald, fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  // Category chip (shown only if distinct from role)
                                  if (currentLot.category.trim().isNotEmpty &&
                                      currentLot.category.trim().toLowerCase() != currentPlayer.roleString.trim().toLowerCase())
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                      decoration: BoxDecoration(
                                        color: NeoGlassTheme.neonAmber.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: NeoGlassTheme.neonAmber.withValues(alpha: 0.5)),
                                      ),
                                      child: Text(
                                        currentLot.category.toUpperCase(),
                                        style: const TextStyle(color: NeoGlassTheme.neonAmber, fontSize: 9, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  if (currentPlayer.isOverseas)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                                      decoration: BoxDecoration(
                                        color: NeoGlassTheme.neonCyan.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: NeoGlassTheme.neonCyan.withValues(alpha: 0.5)),
                                      ),
                                      child: const Text('OVERSEAS', style: TextStyle(color: NeoGlassTheme.neonCyan, fontSize: 8.5, fontWeight: FontWeight.bold)),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                currentPlayer.fullName,
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                              ),
                              Text(
                                '${currentPlayer.battingStyle} • ${currentPlayer.bowlingStyle}',
                                style: const TextStyle(color: Colors.white54, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const Divider(color: Color(0x22FFFFFF), height: 24),

                    // Price & High Bid Display
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0x33000000),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: NeoGlassTheme.glassBorder),
                        boxShadow: [
                          NeoGlassTheme.neoDarkShadow,
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text('STARTING PRICE', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                                  if (isAdmin)
                                    InkWell(
                                      onTap: () => _showManualStartingPriceDialog(context, db, auction, currentLot),
                                      child: const Padding(
                                        padding: EdgeInsets.only(left: 6),
                                        child: Icon(Icons.edit, size: 12, color: NeoGlassTheme.neonAmber),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                currencyFormat.format(currentLot.startingPrice ?? currentLot.basePrice),
                                style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('CURRENT HIGH BID', style: TextStyle(color: NeoGlassTheme.neonAmber, fontSize: 10, fontWeight: FontWeight.w900)),
                              const SizedBox(height: 2),
                              Text(
                                currencyFormat.format(currentLot.currentBid ?? (currentLot.startingPrice ?? currentLot.basePrice)),
                                style: const TextStyle(color: NeoGlassTheme.neonAmber, fontSize: 22, fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    if (highBidderTeam != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text('Highest Bidder: ', style: TextStyle(color: Colors.white54, fontSize: 11)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: highBidderTeam.primaryColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: highBidderTeam.primaryColor),
                            ),
                            child: Text(
                              highBidderTeam.name,
                              style: TextStyle(color: highBidderTeam.primaryColor, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 10),

                    // COUNTDOWN TIMER STRIP
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: (auction.biddingSecondsRemaining <= 5 && auction.isTimerRunning)
                            ? const Color(0x33F43F5E)
                            : const Color(0x33000000),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: (auction.biddingSecondsRemaining <= 5 && auction.isTimerRunning)
                              ? NeoGlassTheme.neonRose
                              : NeoGlassTheme.glassBorder,
                        ),
                        boxShadow: [
                          NeoGlassTheme.neoDarkShadow,
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              if (auction.biddingSecondsRemaining <= 5 && auction.isTimerRunning)
                                const PulsingLiveDot(color: Colors.redAccent, size: 8)
                              else
                                const Icon(
                                  Icons.timer,
                                  size: 16,
                                  color: Color(0xFF34D399),
                                ),
                              const SizedBox(width: 8),
                              Text(
                                '00:${auction.biddingSecondsRemaining.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  color: (auction.biddingSecondsRemaining <= 5 && auction.isTimerRunning)
                                      ? Colors.redAccent
                                      : Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                (auction.biddingSecondsRemaining <= 5 && auction.isTimerRunning)
                                    ? 'CLOSING SOON!'
                                    : 'BIDDING TIME LEFT',
                                style: TextStyle(
                                  color: (auction.biddingSecondsRemaining <= 5 && auction.isTimerRunning)
                                      ? Colors.redAccent
                                      : Colors.white54,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          if (isAdmin)
                            Row(
                              children: [
                                InkWell(
                                  onTap: () => db.toggleAuctionTimer(auction.id),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    child: Icon(
                                      auction.isTimerRunning ? Icons.pause_circle_filled : Icons.play_circle_filled,
                                      color: Colors.amber,
                                      size: 18,
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () => db.resetAuctionTimer(auction.id, seconds: 15),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    child: Icon(Icons.replay, color: Colors.white70, size: 16),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // =========================================================
                    // BIDDING ACTION CONTROLS (TEAM OWNERS ONLY vs HOST COCKPIT)
                    // =========================================================
                    if (isAdmin) ...[
                      // HOST / AUCTIONEER COCKPIT (Host CANNOT bid! Host controls gavel & floor)
                      _buildHostFloorCockpit(context, db, auction, currentLot),
                    ] else if (myTeam != null) ...[
                      // AUTHENTICATED TEAM OWNER BIDDING CONTROLS
                      _buildTeamOwnerBiddingBar(context, db, auction, myTeam),
                    ] else ...[
                      // SPECTATOR BROADCAST NOTICE
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.amber.withValues(alpha: 0.35)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.visibility, size: 14, color: Colors.amber),
                                SizedBox(width: 6),
                                Text(
                                  'SPECTATOR BROADCAST MODE',
                                  style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Viewers watch live bids in real-time. Only the tournament creator or host can operate the floor, and verified franchise owners can place bids.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => _showEnterAuctionRoomDialog(context, db, auction, safe8Teams, initialTab: 0),
                                  icon: const Icon(Icons.vpn_key, size: 14),
                                  label: const Text('Enter as Team Owner to Bid', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () => _showEnterAuctionRoomDialog(context, db, auction, safe8Teams, initialTab: 1),
                                  icon: const Icon(Icons.gavel, size: 14, color: Color(0xFF34D399)),
                                  label: const Text('Enter as Host / Admin', style: TextStyle(color: Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.bold)),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Color(0xFF34D399)),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

            // Accelerated Round Banner for Unsold Players
            if (unsoldLotsCount > 0 && isAdmin) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.replay, color: Colors.redAccent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$unsoldLotsCount player(s) unsold. Bring them back in Accelerated Round?',
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        db.reAuctionUnsoldLots(auction.id, 0.8);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Unsold players re-entered in Accelerated Round at 20% discount!')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      child: const Text('Accelerate', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // =========================================================
            // 3. DETAILED FRANCHISE SQUAD & REMAINING PURSE INSPECTOR
            // =========================================================
            const Text(
              'FRANCHISE SQUAD & REMAINING PURSE VIEWER',
              style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1),
            ),
            const SizedBox(height: 6),
            const Text(
              'Select any of the 8 teams to inspect remaining purse, bought players, and quota requirements.',
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
            const SizedBox(height: 10),

            if (safe8Teams.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.group_add_outlined, size: 40, color: Colors.amber),
                    const SizedBox(height: 10),
                    const Text('No Teams in this Tournament Yet', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('Host can add franchise teams to begin participating in this auction.', style: TextStyle(color: Colors.white54, fontSize: 11), textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => _showAddTeamDialog(context, db, auction),
                      icon: const Icon(Icons.add, size: 14),
                      label: const Text('Add Franchise Team'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              // 8 Teams Horizontal Scrollable Selector
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: safe8Teams.map((t) {
                    final isSelected = squadViewTeam != null && t.id == squadViewTeam.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        selected: isSelected,
                        avatar: CircleAvatar(backgroundImage: NetworkImage(t.logoUrl), radius: 10),
                        label: Text(t.name),
                        selectedColor: t.primaryColor,
                        backgroundColor: const Color(0xFF0F172A),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                        onSelected: (val) {
                          if (val) setState(() => selectedTeamIdForSquadView = t.id);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
            const SizedBox(height: 12),

            // SELECTED TEAM SQUAD DETAILS CARD
            if (squadViewTeam != null)
              Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: squadViewTeam.primaryColor, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Team Header
                  Row(
                    children: [
                      CircleAvatar(backgroundImage: NetworkImage(squadViewTeam.logoUrl), radius: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              squadViewTeam.name,
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                            ),
                            Text(
                              isAdmin
                                  ? 'Code: ${squadViewTeam.uniqueTeamCode} • PIN: ${squadViewTeam.passcode} (Host View)'
                                  : (myTeam?.id == squadViewTeam.id
                                      ? 'Code: ${squadViewTeam.uniqueTeamCode} • PIN: ${squadViewTeam.passcode} (Your Franchise)'
                                      : 'Code: ${squadViewTeam.uniqueTeamCode} • PIN: Protected 🔒'),
                              style: TextStyle(color: squadViewTeam.primaryColor, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Purse & Squad Metrics Grid
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('PURSE REMAINING', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text(
                                currencyFormat.format(squadViewTeam.purseRemaining),
                                style: TextStyle(color: squadViewTeam.primaryColor, fontSize: 15, fontWeight: FontWeight.w900),
                              ),
                              Text('Max: ${currencyFormat.format(squadViewTeam.maxPurse)}', style: const TextStyle(color: Colors.white38, fontSize: 9)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('SQUAD STRENGTH', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text(
                                '${squadViewTeam.squadCount} / ${squadViewTeam.maxSquadLimit}',
                                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900),
                              ),
                              Text(
                                squadViewTeam.playersStillNeeded > 0
                                    ? 'Need ${squadViewTeam.playersStillNeeded} more players'
                                    : 'Quota Fulfilled!',
                                style: TextStyle(
                                  color: squadViewTeam.playersStillNeeded > 0 ? Colors.amber : const Color(0xFF34D399),
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Purchased Roster List
                  Text(
                    'ACQUIRED PLAYERS (${squadPlayers.length})',
                    style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 8),

                  if (squadPlayers.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF020617),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          const Icon(Icons.shield_outlined, size: 36, color: Colors.white24),
                          const SizedBox(height: 8),
                          Text(
                            'No players acquired yet for ${squadViewTeam.name}',
                            style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Purse is 100% intact (${currencyFormat.format(squadViewTeam.purseRemaining)}). Bidding opens when all teams check in.',
                            style: const TextStyle(color: Colors.white38, fontSize: 11),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    ...squadPlayers.map((p) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(backgroundImage: NetworkImage(p.photoUrl), radius: 14),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.fullName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                  Text('${p.roleString} • ${p.battingStyle}', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF064E3B),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                currencyFormat.format(p.basePrice),
                                style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // LIVE BID TIMELINE
            const Text(
              'LIVE BID TIMELINE',
              style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: db.auctionBids.take(5).length,
                separatorBuilder: (ctx, i) => const Divider(color: Color(0xFF1E293B), height: 1),
                itemBuilder: (ctx, i) {
                  final bid = db.auctionBids[i];
                  return ListTile(
                    dense: true,
                    title: Text(bid.teamName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    trailing: Text(
                      currencyFormat.format(bid.amount),
                      style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.w900, fontSize: 14),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // FLOOR STATUS BANNER (REAL-TIME ALERTS FOR ALL USERS)
  // =========================================================================
  Widget _buildFloorStatusBanner(Auction auction, Team? highBidder) {
    if (auction.floorStatus == FloorStatus.goingOnce) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.amber.shade900,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '⚠️ GOING ONCE at ${currencyFormat.format(auction.currentBid)} to ${highBidder?.name ?? "..."}!',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    } else if (auction.floorStatus == FloorStatus.goingTwice) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade900,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.redAccent, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.campaign, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                '🚨 GOING TWICE! LAST CHANCE TO COUNTER-BID!',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    } else if (auction.floorStatus == FloorStatus.fairWarning) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.purple.shade900,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.purpleAccent, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.gavel, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                '⚡ FAIR WARNING! GAVEL ABOUT TO FALL!',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    } else if (auction.floorStatus == FloorStatus.paused) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF334155),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.pause_circle_filled, color: Colors.white70, size: 18),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                '⏸️ FLOOR PAUSED BY AUCTIONEER',
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  // =========================================================================
  // HOST AUCTIONEER COCKPIT (GAVEL, WARNINGS, PAUSE, MANUAL PRICE)
  // =========================================================================
  Widget _buildHostFloorCockpit(BuildContext context, MockDatabase db, Auction auction, AuctionLot currentLot) {
    return NeoGlassCard(
      glowColor: NeoGlassTheme.neonAmber,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.shield, color: NeoGlassTheme.neonAmber, size: 14),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'AUCTIONEER COCKPIT',
                  style: TextStyle(color: NeoGlassTheme.neonAmber, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _showManualStartingPriceDialog(context, db, auction, currentLot),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: NeoGlassTheme.neonAmber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: NeoGlassTheme.neonAmber.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit, size: 10, color: NeoGlassTheme.neonAmber),
                      SizedBox(width: 4),
                      Text('Edit Price', style: TextStyle(color: NeoGlassTheme.neonAmber, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Countdown Warnings Strip (Going Once / Going Twice / Fair Warning / Pause)
          Row(
            children: [
              Expanded(
                child: _buildGavelActionPill(
                  label: 'Once',
                  subtitle: 'Gavel 1',
                  color: NeoGlassTheme.neonAmber,
                  isActive: auction.floorStatus == FloorStatus.goingOnce,
                  onTap: () => db.setFloorStatus(auction.id, FloorStatus.goingOnce),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildGavelActionPill(
                  label: 'Twice',
                  subtitle: 'Gavel 2',
                  color: const Color(0xFFF97316),
                  isActive: auction.floorStatus == FloorStatus.goingTwice,
                  onTap: () => db.setFloorStatus(auction.id, FloorStatus.goingTwice),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildGavelActionPill(
                  label: 'Final',
                  subtitle: 'Warning',
                  color: NeoGlassTheme.neonRose,
                  isActive: auction.floorStatus == FloorStatus.fairWarning,
                  onTap: () => db.setFloorStatus(auction.id, FloorStatus.fairWarning),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0x33000000),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: NeoGlassTheme.glassBorder),
                ),
                child: IconButton(
                  tooltip: auction.floorStatus == FloorStatus.paused ? 'Resume Floor' : 'Pause Floor',
                  padding: const EdgeInsets.all(7),
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    auction.floorStatus == FloorStatus.paused ? Icons.play_arrow : Icons.pause,
                    color: Colors.white70,
                    size: 18,
                  ),
                  onPressed: () {
                    final next = auction.floorStatus == FloorStatus.paused ? FloorStatus.open : FloorStatus.paused;
                    db.setFloorStatus(auction.id, next);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Main Hammer Buttons: SOLD / UNSOLD
          Row(
            children: [
              Expanded(
                child: NeoGlassButton(
                  onPressed: () => db.setFloorStatus(auction.id, FloorStatus.sold),
                  icon: Icons.gavel,
                  gradient: NeoGlassTheme.neonGradient,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: const Text('HAMMER SOLD', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 12)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: NeoGlassButton(
                  onPressed: () => db.setFloorStatus(auction.id, FloorStatus.unsold),
                  isSecondary: true,
                  color: const Color(0x33F43F5E),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: const Text('UNSOLD (PASS)', style: TextStyle(color: NeoGlassTheme.neonRose, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showAddTeamDialog(context, db, auction),
                  icon: const Icon(Icons.group_add, size: 14),
                  label: const Text('+ Add Team', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AddPlayerDialog(db: db, auctionId: auction.id),
                    );
                  },
                  icon: const Icon(Icons.person_add, size: 14),
                  label: const Text('+ Add Player', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF34D399),
                    side: const BorderSide(color: Color(0xFF059669)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Reset Squads & Purse',
                icon: const Icon(Icons.refresh, color: Colors.orangeAccent, size: 20),
                onPressed: () => _showResetSquadsConfirmDialog(context, db, auction),
              ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              final safe8Teams = db.teams.where((t) => t.tournamentId == auction.tournamentId).toList();
              _showHostFranchiseApprovalsDialog(context, db, auction, safe8Teams);
            },
            icon: const Icon(Icons.badge, size: 14, color: Color(0xFF38BDF8)),
            label: const Text('Franchise Owner Permissions & PINs', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF38BDF8)),
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGavelActionPill({
    required String label,
    required String subtitle,
    required Color color,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.28) : const Color(0x18FFFFFF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? color : NeoGlassTheme.glassBorder,
            width: isActive ? 1.5 : 1.0,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8),
                  NeoGlassTheme.neoLightHighlight,
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w900)),
            const SizedBox(height: 1),
            Text(subtitle, style: TextStyle(color: color.withValues(alpha: 0.75), fontSize: 8.5)),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // TEAM OWNER BIDDING BAR WITH STRICT BUDGET PROTECTION
  // =========================================================================
  Widget _buildTeamOwnerBiddingBar(BuildContext context, MockDatabase db, Auction auction, Team myTeam) {
    final isPaused = auction.floorStatus == FloorStatus.paused;
    final currentLot = db.auctionLots.where((l) => l.id == auction.currentLotId).firstOrNull;
    final minPrice = currentLot?.basePrice ?? 100000;
    final maxEligibleBid = myTeam.getMaxEligibleBid(minPrice);
    final reserveRequired = myTeam.getReserveRequired(minPrice);
    final currentBid = auction.currentBid ?? (currentLot?.startingPrice ?? minPrice);
    final nextMinBid = currentBid + auction.minBidIncrement;

    final isSquadFull = myTeam.squadCount >= myTeam.maxSquadLimit;
    final isBudgetExhausted = nextMinBid > maxEligibleBid;
    final isLeadingBidder = auction.highBidderTeamId == myTeam.id;
    final canBid = !isPaused && !isSquadFull && !isBudgetExhausted;

    return NeoGlassCard(
      glowColor: myTeam.primaryColor,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // TEAM PURSE SUMMARY ROW
          Row(
            children: [
              CircleAvatar(backgroundImage: NetworkImage(myTeam.logoUrl), radius: 14),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TEAM BIDDING • ${myTeam.name.toUpperCase()}',
                        style: TextStyle(color: myTeam.primaryColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.8)),
                    Row(
                      children: [
                        Text('Purse: ${currencyFormat.format(myTeam.purseRemaining)}',
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
                        const SizedBox(width: 6),
                        Text('• Squad: ${myTeam.squadCount}/${myTeam.minSquadRequirement} (Max ${myTeam.maxSquadLimit})',
                            style: const TextStyle(color: Colors.white54, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
              if (isLeadingBidder)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: const Text('HIGHEST BIDDER', style: TextStyle(color: Colors.greenAccent, fontSize: 9, fontWeight: FontWeight.w900)),
                ),
            ],
          ),

          const SizedBox(height: 10),

          // BUDGET PROTECTION SAFETY BADGE
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, size: 14, color: Color(0xFF34D399)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Budget Protection: Max Eligible Bid ${currencyFormat.format(maxEligibleBid)} (Reserves ${currencyFormat.format(reserveRequired)} for ${myTeam.playersStillNeeded} slots)',
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // MAIN "PLACE BID" BUTTON
          ElevatedButton(
            onPressed: canBid
                ? () {
                    final ok = db.placeAuctionBid(
                      auctionId: auction.id,
                      teamId: myTeam.id,
                      increment: auction.minBidIncrement,
                    );
                    if (!ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Bid blocked: Check squad limits, budget protection reserve, or pause status.')),
                      );
                    }
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: isLeadingBidder ? Colors.green.shade700 : Colors.amber,
              foregroundColor: isLeadingBidder ? Colors.white : Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isLeadingBidder ? Icons.check : Icons.gavel, size: 16),
                const SizedBox(width: 8),
                Text(
                  isSquadFull
                      ? 'Squad Full (${myTeam.maxSquadLimit} players)'
                      : isBudgetExhausted
                          ? 'Budget Protection Limit Reached'
                          : isLeadingBidder
                              ? 'You Hold High Bid: ${currencyFormat.format(currentBid)}'
                              : 'PLACE BID: ${currencyFormat.format(nextMinBid)} (+${currencyFormat.format(auction.minBidIncrement)})',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // QUICK INCREMENT ROW (+50k, +1L, +Custom)
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: (!canBid || nextMinBid + 50000 - auction.minBidIncrement > maxEligibleBid)
                      ? null
                      : () {
                          db.placeAuctionBid(
                            auctionId: auction.id,
                            teamId: myTeam.id,
                            increment: 50000,
                          );
                        },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.amber,
                    side: const BorderSide(color: Colors.amber),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('+₹50k', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: (!canBid || nextMinBid + 100000 - auction.minBidIncrement > maxEligibleBid)
                      ? null
                      : () {
                          db.placeAuctionBid(
                            auctionId: auction.id,
                            teamId: myTeam.id,
                            increment: 100000,
                          );
                        },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.amber,
                    side: const BorderSide(color: Colors.amber),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('+₹1 Lakh', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: !canBid
                      ? null
                      : () => _showCustomBidDialog(context, db, auction, myTeam, maxEligibleBid),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Custom Bid', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCustomBidDialog(BuildContext context, MockDatabase db, Auction auction, Team myTeam, int maxEligibleBid) {
    final currentBid = auction.currentBid ?? 300000;
    final incrementController = TextEditingController(text: '${auction.minBidIncrement * 2}');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Place Custom Bid', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Bid: ${currencyFormat.format(currentBid)}', style: const TextStyle(color: Colors.amber, fontSize: 13, fontWeight: FontWeight.bold)),
            Text('Max Safe Bid: ${currencyFormat.format(maxEligibleBid)}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
            const SizedBox(height: 12),
            TextField(
              controller: incrementController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Bid Increment (₹)',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            onPressed: () {
              final inc = int.tryParse(incrementController.text.trim()) ?? auction.minBidIncrement;
              final ok = db.placeAuctionBid(auctionId: auction.id, teamId: myTeam.id, increment: inc);
              Navigator.pop(ctx);
              if (!ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Custom bid rejected: Exceeds budget protection limit or insufficient purse.')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
            child: const Text('Confirm Bid', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // HOST MANUAL STARTING PRICE DIALOG
  // =========================================================================
  void _showManualStartingPriceDialog(BuildContext context, MockDatabase db, Auction auction, AuctionLot lot) {
    final priceController = TextEditingController(text: '${lot.startingPrice ?? lot.basePrice}');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Row(
          children: const [
            Icon(Icons.edit, color: Colors.amber, size: 20),
            SizedBox(width: 8),
            Text('Set Starting Bidding Price', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Host can manually set or discount the starting price before teams start bidding.',
              style: TextStyle(color: Colors.white70, fontSize: 11),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'Opening Starting Price (₹)',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              children: [200000, 500000, 1000000, 2000000].map((p) {
                return ActionChip(
                  label: Text(currencyFormat.format(p), style: const TextStyle(fontSize: 10)),
                  backgroundColor: const Color(0xFF0F172A),
                  onPressed: () => priceController.text = '$p',
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            onPressed: () {
              final newPrice = int.tryParse(priceController.text.trim()) ?? lot.basePrice;
              db.setLotStartingPrice(auction.id, lot.id, newPrice);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF059669),
                  content: Text('Starting price set to ${currencyFormat.format(newPrice)}!'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
            child: const Text('Update Price', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // HOST PLAYER POOL & WHEEL MANAGER MODAL
  // =========================================================================
  void _showHostPlayerPoolManagerDialog(BuildContext context, MockDatabase db, Auction auction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final lots = db.auctionLots.where((l) => l.auctionId == auction.id).toList();
            final eligibleCount = lots.where((l) => l.status == LotStatus.pending && l.isSelectedForSpin).length;
            final pendingCount = lots.where((l) => l.status == LotStatus.pending).length;

            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              maxChildSize: 0.95,
              minChildSize: 0.5,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.manage_accounts, color: Colors.amber, size: 20),
                              SizedBox(width: 8),
                              Text('Host Player Pool & Wheel Manager', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white54),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Select which players enter the spin wheel ($eligibleCount of $pendingCount eligible for spin). You can also call any player directly to the board!',
                        style: const TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                      const SizedBox(height: 12),

                      // Quick Toggle Row
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              db.selectAllLotsForSpin(auction.id, true);
                              setSheetState(() {});
                            },
                            icon: const Icon(Icons.select_all, size: 14, color: Color(0xFF34D399)),
                            label: const Text('Select All', style: TextStyle(color: Color(0xFF34D399), fontSize: 11)),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              db.selectAllLotsForSpin(auction.id, false);
                              setSheetState(() {});
                            },
                            icon: const Icon(Icons.deselect, size: 14, color: Colors.white54),
                            label: const Text('Deselect All', style: TextStyle(color: Colors.white54, fontSize: 11)),
                          ),
                          const Spacer(),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              showDialog(
                                context: context,
                                builder: (c) => AddPlayerDialog(db: db, auctionId: auction.id),
                              );
                            },
                            icon: const Icon(Icons.person_add, size: 13),
                            label: const Text('Add Player', style: TextStyle(fontSize: 11)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Color(0xFF1E293B), height: 16),

                      // Player Lots List
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: lots.length,
                          itemBuilder: (context, i) {
                            final lot = lots[i];
                            final player = db.players.where((p) => p.id == lot.playerId).firstOrNull;
                            final isPending = lot.status == LotStatus.pending;
                            final isCurrent = lot.id == auction.currentLotId;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isCurrent ? const Color(0xFF064E3B) : const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(12),
                                border: isCurrent ? Border.all(color: const Color(0xFF34D399), width: 1.5) : null,
                              ),
                              child: Row(
                                children: [
                                  if (isPending)
                                    Checkbox(
                                      value: lot.isSelectedForSpin,
                                      activeColor: const Color(0xFF34D399),
                                      onChanged: (val) {
                                        db.toggleLotForSpin(lot.id, val ?? true);
                                        setSheetState(() {});
                                      },
                                    )
                                  else
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: lot.status == LotStatus.sold ? const Color(0xFF059669) : Colors.red.shade900,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        lot.status.name.toUpperCase(),
                                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  const SizedBox(width: 8),
                                  CircleAvatar(backgroundImage: NetworkImage(player?.photoUrl ?? ''), radius: 16),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(player?.fullName ?? 'Player ${lot.lotNumber}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                        Text(
                                          '${player?.roleString ?? lot.category} • Start: ${currencyFormat.format(lot.startingPrice ?? lot.basePrice)}',
                                          style: const TextStyle(color: Colors.white54, fontSize: 10),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isPending && !isCurrent) ...[
                                    ElevatedButton(
                                      onPressed: () {
                                        db.callPlayerLotToBoard(auction.id, lot.id);
                                        Navigator.pop(ctx);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('${player?.fullName} called to the board!')),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF059669),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      ),
                                      child: const Text('Call Next', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                  ] else if (isCurrent) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: const Color(0xFF34D399), borderRadius: BorderRadius.circular(6)),
                                      child: const Text('ON BOARD', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w900)),
                                    ),
                                  ],
                                ],
                              ),
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
      },
    );
  }

  // =========================================================================
  // MODALS: ENTER AUCTION ROOM AS TEAM OWNER OR HOST
  // =========================================================================

  void _showTeamOwnerGlobalLoginDialog(BuildContext context, MockDatabase db) {
    String selectedAucId = selectedAuctionId ?? (db.auctions.isNotEmpty ? db.auctions.first.id : '');
    final mobileController = TextEditingController();
    final auctionIdController = TextEditingController(text: selectedAucId);
    String? errorMessage;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final auction = db.auctions.where((a) => a.id == selectedAucId).firstOrNull;
          final teamsInAuction = auction != null
              ? db.teams.where((t) => t.tournamentId == auction.tournamentId).toList()
              : <Team>[];

          return AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: const [
                Icon(Icons.vpn_key, color: Colors.amber, size: 22),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Franchise Owner Table Entry',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Enter your Auction ID & Registered Mobile Number to authenticate your dedicated franchise table and place bids.',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  const SizedBox(height: 14),

                  if (db.auctions.isNotEmpty) ...[
                    DropdownButtonFormField<String>(
                      value: db.auctions.any((a) => a.id == selectedAucId) ? selectedAucId : db.auctions.first.id,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF1E293B),
                      decoration: InputDecoration(
                        labelText: 'Select Auction',
                        labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      style: const TextStyle(color: Colors.white, fontSize: 12.5),
                      items: db.auctions.map((a) {
                        return DropdownMenuItem(
                          value: a.id,
                          child: Text(
                            '${a.title} [${a.id}]',
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedAucId = val;
                            auctionIdController.text = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                  ],

                  TextField(
                    controller: auctionIdController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Auction ID *',
                      labelStyle: const TextStyle(color: Colors.white70),
                      hintText: 'e.g. AUCTION-BPL',
                      prefixIcon: const Icon(Icons.tag, color: Colors.amber, size: 18),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (val) {
                      setDialogState(() => selectedAucId = val.trim());
                    },
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: mobileController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Registered Owner Mobile Number *',
                      labelStyle: const TextStyle(color: Colors.white70),
                      hintText: 'e.g. 9876543201',
                      prefixIcon: const Icon(Icons.phone_android, color: Color(0xFF34D399), size: 18),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),

                  if (teamsInAuction.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text('Registered Teams in this Auction:', style: TextStyle(color: Colors.white38, fontSize: 10)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: teamsInAuction.map((t) {
                        return ActionChip(
                          label: Text(
                            '${t.name} ${t.ownerMobileNumber.isNotEmpty ? "(${t.ownerMobileNumber})" : ""}',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: const Color(0xFF0F172A),
                          side: BorderSide(color: t.primaryColor.withValues(alpha: 0.6)),
                          onPressed: () {
                            setDialogState(() {
                              mobileController.text = t.ownerMobileNumber.isNotEmpty ? t.ownerMobileNumber : t.uniqueTeamCode;
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],

                  if (errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  final aucId = auctionIdController.text.trim();
                  final mobile = mobileController.text.trim();
                  if (aucId.isEmpty || mobile.isEmpty) {
                    setDialogState(() => errorMessage = 'Please enter both Auction ID and registered Mobile Number.');
                    return;
                  }

                  final ok = db.enterAuctionAsTeamOwner(
                    auctionId: aucId,
                    mobileNumber: mobile,
                  );

                  if (ok) {
                    final team = db.currentAuthenticatedTeam;
                    Navigator.pop(ctx);
                    setState(() {
                      selectedAuctionId = aucId;
                      selectedTeamIdForSquadView = team?.id;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF009270),
                        content: Text('🎉 Welcome, ${team?.name ?? "Team Owner"}! Seated at franchise bidding table.'),
                      ),
                    );
                  } else {
                    setDialogState(() => errorMessage = 'No team with mobile "$mobile" found in auction "$aucId". Please check credentials or contact host.');
                  }
                },
                icon: const Icon(Icons.login, size: 16),
                label: const Text('Enter Table & Bid', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditAuctionDialog(BuildContext context, MockDatabase db, Auction auction) {
    final titleCtrl = TextEditingController(text: auction.title);
    final purseCtrl = TextEditingController(text: '${auction.maxPursePerTeam}');
    final minBidCtrl = TextEditingController(text: '${auction.minBidIncrement}');
    final teamsCountCtrl = TextEditingController(text: '${auction.requiredTeamsCount}');
    final pinCtrl = TextEditingController(text: auction.adminPasscode);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.edit_note, color: Colors.amber, size: 22),
            SizedBox(width: 8),
            Text('Edit Auction Setup', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Host can update auction title, purse limit, bid increments, and security PIN.',
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: titleCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Auction Title *',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: purseCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Franchise Max Purse (₹) *',
                  labelStyle: const TextStyle(color: Colors.white70),
                  prefixText: '₹ ',
                  prefixStyle: const TextStyle(color: Colors.amber),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: minBidCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Min Bid Incr (₹) *',
                        labelStyle: const TextStyle(color: Colors.white70),
                        prefixText: '₹ ',
                        prefixStyle: const TextStyle(color: Colors.amber),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: teamsCountCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Teams Required *',
                        labelStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: pinCtrl,
                obscureText: true,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Host Admin PIN *',
                  labelStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.security, size: 16, color: Color(0xFF34D399)),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleCtrl.text.trim().isEmpty) return;
              final purse = int.tryParse(purseCtrl.text.trim()) ?? auction.maxPursePerTeam;
              final minBid = int.tryParse(minBidCtrl.text.trim()) ?? auction.minBidIncrement;
              final tCount = int.tryParse(teamsCountCtrl.text.trim()) ?? auction.requiredTeamsCount;
              final pin = pinCtrl.text.trim().isNotEmpty ? pinCtrl.text.trim() : auction.adminPasscode;

              db.updateAuction(
                auctionId: auction.id,
                title: titleCtrl.text.trim(),
                maxPursePerTeam: purse,
                minBidIncrement: minBid,
                requiredTeamsCount: tCount,
                adminPasscode: pin,
              );

              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Color(0xFF009270),
                  content: Text('Auction setup updated successfully!'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF009270),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEnterAuctionRoomDialog(
    BuildContext context,
    MockDatabase db,
    Auction auction,
    List<Team> safe8Teams, {
    int initialTab = 0,
  }) {
    int activeTab = initialTab;
    final mobileController = TextEditingController();
    final teamCodeController = TextEditingController();
    final teamPassController = TextEditingController();
    final hostPassController = TextEditingController();
    String? errorMessage;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: const [
                Icon(Icons.gavel, color: Colors.amber, size: 20),
                SizedBox(width: 8),
                Text('Enter Auction Room', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Tab toggle
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setDialogState(() => activeTab = 0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                color: activeTab == 0 ? Colors.amber : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Team Owner (Bid)',
                                style: TextStyle(
                                  color: activeTab == 0 ? Colors.black : Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => setDialogState(() => activeTab = 1),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                color: activeTab == 1 ? const Color(0xFF059669) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Host / Admin',
                                style: TextStyle(
                                  color: activeTab == 1 ? Colors.white : Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (activeTab == 0) ...[
                    // TEAM OWNER LOGIN
                    const Text('Enter your registered Mobile Number to unlock your franchise table:', style: TextStyle(color: Colors.white70, fontSize: 11)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: mobileController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Owner Registered Mobile *',
                        labelStyle: const TextStyle(color: Colors.white70),
                        hintText: 'e.g. 9876543201',
                        prefixIcon: const Icon(Icons.phone_android, color: Color(0xFF34D399), size: 18),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: teamCodeController,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            decoration: InputDecoration(
                              labelText: 'Team ID (Optional)',
                              labelStyle: const TextStyle(color: Colors.white54, fontSize: 11),
                              hintText: 'e.g. TEAM-01',
                              filled: true,
                              fillColor: const Color(0xFF0F172A),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: teamPassController,
                            obscureText: true,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            decoration: InputDecoration(
                              labelText: 'PIN (Optional)',
                              labelStyle: const TextStyle(color: Colors.white54, fontSize: 11),
                              hintText: '1234',
                              filled: true,
                              fillColor: const Color(0xFF0F172A),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (safe8Teams.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text('Or tap your franchise:', style: TextStyle(color: Colors.white38, fontSize: 10)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: safe8Teams.map((t) {
                          return ActionChip(
                            label: Text(
                              '${t.name} ${t.ownerMobileNumber.isNotEmpty ? "(${t.ownerMobileNumber})" : ""}',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                            backgroundColor: const Color(0xFF0F172A),
                            side: BorderSide(color: t.primaryColor.withValues(alpha: 0.6)),
                            onPressed: () {
                              setDialogState(() {
                                mobileController.text = t.ownerMobileNumber.isNotEmpty ? t.ownerMobileNumber : t.uniqueTeamCode;
                                teamCodeController.text = t.uniqueTeamCode;
                                teamPassController.text = t.passcode;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ] else ...[
                    // HOST LOGIN
                    const Text('Enter Host PIN or Tournament Passcode / Room ID to operate spinning wheel, manage floor, and hammer sold.', style: TextStyle(color: Colors.white70, fontSize: 11)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: hostPassController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Host PIN / Tournament Passcode',
                        labelStyle: const TextStyle(color: Colors.white70),
                        hintText: 'admin123 or tournament passcode',
                        prefixIcon: const Icon(Icons.security, color: Color(0xFF34D399), size: 18),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],

                  if (errorMessage != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                onPressed: () {
                  if (activeTab == 0) {
                    final ok = db.enterAuctionAsTeamOwner(
                      auctionId: auction.id,
                      mobileNumber: mobileController.text.trim(),
                      teamCode: teamCodeController.text.trim(),
                      passcode: teamPassController.text.trim(),
                    );
                    if (ok) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF059669),
                          content: Text('🎉 Welcome, ${db.currentAuthenticatedTeam?.name}! Dedicated bidding table unlocked.'),
                        ),
                      );
                    } else {
                      setDialogState(() => errorMessage = 'Invalid Mobile Number or Team Credentials.');
                    }
                  } else {
                    final ok = db.enterAuctionAsHost(
                      auctionId: auction.id,
                      adminPasscode: hostPassController.text,
                    );
                    if (ok) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Color(0xFF059669),
                          content: Text('Host Mode Unlocked! You can control starting prices, spin wheel and hammer sold.'),
                        ),
                      );
                    } else {
                      setDialogState(() => errorMessage = 'Invalid Host PIN.');
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: activeTab == 0 ? Colors.amber : const Color(0xFF34D399),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(activeTab == 0 ? 'Enter & Bid' : 'Unlock Host', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddTeamDialog(BuildContext context, MockDatabase db, Auction auction) {
    final teamNameCtrl = TextEditingController();
    final shortNameCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.group_add, color: Colors.amber, size: 20),
            SizedBox(width: 8),
            Text('Add Franchise Team', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: teamNameCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                labelText: 'Franchise Team Name',
                labelStyle: const TextStyle(color: Colors.white54, fontSize: 11),
                hintText: 'e.g. Royal Warriors',
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (val) {
                final parts = val.trim().split(' ');
                if (parts.length > 1) {
                  shortNameCtrl.text = '${parts.first[0]}${parts.last[0]}'.toUpperCase();
                } else if (val.trim().length >= 3) {
                  shortNameCtrl.text = val.trim().substring(0, 3).toUpperCase();
                }
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: shortNameCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                labelText: 'Short Code',
                labelStyle: const TextStyle(color: Colors.white54, fontSize: 11),
                hintText: 'e.g. RW',
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              if (teamNameCtrl.text.trim().isEmpty) return;
              final newTeam = db.addTeamToAuction(
                auctionId: auction.id,
                teamName: teamNameCtrl.text.trim(),
                shortName: shortNameCtrl.text.trim().isNotEmpty ? shortNameCtrl.text.trim() : null,
              );
              Navigator.pop(ctx);
              setState(() {
                selectedTeamIdForSquadView = newTeam.id;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF059669),
                  content: Text('Team "${newTeam.name}" added! Code: ${newTeam.uniqueTeamCode} • PIN: ${newTeam.passcode}'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
            child: const Text('Add Team', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showResetSquadsConfirmDialog(BuildContext context, MockDatabase db, Auction auction) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 20),
            SizedBox(width: 8),
            Text('Reset Auction Squads & Purses?', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'This will reset all franchise purses in this auction back to 100%, set squad counts to 0, and clear bought players so bidding can be restarted from scratch.',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              db.resetAuctionSquads(auction.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Colors.orange,
                  content: Text('Auction reset: Purses 100% restored, squads cleared!'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.black),
            child: const Text('Reset Everything', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showHostFranchiseApprovalsDialog(
    BuildContext context,
    MockDatabase db,
    Auction auction,
    List<Team> safe8Teams,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: const [
                Icon(Icons.badge, color: Color(0xFF38BDF8), size: 22),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Franchise Owner Permissions & PINs',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'As Auction Host, you give permission for franchise owners to bid. Share their unique Team Code & PIN, or manually check them in below.',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Franchises: ${safe8Teams.length}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                          Text(
                            'Approved to Bid: ${auction.joinedTeamIds.length} / ${safe8Teams.length}',
                            style: TextStyle(
                              color: auction.isReadyToStart ? const Color(0xFF34D399) : Colors.amber,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...safe8Teams.map((team) {
                      final isConnected = auction.joinedTeamIds.contains(team.id);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isConnected ? const Color(0xFF059669) : Colors.white12,
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundImage: NetworkImage(team.logoUrl),
                              radius: 16,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    team.name,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Code: ${team.uniqueTeamCode}   •   PIN: ${team.passcode}',
                                    style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.w900, fontSize: 11),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Purse: ₹${(team.purseRemaining / 100000).toStringAsFixed(1)}L • Squad: ${team.squadCount}/${team.minSquadRequirement}',
                                    style: const TextStyle(color: Colors.white38, fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (isConnected) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF059669).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFF059669)),
                                ),
                                child: const Text(
                                  'Ready to Bid',
                                  style: TextStyle(color: Color(0xFF34D399), fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ] else ...[
                              ElevatedButton(
                                onPressed: () {
                                  db.checkInTeamToAuction(auction.id, team.id);
                                  setDialogState(() {});
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text('Approve', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            actions: [
              if (!auction.isReadyToStart)
                TextButton(
                  onPressed: () {
                    db.checkInAllTeamsToAuction(auction.id);
                    setDialogState(() {});
                  },
                  child: const Text('Approve All 8', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close', style: TextStyle(color: Colors.white70)),
              ),
            ],
          );
        },
      ),
    );
  }

  // =========================================================================
  // DEDICATED REGISTERED PLAYER PERSONA DASHBOARD
  // =========================================================================
  Widget _buildPlayerPersonaDashboard(BuildContext context, MockDatabase db, Auction auction) {
    final player = (db.authenticatedPlayerId != null
            ? db.players.where((p) => p.id == db.authenticatedPlayerId).firstOrNull
            : null) ??
        db.players.firstOrNull;

    if (player == null) return const SizedBox.shrink();

    final isSold = player.auctionStatus == PlayerAuctionStatus.sold;
    final isInAuction = player.auctionStatus == PlayerAuctionStatus.inAuction ||
        (auction.currentLotId != null &&
            db.auctionLots.where((l) => l.id == auction.currentLotId && l.playerId == player.id).isNotEmpty);
    final isUnsold = player.auctionStatus == PlayerAuctionStatus.unsold;
    final winningTeam = player.soldTeamId != null ? db.teams.where((t) => t.id == player.soldTeamId).firstOrNull : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isSold
              ? [const Color(0xFF065F46), const Color(0xFF0F172A)]
              : (isInAuction
                  ? [const Color(0xFF991B1B), const Color(0xFF0F172A)]
                  : [const Color(0xFF1E3A8A), const Color(0xFF0F172A)]),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSold ? const Color(0xFF34D399) : (isInAuction ? Colors.redAccent : const Color(0xFF60A5FA)),
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: (isSold ? const Color(0xFF34D399) : (isInAuction ? Colors.redAccent : Colors.blue)).withValues(alpha: 0.25),
            blurRadius: 16,
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
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: CircleAvatar(
                  radius: 26,
                  backgroundImage: NetworkImage(player.photoUrl),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            player.fullName,
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF10B981)),
                          ),
                          child: const Text('APPROVED PLAYER', style: TextStyle(color: Color(0xFF34D399), fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${player.roleString} • ${player.battingStyle} • ${player.city.isNotEmpty ? player.city : "Domestic"} • Base: ${currencyFormat.format(player.basePrice)}',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Live Auction Status Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            child: isSold
                ? Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.stars, color: Colors.amber, size: 18),
                          SizedBox(width: 6),
                          Text('🎉 CONGRATULATIONS! YOU ARE SOLD!', style: TextStyle(color: Colors.amber, fontSize: 13, fontWeight: FontWeight.w900)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (winningTeam != null)
                            CircleAvatar(radius: 12, backgroundImage: NetworkImage(winningTeam.logoUrl)),
                          const SizedBox(width: 8),
                          Text(
                            'Franchise: ${winningTeam?.name ?? "Winning Franchise"}',
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Winning Bid: ${currencyFormat.format(player.soldPrice ?? player.basePrice)} • Round ${player.soldRound ?? 1}',
                        style: const TextStyle(color: Color(0xFF34D399), fontSize: 15, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.chat_bubble, size: 12, color: Color(0xFF22C55E)),
                          const SizedBox(width: 4),
                          Text(
                            'Automated WhatsApp notification sent to ${player.mobileNumber}',
                            style: const TextStyle(color: Colors.white60, fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  )
                : (isInAuction
                    ? Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.whatshot, color: Colors.redAccent, size: 18),
                              SizedBox(width: 6),
                              Text('🔴 YOU ARE LIVE ON THE AUCTION FLOOR!', style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w900)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Current Highest Bid: ${currencyFormat.format(auction.currentBid ?? player.basePrice)}',
                            style: const TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Leader: ${auction.highBidderTeamId != null ? (db.teams.where((t) => t.id == auction.highBidderTeamId).firstOrNull?.name ?? "Bid Placed") : "Base Price (Opening Bid)"}',
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      )
                    : (isUnsold
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.info_outline, color: Colors.orangeAccent, size: 16),
                              const SizedBox(width: 8),
                              Text('Unsold in Round ${auction.currentRound}. Re-eligible for upcoming rounds.', style: const TextStyle(color: Colors.orangeAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.hourglass_top, color: Color(0xFF60A5FA), size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'In Auction Pool (Base: ${currencyFormat.format(player.basePrice)}). Ready for spin.',
                                style: const TextStyle(color: Color(0xFF93C5FD), fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ))),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // PLAYERS HUB: AVAILABLE, SOLD, AND UNSOLD SECTIONS
  // =========================================================================
  void _showPlayersHubDialog(BuildContext context, MockDatabase db, Auction auction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return DefaultTabController(
          length: 3,
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              final aLots = db.auctionLots.where((l) => l.auctionId == auction.id).toList();
              final availableLots = aLots.where((l) => l.status == LotStatus.pending).toList();
              final soldLots = aLots.where((l) => l.status == LotStatus.sold).toList();
              final unsoldLots = aLots.where((l) => l.status == LotStatus.unsold).toList();
              final isAdmin = db.canManageAuctionFloor(auction.id);

              return DraggableScrollableSheet(
                initialChildSize: 0.85,
                maxChildSize: 0.95,
                minChildSize: 0.5,
                expand: false,
                builder: (context, scrollController) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.people_alt, color: Color(0xFF34D399), size: 20),
                                SizedBox(width: 8),
                                Text('Players Hub', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white54),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Tab Bar: Available / Sold / Unsold
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TabBar(
                            indicatorColor: const Color(0xFF009270),
                            indicatorWeight: 3,
                            labelColor: const Color(0xFF34D399),
                            unselectedLabelColor: Colors.white60,
                            tabs: [
                              Tab(text: 'Available (${availableLots.length})'),
                              Tab(text: 'Sold (${soldLots.length})'),
                              Tab(text: 'Unsold (${unsoldLots.length})'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Tab Views
                        Expanded(
                          child: TabBarView(
                            children: [
                              // 1. AVAILABLE PLAYERS
                              ListView.separated(
                                controller: scrollController,
                                itemCount: availableLots.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (context, i) {
                                  final lot = availableLots[i];
                                  final player = db.players.where((p) => p.id == lot.playerId).firstOrNull;
                                  return Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E293B),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.white12),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(backgroundImage: NetworkImage(player?.photoUrl ?? ''), radius: 18),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(player?.fullName ?? 'Player #${lot.lotNumber}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                              Text(
                                                '${player?.roleString ?? lot.category} • Base: ${currencyFormat.format(lot.basePrice)}',
                                                style: const TextStyle(color: Colors.white60, fontSize: 11),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (isAdmin)
                                          ElevatedButton(
                                            onPressed: () {
                                              db.callPlayerLotToBoard(auction.id, lot.id);
                                              Navigator.pop(ctx);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('${player?.fullName} brought to the stage!')),
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF009270),
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              minimumSize: Size.zero,
                                            ),
                                            child: const Text('Bring to Stage', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),

                              // 2. SOLD PLAYERS (WITH REVERSE SALE OPTION)
                              soldLots.isEmpty
                                  ? const Center(child: Text('No players sold yet.', style: TextStyle(color: Colors.white54)))
                                  : ListView.separated(
                                      controller: scrollController,
                                      itemCount: soldLots.length,
                                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                                      itemBuilder: (context, i) {
                                        final lot = soldLots[i];
                                        final player = db.players.where((p) => p.id == lot.playerId).firstOrNull;
                                        final team = db.teams.where((t) => t.id == lot.winningTeamId).firstOrNull;
                                        final soldPrice = lot.soldPrice ?? lot.currentBid ?? lot.basePrice;

                                        return Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1E293B),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.5)),
                                          ),
                                          child: Row(
                                            children: [
                                              CircleAvatar(backgroundImage: NetworkImage(player?.photoUrl ?? ''), radius: 18),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Flexible(
                                                          child: Text(player?.fullName ?? 'Player', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                                        ),
                                                        const SizedBox(width: 6),
                                                        Text('₹${(soldPrice / 100000).toStringAsFixed(1)}L', style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.w900, fontSize: 12)),
                                                      ],
                                                    ),
                                                    Row(
                                                      children: [
                                                        if (team != null) ...[
                                                          CircleAvatar(radius: 6, backgroundImage: NetworkImage(team.logoUrl)),
                                                          const SizedBox(width: 4),
                                                        ],
                                                        Text('${team?.name ?? "Sold Team"} • Rnd ${lot.round}', style: const TextStyle(color: Colors.white60, fontSize: 10.5)),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (isAdmin)
                                                IconButton(
                                                  tooltip: 'Reverse Sold Lot (Correction)',
                                                  icon: const Icon(Icons.undo, color: Colors.redAccent, size: 18),
                                                  onPressed: () {
                                                    final ok = db.reverseSoldLot(
                                                      auctionId: auction.id,
                                                      lotId: lot.id,
                                                      reason: 'Corrected by Tournament Admin',
                                                    );
                                                    if (ok) {
                                                      setSheetState(() {});
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(content: Text('Reversed sale of ${player?.fullName}. Purse refunded.')),
                                                      );
                                                    }
                                                  },
                                                ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),

                              // 3. UNSOLD PLAYERS (WITH ADVANCE ROUND TRIGGER)
                              unsoldLots.isEmpty
                                  ? const Center(child: Text('No unsold players.', style: TextStyle(color: Colors.white54)))
                                  : Column(
                                      children: [
                                        if (isAdmin) ...[
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            margin: const EdgeInsets.only(bottom: 10),
                                            decoration: BoxDecoration(
                                              color: Colors.amber.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(color: Colors.amber),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.replay, color: Colors.amber, size: 18),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    '${unsoldLots.length} Unsold. Advance to Round ${auction.currentRound + 1}?',
                                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    db.advanceAuctionRound(auctionId: auction.id, unsoldPriceDiscount: 0.20);
                                                    setSheetState(() {});
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(content: Text('Advanced to Round ${auction.currentRound}! Unsold players re-entered.')),
                                                    );
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.amber,
                                                    foregroundColor: Colors.black,
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    minimumSize: Size.zero,
                                                  ),
                                                  child: const Text('Advance Round', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                        Expanded(
                                          child: ListView.separated(
                                            controller: scrollController,
                                            itemCount: unsoldLots.length,
                                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                                            itemBuilder: (context, i) {
                                              final lot = unsoldLots[i];
                                              final player = db.players.where((p) => p.id == lot.playerId).firstOrNull;
                                              return Container(
                                                padding: const EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF1E293B),
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                                                ),
                                                child: Row(
                                                  children: [
                                                    CircleAvatar(backgroundImage: NetworkImage(player?.photoUrl ?? ''), radius: 18),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(player?.fullName ?? 'Player', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                                          Text('Base: ${currencyFormat.format(lot.basePrice)} • Unsold', style: const TextStyle(color: Colors.redAccent, fontSize: 10.5)),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
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
                },
              );
            },
          ),
        );
      },
    );
  }

  // =========================================================================
  // BULK IMPORT PLAYERS (EXCEL / CSV IMPORT)
  // =========================================================================
  void _showBulkImportCsvDialog(BuildContext context, MockDatabase db, Auction auction) {
    final csvController = TextEditingController();

    const sampleCsv = '''FullName, Mobile, Role, BasePrice, Category, BattingStyle, BowlingStyle, Age, City, Overseas
Virat Kohli, 9800000001, batsman, 2000000, marquee, Right Hand Bat, Right Arm Medium, 35, Delhi, false
Jasprit Bumrah, 9800000002, bowler, 2000000, marquee, Right Hand Bat, Right Arm Fast, 30, Ahmedabad, false
Andre Russell, 9800000003, allrounder, 1500000, marquee, Right Hand Bat, Right Arm Fast, 36, Kingston, true
Heinrich Klaasen, 9800000004, wicketkeeper, 1500000, marquee, Right Hand Bat, Off Break, 33, Pretoria, true
Rinku Singh, 9800000005, batsman, 1000000, emerging, Left Hand Bat, Off Break, 27, Aligarh, false''';

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.file_upload, color: Color(0xFF38BDF8), size: 22),
              SizedBox(width: 8),
              Text('Bulk Player Import (CSV)', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Paste CSV / Excel lines with player details. Duplicates by name or mobile will be skipped automatically.',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => csvController.text = sampleCsv,
                    icon: const Icon(Icons.flash_on, size: 14, color: Colors.amberAccent),
                    label: const Text('Paste Sample CSV', style: TextStyle(color: Colors.amberAccent, fontSize: 11)),
                  ),
                ),
                TextField(
                  controller: csvController,
                  maxLines: 8,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'monospace'),
                  decoration: InputDecoration(
                    hintText: 'FullName, Mobile, Role, BasePrice, Category...',
                    hintStyle: const TextStyle(color: Colors.white30, fontSize: 11),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton.icon(
              onPressed: () {
                final result = db.bulkImportPlayersFromCsv(auctionId: auction.id, csvData: csvController.text);
                Navigator.pop(ctx);
                if (result['success'] == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Successfully imported ${result['imported']} players! (${result['duplicates']} duplicates skipped)'),
                      backgroundColor: const Color(0xFF009270),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Import error: ${result['error']}'), backgroundColor: Colors.redAccent),
                  );
                }
              },
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Import Players', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF009270), foregroundColor: Colors.white),
            ),
          ],
        );
      },
    );
  }

  // =========================================================================
  // WHATSAPP CLOUD API NOTIFICATIONS LOG
  // =========================================================================
  void _showWhatsAppNotificationsDialog(BuildContext context, MockDatabase db, Auction auction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final notifs = db.whatsappNotifications.where((n) => n.auctionId == auction.id).toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              maxChildSize: 0.9,
              minChildSize: 0.4,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.chat_bubble, color: Color(0xFF22C55E), size: 20),
                              SizedBox(width: 8),
                              Text('WhatsApp Notifications', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white54),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.verified, size: 14, color: Color(0xFF22C55E)),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Meta WhatsApp Cloud API: Active • Template: cricket_sold_alert',
                                style: TextStyle(color: Color(0xFF86EFAC), fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      Expanded(
                        child: notifs.isEmpty
                            ? const Center(
                                child: Text(
                                  'No notifications sent yet. Whenever a player is SOLD, congratulatory messages are dispatched automatically.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white54, fontSize: 12),
                                ),
                              )
                            : ListView.separated(
                                controller: scrollController,
                                itemCount: notifs.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (context, i) {
                                  final n = notifs[i];
                                  final isSent = n.status == WhatsAppNotificationStatus.sent;

                                  return Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E293B),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: isSent ? const Color(0xFF22C55E).withValues(alpha: 0.4) : Colors.amber.withValues(alpha: 0.4)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'To: ${n.recipientName} (${n.recipientMobile})',
                                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: (isSent ? const Color(0xFF22C55E) : Colors.amber).withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                n.status.name.toUpperCase(),
                                                style: TextStyle(color: isSent ? const Color(0xFF86EFAC) : Colors.amberAccent, fontSize: 9.5, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(n.messageContent, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                                        const SizedBox(height: 4),
                                        Text(
                                          DateFormat('dd MMM, hh:mm:ss a').format(n.timestamp),
                                          style: const TextStyle(color: Colors.white38, fontSize: 9.5),
                                        ),
                                      ],
                                    ),
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
      },
    );
  }

  // =========================================================================
  // AUCTION SUMMARY REPORTS & CSV EXPORT
  // =========================================================================
  void _showAuctionReportsDialog(BuildContext context, MockDatabase db, Auction auction) {
    final report = db.generateAuctionReport(auction.id);
    final teamsData = (report['teams'] as List<dynamic>? ?? []);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.assessment, color: Colors.amber, size: 20),
                          SizedBox(width: 8),
                          Text('Auction Report & Analytics', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Quick Metrics Row
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(10)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('TOTAL SPENDING', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold)),
                              Text(currencyFormat.format(report['totalSpent'] ?? 0), style: const TextStyle(color: Color(0xFF34D399), fontSize: 14, fontWeight: FontWeight.w900)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(10)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('PLAYERS SOLD', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold)),
                              Text('${report['soldLots']} / ${report['totalLots']}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(10)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('TOP BUY', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold)),
                              Text(report['topPlayerName'] ?? 'N/A', style: const TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.w900), overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  const Text('FRANCHISE SPENDING BREAKDOWN', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: teamsData.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final t = teamsData[i];
                        return Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(t['name'] ?? 'Team', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                    Text('Owner: ${t['owner']} • Squad: ${t['squadCount']} players', style: const TextStyle(color: Colors.white54, fontSize: 10)),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('Spent: ${currencyFormat.format(t['spent'] ?? 0)}', style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                                  Text('Remaining: ${currencyFormat.format(t['purseRemaining'] ?? 0)}', style: const TextStyle(color: Color(0xFF34D399), fontSize: 10)),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      final csv = db.exportAuctionReportCsv(auction.id);
                      Navigator.pop(ctx);
                      showDialog(
                        context: context,
                        builder: (c) => AlertDialog(
                          backgroundColor: const Color(0xFF1E293B),
                          title: const Text('Exported CSV Preview', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                          content: SingleChildScrollView(
                            child: SelectableText(csv, style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace')),
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(c), child: const Text('Close')),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Export Report (CSV)', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF009270), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // =========================================================================
  // IMMUTABLE AUDIT TRAIL MODAL
  // =========================================================================
  void _showAuditTrailDialog(BuildContext context, MockDatabase db, Auction auction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        final logs = db.auditLogs.where((l) => l.auctionId == auction.id || l.category == 'auction').toList();

        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.history, color: Colors.cyanAccent, size: 20),
                          SizedBox(width: 8),
                          Text('Immutable Audit Trail', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Expanded(
                    child: logs.isEmpty
                        ? const Center(child: Text('No audit logs recorded yet.', style: TextStyle(color: Colors.white54)))
                        : ListView.separated(
                            controller: scrollController,
                            itemCount: logs.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, i) {
                              final log = logs[i];
                              return Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.cyan.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(log.action, style: const TextStyle(color: Colors.cyanAccent, fontSize: 9.5, fontWeight: FontWeight.bold)),
                                        ),
                                        Text(DateFormat('hh:mm:ss a').format(log.timestamp), style: const TextStyle(color: Colors.white38, fontSize: 9)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(log.details, style: const TextStyle(color: Colors.white, fontSize: 11)),
                                    const SizedBox(height: 2),
                                    Text('By: ${log.performedBy} (${log.role.isNotEmpty ? log.role : "User"})', style: const TextStyle(color: Colors.white54, fontSize: 9.5)),
                                  ],
                                ),
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
}

class AuctionWheelPainter extends CustomPainter {
  final int itemsCount;

  AuctionWheelPainter({required this.itemsCount});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final sweepAngle = (2 * pi) / itemsCount;

    // High-end dark stadium metallic palette with subtle sheen
    final segmentColors = [
      const Color(0xFF0F172A),
      const Color(0xFF1E293B),
      const Color(0xFF131D31),
      const Color(0xFF1A2642),
      const Color(0xFF111C2E),
      const Color(0xFF1E2C44),
      const Color(0xFF152238),
      const Color(0xFF1D2A40),
    ];

    for (int i = 0; i < itemsCount; i++) {
      final paint = Paint()
        ..color = segmentColors[i % segmentColors.length]
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * sweepAngle,
        sweepAngle,
        true,
        paint,
      );

      // Subtle metallic divider line
      final dividerPaint = Paint()
        ..color = const Color(0xFF334155).withValues(alpha: 0.8)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;

      final edgeX = center.dx + radius * cos(i * sweepAngle);
      final edgeY = center.dy + radius * sin(i * sweepAngle);
      canvas.drawLine(center, Offset(edgeX, edgeY), dividerPaint);

      // Gold notch dot at the outer perimeter
      final dotPaint = Paint()
        ..color = const Color(0xFFF59E0B)
        ..style = PaintingStyle.fill;
      final dotX = center.dx + (radius - 7) * cos(i * sweepAngle + sweepAngle / 2);
      final dotY = center.dy + (radius - 7) * sin(i * sweepAngle + sweepAngle / 2);
      canvas.drawCircle(Offset(dotX, dotY), 2.2, dotPaint);
    }

    // Outer luxury gold metallic broadcast bezel
    final outerRing = Paint()
      ..shader = const SweepGradient(
        colors: [
          Color(0xFFD97706),
          Color(0xFFFDE68A),
          Color(0xFFB45309),
          Color(0xFFF59E0B),
          Color(0xFFD97706),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawCircle(center, radius - 2, outerRing);

    // Inner shadow track
    final innerTrack = Paint()
      ..color = const Color(0xFF020617).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius - 5, innerTrack);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
