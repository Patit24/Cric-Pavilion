import 'package:flutter/material.dart';
import '../../services/mock_database.dart';

class CreateTournamentDialog extends StatefulWidget {
  final MockDatabase db;

  const CreateTournamentDialog({super.key, required this.db});

  @override
  State<CreateTournamentDialog> createState() => _CreateTournamentDialogState();
}

class _CreateTournamentDialogState extends State<CreateTournamentDialog> {
  final nameController = TextEditingController(text: 'National Premier League 2026');
  final shortController = TextEditingController(text: 'NPL 2026');
  final locationController = TextEditingController(text: 'Eden Gardens, Kolkata');
  final roomController = TextEditingController(text: 'TOURN-NPL-2026');
  final passController = TextEditingController(text: '1234');
  int selectedOvers = 20;
  bool autoCreateAuction = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: const [
          Icon(Icons.emoji_events, color: Color(0xFF34D399), size: 22),
          SizedBox(width: 8),
          Text(
            'Create New Tournament',
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
              'Set up a full tournament with a private Room ID & PIN for scorer access, plus automatic 8 franchise teams & player auction.',
              style: TextStyle(color: Colors.white70, fontSize: 11),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                labelText: 'Tournament Name',
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
                    controller: shortController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Short Code',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (val) {
                      if (val.trim().isNotEmpty) {
                        setState(() {
                          roomController.text = 'TOURN-${val.trim().toUpperCase().replaceAll(' ', '')}-2026';
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: selectedOvers,
                    dropdownColor: const Color(0xFF1E293B),
                    decoration: InputDecoration(
                      labelText: 'Match Format',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    items: const [
                      DropdownMenuItem(value: 20, child: Text('T20 (20 Overs)')),
                      DropdownMenuItem(value: 10, child: Text('T10 (10 Overs)')),
                      DropdownMenuItem(value: 50, child: Text('ODI (50 Overs)')),
                    ],
                    onChanged: (val) => setState(() => selectedOvers = val ?? 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: locationController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                labelText: 'Location / Stadium',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 14),

            // Room Security Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF064E3B).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF059669)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.lock, size: 14, color: Color(0xFF34D399)),
                      SizedBox(width: 6),
                      Text(
                        'TOURNAMENT ROOM SECURITY',
                        style: TextStyle(color: Color(0xFF34D399), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: roomController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Tournament Room ID',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: passController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Host Password / PIN',
                      labelStyle: const TextStyle(color: Colors.white70),
                      hintText: 'e.g. 1234',
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Auto-Provision 8 Teams & Auction', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              subtitle: const Text('Creates 8 franchise teams with unique IDs & links player auction room', style: TextStyle(color: Colors.white54, fontSize: 10)),
              value: autoCreateAuction,
              activeColor: const Color(0xFF34D399),
              onChanged: (val) => setState(() => autoCreateAuction = val),
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
            if (nameController.text.trim().isEmpty || roomController.text.trim().isEmpty) return;
            final created = widget.db.createTournament(
              name: nameController.text.trim(),
              shortName: shortController.text.trim(),
              location: locationController.text.trim(),
              overs: selectedOvers,
              roomId: roomController.text.trim(),
              passcode: passController.text.trim(),
              createAuction: autoCreateAuction,
            );

            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: const Color(0xFF059669),
                content: Text('Tournament "${created.name}" created with Room: ${created.roomId}!'),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF34D399),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Create Tournament', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
