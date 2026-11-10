import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/mock_database.dart';

class AuctionProjectorScreen extends StatefulWidget {
  final String auctionId;

  const AuctionProjectorScreen({super.key, required this.auctionId});

  @override
  State<AuctionProjectorScreen> createState() => _AuctionProjectorScreenState();
}

class _AuctionProjectorScreenState extends State<AuctionProjectorScreen> {
  Timer? _countdownTimer;
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final db = Provider.of<MockDatabase>(context, listen: false);
      final auc = db.getAuction(widget.auctionId);
      if (auc.isTimerRunning) {
        db.tickAuctionTimer(widget.auctionId);
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final db = context.watch<MockDatabase>();
    final auction = db.getAuction(widget.auctionId);
    final currentLot = db.auctionLots.where((l) => l.id == auction.currentLotId).firstOrNull;
    final currentPlayer = currentLot != null
        ? db.players.where((p) => p.id == currentLot.playerId).firstOrNull
        : null;

    final highBidderTeam = auction.highBidderTeamId != null
        ? db.teams.where((t) => t.id == auction.highBidderTeamId).firstOrNull
        : null;

    final teams = db.teams.where((t) => t.tournamentId == auction.tournamentId).toList();
    final bids = db.auctionBids.where((b) => b.lotId == currentLot?.id).take(5).toList();

    final secondsLeft = auction.biddingSecondsRemaining;
    final isUrgent = secondsLeft <= 5 && auction.isTimerRunning;

    return Scaffold(
      backgroundColor: const Color(0xFF020617), // Deep stadium midnight
      body: SafeArea(
        child: Column(
          children: [
            // TOP STADIUM HEADER BAR
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFD97706), Color(0xFFF59E0B)]),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.tv, color: Colors.black, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                auction.title.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE11D48).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE11D48)),
                                ),
                                child: const Row(
                                  children: [
                                    CircleAvatar(radius: 3, backgroundColor: Color(0xFFE11D48)),
                                    SizedBox(width: 4),
                                    Text('LIVE BROADCAST', style: TextStyle(color: Color(0xFFE11D48), fontSize: 9, fontWeight: FontWeight.w900)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Ceremony Projector View • Lot ${auction.completedLots + 1} of ${auction.totalLots}',
                            style: const TextStyle(color: Colors.white54, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Floor Gavel Status Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getFloorStatusColor(auction.floorStatus).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _getFloorStatusColor(auction.floorStatus)),
                        ),
                        child: Text(
                          _getFloorStatusText(auction.floorStatus).toUpperCase(),
                          style: TextStyle(
                            color: _getFloorStatusColor(auction.floorStatus),
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Exit Projector View Button
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.fullscreen_exit, size: 16),
                        label: const Text('Exit Fullscreen', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF334155),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // MAIN STAGE (SPLIT VIEW)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // LEFT: GIANT PLAYER SHOWCASE CARD
                    Expanded(
                      flex: 6,
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: const Color(0xFF334155), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: currentPlayer == null
                            ? const Center(
                                child: Text('No Player Currently on Stage', style: TextStyle(color: Colors.white54, fontSize: 18)),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Player HD Image
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(20),
                                        child: Image.network(
                                          currentPlayer.photoUrl,
                                          width: 140,
                                          height: 140,
                                          fit: BoxFit.cover,
                                          errorBuilder: (ctx, err, stack) => Container(
                                            width: 140,
                                            height: 140,
                                            color: Colors.grey.shade800,
                                            child: const Icon(Icons.person, color: Colors.white54, size: 64),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 24),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.amber.shade900.withValues(alpha: 0.4),
                                                    borderRadius: BorderRadius.circular(8),
                                                    border: Border.all(color: Colors.amber.shade600),
                                                  ),
                                                  child: Text(
                                                    currentLot?.category.toUpperCase() ?? 'PLAYER',
                                                    style: TextStyle(color: Colors.amber.shade400, fontSize: 11, fontWeight: FontWeight.w900),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF064E3B),
                                                    borderRadius: BorderRadius.circular(8),
                                                    border: Border.all(color: const Color(0xFF059669)),
                                                  ),
                                                  child: Text(
                                                    currentPlayer.roleString.toUpperCase(),
                                                    style: const TextStyle(color: Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.w900),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              currentPlayer.fullName,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 32,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: -0.5,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              '${currentPlayer.battingStyle}  •  ${currentPlayer.bowlingStyle}',
                                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Career: ${currentPlayer.matches} Matches • ${currentPlayer.runs} Runs • ${currentPlayer.wickets} Wickets',
                                              style: const TextStyle(color: Colors.white54, fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  const Spacer(),

                                  // Starting vs Base Price Banner
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF020617).withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        Column(
                                          children: [
                                            const Text('BASE PRICE', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                                            const SizedBox(height: 4),
                                            Text(
                                              currencyFormat.format(currentPlayer.basePrice),
                                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                                            ),
                                          ],
                                        ),
                                        Container(width: 1, height: 36, color: Colors.white12),
                                        Column(
                                          children: [
                                            const Text('MIN BID INCREMENT', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                                            const SizedBox(height: 4),
                                            Text(
                                              '+${currencyFormat.format(auction.minBidIncrement)}',
                                              style: const TextStyle(color: Color(0xFF34D399), fontSize: 18, fontWeight: FontWeight.w900),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(width: 24),

                    // RIGHT: GIANT CURRENT HIGH BID & TIMER
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // CURRENT HIGH BID HERO PANEL
                          Expanded(
                            flex: 6,
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    highBidderTeam?.primaryColor.withValues(alpha: 0.25) ?? const Color(0xFF1E293B),
                                    const Color(0xFF0F172A),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: highBidderTeam?.primaryColor ?? Colors.amber,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (highBidderTeam?.primaryColor ?? Colors.amber).withValues(alpha: 0.2),
                                    blurRadius: 30,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'CURRENT HIGH BID',
                                    style: TextStyle(
                                      color: Colors.amber,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      currencyFormat.format(auction.currentBid ?? (currentLot?.startingPrice ?? currentLot?.basePrice ?? 0)),
                                      style: const TextStyle(
                                        color: Colors.amber,
                                        fontSize: 54,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -1,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  if (highBidderTeam != null) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: highBidderTeam.primaryColor.withValues(alpha: 0.25),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: highBidderTeam.primaryColor, width: 1.5),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          CircleAvatar(
                                            backgroundImage: NetworkImage(highBidderTeam.logoUrl),
                                            radius: 16,
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            highBidderTeam.name,
                                            style: TextStyle(
                                              color: highBidderTeam.primaryColor,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(Icons.arrow_upward, color: Colors.greenAccent, size: 18),
                                        ],
                                      ),
                                    ),
                                  ] else ...[
                                    const Text('Floor Open • Awaiting Opening Bid', style: TextStyle(color: Colors.white54, fontSize: 13)),
                                  ],
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // COUNTDOWN TIMER & LIVE FEED ROW
                          Expanded(
                            flex: 4,
                            child: Row(
                              children: [
                                // CIRCULAR COUNTDOWN TIMER
                                Expanded(
                                  flex: 4,
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F172A),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: isUrgent ? Colors.redAccent : const Color(0xFF334155)),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '00:${secondsLeft.toString().padLeft(2, '0')}',
                                          style: TextStyle(
                                            color: isUrgent ? Colors.redAccent : Colors.white,
                                            fontSize: 32,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          isUrgent ? 'CLOSING SOON!' : 'BIDDING TIME LEFT',
                                          style: TextStyle(
                                            color: isUrgent ? Colors.redAccent : Colors.white54,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // LIVE BID TICKER
                                Expanded(
                                  flex: 6,
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F172A),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: const Color(0xFF334155)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'LIVE BIDDING STREAM',
                                          style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                                        ),
                                        const SizedBox(height: 6),
                                        Expanded(
                                          child: bids.isEmpty
                                              ? const Center(
                                                  child: Text('No bids yet on this lot', style: TextStyle(color: Colors.white38, fontSize: 11)),
                                                )
                                              : ListView.builder(
                                                  itemCount: bids.length,
                                                  itemBuilder: (ctx, i) {
                                                    final b = bids[i];
                                                    return Padding(
                                                      padding: const EdgeInsets.symmetric(vertical: 2),
                                                      child: Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          Text(b.teamName, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                                          Text(currencyFormat.format(b.amount), style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // BOTTOM STRIP: 8 FRANCHISE TEAMS REALTIME PURSE STRIP
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: teams.map((t) {
                    final isLeading = auction.highBidderTeamId == t.id;
                    return Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isLeading ? t.primaryColor.withValues(alpha: 0.25) : const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isLeading ? t.primaryColor : Colors.white10,
                          width: isLeading ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(backgroundImage: NetworkImage(t.logoUrl), radius: 12),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.shortName, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
                              Text(
                                currencyFormat.format(t.purseRemaining),
                                style: TextStyle(color: t.primaryColor, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('${t.squadCount}/${t.minSquadRequirement}', style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getFloorStatusColor(FloorStatus status) {
    switch (status) {
      case FloorStatus.open:
        return const Color(0xFF10B981);
      case FloorStatus.goingOnce:
        return Colors.orangeAccent;
      case FloorStatus.goingTwice:
        return Colors.deepOrangeAccent;
      case FloorStatus.fairWarning:
        return Colors.redAccent;
      case FloorStatus.sold:
        return Colors.blueAccent;
      case FloorStatus.unsold:
        return Colors.grey;
      case FloorStatus.paused:
        return Colors.purpleAccent;
    }
  }

  String _getFloorStatusText(FloorStatus status) {
    switch (status) {
      case FloorStatus.open:
        return 'Floor Open';
      case FloorStatus.goingOnce:
        return 'Going Once...';
      case FloorStatus.goingTwice:
        return 'Going Twice...';
      case FloorStatus.fairWarning:
        return 'Fair Warning!';
      case FloorStatus.sold:
        return 'SOLD';
      case FloorStatus.unsold:
        return 'UNSOLD';
      case FloorStatus.paused:
        return 'Floor Paused';
    }
  }
}
