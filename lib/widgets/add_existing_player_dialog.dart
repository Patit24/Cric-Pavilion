import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/mock_database.dart';
import '../screens/players/player_profile_screen.dart';

class AddExistingPlayerDialog extends StatefulWidget {
  final String teamId;
  final String? tournamentId;
  final String? matchId;
  final bool isPlayingXIContext;
  final Function(Player player)? onPlayerAdded;

  const AddExistingPlayerDialog({
    super.key,
    required this.teamId,
    this.tournamentId,
    this.matchId,
    this.isPlayingXIContext = false,
    this.onPlayerAdded,
  });

  @override
  State<AddExistingPlayerDialog> createState() => _AddExistingPlayerDialogState();
}

class _AddExistingPlayerDialogState extends State<AddExistingPlayerDialog> {
  final _mobileController = TextEditingController();
  final _nameController = TextEditingController();
  PlayerRole _selectedRole = PlayerRole.allRounder;
  String _battingStyle = 'Right Hand Bat';
  String _bowlingStyle = 'Right Arm Medium';
  bool _showAdvancedStyles = false;

  bool _isSearching = false;
  PlayerLookupResult? _lookupResult;
  String? _statusMessage;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _mobileController.addListener(_onMobileChanged);
  }

  @override
  void dispose() {
    _mobileController.removeListener(_onMobileChanged);
    _mobileController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _onMobileChanged() {
    final norm = MockDatabase.normalizeMobile(_mobileController.text.trim());

    if (norm.length == 10) {
      _performLookup(norm);
    } else {
      if (_lookupResult != null) {
        setState(() {
          _lookupResult = null;
          _statusMessage = null;
          _isError = false;
        });
      }
    }
  }

  void _performLookup(String normMobile) {
    final db = Provider.of<MockDatabase>(context, listen: false);
    setState(() {
      _isSearching = true;
      _statusMessage = null;
      _isError = false;
    });

    final result = db.lookupPlayerByMobile(
      normMobile,
      targetTeamId: widget.teamId,
      targetTournamentId: widget.tournamentId,
    );

    setState(() {
      _isSearching = false;
      _lookupResult = result;
      if (result.isFound && result.player != null) {
        // Pre-fill registered player details if name is empty
        if (_nameController.text.trim().isEmpty) {
          _nameController.text = result.player!.fullName;
        }
        _selectedRole = result.player!.role;
        _battingStyle = result.player!.battingStyle;
        _bowlingStyle = result.player!.bowlingStyle;
      }
    });
  }

  void _addOrRegisterPlayer() {
    final name = _nameController.text.trim();
    final rawMobile = _mobileController.text.trim();
    final db = Provider.of<MockDatabase>(context, listen: false);
    final normMobile = MockDatabase.normalizeMobile(rawMobile);

    if (name.isEmpty) {
      setState(() {
        _statusMessage = 'Please enter player full name';
        _isError = true;
      });
      return;
    }

    if (normMobile.length < 10) {
      setState(() {
        _statusMessage = 'Please enter a valid 10-digit mobile number';
        _isError = true;
      });
      return;
    }

    // 1. If player is already registered in permanent database
    if (_lookupResult?.isFound == true && _lookupResult!.player != null) {
      final player = _lookupResult!.player!;

      if (_lookupResult!.isAlreadyInTeam) {
        setState(() {
          _statusMessage = '${player.fullName} is already a member of this squad.';
          _isError = true;
        });
        return;
      }

      if (_lookupResult!.hasTournamentConflict) {
        setState(() {
          _statusMessage = '${player.fullName} is already registered with ${_lookupResult!.conflictingTeamName} in this tournament.';
          _isError = true;
        });
        return;
      }

      final res = db.addPlayerToTeamByMobile(
        teamId: widget.teamId,
        mobileNumber: player.mobileNumber,
        tournamentId: widget.tournamentId,
      );

      if (res['success'] == true) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.of(context).pop();
        widget.onPlayerAdded?.call(player);
        messenger.showSnackBar(
          SnackBar(
            content: Text('✅ Existing player ${player.fullName} (${player.permanentPlayerCode}) added to squad!'),
            backgroundColor: const Color(0xFF009270),
          ),
        );
      } else {
        setState(() {
          _statusMessage = res['message'];
          _isError = true;
        });
      }
      return;
    }

    // 2. If player is not registered -> Automatically register in database
    final newPlayer = db.registerPermanentPlayer(
      fullName: name,
      mobileNumber: normMobile,
      role: _selectedRole,
      battingStyle: _battingStyle,
      bowlingStyle: _bowlingStyle,
      teamId: widget.teamId,
      tournamentId: widget.tournamentId,
    );

    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    widget.onPlayerAdded?.call(newPlayer);
    messenger.showSnackBar(
      SnackBar(
        content: Text('✅ Automatically registered & added ${newPlayer.fullName} (${newPlayer.permanentPlayerCode}) to squad!'),
        backgroundColor: const Color(0xFF009270),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final normMobile = MockDatabase.normalizeMobile(_mobileController.text.trim());
    final is10Digits = normMobile.length == 10;
    final isExistingPlayer = _lookupResult?.isFound == true && _lookupResult?.player != null;
    final player = _lookupResult?.player;

    return Dialog(
      backgroundColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isExistingPlayer ? const Color(0xFF00F5A0) : const Color(0x3300F5A0),
          width: 1.4,
        ),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00F5A0).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isExistingPlayer ? Icons.verified_user : Icons.person_add_alt_1,
                      color: const Color(0xFF00F5A0),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isPlayingXIContext ? 'Add Player to Playing XI' : 'Add Player to Squad',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const Text(
                          'Direct input: Auto-links registered or registers new',
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
              const SizedBox(height: 16),

              // 1. Player Full Name Input
              const Text(
                'Player Full Name *',
                style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'e.g. Virat Sharma',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                  prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF00F5A0), size: 18),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF00F5A0), width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 2. Player Mobile Number Input (10 Digits)
              const Text(
                'Player Mobile Number (10 Digits) *',
                style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Text('+91', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _mobileController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'e.g. 9830112233',
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                        filled: true,
                        fillColor: const Color(0xFF1E293B),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.horizontal(right: Radius.circular(10)),
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                        enabledBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.horizontal(right: Radius.circular(10)),
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.horizontal(right: Radius.circular(10)),
                          borderSide: BorderSide(color: Color(0xFF00F5A0), width: 1.5),
                        ),
                        suffixIcon: _isSearching
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00F5A0))),
                              )
                            : (isExistingPlayer
                                ? const Icon(Icons.check_circle, color: Color(0xFF00F5A0), size: 18)
                                : null),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 3. Playing Role Selection
              const Text(
                'Playing Role',
                style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: PlayerRole.values.map((role) {
                  final isSelected = _selectedRole == role;
                  return ChoiceChip(
                    label: Text(
                      role.name.toUpperCase(),
                      style: TextStyle(
                        color: isSelected ? Colors.black : Colors.white70,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 11,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFF00F5A0),
                    backgroundColor: const Color(0xFF1E293B),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF00F5A0) : Colors.white24,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _selectedRole = role);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),

              // 4. Advanced Batting & Bowling Styles (Collapsible)
              InkWell(
                onTap: () => setState(() => _showAdvancedStyles = !_showAdvancedStyles),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        _showAdvancedStyles ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: const Color(0xFF00F5A0),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _showAdvancedStyles ? 'Hide batting & bowling style' : 'More options: Batting & bowling style',
                          style: const TextStyle(color: Color(0xFF00F5A0), fontSize: 11.5, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_showAdvancedStyles) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _battingStyle,
                        dropdownColor: const Color(0xFF0F172A),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        decoration: const InputDecoration(
                          labelText: 'Batting',
                          labelStyle: TextStyle(color: Colors.white70, fontSize: 11),
                          filled: true,
                          fillColor: Color(0xFF1E293B),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Right Hand Bat', child: Text('Right Hand')),
                          DropdownMenuItem(value: 'Left Hand Bat', child: Text('Left Hand')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _battingStyle = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _bowlingStyle,
                        dropdownColor: const Color(0xFF0F172A),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        decoration: const InputDecoration(
                          labelText: 'Bowling',
                          labelStyle: TextStyle(color: Colors.white70, fontSize: 11),
                          filled: true,
                          fillColor: Color(0xFF1E293B),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Right Arm Medium', child: Text('Right Medium')),
                          DropdownMenuItem(value: 'Right Arm Fast', child: Text('Right Fast')),
                          DropdownMenuItem(value: 'Right Arm Spin', child: Text('Right Spin')),
                          DropdownMenuItem(value: 'Left Arm Medium', child: Text('Left Medium')),
                          DropdownMenuItem(value: 'Left Arm Fast', child: Text('Left Fast')),
                          DropdownMenuItem(value: 'Left Arm Spin', child: Text('Left Spin')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _bowlingStyle = val);
                        },
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),

              // 5. Dynamic Detection Card: Existing vs New Player
              if (isExistingPlayer && player != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF00F5A0), width: 1.2),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF00F5A0).withValues(alpha: 0.1), blurRadius: 8),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00F5A0).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified, color: Color(0xFF00F5A0), size: 12),
                                SizedBox(width: 4),
                                Text(
                                  'REGISTERED IN DATABASE',
                                  style: TextStyle(color: Color(0xFF00F5A0), fontWeight: FontWeight.bold, fontSize: 9.5),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            player.permanentPlayerCode,
                            style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: NetworkImage(player.photoUrl),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  player.fullName,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Text(
                                  '${player.roleString} • ${player.battingStyle}',
                                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PlayerProfileScreen(playerId: player.id),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white24),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            child: const Text('Stats', style: TextStyle(color: Colors.white, fontSize: 11)),
                          ),
                        ],
                      ),
                      if (_lookupResult!.isAlreadyInTeam) ...[
                        const SizedBox(height: 6),
                        const Text(
                          '⚠️ Already a member of this squad.',
                          style: TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ] else if (_lookupResult!.hasTournamentConflict) ...[
                        const SizedBox(height: 6),
                        Text(
                          '⚠️ Registered with ${_lookupResult!.conflictingTeamName} in this tournament.',
                          style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ] else if (is10Digits && _lookupResult?.isFound == false) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF38BDF8), width: 0.8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.person_add, color: Color(0xFF38BDF8), size: 18),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'New Player: Auto-Registration',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            Text(
                              'Not registered yet. Adding will automatically create permanent database record with unique ID.',
                              style: TextStyle(color: Colors.white70, fontSize: 10.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Error or Status message banner
              if (_statusMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _isError ? const Color(0x33EF4444) : const Color(0x2238BDF8),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _isError ? Colors.redAccent : Colors.lightBlueAccent, width: 0.8),
                  ),
                  child: Row(
                    children: [
                      Icon(_isError ? Icons.error_outline : Icons.info_outline, color: _isError ? Colors.redAccent : Colors.lightBlueAccent, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _statusMessage!,
                          style: TextStyle(color: _isError ? Colors.redAccent : Colors.lightBlueAccent, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),

              // 6. Primary Action Button
              ElevatedButton.icon(
                onPressed: (_lookupResult?.isAlreadyInTeam == true || _lookupResult?.hasTournamentConflict == true)
                    ? null
                    : _addOrRegisterPlayer,
                icon: Icon(isExistingPlayer ? Icons.person_add_alt_1 : Icons.how_to_reg, size: 18),
                label: Text(
                  isExistingPlayer
                      ? (widget.isPlayingXIContext ? 'Add Existing to Playing XI' : 'Add Existing Player to Squad')
                      : (widget.isPlayingXIContext ? 'Auto-Register & Add to Playing XI' : 'Auto-Register & Add to Squad'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00F5A0),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 2,
                ),
              ),
              const SizedBox(height: 14),

              // 7. Player Login & Match Summary Explanation Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFF00F5A0), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '📱 Once this match is scored, the player can log into Cricpavilion using their mobile number (+91 ${_mobileController.text.trim().isNotEmpty ? _mobileController.text.trim() : "XXXXXXXXXX"}) or Google to watch match results, full scorecards, and track their personal career stats.',
                        style: const TextStyle(color: Colors.white60, fontSize: 10.5, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
