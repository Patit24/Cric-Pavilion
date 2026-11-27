import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'services/mock_database.dart';
import 'services/google_auth_service.dart';
import 'services/firestore_database_service.dart';
import 'theme/neo_glass_theme.dart';
import 'screens/home_screen.dart';
import 'screens/scorer/scorer_screen.dart';
import 'screens/auction/auction_screen.dart';
import 'screens/tournaments/tournament_hub_screen.dart';
import 'screens/public/join_auction_screen.dart';
import 'screens/matches/completed_matches_screen.dart';
import 'screens/players/player_directory_screen.dart';
import 'widgets/organize_hub_modal.dart';
import 'widgets/auth_modal_dialog.dart';
import 'widgets/account_auth_pill.dart';
import 'widgets/privacy_policy_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }

  final db = MockDatabase(loadDemoSeed: false);
  await db.initPersistence();
  db.purgeAllDemoData();

  // Complete any pending Web Google Sign-In Redirect flow (without overwriting an existing restored session)
  try {
    final redirectAuth = await GoogleAuthService.checkWebRedirectResult(
      onlyIfRedirected: db.currentUser != null,
    );
    if (redirectAuth != null && redirectAuth.success && redirectAuth.email != null) {
      final user = db.signInWithGoogle(
        email: redirectAuth.email!,
        displayName: redirectAuth.displayName ?? redirectAuth.email!.split('@').first,
        photoUrl: redirectAuth.photoUrl,
      );
      await FirestoreDatabaseService.fetchAndMergeCurrentUser(db);
      if (user.hasVerifiedMobile) {
        FirestoreDatabaseService.pushUserProfile(user);
      }
    }
  } catch (e) {
    debugPrint('Redirect auth completion notice: $e');
  }

  // Listen for asynchronous Firebase Auth hydration on Web/Mobile
  if (FirestoreDatabaseService.isFirebaseAvailable) {
    FirebaseAuth.instance.authStateChanges().listen((User? fbUser) async {
      if (fbUser == null || db.currentUser != null) return;
      final email = fbUser.email ?? '';
      if (email.isEmpty || email.endsWith('@sync.cricpavilion.app')) return;
      if (!fbUser.providerData.any((p) => p.providerId == 'google.com')) return;

      final user = db.signInWithGoogle(
        email: email,
        displayName: fbUser.displayName ?? email.split('@').first,
        photoUrl: fbUser.photoURL,
      );
      await FirestoreDatabaseService.fetchAndMergeCurrentUser(db);
      if (user.hasVerifiedMobile) {
        FirestoreDatabaseService.pushUserProfile(user);
      }
    });
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<MockDatabase>.value(value: db),
      ],
      child: const CricPavilionApp(),
    ),
  );
}

class CricPavilionApp extends StatelessWidget {
  const CricPavilionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CricPavilion Pro',
      debugShowCheckedModeBanner: false,
      theme: NeoGlassTheme.themeData,
      home: const MainNavigationShell(),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final db = context.read<MockDatabase>();
      if (db.currentUser != null && !db.currentUser!.isProfileComplete) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const AuthModalDialog(
            initialActionPrompt: 'Complete your first-time mobile OTP verification',
          ),
        );
      }
    });
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final db = context.watch<MockDatabase>();
    final isAuth = db.isAuthenticated;

    final screens = [
      HomeScreen(onTabChange: _onTabTapped),
      const ScorerScreen(),
      const CompletedMatchesScreen(),
      const PlayerDirectoryScreen(),
      const TournamentHubScreen(),
    ];

    return Scaffold(
      extendBody: true,
      drawer: _buildPublicDrawer(context),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0C1322).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.14),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                offset: const Offset(0, 10),
                blurRadius: 20,
              ),
              BoxShadow(
                color: const Color(0xFF00F5A0).withValues(alpha: 0.08),
                blurRadius: 16,
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.08),
                offset: const Offset(0, -1),
                blurRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavTab(0, Icons.home_rounded, Icons.home_outlined, 'Home'),
                    _buildNavTab(1, Icons.radio_button_checked, Icons.radio_button_unchecked, 'Scorer'),
                    _buildNavTab(2, Icons.sports_cricket, Icons.sports_cricket_outlined, 'Results'),
                    _buildNavTab(
                      3,
                      isAuth ? Icons.person_rounded : Icons.people_rounded,
                      isAuth ? Icons.person_outline : Icons.people_outline,
                      isAuth ? 'My Profile' : 'Players',
                    ),
                    _buildNavTab(4, Icons.emoji_events, Icons.emoji_events_outlined, 'Hub'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavTab(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isSelected = _currentIndex == index;

    return InkWell(
      onTap: () => _onTabTapped(index),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 12 : 8,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00F5A0).withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: const Color(0xFF00F5A0).withValues(alpha: 0.6), width: 1.0)
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF00F5A0).withValues(alpha: 0.25),
                    blurRadius: 10,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected ? const Color(0xFF00F5A0) : Colors.white60,
              size: 20,
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF00F5A0),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPublicDrawer(BuildContext context) {
    final db = Provider.of<MockDatabase>(context);
    final user = db.currentUser;

    return Drawer(
      backgroundColor: const Color(0xFF070B14),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drawer Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: NeoGlassTheme.neonGradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            NeoGlassTheme.neoGlowShadow(NeoGlassTheme.neonEmerald, opacity: 0.3),
                          ],
                        ),
                        child: const Icon(Icons.sports_cricket, color: Colors.black, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CricPavilion Pro',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            'Public Cricket & Auction Platform',
                            style: TextStyle(color: NeoGlassTheme.neonEmerald, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const AccountAuthPill(),
                ],
              ),
            ),

            // Directory Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildDrawerTile(
                    icon: Icons.hub_rounded,
                    title: 'Organize / Host Tournament',
                    subtitle: 'Create tournament or direct 2-team match',
                    iconColor: const Color(0xFF00F5A0),
                    onTap: () {
                      Navigator.pop(context);
                      OrganizeHubModal.show(context);
                    },
                  ),
                  const Divider(color: Color(0xFF1E293B), height: 16),
                  _buildDrawerTile(
                    icon: Icons.home_rounded,
                    title: 'Home',
                    subtitle: 'Live stadium, featured matches & feeds',
                    onTap: () {
                      Navigator.pop(context);
                      _onTabTapped(0);
                    },
                  ),
                  _buildDrawerTile(
                    icon: Icons.radio_button_checked,
                    title: 'Live Scores',
                    subtitle: 'Ball-by-ball commentary & scorecards',
                    onTap: () {
                      Navigator.pop(context);
                      _onTabTapped(1);
                    },
                  ),
                  _buildDrawerTile(
                    icon: Icons.sports_cricket_rounded,
                    title: 'Completed Matches',
                    subtitle: 'Permanent results & full scorecards',
                    onTap: () {
                      Navigator.pop(context);
                      _onTabTapped(2);
                    },
                  ),
                  _buildDrawerTile(
                    icon: db.isAuthenticated ? Icons.person_rounded : Icons.people_alt_rounded,
                    title: db.isAuthenticated ? 'My Player Profile & Stats' : 'Players & Stats Directory',
                    subtitle: db.isAuthenticated ? 'Your career records, batting & bowling stats' : 'Lookup registered players & career records',
                    onTap: () {
                      Navigator.pop(context);
                      _onTabTapped(3);
                    },
                  ),
                  _buildDrawerTile(
                    icon: Icons.emoji_events_rounded,
                    title: 'Tournaments',
                    subtitle: 'Standings, points table & caps',
                    onTap: () {
                      Navigator.pop(context);
                      _onTabTapped(4);
                    },
                  ),
                  _buildDrawerTile(
                    icon: Icons.gavel_rounded,
                    title: 'Live Auctions',
                    subtitle: 'IPL-style franchise bidding arenas',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AuctionScreen()),
                      );
                    },
                  ),
                  const Divider(color: Color(0xFF1E293B), height: 16),
                  _buildDrawerTile(
                    icon: Icons.vpn_key_rounded,
                    title: 'Join Auction with PIN',
                    subtitle: 'Franchise onboarding via 6-digit PIN',
                    iconColor: Colors.amberAccent,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const JoinAuctionScreen()),
                      );
                    },
                  ),
                  if (user == null) ...[
                    _buildDrawerTile(
                      icon: Icons.g_mobiledata_rounded,
                      title: 'Sign in with Google',
                      subtitle: '1-tap instant account access',
                      iconColor: const Color(0xFF4285F4),
                      onTap: () {
                        Navigator.pop(context);
                        showDialog(context: context, builder: (_) => const AuthModalDialog());
                      },
                    ),
                  ],
                  _buildDrawerTile(
                    icon: user == null ? Icons.login_rounded : Icons.account_circle_outlined,
                    title: user == null ? 'Organizer Login (Email & 2FA)' : 'My Account (${user.fullName.split(" ").first})',
                    subtitle: user == null ? 'Sign in to manage tournaments & score' : user.email,
                    iconColor: NeoGlassTheme.neonCyan,
                    onTap: () {
                      Navigator.pop(context);
                      if (user == null) {
                        showDialog(context: context, builder: (_) => const AuthModalDialog());
                      }
                    },
                  ),
                  _buildDrawerTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    subtitle: 'Data protection & user rights',
                    iconColor: const Color(0xFF00F5A0),
                    onTap: () {
                      Navigator.pop(context);
                      PrivacyPolicyDialog.show(context);
                    },
                  ),
                ],
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFF1E293B))),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('v2.4.0 Production', style: TextStyle(color: Colors.white38, fontSize: 10)),
                  Text('ICC Compliant', style: TextStyle(color: NeoGlassTheme.neonEmerald, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return ListTile(
      dense: true,
      leading: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: (iconColor ?? Colors.white70).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor ?? Colors.white70, size: 18),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 10)),
      onTap: onTap,
    );
  }
}
