import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/mock_database.dart';
import '../../theme/neo_glass_theme.dart';

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
      backgroundColor: GlassTokens.bgIcyWhite, // Modern deep obsidian stadium
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 900 || constraints.maxHeight < 600;
            if (isMobile) {
              return _buildMobileBroadcastView(
                context,
                db,
                auction,
                currentLot,
                currentPlayer,
                highBidderTeam,
                teams,
                bids,
                secondsLeft,
                isUrgent,
              );
            }
            return _buildWidescreenStadiumView(
              context,
              db,
              auction,
              currentLot,
              currentPlayer,
              highBidderTeam,
              teams,
              bids,
              secondsLeft,
              isUrgent,
            );
          },
        ),
      ),
    );
  }

  // =========================================================================
  // 1. MOBILE-OPTIMIZED STADIUM BROADCAST (ZERO OVERFLOW, 100% RESPONSIVE)
  // =========================================================================
  Widget _buildMobileBroadcastView(
    BuildContext context,
    MockDatabase db,
    Auction auction,
    AuctionLot? currentLot,
    Player? currentPlayer,
    Team? highBidderTeam,
    List<Team> teams,
    List<AuctionBid> bids,
    int secondsLeft,
    bool isUrgent,
  ) {
    return Column(
      children: [
        // Responsive Mobile Top Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: GlassTokens.inkPrimary,
            border: Border(bottom: BorderSide(color: GlassTokens.inkPrimary.withValues(alpha: 0.08))),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: GlassTokens.inkPrimary, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE11D48),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(radius: 2.5, backgroundColor: Colors.white),
                    SizedBox(width: 4),
                    Text('LIVE', style: TextStyle(color: GlassTokens.inkPrimary, fontSize: 8.5, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  auction.title,
                  style: const TextStyle(color: GlassTokens.inkPrimary, fontSize: 13, fontWeight: FontWeight.w900),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: _getFloorStatusColor(auction.floorStatus).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _getFloorStatusColor(auction.floorStatus)),
                ),
                child: Text(
                  _getFloorStatusText(auction.floorStatus).toUpperCase(),
                  style: TextStyle(
                    color: _getFloorStatusColor(auction.floorStatus),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Scrollable Stadium Center
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // PLAYER SHOWCASE CARD
                if (currentPlayer != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF131D31), Colors.white],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: GlassTokens.inkPrimary.withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.amber, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.amber.withValues(alpha: 0.3),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 32,
                                backgroundImage: NetworkImage(currentPlayer.photoUrl),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF009270).withValues(alpha: 0.25),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFF009270)),
                                    ),
                                    child: Text(
                                      currentPlayer.roleString.toUpperCase(),
                                      style: const TextStyle(color: Color(0xFF34D399), fontSize: 9.5, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    currentPlayer.fullName,
                                    style: const TextStyle(color: GlassTokens.inkPrimary, fontSize: 18, fontWeight: FontWeight.w900),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${currentPlayer.battingStyle} • ${currentPlayer.bowlingStyle}',
                                    style: const TextStyle(color: GlassTokens.inkSecondary, fontSize: 11),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Base Price: ${currencyFormat.format(currentPlayer.basePrice)}',
                              style: const TextStyle(color: GlassTokens.inkSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'Lot #${currentLot?.lotNumber ?? 1}',
                              style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: GlassTokens.inkPrimary,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: GlassTokens.glassHairline),
                    ),
                    alignment: Alignment.center,
                    child: const Text('Awaiting Player on Stage...', style: TextStyle(color: GlassTokens.inkSecondary, fontSize: 13)),
                  ),

                const SizedBox(height: 12),

                // CURRENT HIGH BID HERO CARD
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        highBidderTeam?.primaryColor.withValues(alpha: 0.22) ?? GlassTokens.bgLightBlue,
                        Colors.white,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: highBidderTeam?.primaryColor ?? Colors.amber.withValues(alpha: 0.8),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'CURRENT HIGHEST BID',
                        style: TextStyle(color: Colors.amber, fontSize: 10.5, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          currencyFormat.format(auction.currentBid ?? (currentLot?.startingPrice ?? currentLot?.basePrice ?? 0)),
                          style: const TextStyle(color: Colors.amber, fontSize: 38, fontWeight: FontWeight.w900),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (highBidderTeam != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: highBidderTeam.primaryColor.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: highBidderTeam.primaryColor),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                backgroundImage: NetworkImage(highBidderTeam.logoUrl),
                                radius: 10,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                highBidderTeam.name,
                                style: TextStyle(color: highBidderTeam.primaryColor, fontWeight: FontWeight.w900, fontSize: 13),
                              ),
                            ],
                          ),
                        )
                      else
                        const Text('Floor Open • Awaiting Opening Bid', style: TextStyle(color: GlassTokens.inkSecondary, fontSize: 11)),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // COUNTDOWN TIMER & LIVE BIDS
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timer Box
                    Expanded(
                      flex: 4,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: GlassTokens.inkPrimary,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isUrgent ? Colors.redAccent : GlassTokens.glassHairline),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '00:${secondsLeft.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                color: isUrgent ? Colors.redAccent : Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isUrgent ? 'CLOSING SOON!' : 'TIME LEFT',
                              style: TextStyle(
                                color: isUrgent ? Colors.redAccent : GlassTokens.inkSecondary,
                                fontSize: 8.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Live Bids Feed
                    Expanded(
                      flex: 6,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: GlassTokens.inkPrimary,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: GlassTokens.glassHairline),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('RECENT BIDS', style: TextStyle(color: GlassTokens.inkSecondary, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.8)),
                            const SizedBox(height: 6),
                            if (bids.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text('No bids yet', style: TextStyle(color: GlassTokens.inkMuted, fontSize: 10)),
                              )
                            else
                              ...bids.take(3).map((b) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Flexible(
                                          child: Text(b.teamName, style: const TextStyle(color: GlassTokens.inkPrimary, fontSize: 10.5, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                        ),
                                        Text(currencyFormat.format(b.amount), style: const TextStyle(color: Colors.amber, fontSize: 10.5, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  )),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Bottom Franchise Ticker (Horizontal scrolling, zero overflow)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0B132B),
            border: Border(top: BorderSide(color: GlassTokens.inkPrimary.withValues(alpha: 0.08))),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: teams.map((t) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: GlassTokens.bgLightBlue,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: t.primaryColor.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(backgroundImage: NetworkImage(t.logoUrl), radius: 9),
                      const SizedBox(width: 6),
                      Text(t.shortName, style: const TextStyle(color: GlassTokens.inkPrimary, fontSize: 10.5, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 4),
                      Text(currencyFormat.format(t.purseRemaining), style: TextStyle(color: t.primaryColor, fontSize: 9.5, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 4),
                      Text('(${t.squadCount})', style: const TextStyle(color: GlassTokens.inkSecondary, fontSize: 9)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // 2. WIDESCREEN / TV CEREMONY BROADCAST (DUAL PANE, ADAPTIVE)
  // =========================================================================
  Widget _buildWidescreenStadiumView(
    BuildContext context,
    MockDatabase db,
    Auction auction,
    AuctionLot? currentLot,
    Player? currentPlayer,
    Team? highBidderTeam,
    List<Team> teams,
    List<AuctionBid> bids,
    int secondsLeft,
    bool isUrgent,
  ) {
    return Column(
      children: [
        // TOP STADIUM HEADER BAR
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: GlassTokens.inkPrimary,
            border: Border(bottom: BorderSide(color: GlassTokens.inkPrimary.withValues(alpha: 0.1))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  auction.title.toUpperCase(),
                                  style: const TextStyle(
                                    color: GlassTokens.inkPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                  ),
                                  overflow: TextOverflow.ellipsis,
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
                                  mainAxisSize: MainAxisSize.min,
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
                            style: const TextStyle(color: GlassTokens.inkSecondary, fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
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

        // MAIN STAGE
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // LEFT: PLAYER SHOWCASE CARD
                Expanded(
                  flex: 6,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.white, GlassTokens.bgLightBlue],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFF334155), width: 1.5),
                    ),
                    child: currentPlayer == null
                        ? const Center(child: Text('No Player Currently on Stage', style: TextStyle(color: GlassTokens.inkSecondary, fontSize: 16)))
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(18),
                                    child: Image.network(
                                      currentPlayer.photoUrl,
                                      width: 110,
                                      height: 110,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 110,
                                        height: 110,
                                        color: Colors.grey.shade800,
                                        child: const Icon(Icons.person, color: GlassTokens.inkSecondary, size: 48),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF009270).withValues(alpha: 0.25),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: const Color(0xFF009270)),
                                          ),
                                          child: Text(
                                            currentPlayer.roleString.toUpperCase(),
                                            style: const TextStyle(color: Color(0xFF34D399), fontSize: 10.5, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          currentPlayer.fullName,
                                          style: const TextStyle(color: GlassTokens.inkPrimary, fontSize: 26, fontWeight: FontWeight.w900),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${currentPlayer.battingStyle} • ${currentPlayer.bowlingStyle}',
                                          style: const TextStyle(color: GlassTokens.inkSecondary, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF020617).withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    Column(
                                      children: [
                                        const Text('BASE PRICE', style: TextStyle(color: GlassTokens.inkSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        Text(
                                          currencyFormat.format(currentPlayer.basePrice),
                                          style: const TextStyle(color: GlassTokens.inkPrimary, fontSize: 18, fontWeight: FontWeight.w900),
                                        ),
                                      ],
                                    ),
                                    Container(width: 1, height: 32, color: GlassTokens.glassHairline),
                                    Column(
                                      children: [
                                        const Text('MIN BID INCREMENT', style: TextStyle(color: GlassTokens.inkSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
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
                const SizedBox(width: 20),

                // RIGHT: CURRENT HIGH BID & TIMER
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 6,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                highBidderTeam?.primaryColor.withValues(alpha: 0.25) ?? GlassTokens.bgLightBlue,
                                Colors.white,
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: highBidderTeam?.primaryColor ?? Colors.amber,
                              width: 1.8,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('CURRENT HIGH BID', style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                              const SizedBox(height: 6),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  currencyFormat.format(auction.currentBid ?? (currentLot?.startingPrice ?? currentLot?.basePrice ?? 0)),
                                  style: const TextStyle(color: Colors.amber, fontSize: 46, fontWeight: FontWeight.w900),
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (highBidderTeam != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: highBidderTeam.primaryColor.withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: highBidderTeam.primaryColor),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircleAvatar(backgroundImage: NetworkImage(highBidderTeam.logoUrl), radius: 14),
                                      const SizedBox(width: 8),
                                      Text(highBidderTeam.name, style: TextStyle(color: highBidderTeam.primaryColor, fontSize: 16, fontWeight: FontWeight.w900)),
                                    ],
                                  ),
                                )
                              else
                                const Text('Floor Open • Awaiting Opening Bid', style: TextStyle(color: GlassTokens.inkSecondary, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        flex: 4,
                        child: Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: GlassTokens.inkPrimary,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: isUrgent ? Colors.redAccent : const Color(0xFF334155)),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('00:${secondsLeft.toString().padLeft(2, '0')}', style: TextStyle(color: isUrgent ? Colors.redAccent : Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                                    Text(isUrgent ? 'CLOSING!' : 'TIME LEFT', style: TextStyle(color: isUrgent ? Colors.redAccent : GlassTokens.inkSecondary, fontSize: 8.5, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 6,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: GlassTokens.inkPrimary,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: const Color(0xFF334155)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('LIVE BIDS', style: TextStyle(color: GlassTokens.inkSecondary, fontSize: 9, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Expanded(
                                      child: bids.isEmpty
                                          ? const Center(child: Text('No bids yet', style: TextStyle(color: GlassTokens.inkMuted, fontSize: 10)))
                                          : ListView.builder(
                                              itemCount: bids.length,
                                              itemBuilder: (_, i) => Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(bids[i].teamName, style: const TextStyle(color: GlassTokens.inkPrimary, fontSize: 10.5, fontWeight: FontWeight.bold)),
                                                  Text(currencyFormat.format(bids[i].amount), style: const TextStyle(color: Colors.amber, fontSize: 10.5, fontWeight: FontWeight.bold)),
                                                ],
                                              ),
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

        // Bottom Strip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: GlassTokens.inkPrimary,
            border: Border(top: BorderSide(color: GlassTokens.inkPrimary.withValues(alpha: 0.1))),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: teams.map((t) {
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: GlassTokens.bgLightBlue,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: t.primaryColor.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(backgroundImage: NetworkImage(t.logoUrl), radius: 10),
                      const SizedBox(width: 8),
                      Text(t.shortName, style: const TextStyle(color: GlassTokens.inkPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 6),
                      Text(currencyFormat.format(t.purseRemaining), style: TextStyle(color: t.primaryColor, fontSize: 10.5, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 6),
                      Text('${t.squadCount}/${t.minSquadRequirement}', style: const TextStyle(color: GlassTokens.inkSecondary, fontSize: 9.5)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
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
        return const Color(0xFF38BDF8);
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
