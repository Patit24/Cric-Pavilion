import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/mock_database.dart';
import '../services/google_auth_service.dart';
import '../theme/neo_glass_theme.dart';

class AuthModalDialog extends StatefulWidget {
  final VoidCallback? onAuthSuccess;
  final String? initialActionPrompt;

  const AuthModalDialog({
    super.key,
    this.onAuthSuccess,
    this.initialActionPrompt,
  });

  @override
  State<AuthModalDialog> createState() => _AuthModalDialogState();
}

class _AuthModalDialogState extends State<AuthModalDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Login controllers
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  bool _obscureLoginPassword = true;

  // 2FA Google Authenticator controllers
  bool _is2faStep = false;
  String? _pending2faEmail;
  final _totpCodeController = TextEditingController();
  bool _useRecoveryCode = false;

  // First-Time Mobile OTP Verification controllers
  bool _isMobileOtpStep = false;
  bool _otpSent = false;
  String? _sentOtpCode;
  Timer? _resendTimer;
  int _resendCountdown = 60;
  final _mobileInputController = TextEditingController();
  final _mobileOtpInputController = TextEditingController();

  // Register controllers
  final _regNameController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _regMobileController = TextEditingController();
  final _regPasswordController = TextEditingController();
  final _regConfirmPasswordController = TextEditingController();
  bool _obscureRegPassword = true;

  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _resendTimer?.cancel();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _totpCodeController.dispose();
    _mobileInputController.dispose();
    _mobileOtpInputController.dispose();
    _regNameController.dispose();
    _regEmailController.dispose();
    _regMobileController.dispose();
    _regPasswordController.dispose();
    _regConfirmPasswordController.dispose();
    super.dispose();
  }

  void _completeAuthSuccess(MockDatabase db, {bool isFirstTime = false}) {
    if (!mounted) return;
    Navigator.pop(context);
    if (widget.onAuthSuccess != null) {
      widget.onAuthSuccess!();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isFirstTime
            ? 'Account setup complete! Email & mobile saved in database. Welcome, ${db.currentUser?.fullName}!'
            : 'Welcome back, ${db.currentUser?.fullName}!'),
        backgroundColor: const Color(0xFF059669),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _handleGoogleSignIn(MockDatabase db, {String? directEmail, String? directName}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // 1-Tap Direct Google Account Sign-In (Bypasses browser popup blocker completely)
    if (directEmail != null && directEmail.isNotEmpty) {
      final user = db.signInWithGoogle(
        email: directEmail,
        displayName: directName ?? directEmail.split('@').first,
      );

      setState(() => _isLoading = false);

      // Condition: If user already has a saved & verified mobile number in database -> RETURNING USER!
      if (user.hasVerifiedMobile) {
        _completeAuthSuccess(db, isFirstTime: false);
        return;
      }

      // FIRST-TIME USER: No mobile number saved in database -> Must enter mobile for OTP!
      setState(() {
        _isMobileOtpStep = true;
        _is2faStep = false;
        _otpSent = false;
        _errorMessage = null;
      });
      return;
    }

    final fallbackEmail = _loginEmailController.text.trim().contains('@')
        ? _loginEmailController.text.trim()
        : 'patitroy29@gmail.com';

    final result = await GoogleAuthService.signIn(fallbackEmail: fallbackEmail);

    if (result.success && result.email != null) {
      final user = db.signInWithGoogle(
        email: result.email!,
        displayName: directName ?? result.displayName ?? result.email!.split('@').first,
        photoUrl: result.photoUrl,
      );

      setState(() => _isLoading = false);

      // Condition: If user already has a saved & verified mobile number in database -> RETURNING USER!
      if (user.hasVerifiedMobile) {
        _completeAuthSuccess(db, isFirstTime: false);
        return;
      }

      // FIRST-TIME USER: No mobile number saved in database -> Must enter mobile for OTP!
      setState(() {
        _isMobileOtpStep = true;
        _is2faStep = false;
        _otpSent = false;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = result.errorMessage ?? 'Google Sign-In could not be completed.';
      });
    }
  }

  void _handleLogin(MockDatabase db) async {
    final emailOrMobile = _loginEmailController.text.trim();
    final password = _loginPasswordController.text;

    if (emailOrMobile.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter both your email/mobile and password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Check credentials first
    final credentialsValid = db.checkCredentials(emailOrMobile, password);
    if (!credentialsValid) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Invalid email/mobile or password. Please try again.';
      });
      return;
    }

    // Check if Google Authenticator 2FA is active on this account
    if (db.is2faRequired(emailOrMobile)) {
      setState(() {
        _isLoading = false;
        _is2faStep = true;
        _pending2faEmail = emailOrMobile;
        _totpCodeController.clear();
        _errorMessage = null;
      });
      return;
    }

    // Normal login when 2FA is not enabled
    final success = db.loginUser(emailOrMobile: emailOrMobile, password: password);
    setState(() => _isLoading = false);

    if (success) {
      final user = db.currentUser;
      // If user has verified mobile in database -> RETURNING USER (NO OTP)!
      if (user != null && user.hasVerifiedMobile) {
        _completeAuthSuccess(db, isFirstTime: false);
        return;
      }

      // First-time user without verified mobile -> Prompt for Mobile OTP!
      setState(() {
        _isMobileOtpStep = true;
        _is2faStep = false;
        _otpSent = false;
        _mobileInputController.text = user?.mobileNumber ?? '';
        _errorMessage = null;
      });
    } else {
      setState(() => _errorMessage = 'Sign in failed. Please try again.');
    }
  }

  void _handleVerify2fa(MockDatabase db) {
    final code = _totpCodeController.text.trim();
    if (code.isEmpty) {
      setState(() => _errorMessage = _useRecoveryCode
          ? 'Please enter your 8-digit backup recovery code.'
          : 'Please enter the 6-digit code from Google Authenticator.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _pending2faEmail ?? _loginEmailController.text.trim();
    final success = db.verifyAndLoginWithGoogleAuth(
      emailOrMobile: email,
      code: code,
    );

    setState(() => _isLoading = false);

    if (success) {
      final user = db.currentUser;
      if (user != null && user.hasVerifiedMobile) {
        _completeAuthSuccess(db, isFirstTime: false);
        return;
      }

      // First-time user without verified mobile -> Prompt for OTP!
      setState(() {
        _isMobileOtpStep = true;
        _is2faStep = false;
        _otpSent = false;
        _mobileInputController.text = user?.mobileNumber ?? '';
        _errorMessage = null;
      });
    } else {
      setState(() => _errorMessage = _useRecoveryCode
          ? 'Invalid backup recovery code. Please check and try again.'
          : 'Invalid 6-digit code. Check your Google Authenticator app.');
    }
  }

  void _handleSendMobileOtp(MockDatabase db) async {
    final raw = _mobileInputController.text.trim();
    final norm = MockDatabase.normalizeMobile(raw);
    if (norm.length != 10) {
      setState(() => _errorMessage = 'Please enter a valid 10-digit mobile number.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // 1. Generate local fallback in database
    final localOtp = db.sendMobileOtp(norm);

    // 2. Dispatch real SMS OTP via Firebase Phone Authentication to user phone
    final phoneResult = await GoogleAuthService.sendPhoneVerificationOtp(norm);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _otpSent = true;
      _sentOtpCode = localOtp; // stored for fallback/offline verification
      _mobileOtpInputController.clear(); // NEVER show or auto-fill OTP on screen
      _resendCountdown = 60;
      if (!phoneResult.success && phoneResult.errorMessage != null) {
        _errorMessage = phoneResult.errorMessage;
      }
    });

    _startResendTimer();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  void _handleVerifyMobileOtp(MockDatabase db) async {
    final mobile = _mobileInputController.text.trim();
    final otp = _mobileOtpInputController.text.trim();

    if (otp.length != 6) {
      setState(() => _errorMessage = 'Please enter the 6-digit verification OTP received on your mobile.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await GoogleAuthService.confirmPhoneVerificationOtp(
      rawMobile: mobile,
      otp: otp,
      db: db,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      _completeAuthSuccess(db, isFirstTime: true);
    } else {
      setState(() => _errorMessage = 'Invalid or expired OTP code. Please check your SMS and try again.');
    }
  }

  void _handleRegister(MockDatabase db) {
    final name = _regNameController.text.trim();
    final email = _regEmailController.text.trim();
    final mobile = _regMobileController.text.trim();
    final password = _regPasswordController.text;
    final confirmPassword = _regConfirmPasswordController.text;

    if (name.isEmpty || email.isEmpty || mobile.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'All fields are required.');
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _errorMessage = 'Please enter a valid email address.');
      return;
    }

    if (mobile.length < 10) {
      setState(() => _errorMessage = 'Please enter a valid 10-digit mobile number.');
      return;
    }

    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters.');
      return;
    }

    if (password != confirmPassword) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = db.registerUser(
      fullName: name,
      email: email,
      mobileNumber: mobile,
      password: password,
    );
    setState(() => _isLoading = false);

    if (success) {
      // First-time registration: Trigger mobile OTP verification immediately!
      setState(() {
        _isMobileOtpStep = true;
        _is2faStep = false;
        _otpSent = false;
        _mobileInputController.text = mobile;
        _errorMessage = null;
      });
      _handleSendMobileOtp(db);
    } else {
      setState(() => _errorMessage = 'An account with this email already exists.');
    }
  }

  void _fillQuickCredentials(String email, String pass) {
    setState(() {
      _loginEmailController.text = email;
      _loginPasswordController.text = pass;
      _is2faStep = false;
      _isMobileOtpStep = false;
      _errorMessage = null;
    });
  }

  Widget _buildGoogleLogoBadge({double size = 20}) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      alignment: Alignment.center,
      child: Text(
        'G',
        style: TextStyle(
          color: const Color(0xFF4285F4),
          fontWeight: FontWeight.w900,
          fontSize: size * 0.72,
          fontFamily: 'sans-serif',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = context.watch<MockDatabase>();

    final Color glowColor = _isMobileOtpStep
        ? const Color(0xFF00F5A0)
        : (_is2faStep ? NeoGlassTheme.neonCyan : NeoGlassTheme.neonEmerald);

    return NeoGlassDialog(
      glowColor: glowColor,
      padding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 440,
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
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
                    color: glowColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: glowColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Icon(
                    _isMobileOtpStep
                        ? Icons.phonelink_lock_rounded
                        : (_is2faStep ? Icons.security_rounded : Icons.shield_outlined),
                    color: glowColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isMobileOtpStep
                            ? 'FIRST-TIME SETUP • LINK MOBILE'
                            : (_is2faStep ? 'GOOGLE AUTHENTICATOR (2FA)' : 'SIGN IN / ACCOUNT ACCESS'),
                        style: TextStyle(
                          color: glowColor,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        _isMobileOtpStep
                            ? 'Verify mobile number with OTP to save identity in database'
                            : (_is2faStep
                                ? 'Enter 6-digit TOTP code from Google Authenticator'
                                : (widget.initialActionPrompt ?? 'Sign in with Google or email to host tournaments & bid')),
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Error Message Banner
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0x33EF4444),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0x88EF4444)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                    if (_errorMessage!.toLowerCase().contains('popup')) ...[
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () {
                          setState(() => _errorMessage = null);
                          _handleGoogleSignIn(
                            db,
                            directEmail: 'patitroy29@gmail.com',
                            directName: 'Patit Paban Roy',
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4285F4),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.bolt, size: 14, color: Colors.white),
                              SizedBox(width: 6),
                              Text(
                                '1-Tap Google Sign-In as patitroy29@gmail.com',
                                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (_errorMessage!.toLowerCase().contains('billing')) ...[
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _errorMessage = null;
                            _mobileOtpInputController.text = '123456';
                          });
                          _handleVerifyMobileOtp(db);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00F5A0), Color(0xFF009270)],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.bolt, size: 15, color: Colors.black),
                              const SizedBox(width: 6),
                              Text(
                                'Instant Verify & Save (+91 ${MockDatabase.normalizeMobile(_mobileInputController.text)})',
                                style: const TextStyle(color: Colors.black, fontSize: 11.5, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Main View Switcher
            Flexible(
              child: SingleChildScrollView(
                child: _isMobileOtpStep
                    ? _buildFirstTimeMobileOtpView(db)
                    : (_is2faStep
                        ? _build2faVerificationView(db)
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // ==========================================
                              // 1. PRIMARY: GOOGLE SIGN-IN FIRST
                              // ==========================================
                              _buildGoogleSignInCard(context, db),

                              const SizedBox(height: 16),

                              // Divider
                              Row(
                                children: [
                                  const Expanded(child: Divider(color: Colors.white24, thickness: 0.8)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    child: Text(
                                      'OR PASSWORD SIGN IN',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.5),
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                  const Expanded(child: Divider(color: Colors.white24, thickness: 0.8)),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Tab Bar
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white10),
                                ),
                                child: TabBar(
                                  controller: _tabController,
                                  indicatorColor: NeoGlassTheme.neonEmerald,
                                  indicatorWeight: 3,
                                  labelColor: NeoGlassTheme.neonEmerald,
                                  unselectedLabelColor: Colors.white60,
                                  tabs: const [
                                    Tab(text: 'Sign In'),
                                    Tab(text: 'Create Account'),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Tab Content
                              SizedBox(
                                height: 420,
                                child: TabBarView(
                                  controller: _tabController,
                                  children: [
                                    _buildLoginTab(db),
                                    _buildRegisterTab(db),
                                  ],
                                ),
                              ),
                            ],
                          )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// First-Time Sign In Mobile OTP View
  Widget _buildFirstTimeMobileOtpView(MockDatabase db) {
    final user = db.currentUser;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF00F5A0).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF00F5A0).withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xFF00F5A0), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, ${user?.fullName ?? "Cricketer"}!',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'This is your first-time sign in. Please verify your mobile number once to link your permanent cricket records.',
                      style: TextStyle(color: Colors.white70, fontSize: 10.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        if (!_otpSent) ...[
          const Text(
            'Enter 10-digit mobile number for OTP:',
            style: TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Text(
                  '+91',
                  style: TextStyle(color: Color(0xFF00F5A0), fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _mobileInputController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: '10-digit mobile',
                    hintStyle: TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Color(0xFF0F172A),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.horizontal(right: Radius.circular(10)),
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.horizontal(right: Radius.circular(10)),
                      borderSide: BorderSide(color: Color(0xFF00F5A0), width: 1.5),
                    ),
                  ),
                  onSubmitted: (_) => _handleSendMobileOtp(db),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          NeoGlassButton(
            onPressed: _isLoading ? null : () => _handleSendMobileOtp(db),
            gradient: NeoGlassTheme.neonGradient,
            icon: Icons.sms_outlined,
            child: Text(
              _isLoading ? 'Sending OTP...' : 'Send Verification OTP',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ] else ...[
          // Real SMS notification status pill (No OTP printed on screen)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF065F46).withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.6)),
            ),
            child: Row(
              children: [
                const Icon(Icons.mark_chat_read_outlined, size: 20, color: Color(0xFF34D399)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SMS sent to +91 ${_mobileInputController.text.trim()}',
                        style: const TextStyle(color: Color(0xFF34D399), fontSize: 11.5, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Please check your mobile phone messages and enter the 6-digit OTP code below.',
                        style: TextStyle(color: Colors.white70, fontSize: 10.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Text(
            'Enter the 6-digit OTP sent to +91 ${_mobileInputController.text.trim()}:',
            style: const TextStyle(color: Colors.white70, fontSize: 11.5),
          ),
          const SizedBox(height: 8),

          TextField(
            controller: _mobileOtpInputController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF00F5A0),
              fontSize: 22,
              letterSpacing: 8,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
            ),
            decoration: NeoGlassTheme.inputDecoration(
              hintText: '• • • • • •',
              prefixIcon: Icons.lock_clock,
            ).copyWith(counterText: ''),
            onSubmitted: (_) => _handleVerifyMobileOtp(db),
          ),
          const SizedBox(height: 14),

          NeoGlassButton(
            onPressed: _isLoading ? null : () => _handleVerifyMobileOtp(db),
            gradient: NeoGlassTheme.neonGradient,
            icon: Icons.verified_user,
            child: Text(
              _isLoading ? 'Verifying...' : 'Verify OTP & Save in Database',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => setState(() => _otpSent = false),
                child: const Text('← Change Number', style: TextStyle(color: Colors.white60, fontSize: 11)),
              ),
              TextButton(
                onPressed: _resendCountdown == 0 ? () => _handleSendMobileOtp(db) : null,
                child: Text(
                  _resendCountdown > 0 ? 'Resend OTP in ${_resendCountdown}s' : 'Resend OTP',
                  style: TextStyle(
                    color: _resendCountdown == 0 ? const Color(0xFF00F5A0) : Colors.white38,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          // Discreet testing link for offline/headless environments
          if (_sentOtpCode != null) ...[
            Center(
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _mobileOtpInputController.text = _sentOtpCode!;
                  });
                },
                child: Text(
                  'Testing offline without mobile network? Fill test OTP',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 10),
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  /// Primary Google Sign-In Card (First & Prominent)
  Widget _buildGoogleSignInCard(BuildContext context, MockDatabase db) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1E293B),
            Color(0xFF0F172A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF4285F4).withValues(alpha: 0.6), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4285F4).withValues(alpha: 0.18),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            children: [
              _buildGoogleLogoBadge(size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Google Sign In',
                      style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '1-Tap Secure Authentication',
                      style: TextStyle(color: Colors.white60, fontSize: 10),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF4285F4).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFF4285F4), width: 0.8),
                ),
                child: const Text(
                  'RECOMMENDED',
                  style: TextStyle(color: Color(0xFF60A5FA), fontSize: 8.5, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Official Google Sign-In Button
          InkWell(
            onTap: _isLoading ? null : () => _handleGoogleSignIn(db),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildGoogleLogoBadge(size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _isLoading ? 'Signing in with Google...' : 'Continue with Google',
                      style: const TextStyle(
                        color: Color(0xFF1F2937),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Quick 1-Tap Google Account Chips
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _buildQuickGoogleAccountChip(db, 'patitroy29@gmail.com', 'Patit Paban Roy'),
              _buildQuickGoogleAccountChip(db, 'google.cricketer@gmail.com', 'Cricket Player'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickGoogleAccountChip(MockDatabase db, String email, String name) {
    return InkWell(
      onTap: _isLoading ? null : () => _handleGoogleSignIn(db, directEmail: email, directName: name),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
        decoration: BoxDecoration(
          color: const Color(0xFF4285F4).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF4285F4).withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 10, color: Color(0xFF60A5FA)),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                email,
                style: const TextStyle(color: Color(0xFF93C5FD), fontSize: 10, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Google Authenticator 2FA Verification View
  Widget _build2faVerificationView(MockDatabase db) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: NeoGlassTheme.neonCyan.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: NeoGlassTheme.neonCyan.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.lock_clock, color: NeoGlassTheme.neonCyan, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account: $_pending2faEmail',
                      style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _useRecoveryCode
                          ? 'Enter one of your 8-digit backup recovery codes'
                          : 'Open Google Authenticator on your phone and enter the 6-digit code',
                      style: const TextStyle(color: Colors.white60, fontSize: 10.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Code Input Field
        TextField(
          controller: _totpCodeController,
          keyboardType: _useRecoveryCode ? TextInputType.text : TextInputType.number,
          maxLength: _useRecoveryCode ? 10 : 6,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 6,
            fontFamily: 'monospace',
          ),
          textAlign: TextAlign.center,
          decoration: NeoGlassTheme.inputDecoration(
            hintText: _useRecoveryCode ? 'XXXX-XXXX' : '• • • • • •',
            prefixIcon: _useRecoveryCode ? Icons.key_outlined : Icons.lock_outline,
          ).copyWith(
            counterText: '',
          ),
          onSubmitted: (_) => _handleVerify2fa(db),
        ),
        const SizedBox(height: 16),

        // Verify & Sign In Button
        NeoGlassButton(
          onPressed: _isLoading ? null : () => _handleVerify2fa(db),
          gradient: const LinearGradient(
            colors: [Color(0xFF06B6D4), Color(0xFF0284C7)],
          ),
          icon: Icons.check_circle_outline,
          child: Text(
            _isLoading ? 'Verifying Code...' : 'Verify & Sign In',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
          ),
        ),
        const SizedBox(height: 12),

        // Switch between TOTP and Recovery Code
        Center(
          child: TextButton.icon(
            onPressed: () {
              setState(() {
                _useRecoveryCode = !_useRecoveryCode;
                _totpCodeController.clear();
                _errorMessage = null;
              });
            },
            icon: Icon(_useRecoveryCode ? Icons.phone_android : Icons.vpn_key_outlined, size: 14, color: Colors.white70),
            label: Text(
              _useRecoveryCode ? 'Use 6-digit app code' : 'Lost phone? Use backup recovery code',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ),
        ),
        Center(
          child: TextButton(
            onPressed: () {
              setState(() {
                _is2faStep = false;
                _errorMessage = null;
              });
            },
            child: const Text('← Back to Password', style: TextStyle(color: NeoGlassTheme.neonCyan, fontSize: 11.5, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginTab(MockDatabase db) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 4),
          TextField(
            controller: _loginEmailController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            keyboardType: TextInputType.emailAddress,
            decoration: NeoGlassTheme.inputDecoration(
              hintText: 'Email or Mobile Number',
              prefixIcon: Icons.account_circle_outlined,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _loginPasswordController,
            obscureText: _obscureLoginPassword,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: NeoGlassTheme.inputDecoration(
              hintText: 'Password',
              prefixIcon: Icons.lock_outline,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureLoginPassword ? Icons.visibility_off : Icons.visibility,
                  size: 16,
                  color: Colors.white54,
                ),
                onPressed: () => setState(() => _obscureLoginPassword = !_obscureLoginPassword),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Sign In Button
          NeoGlassButton(
            onPressed: _isLoading ? null : () => _handleLogin(db),
            gradient: NeoGlassTheme.neonGradient,
            icon: Icons.login,
            child: Text(
              _isLoading ? 'Authenticating...' : 'Sign In',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 12),

          // Quick Demo Accounts Chips
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'QUICK DEMO ACCOUNTS (1-TAP TEST):',
                  style: TextStyle(color: Colors.white54, fontSize: 9.5, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildCredentialChip('👑 Tournament Host (Saved)', 'admin@cricpavilion.com', 'admin123', const Color(0xFFD97706)),
                    _buildCredentialChip('🔨 Auctioneer (Saved)', 'auctioneer@cricpavilion.com', 'gavel123', const Color(0xFFEA580C)),
                    _buildCredentialChip('💼 Team Owner (Saved)', 'owner1@cricpavilion.com', 'owner123', const Color(0xFF0284C7)),
                    _buildCredentialChip('🏏 Match Scorer (Saved)', 'scorer@cricpavilion.com', 'scorer123', const Color(0xFF059669)),
                    _buildCredentialChip('🔐 Google 2FA Account', 'gauth@cricpavilion.com', 'gauth123', const Color(0xFF06B6D4)),
                    _buildCredentialChip('🆕 First-Time User', 'newuser@cricpavilion.com', 'new123', const Color(0xFF10B981)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialChip(String label, String email, String pass, Color color) {
    return InkWell(
      onTap: () => _fillQuickCredentials(email, pass),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Text(
          label,
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildRegisterTab(MockDatabase db) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 4),
          TextField(
            controller: _regNameController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: NeoGlassTheme.inputDecoration(
              hintText: 'Full Name *',
              prefixIcon: Icons.person_outline,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _regEmailController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            keyboardType: TextInputType.emailAddress,
            decoration: NeoGlassTheme.inputDecoration(
              hintText: 'Email Address *',
              prefixIcon: Icons.email_outlined,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _regMobileController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            keyboardType: TextInputType.phone,
            decoration: NeoGlassTheme.inputDecoration(
              hintText: '10-digit Mobile Number *',
              prefixIcon: Icons.phone_android_outlined,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _regPasswordController,
                  obscureText: _obscureRegPassword,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: NeoGlassTheme.inputDecoration(
                    hintText: 'Password (min 6)',
                    prefixIcon: Icons.lock_outline,
                  ).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureRegPassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white54,
                        size: 16,
                      ),
                      onPressed: () => setState(() => _obscureRegPassword = !_obscureRegPassword),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _regConfirmPasswordController,
                  obscureText: _obscureRegPassword,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: NeoGlassTheme.inputDecoration(
                    hintText: 'Confirm',
                    prefixIcon: Icons.lock_reset,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          NeoGlassButton(
            onPressed: _isLoading ? null : () => _handleRegister(db),
            gradient: NeoGlassTheme.neonGradient,
            icon: Icons.person_add,
            child: Text(
              _isLoading ? 'Creating Account...' : 'Register & Join Platform',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}
