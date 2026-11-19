import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/mock_database.dart';
import 'screens/home_screen.dart';
import 'screens/scorer/scorer_screen.dart';
import 'screens/auction/auction_screen.dart';
import 'screens/matches/matches_list_screen.dart';
import 'screens/tournaments/tournament_hub_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MockDatabase()),
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
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF111827), // Cricbuzz clean dark slate
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF009270), // Cricbuzz Iconic Green
          secondary: Color(0xFF10B981),
          surface: Color(0xFF1F2937),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF009270), // Cricbuzz Green Header
          elevation: 0,
          foregroundColor: Colors.white,
        ),
      ),
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

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(onTabChange: _onTabTapped),
      const ScorerScreen(),
      const AuctionScreen(),
      const MatchesListScreen(),
      const TournamentHubScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabTapped,
        backgroundColor: const Color(0xFF0B1120),
        indicatorColor: const Color(0xFF059669),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: Colors.white),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.radio_button_checked),
            selectedIcon: Icon(Icons.radio_button_checked, color: Colors.white),
            label: 'Scorer',
          ),
          NavigationDestination(
            icon: Icon(Icons.gavel_outlined),
            selectedIcon: Icon(Icons.gavel, color: Colors.white),
            label: 'Auction',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_cricket_outlined),
            selectedIcon: Icon(Icons.sports_cricket, color: Colors.white),
            label: 'Matches',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events, color: Colors.white),
            label: 'Tournament',
          ),
        ],
      ),
    );
  }
}
