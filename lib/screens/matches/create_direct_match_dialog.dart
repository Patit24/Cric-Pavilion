import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/mock_database.dart';
import '../../widgets/add_existing_player_dialog.dart';
import '../scorer/scorer_screen.dart';

class CreateDirectMatchDialog extends StatefulWidget {
  final MockDatabase db;

  const CreateDirectMatchDialog({super.key, required this.db});

  @override
  State<CreateDirectMatchDialog> createState() => _CreateDirectMatchDialogState();
}

class _CreateDirectMatchDialogState extends State<CreateDirectMatchDialog> {
  int _currentStep = 0;

  // Step 1: Match Details
  final _matchNameController = TextEditingController(text: 'Friendly Derby');
  final _venueController = TextEditingController(text: 'Eden Gardens');
  int _overs = 8;

  // Step 2: Two Teams
  final _teamANameController = TextEditingController(text: 'Royal Strikers');
  final _teamBNameController = TextEditingController(text: 'Super Giants');

  // Step 3: Squad & Playing XI
  List<Player> _teamAPlayers = [];
  List<Player> _teamBPlayers = [];
  String? _captainAId;
  String? _captainBId;
  String? _keeperAId;
  String? _keeperBId;

  // Step 4: Toss
  int _tossWinnerIndex = 0; // 0 for Team A, 1 for Team B
  String _tossDecision = 'bat'; // 'bat' or 'bowl'

  @override
  void initState() {
    super.initState();
    _populateDefaultDirectSquads();
  }

  void _populateDefaultDirectSquads() {
    // Pick existing registered players or seed quick roster
    final allRegistered = widget.db.players;
    if (allRegistered.length >= 4) {
      _teamAPlayers = allRegistered.take(allRegistered.length ~/ 2).toList();
      _teamBPlayers = allRegistered.skip(allRegistered.length ~/ 2).toList();
    } else {
      // Create quick initial players
      for (int i = 1; i <= 2; i++) {
        _teamAPlayers.add(widget.db.registerPermanentPlayer(
          fullName: 'Player A$i',
          mobileNumber: '983020100$i',
          role: i == 1 ? PlayerRole.batsman : PlayerRole.bowler,
        ));
        _teamBPlayers.add(widget.db.registerPermanentPlayer(
          fullName: 'Player B$i',
          mobileNumber: '983020200$i',
          role: i == 1 ? PlayerRole.batsman : PlayerRole.bowler,
        ));
      }
    }
    _captainAId = _teamAPlayers.firstOrNull?.id;
    _keeperAId = _teamAPlayers.skip(1).firstOrNull?.id;
    _captainBId = _teamBPlayers.firstOrNull?.id;
    _keeperBId = _teamBPlayers.skip(1).firstOrNull?.id;
  }

  void _addPlayerToTeam(bool isTeamA) {
    showDialog(
      context: context,
      builder: (ctx) => AddExistingPlayerDialog(
        teamId: isTeamA ? 'direct_team_a' : 'direct_team_b',
        tournamentId: 'standalone',
        onPlayerAdded: (player) {
          setState(() {
            if (isTeamA) {
              if (!_teamAPlayers.any((p) => p.id == player.id)) {
                _teamAPlayers.add(player);
                _captainAId ??= player.id;
              }
            } else {
              if (!_teamBPlayers.any((p) => p.id == player.id)) {
                _teamBPlayers.add(player);
                _captainBId ??= player.id;
              }
            }
          });
        },
      ),
    );
  }

  void _launchDirectMatch() {
    if (_teamAPlayers.isEmpty || _teamBPlayers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Both teams must have at least 1 player.')),
      );
      return;
    }

    final match = widget.db.createDirectMatch(
      matchName: _matchNameController.text.trim(),
      teamAName: _teamANameController.text.trim(),
      teamBName: _teamBNameController.text.trim(),
      overs: _overs,
      venue: _venueController.text.trim(),
      tossWonBy: _tossWinnerIndex == 0 ? 'team_direct_a' : 'team_direct_b',
      tossDecision: _tossDecision,
      playingXIA: _teamAPlayers.map((p) => p.id).toList(),
      playingXIB: _teamBPlayers.map((p) => p.id).toList(),
      captainAId: _captainAId,
      captainBId: _captainBId,
      keeperAId: _keeperAId,
      keeperBId: _keeperBId,
    );

    Navigator.of(context).pop();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScorerScreen(initialMatchId: match.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0x3300F5A0), width: 1.2),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D9F5).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.flash_on, color: Color(0xFF00D9F5), size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Direct 2-Team Match',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Standalone match with permanent scorecards & stats',
                          style: TextStyle(color: Colors.white60, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white60, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Step indicator
              Row(
                children: [
                  _buildStepPill(0, '1. Details'),
                  const SizedBox(width: 6),
                  _buildStepPill(1, '2. Lineups'),
                  const SizedBox(width: 6),
                  _buildStepPill(2, '3. Toss & Play'),
                ],
              ),
              const SizedBox(height: 14),

              Expanded(
                child: SingleChildScrollView(
                  child: _buildCurrentStepContent(),
                ),
              ),

              const SizedBox(height: 14),
              Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _currentStep--),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white38),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Back', style: TextStyle(color: Colors.white, fontSize: 13)),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentStep < 2) {
                          setState(() => _currentStep++);
                        } else {
                          _launchDirectMatch();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00F5A0),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        _currentStep < 2 ? 'Next: Lineups →' : 'Start Live Scoring ⚡',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepPill(int index, String label) {
    final isDone = _currentStep > index;
    final isCurrent = _currentStep == index;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: isCurrent
              ? const Color(0xFF00F5A0).withValues(alpha: 0.2)
              : (isDone ? const Color(0xFF009270).withValues(alpha: 0.2) : const Color(0xFF1E293B)),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isCurrent ? const Color(0xFF00F5A0) : (isDone ? const Color(0xFF009270) : Colors.white12),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isCurrent ? const Color(0xFF00F5A0) : (isDone ? Colors.white70 : Colors.white38),
              fontSize: 11,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Match Title & Location', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: _matchNameController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'e.g. Sunday Derby / Friendly Cup',
                filled: true,
                fillColor: Color(0xFF1E293B),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Venue / Ground', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: _venueController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'e.g. Eden Gardens, Kolkata',
                filled: true,
                fillColor: Color(0xFF1E293B),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            const Text('Match Format (Overs Per Innings)', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [5, 8, 10, 15, 20].map((ov) {
                final isSelected = _overs == ov;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: InkWell(
                      onTap: () => setState(() => _overs = ov),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF00F5A0) : const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isSelected ? const Color(0xFF00F5A0) : Colors.white24),
                        ),
                        child: Center(
                          child: Text(
                            '$ov Ov',
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('Competing Teams', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _teamANameController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: 'Team 1 Name',
                      labelStyle: TextStyle(color: Color(0xFF00F5A0), fontSize: 11),
                      filled: true,
                      fillColor: Color(0xFF1E293B),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('VS', style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                Expanded(
                  child: TextField(
                    controller: _teamBNameController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: 'Team 2 Name',
                      labelStyle: TextStyle(color: Color(0xFF00D9F5), fontSize: 11),
                      filled: true,
                      fillColor: Color(0xFF1E293B),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );

      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Team A Squad
            _buildTeamSquadSelector(
              teamTitle: _teamANameController.text,
              players: _teamAPlayers,
              captainId: _captainAId,
              keeperId: _keeperAId,
              isTeamA: true,
              themeColor: const Color(0xFF00F5A0),
            ),
            const SizedBox(height: 16),
            // Team B Squad
            _buildTeamSquadSelector(
              teamTitle: _teamBNameController.text,
              players: _teamBPlayers,
              captainId: _captainBId,
              keeperId: _keeperBId,
              isTeamA: false,
              themeColor: const Color(0xFF00D9F5),
            ),
          ],
        );

      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🪙 Toss Winner', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _tossWinnerIndex = 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _tossWinnerIndex == 0 ? const Color(0xFF00F5A0) : const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                _teamANameController.text,
                                style: TextStyle(
                                  color: _tossWinnerIndex == 0 ? Colors.black : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _tossWinnerIndex = 1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _tossWinnerIndex == 1 ? const Color(0xFF00D9F5) : const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                _teamBNameController.text,
                                style: TextStyle(
                                  color: _tossWinnerIndex == 1 ? Colors.black : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Elected Decision', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _tossDecision = 'bat'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _tossDecision == 'bat' ? Colors.white : const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '🏏 Elected to BAT',
                                style: TextStyle(
                                  color: _tossDecision == 'bat' ? Colors.black : Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _tossDecision = 'bowl'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _tossDecision == 'bowl' ? Colors.white : const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '⚾ Elected to BOWL',
                                style: TextStyle(
                                  color: _tossDecision == 'bowl' ? Colors.black : Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0x2200F5A0),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF00F5A0), width: 0.8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF00F5A0), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ready to begin live ball-by-ball scoring. All records are permanently saved to player profiles.',
                      style: TextStyle(color: Colors.white, fontSize: 11.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTeamSquadSelector({
    required String teamTitle,
    required List<Player> players,
    required String? captainId,
    required String? keeperId,
    required bool isTeamA,
    required Color themeColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: themeColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                teamTitle,
                style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(width: 8),
              Text(
                '(${players.length} players)',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _addPlayerToTeam(isTeamA),
                icon: const Icon(Icons.person_add, size: 13),
                label: const Text('Add by Mobile', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...players.map((p) {
            final isCap = p.id == captainId;
            final isWk = p.id == keeperId;
            return Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  CircleAvatar(radius: 12, backgroundImage: NetworkImage(p.photoUrl)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      p.fullName,
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        if (isTeamA) {
                          _captainAId = p.id;
                        } else {
                          _captainBId = p.id;
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isCap ? Colors.amberAccent : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.amberAccent, width: 0.8),
                      ),
                      child: Text(
                        'C',
                        style: TextStyle(
                          color: isCap ? Colors.black : Colors.amberAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () {
                      setState(() {
                        if (isTeamA) {
                          _keeperAId = p.id;
                        } else {
                          _keeperBId = p.id;
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isWk ? const Color(0xFF00D9F5) : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFF00D9F5), width: 0.8),
                      ),
                      child: Text(
                        'WK',
                        style: TextStyle(
                          color: isWk ? Colors.black : const Color(0xFF00D9F5),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
