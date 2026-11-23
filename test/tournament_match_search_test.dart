import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cricket_app/models/models.dart';
import 'package:cricket_app/services/mock_database.dart';

void main() {
  group('Tournament Name Match & Live Results Search Tests', () {
    late MockDatabase db;

    setUp(() {
      db = MockDatabase(loadDemoSeed: false);
    });

    test('1. Multiple Simultaneous Live Matches across Tournaments are supported and searchable by Tournament Name', () {
      // Create Tournament 1: BPL 2026
      final tourn1 = db.createTournament(
        name: 'Bangladesh Premier League 2026',
        shortName: 'BPL 2026',
        location: 'Dhaka',
        overs: 20,
        roomId: 'BPL-2026',
        passcode: '1234',
        totalTeams: 2,
        customTeamsWithPlayers: [
          {
            'name': 'Dhaka Gladiators',
            'shortName': 'DHG',
            'color': const Color(0xFF009270),
            'players': [
              {'name': 'Player D1', 'mobile': '9830000001', 'role': 'Batsman'},
              {'name': 'Player D2', 'mobile': '9830000002', 'role': 'Bowler'},
            ],
          },
          {
            'name': 'Chittagong Kings',
            'shortName': 'CKG',
            'color': const Color(0xFF0284C7),
            'players': [
              {'name': 'Player C1', 'mobile': '9830000003', 'role': 'Batsman'},
              {'name': 'Player C2', 'mobile': '9830000004', 'role': 'Bowler'},
            ],
          },
        ],
      );

      // Create Tournament 2: IPL 2026
      final tourn2 = db.createTournament(
        name: 'Indian Premier League 2026',
        shortName: 'IPL 2026',
        location: 'Mumbai',
        overs: 20,
        roomId: 'IPL-2026',
        passcode: '5678',
        totalTeams: 2,
        customTeamsWithPlayers: [
          {
            'name': 'Kolkata Knight Riders',
            'shortName': 'KKR',
            'color': const Color(0xFF4C1D95),
            'players': [
              {'name': 'Player K1', 'mobile': '9830000011', 'role': 'Batsman'},
              {'name': 'Player K2', 'mobile': '9830000012', 'role': 'Bowler'},
            ],
          },
          {
            'name': 'Mumbai Indians',
            'shortName': 'MI',
            'color': const Color(0xFF0369A1),
            'players': [
              {'name': 'Player M1', 'mobile': '9830000013', 'role': 'Batsman'},
              {'name': 'Player M2', 'mobile': '9830000014', 'role': 'Bowler'},
            ],
          },
        ],
      );

      // Each tournament automatically created its inaugural match
      final match1 = db.matches.firstWhere((m) => m.tournamentId == tourn1.id);
      final match2 = db.matches.firstWhere((m) => m.tournamentId == tourn2.id);

      // Set both matches to live simultaneously
      match1.status = MatchStatus.live;
      match2.status = MatchStatus.live;

      // Verify both matches are LIVE together
      final liveMatchesAll = db.matches.where((m) => m.status == MatchStatus.live).toList();
      expect(liveMatchesAll.length, equals(2));

      // Test searching for BPL 2026
      const searchBPL = 'bpl';
      final bplFiltered = liveMatchesAll.where((m) {
        final t = db.getTournament(m.tournamentId);
        return (t?.name.toLowerCase().contains(searchBPL) == true) ||
            (t?.shortName.toLowerCase().contains(searchBPL) == true);
      }).toList();

      expect(bplFiltered.length, equals(1));
      expect(bplFiltered.first.id, equals(match1.id));
      expect(bplFiltered.first.tournamentId, equals(tourn1.id));

      // Test searching for IPL 2026
      const searchIPL = 'ipl';
      final iplFiltered = liveMatchesAll.where((m) {
        final t = db.getTournament(m.tournamentId);
        return (t?.name.toLowerCase().contains(searchIPL) == true) ||
            (t?.shortName.toLowerCase().contains(searchIPL) == true);
      }).toList();

      expect(iplFiltered.length, equals(1));
      expect(iplFiltered.first.id, equals(match2.id));
      expect(iplFiltered.first.tournamentId, equals(tourn2.id));
    });

    test('2. Searching by tournament name filters completed match results accurately', () {
      final tourn1 = db.createTournament(
        name: 'County Championship 2026',
        shortName: 'County',
        location: 'London',
        overs: 20,
        roomId: 'COUNTY-2026',
        passcode: '1111',
        totalTeams: 2,
        customTeamsWithPlayers: [
          {
            'name': 'Surrey',
            'shortName': 'SUR',
            'color': const Color(0xFF009270),
            'players': [
              {'name': 'Player S1', 'mobile': '9830000021', 'role': 'Batsman'},
              {'name': 'Player S2', 'mobile': '9830000022', 'role': 'Bowler'},
            ],
          },
          {
            'name': 'Yorkshire',
            'shortName': 'YOR',
            'color': const Color(0xFF0284C7),
            'players': [
              {'name': 'Player Y1', 'mobile': '9830000023', 'role': 'Batsman'},
              {'name': 'Player Y2', 'mobile': '9830000024', 'role': 'Bowler'},
            ],
          },
        ],
      );

      final tourn2 = db.createTournament(
        name: 'Ranji Trophy 2026',
        shortName: 'Ranji',
        location: 'Bengaluru',
        overs: 20,
        roomId: 'RANJI-2026',
        passcode: '2222',
        totalTeams: 2,
        customTeamsWithPlayers: [
          {
            'name': 'Karnataka',
            'shortName': 'KAR',
            'color': const Color(0xFFB45309),
            'players': [
              {'name': 'Player K1', 'mobile': '9830000031', 'role': 'Batsman'},
              {'name': 'Player K2', 'mobile': '9830000032', 'role': 'Bowler'},
            ],
          },
          {
            'name': 'Mumbai',
            'shortName': 'MUM',
            'color': const Color(0xFF1D4ED8),
            'players': [
              {'name': 'Player M1', 'mobile': '9830000033', 'role': 'Batsman'},
              {'name': 'Player M2', 'mobile': '9830000034', 'role': 'Bowler'},
            ],
          },
        ],
      );

      final match1 = db.matches.firstWhere((m) => m.tournamentId == tourn1.id);
      final match2 = db.matches.firstWhere((m) => m.tournamentId == tourn2.id);

      final team1A = db.teams.firstWhere((t) => t.tournamentId == tourn1.id);
      final team2B = db.teams.where((t) => t.tournamentId == tourn2.id).toList()[1];

      match1.status = MatchStatus.completed;
      match1.winnerId = team1A.id;
      match1.winMargin = '42 runs';

      match2.status = MatchStatus.completed;
      match2.winnerId = team2B.id;
      match2.winMargin = '5 wickets';

      // Verify completed matches
      final allCompleted = db.completedMatches;
      expect(allCompleted.length, equals(2));

      // Filter by "ranji"
      final ranjiMatches = allCompleted.where((m) {
        final t = db.getTournament(m.tournamentId);
        return t?.name.toLowerCase().contains('ranji') == true ||
            t?.shortName.toLowerCase().contains('ranji') == true;
      }).toList();

      expect(ranjiMatches.length, equals(1));
      expect(ranjiMatches.first.id, equals(match2.id));
      expect(ranjiMatches.first.winMargin, equals('5 wickets'));

      // Filter by "county"
      final countyMatches = allCompleted.where((m) {
        final t = db.getTournament(m.tournamentId);
        return t?.name.toLowerCase().contains('county') == true ||
            t?.shortName.toLowerCase().contains('county') == true;
      }).toList();

      expect(countyMatches.length, equals(1));
      expect(countyMatches.first.id, equals(match1.id));
      expect(countyMatches.first.winMargin, equals('42 runs'));
    });

    test('3. Tournament search query handles partial keywords, spaces, and case-insensitivity', () {
      final tourn = db.createTournament(
        name: 'Super Smash T20 League',
        shortName: 'Super Smash',
        location: 'Auckland',
        overs: 20,
        roomId: 'SMASH-2026',
        passcode: '9999',
        totalTeams: 2,
        customTeamsWithPlayers: [
          {
            'name': 'Auckland Aces',
            'shortName': 'ACA',
            'color': const Color(0xFF009270),
            'players': [
              {'name': 'Player A1', 'mobile': '9830000041', 'role': 'Batsman'},
              {'name': 'Player A2', 'mobile': '9830000042', 'role': 'Bowler'},
            ],
          },
          {
            'name': 'Otago Volts',
            'shortName': 'OTV',
            'color': const Color(0xFF0284C7),
            'players': [
              {'name': 'Player O1', 'mobile': '9830000043', 'role': 'Batsman'},
              {'name': 'Player O2', 'mobile': '9830000044', 'role': 'Bowler'},
            ],
          },
        ],
      );

      final match = db.matches.firstWhere((m) => m.tournamentId == tourn.id);

      bool matchesQuery(MatchModel m, String query) {
        final q = query.trim().toLowerCase();
        if (q.isEmpty) return true;
        final t = db.getTournament(m.tournamentId);
        final tName = t?.name.toLowerCase() ?? '';
        final tShort = t?.shortName.toLowerCase() ?? '';
        return tName.contains(q) || tShort.contains(q);
      }

      expect(matchesQuery(match, 'SUPER'), isTrue);
      expect(matchesQuery(match, 'smash'), isTrue);
      expect(matchesQuery(match, 't20 league'), isTrue);
      expect(matchesQuery(match, 'premier'), isFalse);
    });
  });
}
