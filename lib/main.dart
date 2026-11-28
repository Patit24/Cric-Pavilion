import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
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
import 'screens/matches/match_detail_screen.dart';
import 'screens/players/player_directory_screen.dart';
import 'widgets/organize_hub_modal.dart';
import 'widgets/auth_modal_dialog.dart';
import 'widgets/account_auth_pill.dart';
import 'widgets/privacy_policy_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
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
      FirestoreDatabaseService.pushUserProfile(db.currentUser ?? user);
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
      FirestoreDatabaseService.pushUserProfile(db.currentUser ?? user);
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

  static String? extractPublicMatchId(String? routeName) {
    if (routeName == null || routeName.isEmpty) return null;
    final uri = Uri.tryParse(routeName);
    if (uri == null) return null;
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.length >= 2 && segments[0] == 'match') {
      return segments[1];
    }
    if (uri.queryParameters.containsKey('matchId')) {
      return uri.queryParameters['matchId'];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CricPavilion Pro',
      debugShowCheckedModeBanner: false,
      theme: NeoGlassTheme.themeData,
      onGenerateRoute: (settings) {
        final matchId = extractPublicMatchId(settings.name);
        if (matchId != null && matchId.isNotEmpty) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => MatchDetailScreen(matchId: matchId),
          );
        }
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const MainNavigationShell(),
        );
      },
      onUnknownRoute: (settings) => MaterialPageRoute(
        settings: settings,
        builder: (_) => const MainNavigationShell(),
      ),
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
  bool _sidebarCollapsed = false;

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

    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final navItems = [
      const GlassNavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
      const GlassNavItem(icon: Icons.radio_button_unchecked, activeIcon: Icons.radio_button_checked, label: 'Live Scorer'),
      const GlassNavItem(icon: Icons.sports_cricket_outlined, activeIcon: Icons.sports_cricket, label: 'Results'),
      GlassNavItem(
        icon: isAuth ? Icons.person_outline : Icons.people_outline,
        activeIcon: isAuth ? Icons.person_rounded : Icons.people_rounded,
        label: isAuth ? 'My Profile' : 'Players',
      ),
      const GlassNavItem(icon: Icons.emoji_events_outlined, activeIcon: Icons.emoji_events, label: 'Tournaments'),
    ];

    return GlassScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        drawer: _buildPublicDrawer(context),
        body: Row(
          children: [
            if (isDesktop)
              GlassSidebar(
                items: navItems,
                selectedIndex: _currentIndex,
                onSelect: _onTabTapped,
                collapsed: _sidebarCollapsed,
                onToggleCollapse: () => setState(() => _sidebarCollapsed = !_sidebarCollapsed),
                footer: const AccountAuthPill(compact: true),
              ),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: screens,
              ),
            ),
          ],
        ),
        bottomNavigationBar: isDesktop
            ? null
            : SafeArea(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                  decoration: BoxDecoration(
                    color: GlassTokens.glassFillHigh,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white, width: 1.2),
                    boxShadow: GlassTokens.softShadow(),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
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
      ),
    );
  }

  Widget _buildNavTab(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isSelected = _currentIndex == index;

    return InkWell(
      onTap: () => _onTabTapped(index),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 12 : 8,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? GlassTokens.electricBlue.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: GlassTokens.electricBlue.withValues(alpha: 0.28), width: 1.0)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected ? GlassTokens.electricBlue : GlassTokens.inkSecondary,
              size: 20,
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: GlassTokens.electricBlue,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
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
      backgroundColor: GlassTokens.bgIcyWhite,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drawer Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: GlassTokens.canvasGradient,
                border: Border(bottom: BorderSide(color: GlassTokens.glassHairline)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: GlassTokens.accentGradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: GlassTokens.softShadow(glow: GlassTokens.electricBlue),
                        ),
                        child: const Icon(Icons.sports_cricket, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CricPavilion Pro',
                            style: TextStyle(
                              color: GlassTokens.inkPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.3,
                            ),
                          ),
                          Text(
                            'Public Cricket & Auction Platform',
                            style: TextStyle(color: GlassTokens.electricBlue, fontSize: 10.5, fontWeight: FontWeight.w700),
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
                border: Border(top: BorderSide(color: GlassTokens.glassHairline)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('v2.4.0 Production', style: TextStyle(color: GlassTokens.inkMuted, fontSize: 10)),
                  Text('ICC Compliant', style: TextStyle(color: GlassTokens.mintGreen, fontSize: 10, fontWeight: FontWeight.bold)),
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
          color: (iconColor ?? GlassTokens.electricBlue).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor ?? GlassTokens.electricBlue, size: 18),
      ),
      title: Text(title, style: const TextStyle(color: GlassTokens.inkPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(color: GlassTokens.inkSecondary, fontSize: 10)),
      onTap: onTap,
    );
  }
}
