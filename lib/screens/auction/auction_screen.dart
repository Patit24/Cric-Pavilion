import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../services/mock_database.dart';

class AuctionScreen extends StatefulWidget {
  const AuctionScreen({super.key});

  @override
  State<AuctionScreen> createState() => _AuctionScreenState();
}

class _AuctionScreenState extends State<AuctionScreen> with SingleTickerProviderStateMixin {
  late AnimationController _wheelController;
  late Animation<double> _wheelAnimation;
  double _currentAngle = 0.0;
  bool _isSpinning = false;
  String selectedBiddingTeamId = 'team_barasat';

  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
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

  void _spinWheel(MockDatabase db) {
    if (_isSpinning) return;
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
    final auction = db.auction;
    final currentLot = db.auctionLots.where((l) => l.id == auction.currentLotId).firstOrNull;
    final currentPlayer = currentLot != null
        ? db.players.where((p) => p.id == currentLot.playerId).firstOrNull
        : null;
    final highBidderTeam = db.teams.where((t) => t.id == auction.highBidderTeamId).firstOrNull;

    final isUnlocked = db.isAuctionUnlocked;
    final isAdmin = db.isAuctionAdmin;

    return Scaffold(
      backgroundColor: const Color(0xFF020617), // Deep cinematic stadium dark
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.amber.shade400, borderRadius: BorderRadius.circular(6)),
                  child: const Icon(Icons.gavel, size: 14, color: Colors.black),
                ),
                const SizedBox(width: 8),
                const Text(
                  'FRANCHISE AUCTION STAGE',
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                ),
              ],
            ),
            Row(
              children: [
                Icon(
                  isUnlocked ? Icons.check_circle : Icons.lock_outline,
                  size: 11,
                  color: isUnlocked ? const Color(0xFF34D399) : Colors.amber,
                ),
                const SizedBox(width: 4),
                Text(
                  isUnlocked
                      ? '${isAdmin ? "Auctioneer Admin" : "Franchise Owner"} (Room: ${db.currentAuctionRoomId ?? "AUCTION-BPL"})'
                      : 'Spectator Broadcast (Live Watch Only)',
                  style: TextStyle(
                    color: isUnlocked ? const Color(0xFF34D399) : Colors.amber.shade300,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (!isUnlocked) ...[
            TextButton.icon(
              onPressed: () => _showEnterAuctionRoomDialog(context, db),
              icon: const Icon(Icons.vpn_key, size: 14, color: Colors.amber),
              label: const Text('Enter Room', style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
            IconButton(
              tooltip: 'Create Auction Room',
              icon: const Icon(Icons.add_circle_outline, color: Colors.white70, size: 20),
              onPressed: () => _showCreateAuctionRoomDialog(context, db),
            ),
          ] else ...[
            TextButton.icon(
              onPressed: () {
                db.lockAuctionRoom();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Auction console locked. Returned to Spectator Mode.')),
                );
              },
              icon: const Icon(Icons.lock, size: 14, color: Colors.redAccent),
              label: const Text('Exit Room', style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber),
            ),
            child: Row(
              children: [
                const Icon(Icons.circle, size: 7, color: Colors.amber),
                const SizedBox(width: 5),
                Text(
                  'LOT ${currentLot?.lotNumber ?? 1}/${auction.totalLots}',
                  style: const TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // SPINNING WHEEL BANNER
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
                          if (!isUnlocked) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Spectator Mode: Spin wheel is reserved for the Auctioneer with Admin PIN.')),
                            );
                            _showEnterAuctionRoomDialog(context, db);
                          } else if (!isAdmin) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Franchise Bidder: Spin wheel requires Auctioneer Admin PIN (admin123).')),
                            );
                          } else {
                            if (!_isSpinning) _spinWheel(db);
                          }
                        },
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: isUnlocked && isAdmin ? Colors.amber.shade500 : Colors.grey.shade800,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (isUnlocked && isAdmin ? Colors.amber : Colors.black).withValues(alpha: 0.5),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _isSpinning ? '...' : (isUnlocked && isAdmin ? 'SPIN' : 'LOCK'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: isUnlocked && isAdmin ? Colors.black : Colors.white70,
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
                        ? 'Revealing next franchise lot...'
                        : (isUnlocked && isAdmin
                            ? 'Tap SPIN to reveal player dynamically'
                            : 'Wheel operated by Official Auctioneer'),
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // CURRENT LOT STAGE CARD
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
                              const Text('CURRENT BID', style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.w900)),
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
                          const Text('Leading Bidder: ', style: TextStyle(color: Colors.white54, fontSize: 11)),
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

                    // CONTROLS SECTION: Unlocked Franchise Console OR Spectator Broadcast Card
                    if (isUnlocked) ...[
                      // FRANCHISE BIDDING CONTROLS
                      const Text('Place Bid for Franchise:', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: selectedBiddingTeamId,
                        dropdownColor: const Color(0xFF1E293B),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: const Color(0xFF1E293B),
                        ),
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        items: db.teams.map((t) {
                          return DropdownMenuItem(
                            value: t.id,
                            child: Text('${t.name} (Purse: ${currencyFormat.format(t.purseRemaining)})'),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => selectedBiddingTeamId = val ?? 'team_barasat'),
                      ),
                      const SizedBox(height: 10),

                      // Bid Increment Buttons (+25k, +50k, +1L)
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => db.placeAuctionBid(selectedBiddingTeamId, 25000),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber.shade600,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('+₹25k', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => db.placeAuctionBid(selectedBiddingTeamId, 50000),
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
                              onPressed: () => db.placeAuctionBid(selectedBiddingTeamId, 100000),
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
                      const SizedBox(height: 14),

                      // Auctioneer Final Action: SOLD / UNSOLD
                      if (isAdmin) ...[
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => db.sellCurrentLot(),
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
                                onPressed: () => db.passCurrentLot(),
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
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'Hammer SOLD / UNSOLD requires Auctioneer Admin PIN (admin123)',
                            style: TextStyle(color: Colors.white54, fontSize: 10),
                          ),
                        ),
                      ],
                    ] else ...[
                      // SPECTATOR BROADCAST LOCK CARD
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.visibility, color: Colors.amber, size: 14),
                                const SizedBox(width: 6),
                                const Text(
                                  'LIVE AUCTION BROADCAST',
                                  style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white10,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('Spectator Watch', style: TextStyle(color: Colors.white60, fontSize: 9)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Only registered franchise owners with their Team Room PIN can place live bids, and authorized auctioneers can hammer lots.',
                              style: TextStyle(color: Colors.white70, fontSize: 10),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _showEnterAuctionRoomDialog(context, db),
                                    icon: const Icon(Icons.vpn_key, size: 14),
                                    label: const Text('ENTER AUCTION ROOM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.amber,
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _showCreateAuctionRoomDialog(context, db),
                                    icon: const Icon(Icons.add_circle_outline, size: 14),
                                    label: const Text('CREATE ROOM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: const BorderSide(color: Colors.white38),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Demo: Team Owner PIN: 1234  •  Auctioneer PIN: admin123',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white38, fontSize: 9),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // FRANCHISE PURSE STATUS
            const Text(
              'FRANCHISE PURSE & SQUAD STATUS',
              style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1),
            ),
            const SizedBox(height: 10),
            ...db.teams.map((t) {
              final spentRatio = (t.maxPurse - t.purseRemaining) / t.maxPurse;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(t.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(
                          '${currencyFormat.format(t.purseRemaining)} left',
                          style: TextStyle(color: t.primaryColor, fontWeight: FontWeight.w900, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: spentRatio,
                        backgroundColor: Colors.white10,
                        valueColor: AlwaysStoppedAnimation<Color>(t.primaryColor),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Squad: ${t.squadCount} players', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                        Text('Spent: ${(spentRatio * 100).toStringAsFixed(0)}%', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 16),

            // RECENT BID LOG
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

  // ==========================================
  // AUCTION ROOM MODALS
  // ==========================================

  void _showEnterAuctionRoomDialog(BuildContext context, MockDatabase db) {
    final roomController = TextEditingController(text: 'AUCTION-BPL');
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
                  const Text(
                    'Enter your franchise bidding PIN or auctioneer administrator PIN.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: roomController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Auction Room ID',
                      labelStyle: const TextStyle(color: Colors.white70),
                      hintText: 'e.g. AUCTION-BPL',
                      prefixIcon: const Icon(Icons.meeting_room, color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Passcode PIN',
                      labelStyle: const TextStyle(color: Colors.white70),
                      hintText: 'Team PIN (1234) or Admin PIN',
                      prefixIcon: const Icon(Icons.password, color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Demo quick-fill chips
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setDialogState(() {
                              roomController.text = 'AUCTION-BPL';
                              passController.text = '1234';
                              errorMessage = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                            ),
                            child: const Text(
                              '⚡ Team PIN: 1234',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setDialogState(() {
                              roomController.text = 'AUCTION-BPL';
                              passController.text = 'admin123';
                              errorMessage = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF064E3B),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF34D399)),
                            ),
                            child: const Text(
                              '⚡ Admin: admin123',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Color(0xFF34D399), fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

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
                  final success = db.unlockAuctionRoom(
                    roomId: roomController.text,
                    passcode: passController.text,
                  );
                  if (success) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF059669),
                        content: Text(
                          db.isAuctionAdmin
                              ? 'Auctioneer Admin Mode Unlocked! (Hammer & Spin active)'
                              : 'Franchise Bidding Unlocked for your team!',
                        ),
                      ),
                    );
                  } else {
                    setDialogState(() {
                      errorMessage = 'Invalid Room ID or Passcode for this auction.';
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Unlock Auction', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCreateAuctionRoomDialog(BuildContext context, MockDatabase db) {
    final roomController = TextEditingController(text: 'AUCTION-BPL-2026');
    final passController = TextEditingController(text: '1234');
    final adminPassController = TextEditingController(text: 'admin123');
    final nameController = TextEditingController(text: 'BPL Governing Body');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Row(
          children: const [
            Icon(Icons.add_circle, color: Colors.amber, size: 20),
            SizedBox(width: 8),
            Text('Create Auction Room', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Create a franchise auction room. Share Team PIN with franchise owners to bid, and keep Admin PIN for the auctioneer hammer.',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: roomController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Auction Room ID',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Franchise Bidding PIN',
                  labelStyle: const TextStyle(color: Colors.white70),
                  hintText: 'e.g. 1234',
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: adminPassController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Auctioneer Admin PIN',
                  labelStyle: const TextStyle(color: Colors.white70),
                  hintText: 'e.g. admin123',
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Organizer Name',
                  labelStyle: const TextStyle(color: Colors.white70),
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
              if (roomController.text.trim().isEmpty || passController.text.trim().isEmpty) return;
              final newRoom = db.createAuctionRoom(
                auctionId: db.auction.id,
                roomId: roomController.text,
                passcode: passController.text,
                adminPasscode: adminPassController.text,
                createdBy: nameController.text,
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF059669),
                  content: Text('Auction Room "${newRoom.id}" created! Unlocked as Auctioneer Admin.'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Create & Enter Room', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
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
