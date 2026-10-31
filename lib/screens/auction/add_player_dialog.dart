import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/mock_database.dart';

class AddPlayerDialog extends StatefulWidget {
  final MockDatabase db;
  final String auctionId;

  const AddPlayerDialog({super.key, required this.db, required this.auctionId});

  @override
  State<AddPlayerDialog> createState() => _AddPlayerDialogState();
}

class _AddPlayerDialogState extends State<AddPlayerDialog> {
  final nameController = TextEditingController(text: 'Rinku Singh');
  final photoController = TextEditingController(text: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=256');
  final basePriceController = TextEditingController(text: '500000');
  PlayerRole selectedRole = PlayerRole.batsman;
  String selectedBatting = 'Left Hand Bat';
  String selectedBowling = 'Right Arm Off Break';
  String selectedCategory = 'batsman';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: const [
          Icon(Icons.person_add, color: Color(0xFF34D399), size: 22),
          SizedBox(width: 8),
          Text(
            'Add Player to Auction Pool',
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
              'Host can add player name, portrait image URL, position, base price, and category to the auction pool.',
              style: TextStyle(color: Colors.white70, fontSize: 11),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                labelText: 'Player Full Name',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: photoController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                labelText: 'Player Photo URL',
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
                  child: DropdownButtonFormField<PlayerRole>(
                    value: selectedRole,
                    dropdownColor: const Color(0xFF1E293B),
                    decoration: InputDecoration(
                      labelText: 'Role / Position',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    items: const [
                      DropdownMenuItem(value: PlayerRole.batsman, child: Text('Batter')),
                      DropdownMenuItem(value: PlayerRole.bowler, child: Text('Bowler')),
                      DropdownMenuItem(value: PlayerRole.allRounder, child: Text('All-Rounder')),
                      DropdownMenuItem(value: PlayerRole.wicketKeeper, child: Text('Wicketkeeper')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          selectedRole = val;
                          selectedCategory = val == PlayerRole.batsman
                              ? 'batsman'
                              : (val == PlayerRole.bowler ? 'bowler' : 'all_rounder');
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: basePriceController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Base Price (₹)',
                      labelStyle: const TextStyle(color: Colors.white70),
                      hintText: '500000',
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedBatting,
                    dropdownColor: const Color(0xFF1E293B),
                    decoration: InputDecoration(
                      labelText: 'Batting Style',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    items: const [
                      DropdownMenuItem(value: 'Right Hand Bat', child: Text('Right Hand')),
                      DropdownMenuItem(value: 'Left Hand Bat', child: Text('Left Hand')),
                    ],
                    onChanged: (val) => setState(() => selectedBatting = val ?? 'Right Hand Bat'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedBowling,
                    dropdownColor: const Color(0xFF1E293B),
                    decoration: InputDecoration(
                      labelText: 'Bowling Style',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    items: const [
                      DropdownMenuItem(value: 'Right Arm Fast', child: Text('RA Fast')),
                      DropdownMenuItem(value: 'Right Arm Medium', child: Text('RA Medium')),
                      DropdownMenuItem(value: 'Right Arm Spin', child: Text('RA Spin')),
                      DropdownMenuItem(value: 'Left Arm Fast', child: Text('LA Fast')),
                      DropdownMenuItem(value: 'Left Arm Spin', child: Text('LA Spin')),
                      DropdownMenuItem(value: 'None', child: Text('None')),
                    ],
                    onChanged: (val) => setState(() => selectedBowling = val ?? 'Right Arm Fast'),
                  ),
                ),
              ],
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
            if (nameController.text.trim().isEmpty) return;
            final basePrice = int.tryParse(basePriceController.text.trim()) ?? 500000;

            widget.db.addPlayerToAuction(
              auctionId: widget.auctionId,
              fullName: nameController.text.trim(),
              photoUrl: photoController.text.trim(),
              role: selectedRole,
              battingStyle: selectedBatting,
              bowlingStyle: selectedBowling,
              basePrice: basePrice,
              category: selectedCategory,
            );

            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: const Color(0xFF059669),
                content: Text('${nameController.text.trim()} added to Auction Pool!'),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF34D399),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Add Player', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
