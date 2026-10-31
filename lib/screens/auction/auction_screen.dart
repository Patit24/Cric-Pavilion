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

    return Scaffold(
      backgroundColor: const Color(0xFF020617), // Deep cinematic stadium dark
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
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('FRANCHISE AUCTION STAGE', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1)),
                Text('Live Spinning Wheel & Real-Time Bidding', style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber),
            ),
            child: Row(
              children: [
                const Icon(Icons.circle, size: 8, color: Colors.amber),
                const SizedBox(width: 6),
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
                        onTap: _isSpinning ? null : () => _spinWheel(db),
                        child: Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: Colors.amber.shade500,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.amber.withValues(alpha: 0.5), blurRadius: 16, spreadRadius: 2),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _isSpinning ? '...' : 'SPIN',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.black),
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
                    _isSpinning ? 'Revealing next franchise lot...' : 'Tap SPIN to reveal player dynamically',
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ACTIVE PLAYER LOT CARD
            if (currentLot != null && currentPlayer != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.amber.shade700, width: 2),
                  boxShadow: [
                    BoxShadow(color: Colors.amber.withValues(alpha: 0.1), blurRadius: 20, spreadRadius: 2),
                  ],
                ),
                child: Column(
                  children: [
                    // Lot Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade400,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'LOT #${currentLot.lotNumber}',
                            style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w900),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${currentLot.category.toUpperCase()} CATEGORY',
                            style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Player Portrait & Bio
                    Row(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.amber, width: 2),
                            image: DecorationImage(
                              image: NetworkImage(currentPlayer.photoUrl),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentPlayer.fullName,
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${currentPlayer.roleString} • ${currentPlayer.battingStyle}',
                                style: const TextStyle(color: Colors.white60, fontSize: 11),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Base Price: ${currencyFormat.format(currentLot.basePrice)}',
                                style: const TextStyle(color: Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // CURRENT BID DISPLAY
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF020617),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('CURRENT BID', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                              Text(
                                currencyFormat.format(auction.currentBid ?? currentLot.basePrice),
                                style: const TextStyle(color: Colors.amber, fontSize: 24, fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                          if (highBidderTeam != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('HIGHEST BIDDER', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
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
                      ),
                    ),
                    const SizedBox(height: 16),

                    // BIDDING ACTION CONTROLS
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
