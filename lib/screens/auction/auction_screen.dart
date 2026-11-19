import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/mock_database.dart';
import '../../widgets/role_switcher_chip.dart';
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
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        backgroundColor: const Color(0xFF009270),
        title: const Text('Franchise Auctions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        actions: const [RoleSwitcherChip(compact: true), SizedBox(width: 8)],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.gavel_outlined, size: 54, color: Colors.amberAccent),
              const SizedBox(height: 16),
              const Text('No Player Auctions Created', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                'Host a live player auction with franchise budgets, player wheel spin, and owner bidding.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
              const SizedBox(height: 20),
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
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent),
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
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        backgroundColor: const Color(0xFF009270),
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(color: Colors.amber.shade400, borderRadius: BorderRadius.circular(6)),
              child: const Icon(Icons.gavel, size: 14, color: Colors.black),
            ),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'Auctions',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          const RoleSwitcherChip(compact: true),
          const SizedBox(width: 4),
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
          // Banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('OFFICIAL CRICKET DRAFT ARENA', style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                      const SizedBox(height: 6),
                      const Text('Live Player Auctions & Franchise Purses', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      const Text(
                        'Select an auction to view live player lots, 8-team waiting rooms, spinning wheel reveals, and team bidding.',
                        style: TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                    ],
                  ),
                ),
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
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('Host New', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                  ),
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
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        backgroundColor: const Color(0xFF009270),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
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
          const RoleSwitcherChip(compact: true),
          if (isAdmin)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
              tooltip: 'Host Controls',
              color: const Color(0xFF1E293B),
              onSelected: (val) {
                if (val == 'pool') {
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
                }
              },
              itemBuilder: (ctx) => [
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
            ),
          if (!isUnlocked)
            TextButton.icon(
              onPressed: () => _showEnterAuctionRoomDialog(context, db, auction, safe8Teams),
              icon: const Icon(Icons.vpn_key, size: 13, color: Colors.amber),
              label: const Text('Enter', style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
            )
          else
            IconButton(
              tooltip: 'Exit to Spectator',
              icon: const Icon(Icons.logout, size: 18, color: Colors.redAccent),
              onPressed: () {
                db.exitAuctionRoom();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Returned to Spectator Broadcast.')),
                );
              },
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
                          size: const Size(180, 180),
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
                          if (!isAdmin) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Only the Auctioneer Host can spin the wheel to reveal players!')),
                            );
                            return;
                          }
                          _spinWheel(db, auction);
                        },
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: auction.isReadyToStart && isAdmin ? Colors.amber.shade500 : Colors.grey.shade800,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (auction.isReadyToStart && isAdmin ? Colors.amber : Colors.black).withValues(alpha: 0.5),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _isSpinning
                                ? '...'
                                : (!auction.isReadyToStart
                                    ? '8 TEAMS'
                                    : (isAdmin ? 'SPIN' : 'HOST')),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: auction.isReadyToStart && isAdmin ? Colors.black : Colors.white70,
                            ),
                          ),
                        ),
                      ),
                      // Top Pointer Indicator
                      const Positioned(
                        top: 0,
                        child: Icon(Icons.arrow_drop_down, size: 36, color: Colors.amber),
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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
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
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade900.withValues(alpha: 0.4),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.amber.shade600),
                                    ),
                                    child: Text(
                                      currentLot.category.toUpperCase(),
                                      style: TextStyle(color: Colors.amber.shade400, fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF064E3B),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      currentPlayer.roleString.toUpperCase(),
                                      style: const TextStyle(color: Color(0xFF34D399), fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
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

                    const Divider(color: Color(0xFF1E293B), height: 24),

                    // Price & High Bid Display
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
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
                                        child: Icon(Icons.edit, size: 12, color: Colors.amber),
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
                              const Text('CURRENT HIGH BID', style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.w900)),
                              const SizedBox(height: 2),
                              Text(
                                currencyFormat.format(currentLot.currentBid ?? (currentLot.startingPrice ?? currentLot.basePrice)),
                                style: const TextStyle(color: Colors.amber, fontSize: 22, fontWeight: FontWeight.w900),
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
                            ? Colors.redAccent.withValues(alpha: 0.2)
                            : const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: (auction.biddingSecondsRemaining <= 5 && auction.isTimerRunning)
                              ? Colors.redAccent
                              : const Color(0xFF334155),
                        ),
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
            Text(
              '⚠️ GOING ONCE at ${currencyFormat.format(auction.currentBid)} to ${highBidder?.name ?? "..."}!',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
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
          children: [
            const Icon(Icons.campaign, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              '🚨 GOING TWICE! LAST CHANCE TO COUNTER-BID!',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
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
            Text(
              '⚡ FAIR WARNING! GAVEL ABOUT TO FALL!',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
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
            Text(
              '⏸️ FLOOR PAUSED BY AUCTIONEER',
              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12),
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.shield, color: Colors.amber, size: 14),
                  SizedBox(width: 6),
                  Text(
                    'AUCTIONEER COCKPIT (HOST DOES NOT BID)',
                    style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                  ),
                ],
              ),
              InkWell(
                onTap: () => _showManualStartingPriceDialog(context, db, auction, currentLot),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('Edit Start Price', style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Countdown Warnings Strip (Going Once / Going Twice / Fair Warning)
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => db.setFloorStatus(auction.id, FloorStatus.goingOnce),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.amber,
                    side: const BorderSide(color: Colors.amber),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Going Once', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => db.setFloorStatus(auction.id, FloorStatus.goingTwice),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Going Twice', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => db.setFloorStatus(auction.id, FloorStatus.fairWarning),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.purpleAccent,
                    side: const BorderSide(color: Colors.purpleAccent),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Fair Warning', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                tooltip: auction.floorStatus == FloorStatus.paused ? 'Resume Floor' : 'Pause Floor',
                icon: Icon(
                  auction.floorStatus == FloorStatus.paused ? Icons.play_arrow : Icons.pause,
                  color: Colors.white70,
                  size: 20,
                ),
                onPressed: () {
                  final next = auction.floorStatus == FloorStatus.paused ? FloorStatus.open : FloorStatus.paused;
                  db.setFloorStatus(auction.id, next);
                },
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Main Hammer Buttons: SOLD / UNSOLD
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => db.setFloorStatus(auction.id, FloorStatus.sold),
                  icon: const Icon(Icons.gavel, size: 16),
                  label: const Text('HAMMER SOLD', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => db.setFloorStatus(auction.id, FloorStatus.unsold),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade400,
                    side: BorderSide(color: Colors.red.shade400),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('UNSOLD (PASS)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: myTeam.primaryColor.withValues(alpha: 0.5)),
      ),
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
  void _showEnterAuctionRoomDialog(
    BuildContext context,
    MockDatabase db,
    Auction auction,
    List<Team> safe8Teams, {
    int initialTab = 0,
  }) {
    int activeTab = initialTab;
    final teamCodeController = TextEditingController(text: safe8Teams.isNotEmpty ? safe8Teams.first.uniqueTeamCode : '');
    final teamPassController = TextEditingController(text: '1234');
    final hostPassController = TextEditingController(text: 'admin123');
    String? errorMessage;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
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
                    const Text('Enter with your unique Team Code & Passcode to place live bids.', style: TextStyle(color: Colors.white70, fontSize: 11)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: teamCodeController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Unique Team ID',
                        labelStyle: const TextStyle(color: Colors.white70),
                        hintText: 'e.g. TEAM-BBL-01',
                        prefixIcon: const Icon(Icons.shield, color: Colors.amber, size: 18),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: teamPassController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Team Passcode PIN',
                        labelStyle: const TextStyle(color: Colors.white70),
                        hintText: 'e.g. 1234',
                        prefixIcon: const Icon(Icons.password, color: Colors.white54, size: 18),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    if (safe8Teams.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      // Quick select from teams
                      const Text('Or tap your franchise:', style: TextStyle(color: Colors.white38, fontSize: 10)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        children: safe8Teams.map((t) {
                          return ActionChip(
                            label: Text(t.shortName, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            backgroundColor: const Color(0xFF0F172A),
                            onPressed: () {
                              setDialogState(() {
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
                      teamCode: teamCodeController.text,
                      passcode: teamPassController.text,
                    );
                    if (ok) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF059669),
                          content: Text('Welcome, ${db.currentAuthenticatedTeam?.name}! You can now bid.'),
                        ),
                      );
                    } else {
                      setDialogState(() => errorMessage = 'Invalid Team Code or Passcode.');
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
}

class AuctionWheelPainter extends CustomPainter {
  final int itemsCount;

  AuctionWheelPainter({required this.itemsCount});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final sweepAngle = (2 * pi) / itemsCount;

    final colors = [
      const Color(0xFF059669),
      const Color(0xFFD97706),
      const Color(0xFF7C3AED),
      const Color(0xFF0284C7),
      const Color(0xFFDC2626),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFF4F46E5),
    ];

    for (int i = 0; i < itemsCount; i++) {
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * sweepAngle,
        sweepAngle,
        true,
        paint,
      );
    }

    // Outer ring
    final borderPaint = Paint()
      ..color = Colors.amber
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
