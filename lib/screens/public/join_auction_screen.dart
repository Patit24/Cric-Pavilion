import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/mock_database.dart';
import '../../theme/neo_glass_theme.dart';
import '../../widgets/auth_modal_dialog.dart';
import '../auction/auction_screen.dart';

class JoinAuctionScreen extends StatefulWidget {
  final String? prefilledAuctionId;
  final VoidCallback? onBackToHome;

  const JoinAuctionScreen({
    super.key,
    this.prefilledAuctionId,
    this.onBackToHome,
  });

  @override
  State<JoinAuctionScreen> createState() => _JoinAuctionScreenState();
}

class _JoinAuctionScreenState extends State<JoinAuctionScreen> {
  final _idController = TextEditingController();
  final _pinController = TextEditingController();
  bool _obscurePin = true;

  // Step state: 1 = Enter ID & PIN, 2 = Team Details
  int _step = 1;
  Auction? _validatedAuction;
  Tournament? _validatedTournament;
  String? _errorMessage;
  bool _isValidating = false;

  // Team Registration Form
  final _teamNameController = TextEditingController();
  final _teamShortCodeController = TextEditingController();
  Color _selectedTeamColor = const Color(0xFF00F5A0);
  final _logoUrlController = TextEditingController(
    text: 'https://images.unsplash.com/photo-1589487391730-58f20eb2c308?w=120',
  );
  bool _isSubmitting = false;
  Map<String, dynamic>? _registrationResult;

  final List<Color> _presetColors = [
    const Color(0xFF00F5A0), // Neon Emerald
    const Color(0xFF00D9F5), // Neon Cyan
    const Color(0xFFFBBF24), // Amber
    const Color(0xFFF43F5E), // Rose
    const Color(0xFF8B5CF6), // Violet
    const Color(0xFF38BDF8), // Sky Blue
    const Color(0xFFEC4899), // Pink
    const Color(0xFF10B981), // Emerald
  ];

  @override
  void initState() {
    super.initState();
    if (widget.prefilledAuctionId != null && widget.prefilledAuctionId!.isNotEmpty) {
      _idController.text = widget.prefilledAuctionId!;
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _pinController.dispose();
    _teamNameController.dispose();
    _teamShortCodeController.dispose();
    _logoUrlController.dispose();
    super.dispose();
  }

  void _validateCredentials(MockDatabase db) {
    final idOrCode = _idController.text.trim();
    final pin = _pinController.text.trim();

    if (idOrCode.isEmpty) {
      setState(() => _errorMessage = 'Please enter an Auction ID or Code.');
      return;
    }
    if (pin.isEmpty) {
      setState(() => _errorMessage = 'Please enter the 6-digit Auction PIN.');
      return;
    }

    setState(() {
      _isValidating = true;
      _errorMessage = null;
    });

    final result = db.validateAuctionJoinCredentials(
      auctionIdOrCode: idOrCode,
      auctionPin: pin,
    );

    setState(() => _isValidating = false);

    if (!result.isValid) {
      setState(() => _errorMessage = result.errorMessage ?? 'Invalid credentials.');
      return;
    }

    setState(() {
      _validatedAuction = result.auction;
      _validatedTournament = result.tournament;
      _step = 2;
    });
  }

  void _submitTeamRegistration(MockDatabase db) {
    if (!db.isAuthenticated) {
      // Must authenticate first, preserving Auction ID & PIN
      showDialog(
        context: context,
        builder: (ctx) => AuthModalDialog(
          initialActionPrompt: 'Sign in to register your team for "${_validatedAuction?.title}"',
          onAuthSuccess: () {
            setState(() {});
          },
        ),
      );
      return;
    }

    final teamName = _teamNameController.text.trim();
    final shortCode = _teamShortCodeController.text.trim();

    if (teamName.isEmpty) {
      setState(() => _errorMessage = 'Team name is required.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final res = db.submitTeamOwnerRegistration(
      auctionId: _validatedAuction!.id,
      teamName: teamName,
      teamShortName: shortCode.isNotEmpty ? shortCode : (teamName.length >= 3 ? teamName.substring(0, 3) : teamName),
      primaryColor: _selectedTeamColor,
      logoUrl: _logoUrlController.text.trim(),
    );

    setState(() {
      _isSubmitting = false;
      _registrationResult = res;
    });

    if (res['success'] != true) {
      setState(() => _errorMessage = res['error'] as String? ?? 'Registration failed.');
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = context.watch<MockDatabase>();

    return Scaffold(
      backgroundColor: NeoGlassTheme.bgCanvas,
      appBar: AppBar(
        backgroundColor: const Color(0xCC0B1120),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () {
            if (_step == 2 && _registrationResult == null) {
              setState(() => _step = 1);
            } else if (widget.onBackToHome != null) {
              widget.onBackToHome!();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          'Join Auction by PIN',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_registrationResult != null && _registrationResult!['success'] == true)
                    _buildSuccessState(db)
                  else if (_step == 1)
                    _buildStep1CredentialsForm(db)
                  else
                    _buildStep2TeamForm(db),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // STEP 1: ENTER AUCTION ID & PIN
  // =========================================================================
  Widget _buildStep1CredentialsForm(MockDatabase db) {
    return NeoGlassCard(
      glowColor: NeoGlassTheme.neonEmerald,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: NeoGlassTheme.neonEmerald.withValues(alpha: 0.16),
                shape: BoxShape.circle,
                border: Border.all(color: NeoGlassTheme.neonEmerald.withValues(alpha: 0.5), width: 1.5),
              ),
              child: const Icon(Icons.key, color: NeoGlassTheme.neonEmerald, size: 32),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Team Owner Self-Service Entry',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'Enter the Auction ID and 6-digit PIN provided by your tournament organizer to register your franchise and bid live.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 20),

          // Error Message
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0x33EF4444),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0x88EF4444)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, size: 16, color: Color(0xFFF87171)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Color(0xFFF87171), fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Auction ID
          const Text('AUCTION ID OR CODE *', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextField(
            controller: _idController,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            decoration: NeoGlassTheme.inputDecoration(
              hintText: 'e.g. BPL2026-7842 or auc_bpl_2026',
              prefixIcon: Icons.fingerprint,
            ),
          ),
          const SizedBox(height: 14),

          // Auction PIN
          const Text('6-DIGIT AUCTION PIN *', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextField(
            controller: _pinController,
            obscureText: _obscurePin,
            keyboardType: TextInputType.number,
            maxLength: 6,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 3),
            decoration: NeoGlassTheme.inputDecoration(
              hintText: '••••••',
              prefixIcon: Icons.lock_outline,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePin ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white54,
                  size: 18,
                ),
                onPressed: () => setState(() => _obscurePin = !_obscurePin),
              ),
            ),
          ),
          const SizedBox(height: 18),

          NeoGlassButton(
            onPressed: _isValidating ? null : () => _validateCredentials(db),
            gradient: NeoGlassTheme.neonGradient,
            icon: Icons.verified_user,
            child: Text(
              _isValidating ? 'Verifying Credentials...' : 'Verify & Continue →',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
            ),
          ),
          const SizedBox(height: 16),

          // Quick Demo Code helper
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0x330F172A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ACTIVE TOURNAMENT CODES FOR INSTANT TESTING:',
                  style: TextStyle(color: Colors.white54, fontSize: 9.5, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _idController.text = 'BPL2026-7842';
                            _pinController.text = '583921';
                            _errorMessage = null;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: NeoGlassTheme.neonEmerald.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: NeoGlassTheme.neonEmerald.withValues(alpha: 0.4)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('BPL 2026 Mega Auction', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              Text('ID: BPL2026-7842 • PIN: 583921', style: TextStyle(color: NeoGlassTheme.neonEmerald, fontSize: 10)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _idController.text = 'PSL2026-3490';
                            _pinController.text = '123456';
                            _errorMessage = null;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: NeoGlassTheme.neonCyan.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: NeoGlassTheme.neonCyan.withValues(alpha: 0.4)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('PSL 2026 Draft', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              Text('ID: PSL2026-3490 • PIN: 123456', style: TextStyle(color: NeoGlassTheme.neonCyan, fontSize: 10)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // STEP 2: TEAM REGISTRATION FORM
  // =========================================================================
  Widget _buildStep2TeamForm(MockDatabase db) {
    final auc = _validatedAuction!;
    final tourn = _validatedTournament;
    final isAuth = db.isAuthenticated;

    return NeoGlassCard(
      glowColor: NeoGlassTheme.neonCyan,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: NeoGlassTheme.neonCyan.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: NeoGlassTheme.neonCyan.withValues(alpha: 0.5)),
                ),
                child: const Icon(Icons.business_center, color: NeoGlassTheme.neonCyan, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      auc.title,
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${tourn?.name ?? "Tournament"} • Mode: ${auc.joiningMode.label}',
                      style: const TextStyle(color: NeoGlassTheme.neonCyan, fontSize: 10.5, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // User Auth Status Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isAuth ? const Color(0x3310B981) : const Color(0x33F59E0B),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isAuth ? NeoGlassTheme.neonEmerald : Colors.amberAccent),
            ),
            child: Row(
              children: [
                Icon(
                  isAuth ? Icons.verified : Icons.account_circle_outlined,
                  size: 16,
                  color: isAuth ? NeoGlassTheme.neonEmerald : Colors.amberAccent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isAuth
                        ? 'Authenticated as: ${db.currentUser!.fullName} (${db.currentUser!.email})'
                        : 'Sign in required to link this team to your account.',
                    style: TextStyle(
                      color: isAuth ? Colors.white : Colors.amberAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (!isAuth)
                  TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AuthModalDialog(
                          onAuthSuccess: () => setState(() {}),
                        ),
                      );
                    },
                    child: const Text('Sign In', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Error Message
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0x33EF4444),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0x88EF4444)),
              ),
              child: Text(_errorMessage!, style: const TextStyle(color: Color(0xFFF87171), fontSize: 11, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
          ],

          // Team Name Input
          const Text('FRANCHISE / TEAM NAME *', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextField(
            controller: _teamNameController,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            decoration: NeoGlassTheme.inputDecoration(
              hintText: 'e.g. Royal Challengers Barasat',
              prefixIcon: Icons.groups,
            ),
          ),
          const SizedBox(height: 12),

          // Short Code Input
          const Text('TEAM SHORT CODE *', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextField(
            controller: _teamShortCodeController,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            decoration: NeoGlassTheme.inputDecoration(
              hintText: 'e.g. RCB or BBL (max 4 letters)',
              prefixIcon: Icons.tag,
            ),
          ),
          const SizedBox(height: 14),

          // Team Primary Color
          const Text('TEAM THEME COLOR', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            children: _presetColors.map((c) {
              final isSel = _selectedTeamColor == c;
              return InkWell(
                onTap: () => setState(() => _selectedTeamColor = c),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSel ? Colors.white : Colors.transparent,
                      width: 2.5,
                    ),
                    boxShadow: [
                      if (isSel) NeoGlassTheme.neoGlowShadow(c, opacity: 0.5),
                    ],
                  ),
                  child: isSel ? const Icon(Icons.check, size: 16, color: Colors.black) : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              TextButton(
                onPressed: () => setState(() => _step = 1),
                child: const Text('← Re-enter PIN', style: TextStyle(color: Colors.white60)),
              ),
              const Spacer(),
              NeoGlassButton(
                onPressed: _isSubmitting ? null : () => _submitTeamRegistration(db),
                gradient: NeoGlassTheme.neonGradient,
                icon: Icons.check_circle,
                child: Text(
                  _isSubmitting
                      ? 'Submitting...'
                      : (auc.joiningMode == AuctionJoiningMode.automatic
                          ? 'Register Team & Join Auction'
                          : 'Submit for Host Approval'),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // SUCCESS STATE
  // =========================================================================
  Widget _buildSuccessState(MockDatabase db) {
    final mode = _registrationResult!['mode'] as String?;
    final isAuto = mode == 'automatic';

    return NeoGlassCard(
      glowColor: isAuto ? NeoGlassTheme.neonEmerald : NeoGlassTheme.neonAmber,
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (isAuto ? NeoGlassTheme.neonEmerald : Colors.amber).withValues(alpha: 0.2),
              border: Border.all(color: isAuto ? NeoGlassTheme.neonEmerald : Colors.amber, width: 2),
            ),
            child: Icon(
              isAuto ? Icons.check_circle_outline : Icons.hourglass_top,
              size: 40,
              color: isAuto ? NeoGlassTheme.neonEmerald : Colors.amber,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isAuto ? 'Team Approved & Joined!' : 'Registration Submitted!',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            isAuto
                ? 'Your franchise has been added to ${_validatedAuction!.title}. You have full team owner bidding access with ₹${(_validatedAuction!.maxPursePerTeam / 10000000).toStringAsFixed(1)} Cr purse.'
                : 'Your franchise registration has been sent to the host of ${_validatedAuction!.title} for verification. Once approved, your team will appear in the bidding lobby.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 24),

          NeoGlassButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (ctx) => AuctionScreen(initialAuctionId: _validatedAuction!.id),
                ),
              );
            },
            gradient: isAuto ? NeoGlassTheme.neonGradient : NeoGlassTheme.amberGoldGradient,
            icon: Icons.gavel,
            child: Text(
              isAuto ? 'Open Team Owner Bidding Arena' : 'Watch Live Auction',
              style: TextStyle(
                color: isAuto ? Colors.black : Colors.black,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
