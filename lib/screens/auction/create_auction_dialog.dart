import 'package:flutter/material.dart';
import '../../services/mock_database.dart';

class CreateAuctionDialog extends StatefulWidget {
  final MockDatabase db;

  const CreateAuctionDialog({super.key, required this.db});

  @override
  State<CreateAuctionDialog> createState() => _CreateAuctionDialogState();
}

class _CreateAuctionDialogState extends State<CreateAuctionDialog> {
  late String selectedTournamentId;
  final titleController = TextEditingController(text: 'PSL 2026 Player Auction & Draft');
  final adminPassController = TextEditingController(text: 'admin123');
  final purseController = TextEditingController(text: '10000000'); // ₹1 Crore
  final minBidController = TextEditingController(text: '25000'); // ₹25,000
  int requiredTeams = 8;

  @override
  void initState() {
    super.initState();
    selectedTournamentId = widget.db.tournaments.first.id;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: const [
          Icon(Icons.gavel, color: Colors.amber, size: 22),
          SizedBox(width: 8),
          Text(
            'Host New Player Auction',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Set up a live franchise player auction. Host sets 8 participating teams, purses, minimum bid, and wheel rules.',
              style: TextStyle(color: Colors.white70, fontSize: 11),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedTournamentId,
              dropdownColor: const Color(0xFF1E293B),
              decoration: InputDecoration(
                labelText: 'Linked Tournament',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              items: widget.db.tournaments.map((t) {
                return DropdownMenuItem(value: t.id, child: Text(t.name));
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    selectedTournamentId = val;
                    final t = widget.db.tournaments.firstWhere((item) => item.id == val);
                    titleController.text = '${t.name} Franchise Auction';
                  });
                }
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: titleController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                labelText: 'Auction Title',
                labelStyle: const TextStyle(color: Colors.white70),
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
                    controller: purseController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Purse per Team (₹)',
                      labelStyle: const TextStyle(color: Colors.white70),
                      hintText: '10000000',
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: minBidController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Min Bid Inc (₹)',
                      labelStyle: const TextStyle(color: Colors.white70),
                      hintText: '25000',
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
              controller: adminPassController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                labelText: 'Host / Auctioneer PIN',
                labelStyle: const TextStyle(color: Colors.white70),
                hintText: 'e.g. admin123',
                prefixIcon: const Icon(Icons.security, color: Colors.amber, size: 18),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.groups, size: 18, color: Colors.amber),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '8 Teams participate. Every team has a unique Team ID & PIN. Auction will start once all 8 teams enter the room.',
                      style: TextStyle(color: Colors.amber, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: () {
            if (titleController.text.trim().isEmpty) return;
            final purse = int.tryParse(purseController.text.trim()) ?? 10000000;
            final minBid = int.tryParse(minBidController.text.trim()) ?? 25000;

            final created = widget.db.createAuction(
              tournamentId: selectedTournamentId,
              title: titleController.text.trim(),
              adminPasscode: adminPassController.text.trim(),
              maxPursePerTeam: purse,
              minBidIncrement: minBid,
              requiredTeamsCount: 8,
            );

            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: const Color(0xFF059669),
                content: Text('Auction "${created.title}" created with 8 Franchise Teams!'),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Create Auction', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
