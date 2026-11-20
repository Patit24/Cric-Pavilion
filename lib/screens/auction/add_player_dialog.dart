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
  final nameController = TextEditingController();
  final mobileController = TextEditingController();
  final photoController = TextEditingController();
  final basePriceController = TextEditingController();
  PlayerRole selectedRole = PlayerRole.batsman;
  String selectedBatting = 'Right Hand Bat';
  String selectedBowling = 'Right Arm Medium';
  String selectedCategory = 'batsman';

  @override
  void dispose() {
    nameController.dispose();
    mobileController.dispose();
    photoController.dispose();
    basePriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF334155)),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.person_add, color: Color(0xFF34D399), size: 20),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Add Player to Auction Pool',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
              overflow: TextOverflow.ellipsis,
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
              'Add player name, contact mobile, position, and base price to the draft lot.',
              style: TextStyle(color: Colors.white60, fontSize: 11),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                labelText: 'Player Full Name *',
                labelStyle: const TextStyle(color: Colors.white70, fontSize: 11.5),
                hintText: 'e.g. Rohit Sharma',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 11),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: mobileController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                labelText: 'Mobile Number *',
                labelStyle: const TextStyle(color: Colors.white70, fontSize: 11.5),
                hintText: 'e.g. 9876543210',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 11),
                prefixIcon: const Icon(Icons.phone, size: 16, color: Color(0xFF34D399)),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: photoController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                labelText: 'Player Photo URL (Optional)',
                labelStyle: const TextStyle(color: Colors.white70, fontSize: 11.5),
                hintText: 'https://...',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 11),
                prefixIcon: const Icon(Icons.image, size: 16, color: Colors.amber),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),

            // Role selection chips
            const Text('Player Role *', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildRoleSelectChip('Batter', PlayerRole.batsman),
                _buildRoleSelectChip('Bowler', PlayerRole.bowler),
                _buildRoleSelectChip('All-Rounder', PlayerRole.allRounder),
                _buildRoleSelectChip('Wicketkeeper', PlayerRole.wicketKeeper),
              ],
            ),
            const SizedBox(height: 12),

            TextField(
              controller: basePriceController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'Base Price (₹) *',
                labelStyle: const TextStyle(color: Colors.white70, fontSize: 11.5),
                hintText: 'e.g. 500 or 500000',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 11),
                prefixIcon: const Icon(Icons.monetization_on, size: 16, color: Colors.amber),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 6),
            // Quick price chips
            Wrap(
              spacing: 6,
              children: [500, 1000, 5000, 25000, 50000].map((pr) {
                return InkWell(
                  onTap: () => setState(() => basePriceController.text = pr.toString()),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                    ),
                    child: Text('₹$pr', style: const TextStyle(color: Colors.amber, fontSize: 9.5, fontWeight: FontWeight.bold)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedBatting,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF1E293B),
                    decoration: InputDecoration(
                      labelText: 'Batting Style',
                      labelStyle: const TextStyle(color: Colors.white70, fontSize: 11),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
                    isExpanded: true,
                    dropdownColor: const Color(0xFF1E293B),
                    decoration: InputDecoration(
                      labelText: 'Bowling Style',
                      labelStyle: const TextStyle(color: Colors.white70, fontSize: 11),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
          child: const Text('Cancel', style: TextStyle(color: Colors.white54, fontSize: 12)),
        ),
        ElevatedButton(
          onPressed: () {
            if (nameController.text.trim().isEmpty) return;
            final basePrice = int.tryParse(basePriceController.text.trim()) ?? 500;

            widget.db.addPlayerToAuction(
              auctionId: widget.auctionId,
              fullName: nameController.text.trim(),
              mobileNumber: mobileController.text.trim(),
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
            backgroundColor: const Color(0xFF059669),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Add to Pool', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildRoleSelectChip(String label, PlayerRole role) {
    final isSelected = selectedRole == role;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFF059669),
      backgroundColor: const Color(0xFF1E293B),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.white70,
        fontWeight: isSelected ? FontWeight.w900 : FontWeight.normal,
        fontSize: 10.5,
      ),
      onSelected: (val) {
        if (val) {
          setState(() {
            selectedRole = role;
            selectedCategory = role == PlayerRole.batsman
                ? 'batsman'
                : (role == PlayerRole.bowler ? 'bowler' : (role == PlayerRole.wicketKeeper ? 'wicketkeeper' : 'all_rounder'));
          });
        }
      },
    );
  }
}
