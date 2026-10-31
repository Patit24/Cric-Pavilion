import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/mock_database.dart';
import 'create_auction_dialog.dart';
import 'add_player_dialog.dart';

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

  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    selectedAuctionId = widget.initialAuctionId ?? 'auc_bpl_2026';
    _wheelController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  void dispose() {
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final db = context.watch<MockDatabase>();

    if (selectedAuctionId == null) {
      return _buildAuctionDirectory(context, db);
    }

    final auction = db.auctions.where((a) => a.id == selectedAuctionId).firstOrNull ?? db.auctions.first;
    return _buildAuctionArena(context, db, auction);
  }

  // =========================================================================
  // 1. AUCTION DIRECTORY / HUB (BPL, PSL, IPL Auctions)
  // =========================================================================
  Widget _buildAuctionDirectory(BuildContext context, MockDatabase db) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.amber.shade400, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.gavel, size: 16, color: Colors.black),
            ),
            const SizedBox(width: 10),
            const Text(
              'FRANCHISE AUCTION DIRECTORY',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.8),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => CreateAuctionDialog(db: db),
              );
            },
            icon: const Icon(Icons.add_circle, color: Colors.amber, size: 16),
            label: const Text('Host Auction', style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
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
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => CreateAuctionDialog(db: db),
                    );
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isLive ? const Color(0xFF064E3B) : Colors.white10,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.circle, size: 8, color: isLive ? const Color(0xFF34D399) : Colors.white54),
                              const SizedBox(width: 5),
                              Text(
                                isLive ? (ready ? 'LIVE BIDDING' : 'WAITING ROOM (8 TEAMS)') : 'PREVIEW',
                                style: TextStyle(
                                  color: isLive ? const Color(0xFF34D399) : Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
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
                      children: [
                        _buildStatChip(Icons.monetization_on, 'Purse: ${currencyFormat.format(auc.maxPursePerTeam)}'),
                        const SizedBox(width: 8),
                        _buildStatChip(Icons.gavel, 'Min: ${currencyFormat.format(auc.minBidIncrement)}'),
                        const SizedBox(width: 8),
                        _buildStatChip(Icons.groups, '8 Franchises'),
                        const Spacer(),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(6)),
      child: Row(
        children: [
          Icon(icon, size: 11, color: Colors.amber),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
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

    final isUnlocked = db.isAuctionUnlocked;
    final isAdmin = db.isAuctionAdmin;
    final myTeam = db.currentAuthenticatedTeam;

    final participatingTeams = db.teams.where((t) => t.tournamentId == auction.tournamentId || t.tournamentId == 'tourn_bpl_2026').toList();
    final safe8Teams = participatingTeams.length >= 8 ? participatingTeams.sublist(0, 8) : db.teams.take(8).toList();

    // Default squad view team
    selectedTeamIdForSquadView ??= myTeam?.id ?? safe8Teams.first.id;
    final squadViewTeam = safe8Teams.where((t) => t.id == selectedTeamIdForSquadView).firstOrNull ?? safe8Teams.first;
    final squadPlayers = db.players.where((p) => p.teamId == squadViewTeam.id).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
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
                Text(
                  isUnlocked
                      ? (isAdmin ? 'Host / Auctioneer Mode' : 'Owner: ${myTeam?.name ?? "Team Owner"}')
                      : 'Spectator Mode (Broadcast Watch)',
                  style: TextStyle(
                    color: isUnlocked ? (isAdmin ? Colors.amber : const Color(0xFF34D399)) : Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (isAdmin)
            IconButton(
              tooltip: 'Add Player to Auction',
              icon: const Icon(Icons.person_add, color: Color(0xFF34D399), size: 20),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AddPlayerDialog(db: db, auctionId: auction.id),
                );
              },
            ),
          if (!isUnlocked)
            TextButton.icon(
              onPressed: () => _showEnterAuctionRoomDialog(context, db, auction, safe8Teams),
              icon: const Icon(Icons.vpn_key, size: 14, color: Colors.amber),
              label: const Text('Enter Room', style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
            )
          else
            TextButton.icon(
              onPressed: () {
                db.exitAuctionRoom();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Returned to Spectator Broadcast.')),
                );
              },
              icon: const Icon(Icons.lock, size: 14, color: Colors.redAccent),
              label: const Text('Exit', style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                          // Quick check-in shortcut for testing
                          if (!isConnected) {
                            db.checkInTeamToAuction(auction.id, t.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${t.name} entered the room!')),
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

                  if (!auction.isReadyToStart) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              db.checkInAllTeamsToAuction(auction.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('All 8 teams entered! Auction unlocked.')),
                              );
                            },
                            icon: const Icon(Icons.flash_on, size: 14),
                            label: const Text('Check-In All 8 Teams (Quick Test)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // =========================================================
            // SPINNING WHEEL BANNER (HOST CONTROLLED)
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
                  const Text(
                    '🎡 PLAYER SELECTION WHEEL',
                    style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.2),
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
                          painter: AuctionWheelPainter(itemsCount: 8),
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
                                ? 'Host: Tap SPIN to reveal next player lot'
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
                              const Text('BASE PRICE', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text(currencyFormat.format(currentLot.basePrice), style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('CURRENT HIGH BID', style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.w900)),
                              const SizedBox(height: 2),
                              Text(
                                currencyFormat.format(currentLot.currentBid ?? currentLot.basePrice),
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
                          const Text('Winning Bidder: ', style: TextStyle(color: Colors.white54, fontSize: 11)),
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

                    const SizedBox(height: 16),

                    // =========================================================
                    // BIDDING ACTION CONTROLS (TEAM OWNERS ONLY vs HOST HAMMER)
                    // =========================================================
                    if (isAdmin) ...[
                      // HOST / AUCTIONEER HAMMER CONTROLS (Host CANNOT bid!)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shield, color: Colors.amber, size: 14),
                                SizedBox(width: 6),
                                Text(
                                  'HOST AUCTIONEER GAVEL (HOST DOES NOT BID)',
                                  style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => db.sellCurrentLot(auction.id),
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
                                    onPressed: () => db.passCurrentLot(auction.id),
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
                          ],
                        ),
                      ),
                    ] else if (myTeam != null) ...[
                      // AUTHENTICATED TEAM OWNER BIDDING CONTROLS
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Bidding as ${myTeam.name}:',
                                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Purse: ${currencyFormat.format(myTeam.purseRemaining)}',
                                style: TextStyle(color: myTeam.primaryColor, fontSize: 12, fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Bid Increment Buttons (+25k, +50k, +1L)
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    final ok = db.placeAuctionBid(
                                      auctionId: auction.id,
                                      teamId: myTeam.id,
                                      increment: auction.minBidIncrement,
                                    );
                                    if (!ok) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Cannot place bid: check purse or 8-team check-in requirement.')),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber.shade600,
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: Text('+${currencyFormat.format(auction.minBidIncrement)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    final ok = db.placeAuctionBid(
                                      auctionId: auction.id,
                                      teamId: myTeam.id,
                                      increment: 50000,
                                    );
                                    if (!ok) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Cannot place bid: check purse or 8-team check-in requirement.')),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber.shade500,
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: const Text('+₹50k', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    final ok = db.placeAuctionBid(
                                      auctionId: auction.id,
                                      teamId: myTeam.id,
                                      increment: 100000,
                                    );
                                    if (!ok) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Cannot place bid: check purse or 8-team check-in requirement.')),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber.shade400,
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: const Text('+₹1 Lakh', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ] else ...[
                      // SPECTATOR BROADCAST NOTICE
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Only registered franchise owners can place bids on this player lot.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () => _showEnterAuctionRoomDialog(context, db, auction, safe8Teams),
                              icon: const Icon(Icons.vpn_key, size: 14),
                              label: const Text('Enter with Team ID & PIN to Bid', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber,
                                foregroundColor: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

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

            // 8 Teams Horizontal Scrollable Selector
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: safe8Teams.map((t) {
                  final isSelected = t.id == squadViewTeam.id;
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
            const SizedBox(height: 12),

            // SELECTED TEAM SQUAD DETAILS CARD
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
                              'Code: ${squadViewTeam.uniqueTeamCode} • PIN: ${squadViewTeam.passcode}',
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
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
                      alignment: Alignment.center,
                      child: const Text('No players purchased yet in this auction.', style: TextStyle(color: Colors.white54, fontSize: 11)),
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
  // MODALS: ENTER AUCTION ROOM AS TEAM OWNER OR HOST
  // =========================================================================
  void _showEnterAuctionRoomDialog(
    BuildContext context,
    MockDatabase db,
    Auction auction,
    List<Team> safe8Teams,
  ) {
    int activeTab = 0; // 0 = Team Owner, 1 = Host Admin
    final teamCodeController = TextEditingController(text: safe8Teams.first.uniqueTeamCode);
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
                    const SizedBox(height: 10),
                    // Quick select from 8 teams
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
                  ] else ...[
                    // HOST LOGIN
                    const Text('Enter Host PIN to operate spinning wheel and auctioneer hammer.', style: TextStyle(color: Colors.white70, fontSize: 11)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: hostPassController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Auctioneer Host PIN',
                        labelStyle: const TextStyle(color: Colors.white70),
                        hintText: 'admin123',
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
                          content: Text('Host Mode Unlocked! You can spin wheel and hammer sold.'),
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
