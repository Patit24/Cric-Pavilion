import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/mock_database.dart';
import '../../widgets/add_existing_player_dialog.dart';
import '../../widgets/auth_modal_dialog.dart';
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

  // Step 4: Toss & Crease
  int _tossWinnerIndex = 0; // 0 for Team A, 1 for Team B
  String _tossDecision = 'bat'; // 'bat' or 'bowl'
  String? _directStrikerId;
  String? _directNonStrikerId;
  String? _directBowlerId;

  @override
  void initState() {
    super.initState();
    _populateDefaultDirectSquads();
  }

  void _populateDefaultDirectSquads() {
    _teamAPlayers = [];
    _teamBPlayers = [];
    _captainAId = null;
    _keeperAId = null;
    _captainBId = null;
    _keeperBId = null;
    _directStrikerId = null;
    _directNonStrikerId = null;
    _directBowlerId = null;
  }

  void _addPlayerToTeam(bool isTeamA) {
    final nameCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
    PlayerRole role = PlayerRole.allRounder;
    String? localError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0x3300F5A0), width: 1.2),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF00F5A0).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.person_add, color: Color(0xFF00F5A0), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Add Player to ${isTeamA ? _teamANameController.text : _teamBNameController.text}',
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (localError != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                    ),
                    child: Text(localError!, style: const TextStyle(color: Colors.redAccent, fontSize: 11)),
                  ),
                ],
                const Text('Player Full Name *', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    hintText: 'e.g. Virat Sharma',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white24)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white24)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF00F5A0))),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Role', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<PlayerRole>(
                      value: role,
                      dropdownColor: const Color(0xFF1E293B),
                      isExpanded: true,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      items: const [
                        DropdownMenuItem(value: PlayerRole.batsman, child: Text('Batter')),
                        DropdownMenuItem(value: PlayerRole.bowler, child: Text('Bowler')),
                        DropdownMenuItem(value: PlayerRole.allRounder, child: Text('All-Rounder')),
                        DropdownMenuItem(value: PlayerRole.wicketKeeper, child: Text('Wicketkeeper')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => role = val);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Mobile Number (Optional)', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: mobileCtrl,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    hintText: '10 digits or leave blank',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white24)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white24)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF00F5A0))),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _showAddByLookupDialog(isTeamA);
                    },
                    icon: const Icon(Icons.search, size: 14, color: Color(0xFF00D9F5)),
                    label: const Text('Lookup Existing Registered Player', style: TextStyle(color: Color(0xFF00D9F5), fontSize: 11)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) {
                  setDialogState(() => localError = 'Please enter player name');
                  return;
                }
                final rawMob = mobileCtrl.text.trim();
                String normMob = MockDatabase.normalizeMobile(rawMob);
                if (rawMob.isNotEmpty && normMob.length < 10) {
                  setDialogState(() => localError = 'Enter a valid 10-digit number or leave blank');
                  return;
                }
                if (normMob.isEmpty) {
                  normMob = '983${DateTime.now().millisecondsSinceEpoch % 10000000}'.padRight(10, '0');
                }

                // Check if already registered or register
                Player player;
                final existing = widget.db.players.where((x) => x.mobileNumber == normMob).firstOrNull;
                if (existing != null) {
                  player = existing;
                } else {
                  player = widget.db.registerPermanentPlayer(
                    fullName: name,
                    mobileNumber: normMob,
                    role: role,
                  );
                }

                setState(() {
                  final targetList = isTeamA ? _teamAPlayers : _teamBPlayers;
                  if (!targetList.any((p) => p.id == player.id)) {
                    targetList.add(player);
                    if (isTeamA) {
                      _captainAId ??= player.id;
                    } else {
                      _captainBId ??= player.id;
                    }
                  }
                });

                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Added ${player.fullName} to squad'),
                    backgroundColor: const Color(0xFF009270),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00F5A0),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Add to Squad', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddByLookupDialog(bool isTeamA) {
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

  void _editPlayer(Player p, bool isTeamA) {
    final nameController = TextEditingController(text: p.fullName);
    PlayerRole selectedRole = p.role;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0x3300F5A0), width: 1.2),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF00F5A0).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.edit, color: Color(0xFF00F5A0), size: 18),
              ),
              const SizedBox(width: 10),
              const Text('Edit Player', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Player Full Name *', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: nameController,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  hintText: 'Enter player name',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white24)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white24)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF00F5A0))),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Role', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<PlayerRole>(
                    value: selectedRole,
                    dropdownColor: const Color(0xFF1E293B),
                    isExpanded: true,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    items: const [
                      DropdownMenuItem(value: PlayerRole.batsman, child: Text('Batter')),
                      DropdownMenuItem(value: PlayerRole.bowler, child: Text('Bowler')),
                      DropdownMenuItem(value: PlayerRole.allRounder, child: Text('All-Rounder')),
                      DropdownMenuItem(value: PlayerRole.wicketKeeper, child: Text('Wicketkeeper')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedRole = val);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              onPressed: () {
                final newName = nameController.text.trim();
                if (newName.isNotEmpty) {
                  widget.db.updatePlayer(
                    playerId: p.id,
                    fullName: newName,
                    mobileNumber: p.mobileNumber,
                    role: selectedRole,
                  );
                  setState(() {
                    final targetList = isTeamA ? _teamAPlayers : _teamBPlayers;
                    final idx = targetList.indexWhere((x) => x.id == p.id);
                    if (idx != -1) {
                      targetList[idx] = Player(
                        id: p.id,
                        permanentPlayerCode: p.permanentPlayerCode,
                        tournamentId: p.tournamentId,
                        fullName: newName,
                        displayName: newName,
                        mobileNumber: p.mobileNumber,
                        age: p.age,
                        dateOfBirth: p.dateOfBirth,
                        city: p.city,
                        role: selectedRole,
                        battingStyle: p.battingStyle,
                        bowlingStyle: p.bowlingStyle,
                        experienceYears: p.experienceYears,
                        category: selectedRole == PlayerRole.batsman
                            ? 'Batsman'
                            : selectedRole == PlayerRole.bowler
                                ? 'Bowler'
                                : selectedRole == PlayerRole.allRounder
                                    ? 'All-Rounder'
                                    : 'Wicketkeeper',
                        basePrice: p.basePrice,
                        photoUrl: p.photoUrl,
                        teamId: p.teamId,
                        runs: p.runs,
                        wickets: p.wickets,
                        matches: p.matches,
                      );
                    }
                  });
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Player updated to "$newName"'),
                      backgroundColor: const Color(0xFF009270),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00F5A0),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _deletePlayer(Player p, bool isTeamA) {
    setState(() {
      if (isTeamA) {
        _teamAPlayers.removeWhere((x) => x.id == p.id);
        if (_captainAId == p.id) {
          _captainAId = _teamAPlayers.firstOrNull?.id;
        }
        if (_keeperAId == p.id) {
          _keeperAId = _teamAPlayers.skip(1).firstOrNull?.id;
        }
      } else {
        _teamBPlayers.removeWhere((x) => x.id == p.id);
        if (_captainBId == p.id) {
          _captainBId = _teamBPlayers.firstOrNull?.id;
        }
        if (_keeperBId == p.id) {
          _keeperBId = _teamBPlayers.skip(1).firstOrNull?.id;
        }
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed ${p.fullName} from squad'),
        backgroundColor: Colors.redAccent.shade700,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _launchDirectMatch() {
    if (!widget.db.isAuthenticated) {
      showDialog(
        context: context,
        builder: (ctx) => AuthModalDialog(
          initialActionPrompt: 'Login Required: Please sign in or register to create and score friendly matches.',
          onAuthSuccess: () {
            setState(() {});
          },
        ),
      );
      return;
    }

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
      strikerId: _directStrikerId,
      nonStrikerId: _directNonStrikerId,
      bowlerId: _directBowlerId,
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

              if (!widget.db.isAuthenticated) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_outline, color: Colors.amber, size: 16),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Login Required: You must be logged in to create and score matches.',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AuthModalDialog(
                              initialActionPrompt: 'Login Required: Please sign in or register to score friendly matches.',
                              onAuthSuccess: () => setState(() {}),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00F5A0),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Log In', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                    ],
                  ),
                ),
              ],

              // Step indicator
              Row(
                children: [
                  _buildStepPill(0, '1. Details'),
                  const SizedBox(width: 6),
                  _buildStepPill(1, '2. Lineups'),
                  const SizedBox(width: 6),
                  _buildStepPill(2, '3. Toss & Crease'),
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
                        if (!widget.db.isAuthenticated) {
                          showDialog(
                            context: context,
                            builder: (ctx) => AuthModalDialog(
                              initialActionPrompt: 'Login Required: Please sign in or register to score friendly matches.',
                              onAuthSuccess: () => setState(() {}),
                            ),
                          );
                          return;
                        }

                        if (_currentStep < 2) {
                          setState(() => _currentStep++);
                        } else {
                          final isTeamABatting = (_tossWinnerIndex == 0 && _tossDecision == 'bat') ||
                              (_tossWinnerIndex == 1 && _tossDecision == 'bowl');
                          final battingPlayers = isTeamABatting ? _teamAPlayers : _teamBPlayers;
                          if (battingPlayers.length > 1 && _directStrikerId == _directNonStrikerId) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Striker and Non-Striker must be two different players.')),
                            );
                            return;
                          }
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
                        _currentStep == 0
                            ? 'Next: Lineups →'
                            : _currentStep == 1
                                ? 'Next: Toss & Crease →'
                                : 'Start Live Scoring ⚡',
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
              isTeamA: true,
              themeColor: const Color(0xFF00F5A0),
            ),
            const SizedBox(height: 16),
            // Team B Squad
            _buildTeamSquadSelector(
              teamTitle: _teamBNameController.text,
              players: _teamBPlayers,
              isTeamA: false,
              themeColor: const Color(0xFF00D9F5),
            ),
          ],
        );

      case 2:
        final bool isTeamABatting = (_tossWinnerIndex == 0 && _tossDecision == 'bat') ||
            (_tossWinnerIndex == 1 && _tossDecision == 'bowl');
        final battingTeamName = isTeamABatting ? _teamANameController.text : _teamBNameController.text;
        final bowlingTeamName = isTeamABatting ? _teamBNameController.text : _teamANameController.text;
        final battingPlayers = isTeamABatting ? _teamAPlayers : _teamBPlayers;
        final bowlingPlayers = isTeamABatting ? _teamBPlayers : _teamAPlayers;

        if (_directStrikerId == null || !battingPlayers.any((p) => p.id == _directStrikerId)) {
          _directStrikerId = battingPlayers.firstOrNull?.id;
        }
        if (_directNonStrikerId == null || !battingPlayers.any((p) => p.id == _directNonStrikerId)) {
          _directNonStrikerId = battingPlayers.length > 1 ? battingPlayers[1].id : battingPlayers.firstOrNull?.id;
        }
        if (_directBowlerId == null || !bowlingPlayers.any((p) => p.id == _directBowlerId)) {
          _directBowlerId = bowlingPlayers.where((p) => p.role == PlayerRole.bowler).firstOrNull?.id ??
              (bowlingPlayers.isNotEmpty ? bowlingPlayers.first.id : (battingPlayers.isNotEmpty ? battingPlayers.first.id : null));
        }

        final isSameBatter = _directStrikerId != null &&
            _directNonStrikerId != null &&
            _directStrikerId == _directNonStrikerId &&
            battingPlayers.length > 1;

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
                          onTap: () => setState(() {
                            _tossWinnerIndex = 0;
                            _directStrikerId = null;
                            _directNonStrikerId = null;
                            _directBowlerId = null;
                          }),
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
                          onTap: () => setState(() {
                            _tossWinnerIndex = 1;
                            _directStrikerId = null;
                            _directNonStrikerId = null;
                            _directBowlerId = null;
                          }),
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
                          onTap: () => setState(() {
                            _tossDecision = 'bat';
                            _directStrikerId = null;
                            _directNonStrikerId = null;
                            _directBowlerId = null;
                          }),
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
                          onTap: () => setState(() {
                            _tossDecision = 'bowl';
                            _directStrikerId = null;
                            _directNonStrikerId = null;
                            _directBowlerId = null;
                          }),
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

            // Opening Crease Lineup (Innings 1)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0x6600F5A0), width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.sports_cricket, color: Color(0xFF00F5A0), size: 18),
                      const SizedBox(width: 8),
                      const Text(
                        'Select Crease Lineup (Innings 1)',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0x3300F5A0),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Bat: $battingTeamName',
                          style: const TextStyle(color: Color(0xFF00F5A0), fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 1. Striker Dropdown
                  const Text('1. Opening Striker (* Facing Ball 0.1):', style: TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: _directStrikerId,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF0F172A),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white24)),
                    ),
                    items: battingPlayers.map((p) {
                      final pName = p.fullName.isNotEmpty ? p.fullName : p.displayName;
                      return DropdownMenuItem(value: p.id, child: Text(pName, overflow: TextOverflow.ellipsis));
                    }).toList(),
                    onChanged: (val) => setState(() => _directStrikerId = val),
                  ),
                  const SizedBox(height: 10),

                  // 2. Non-Striker Dropdown
                  const Text('2. Opening Non-Striker (Runner at Crease):', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: _directNonStrikerId,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF0F172A),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white24)),
                    ),
                    items: battingPlayers.map((p) {
                      final pName = p.fullName.isNotEmpty ? p.fullName : p.displayName;
                      return DropdownMenuItem(value: p.id, child: Text(pName, overflow: TextOverflow.ellipsis));
                    }).toList(),
                    onChanged: (val) => setState(() => _directNonStrikerId = val),
                  ),
                  const SizedBox(height: 10),

                  if (isSameBatter) ...[
                    const Text('⚠️ Striker & Non-Striker must be different players.', style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                  ],

                  // 3. Bowler Dropdown
                  Text('3. Opening Bowler (Over 1 for $bowlingTeamName):', style: const TextStyle(color: Color(0xFF00D9F5), fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: _directBowlerId,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF0F172A),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white24)),
                    ),
                    items: bowlingPlayers.map((p) {
                      final pName = p.fullName.isNotEmpty ? p.fullName : p.displayName;
                      return DropdownMenuItem(value: p.id, child: Text(pName, overflow: TextOverflow.ellipsis));
                    }).toList(),
                    onChanged: (val) => setState(() => _directBowlerId = val),
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
                label: const Text('+ Add Player', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
          if (players.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              alignment: Alignment.center,
              child: const Text(
                'No players in squad. Tap "+ Add Player" to add.',
                style: TextStyle(color: Colors.white38, fontSize: 11, fontStyle: FontStyle.italic),
              ),
            )
          else
            ...players.map((p) {
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 13,
                      backgroundImage: NetworkImage(p.photoUrl),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.fullName,
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            p.roleString,
                            style: const TextStyle(color: Colors.white54, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    // Edit Player Action
                    Tooltip(
                      message: 'Edit player name',
                      child: InkWell(
                        onTap: () => _editPlayer(p, isTeamA),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.white24, width: 0.8),
                          ),
                          child: const Icon(Icons.edit_outlined, color: Colors.white70, size: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Delete Player Action
                    Tooltip(
                      message: 'Delete player from squad',
                      child: InkWell(
                        onTap: () => _deletePlayer(p, isTeamA),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5), width: 0.8),
                          ),
                          child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 14),
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
