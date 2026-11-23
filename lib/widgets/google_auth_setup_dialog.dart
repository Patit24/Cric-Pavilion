import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/mock_database.dart';
import '../services/totp_service.dart';
import '../theme/neo_glass_theme.dart';

class GoogleAuthSetupDialog extends StatefulWidget {
  final UserAccount user;

  const GoogleAuthSetupDialog({super.key, required this.user});

  static void show(BuildContext context, UserAccount user) {
    showDialog(
      context: context,
      builder: (ctx) => GoogleAuthSetupDialog(user: user),
    );
  }

  @override
  State<GoogleAuthSetupDialog> createState() => _GoogleAuthSetupDialogState();
}

class _GoogleAuthSetupDialogState extends State<GoogleAuthSetupDialog> {
  late String _secret;
  final TextEditingController _codeController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;
  bool _copied = false;
  bool _showRecoveryCodes = false;

  @override
  void initState() {
    super.initState();
    // If user already has a secret, keep it, otherwise generate a fresh Base32 secret
    _secret = widget.user.googleAuthSecret ?? TotpService.generateSecret(length: 20);
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String text, {bool isSecret = true}) {
    Clipboard.setData(ClipboardData(text: text));
    setState(() => _copied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isSecret ? 'Setup key copied to clipboard!' : 'Recovery code copied!'),
        backgroundColor: const Color(0xFF009270),
        duration: const Duration(seconds: 2),
      ),
    );
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  void _handleVerifyAndEnable(MockDatabase db) {
    final code = _codeController.text.trim();
    if (code.isEmpty || code.length < 6) {
      setState(() => _errorMessage = 'Please enter the 6-digit code from Google Authenticator.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = db.enableGoogleAuthenticator(
      userId: widget.user.id,
      secret: _secret,
      verificationCode: code,
    );

    setState(() => _isLoading = false);

    if (success) {
      setState(() => _showRecoveryCodes = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google Authenticator 2FA enabled successfully!'),
          backgroundColor: Color(0xFF009270),
        ),
      );
    } else {
      setState(() => _errorMessage = 'Invalid 6-digit code. Check your device clock and try again.');
    }
  }

  void _handleDisable(MockDatabase db) {
    showDialog(
      context: context,
      builder: (confirmCtx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFEF4444)),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
            SizedBox(width: 8),
            Text('Disable 2FA?', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Disabling Google Authenticator will remove the extra layer of security from your account.',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(confirmCtx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(confirmCtx);
              db.disableGoogleAuthenticator(widget.user.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Google Authenticator 2FA has been disabled.'),
                  backgroundColor: Color(0xFF334155),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Disable', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = context.watch<MockDatabase>();
    final isAlreadyEnabled = widget.user.isGoogleAuthEnabled && !_showRecoveryCodes;
    final formattedKey = TotpService.formatSecret(_secret);
    final otpAuthUri = TotpService.generateOtpAuthUri(
      email: widget.user.email,
      secret: _secret,
      issuer: 'CricPavilion',
    );

    return NeoGlassDialog(
      glowColor: widget.user.isGoogleAuthEnabled ? NeoGlassTheme.neonEmerald : NeoGlassTheme.neonCyan,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top icon + Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (widget.user.isGoogleAuthEnabled ? NeoGlassTheme.neonEmerald : NeoGlassTheme.neonCyan).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (widget.user.isGoogleAuthEnabled ? NeoGlassTheme.neonEmerald : NeoGlassTheme.neonCyan).withValues(alpha: 0.5),
                    ),
                  ),
                  child: Icon(
                    widget.user.isGoogleAuthEnabled ? Icons.verified_user : Icons.security_rounded,
                    color: widget.user.isGoogleAuthEnabled ? NeoGlassTheme.neonEmerald : NeoGlassTheme.neonCyan,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Google Authenticator',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.user.isGoogleAuthEnabled
                            ? 'Two-Factor Authentication (2FA) is Active'
                            : 'Set up RFC 6238 TOTP 2-Factor Authentication',
                        style: TextStyle(
                          color: widget.user.isGoogleAuthEnabled ? const Color(0xFF00F5A0) : Colors.white60,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_showRecoveryCodes) ...[
              // Recovery Codes Display
              _buildRecoveryCodesView(),
            ] else if (isAlreadyEnabled) ...[
              // Already Active View
              _buildAlreadyEnabledView(db),
            ] else ...[
              // Step-by-Step Setup View
              _buildSetupStepsView(db, formattedKey, otpAuthUri),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAlreadyEnabledView(MockDatabase db) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF064E3B).withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF059669)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Account Protected with 2FA',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Every sign-in requires your password plus the 6-digit dynamic code from Google Authenticator.',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Action: View Backup Recovery Codes
        if (widget.user.googleAuthRecoveryCodes.isNotEmpty)
          OutlinedButton.icon(
            onPressed: () => setState(() => _showRecoveryCodes = true),
            icon: const Icon(Icons.key, size: 16, color: NeoGlassTheme.neonCyan),
            label: Text(
              'View Backup Recovery Codes (${widget.user.googleAuthRecoveryCodes.length} remaining)',
              style: const TextStyle(color: NeoGlassTheme.neonCyan, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: NeoGlassTheme.neonCyan.withValues(alpha: 0.6)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        const SizedBox(height: 12),

        // Action: Disable 2FA
        OutlinedButton.icon(
          onPressed: () => _handleDisable(db),
          icon: const Icon(Icons.lock_open, size: 16, color: Colors.redAccent),
          label: const Text(
            'Disable Google Authenticator',
            style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.5)),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _buildSetupStepsView(MockDatabase db, String formattedKey, String otpAuthUri) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Step 1: Open Google Authenticator
        _buildStepBadge('1', 'Open the Google Authenticator app on your smartphone.'),
        const SizedBox(height: 8),

        // Step 2: Add Account & Enter Setup Key
        _buildStepBadge('2', 'Tap "+" and choose "Enter a setup key".'),
        const SizedBox(height: 8),

        // Step 3: Account info & Key Box
        _buildStepBadge('3', 'Enter the following details:'),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Account Name:', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  Text(
                    'CricPavilion (${widget.user.email})',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Divider(color: Colors.white10, height: 16),
              const Text('Your Secret Key (Base32):', style: TextStyle(color: Colors.white54, fontSize: 11)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: NeoGlassTheme.neonCyan.withValues(alpha: 0.4)),
                      ),
                      child: SelectableText(
                        formattedKey,
                        style: const TextStyle(
                          color: NeoGlassTheme.neonCyan,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _copyToClipboard(_secret, isSecret: true),
                    icon: Icon(_copied ? Icons.check : Icons.copy, size: 14, color: Colors.black),
                    label: Text(_copied ? 'Copied' : 'Copy Key', style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _copied ? const Color(0xFF00F5A0) : NeoGlassTheme.neonCyan,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Step 4: Verification 6-digit Code
        _buildStepBadge('4', 'Enter the 6-digit code shown in Google Authenticator:'),
        const SizedBox(height: 8),

        TextField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 8,
            fontFamily: 'monospace',
          ),
          textAlign: TextAlign.center,
          decoration: NeoGlassTheme.inputDecoration(
            hintText: '• • • • • •',
            prefixIcon: Icons.lock_clock_outlined,
          ).copyWith(
            counterText: '',
          ),
          onSubmitted: (_) => _handleVerifyAndEnable(db),
        ),

        if (_errorMessage != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 11.5),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 14),

        // Submit Button
        NeoGlassButton(
          onPressed: _isLoading ? null : () => _handleVerifyAndEnable(db),
          gradient: NeoGlassTheme.neonGradient,
          icon: Icons.shield_outlined,
          child: Text(
            _isLoading ? 'Verifying Code...' : 'Verify & Enable 2FA',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }

  Widget _buildRecoveryCodesView() {
    final codes = widget.user.googleAuthRecoveryCodes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Save Your Backup Recovery Codes',
                    style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'If you lose access to your phone or Google Authenticator app, each code can be used once to sign in.',
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: codes.map((c) {
                  return InkWell(
                    onTap: () => _copyToClipboard(c, isSecret: false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            c,
                            style: const TextStyle(
                              color: Color(0xFF00F5A0),
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.copy, size: 12, color: Colors.white38),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        NeoGlassButton(
          onPressed: () {
            setState(() => _showRecoveryCodes = false);
            Navigator.pop(context);
          },
          gradient: NeoGlassTheme.neonGradient,
          icon: Icons.check_circle_outline,
          child: const Text('I Have Saved My Recovery Codes', style: TextStyle(fontWeight: FontWeight.w900)),
        ),
      ],
    );
  }

  Widget _buildStepBadge(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: NeoGlassTheme.neonCyan.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: NeoGlassTheme.neonCyan),
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: const TextStyle(color: NeoGlassTheme.neonCyan, fontSize: 10, fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
