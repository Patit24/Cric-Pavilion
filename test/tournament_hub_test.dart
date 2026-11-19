import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cricket_app/models/models.dart';
import 'package:cricket_app/services/mock_database.dart';

void main() {
  group('Tournament Engine & Clean Slate User Flow Tests', () {
    test('MockDatabase starts with clean slate by default (0 demo tournaments)', () {
      final cleanDb = MockDatabase(); // default loadDemoSeed: false
      expect(cleanDb.isDemoDataLoaded, isFalse);
      expect(cleanDb.tournaments, isEmpty);
      expect(cleanDb.matches, isEmpty);
      expect(cleanDb.teams, isEmpty);
      expect(cleanDb.players, isEmpty);
      expect(cleanDb.auctions, isEmpty);
      expect(cleanDb.tournament.id, equals('empty_tourn'));
    });

    test('User organizes tournament and can skip player entry during creation', () {
      final db = MockDatabase();

      // Create tournament with 2 teams, but player entry skipped
      final created = db.createTournament(
        name: 'Salt Lake Cup 2026',
        shortName: 'SLC 2026',
        location: 'Salt Lake Stadium, Kolkata',
        overs: 20,
        roomId: 'TOURN-SLC-2026',
        passcode: '1234',
        totalTeams: 2,
        customTeamsWithPlayers: [
          {
            'name': 'Salt Lake Strikers',
            'shortName': 'SLS',
            'color': const Color(0xFF009270),
            'players': <Map<String, String>>[], // Skipped player entry!
          },
          {
            'name': 'Newtown Navigators',
            'shortName': 'NTN',
            'color': const Color(0xFF0284C7),
            'players': <Map<String, String>>[], // Skipped player entry!
          },
        ],
      );

      expect(created.name, equals('Salt Lake Cup 2026'));
      expect(db.tournaments.length, equals(1));
      expect(db.teams.length, equals(2));
      expect(db.matches.length, equals(1)); // Inaugural match created

      final match = db.matches.first;
      expect(match.teamAId, equals(db.teams[0].id));
      expect(match.teamBId, equals(db.teams[1].id));

      // Because player entry was skipped, scoring must be blocked!
      expect(db.areTeamsReadyForScoring(match.teamAId, match.teamBId), isFalse);
    });

    test('Before start scoring, both teams must fill all players names with mobile numbers', () {
      final db = MockDatabase();

      final created = db.createTournament(
        name: 'Champions Cup 2026',
        shortName: 'CC 2026',
        location: 'Eden Gardens',
        overs: 20,
        roomId: 'TOURN-CC-2026',
        passcode: '1234',
        totalTeams: 2,
      );
      expect(created.name, equals('Champions Cup 2026'));

      final match = db.matches.first;
      final teamAId = match.teamAId;
      final teamBId = match.teamBId;

      // 1. When players are missing: blocked
      expect(db.areTeamsReadyForScoring(teamAId, teamBId), isFalse);

      // 2. When players have name but MISSING mobile number: still blocked!
      db.saveTeamSquadWithMobileNumbers(
        teamId: teamAId,
        playerEntries: [
          {'name': 'Rahul Das', 'mobile': '', 'role': 'batter'}, // Missing mobile!
          {'name': 'Suman Biswas', 'mobile': '9876543210', 'role': 'bowler'},
        ],
      );
      db.saveTeamSquadWithMobileNumbers(
        teamId: teamBId,
        playerEntries: [
          {'name': 'Manoj Tiwary', 'mobile': '9876543211', 'role': 'batter'},
          {'name': 'Akash Deep', 'mobile': '9876543212', 'role': 'bowler'},
        ],
      );
      expect(db.areTeamsReadyForScoring(teamAId, teamBId), isFalse);

      // 3. When both teams fill all player names with mobile numbers: scoring UNLOCKED!
      db.saveTeamSquadWithMobileNumbers(
        teamId: teamAId,
        playerEntries: [
          {'name': 'Rahul Das', 'mobile': '9876543209', 'role': 'batter'},
          {'name': 'Suman Biswas', 'mobile': '9876543210', 'role': 'bowler'},
        ],
      );
      expect(db.areTeamsReadyForScoring(teamAId, teamBId), isTrue);

      // Player objects retain mobile number
      final savedA = db.getTeamPlayers(teamAId);
      expect(savedA.length, equals(2));
      expect(savedA.first.mobileNumber, equals('9876543209'));
    });
  });

  group('Tournament Engine & Leaderboard Tests', () {
    late MockDatabase db;

    setUp(() {
      db = MockDatabase(loadDemoSeed: true);
    });

    test('Orange Cap / Top Batters aggregates runs and sorts descending', () {
      final batters = db.getTournamentTopBatters('tourn_bpl_2026');
      expect(batters, isNotEmpty);

      // Verify sorting descending by runs
      for (int i = 0; i < batters.length - 1; i++) {
        expect(batters[i].runs >= batters[i + 1].runs, isTrue);
      }

      final leader = batters.first;
      expect(leader.runs, greaterThan(0));
      expect(leader.strikeRate, greaterThan(0));
    });

    test('Purple Cap / Top Bowlers aggregates wickets and sorts descending', () {
      final bowlers = db.getTournamentTopBowlers('tourn_bpl_2026');
      expect(bowlers, isNotEmpty);

      for (int i = 0; i < bowlers.length - 1; i++) {
        expect(bowlers[i].wickets >= bowlers[i + 1].wickets, isTrue);
      }

      final leader = bowlers.first;
      expect(leader.wickets, greaterThan(0));
    });

    test('Top Fielders aggregates catches and dismissals accurately', () {
      final fielders = db.getTournamentTopFielders('tourn_bpl_2026');
      expect(fielders, isNotEmpty);

      final topFielder = fielders.first;
      expect(topFielder.totalDismissals, greaterThan(0));
      expect(topFielder.catches, greaterThan(0));
    });

    test('Boundary Tracker tracks fours and sixes', () {
      final boundaries = db.getTournamentBoundaryLeaders('tourn_bpl_2026');
      expect(boundaries, isNotEmpty);

      for (final b in boundaries) {
        expect(b.totalBoundaries, equals(b.fours + b.sixes));
        expect(b.boundaryRuns, equals((b.fours * 4) + (b.sixes * 6)));
      }
    });

    test('Tournament MVP ranks players by fantasy performance points', () {
      final mvps = db.getTournamentMVPList('tourn_bpl_2026');
      expect(mvps, isNotEmpty);

      for (int i = 0; i < mvps.length - 1; i++) {
        expect(mvps[i].points >= mvps[i + 1].points, isTrue);
      }
    });

    test('ICC Points Table calculates matches, points and NRR', () {
      final standings = db.getTournamentStandings('tourn_bpl_2026');
      expect(standings, isNotEmpty);

      for (int i = 0; i < standings.length - 1; i++) {
        expect(standings[i].points >= standings[i + 1].points, isTrue);
      }
    });

    test('Ball-by-ball scoring updates Orange Cap leaderboard in real-time', () {
      // Score a SIX for striker on match_1
      db.recordDelivery(
        inningsId: 'inn_1',
        runsBatter: 6,
        extrasRuns: 0,
        extrasType: ExtrasType.none,
      );

      final updatedBatters = db.getTournamentTopBatters('tourn_bpl_2026');
      final updatedStriker = updatedBatters.firstWhere((b) => b.playerId == 'pl_1');

      expect(updatedStriker.runs, greaterThanOrEqualTo(51));
      expect(updatedStriker.sixes, greaterThanOrEqualTo(2));
    });

    test('Tournament format (overs, venue, name) and teams are fully editable', () {
      final db = MockDatabase();

      final createdTourn = db.createTournament(
        name: 'Initial Cup',
        shortName: 'IC',
        location: 'Ground A',
        overs: 20,
        roomId: 'TOURN-IC',
        totalTeams: 2,
        passcode: '9999',
        createAuction: false,
        customTeamsWithPlayers: [
          {'name': 'Team 1', 'shortName': 'T1', 'color': const Color(0xFF009270), 'players': <Map<String, String>>[]},
          {'name': 'Team 2', 'shortName': 'T2', 'color': const Color(0xFF2563EB), 'players': <Map<String, String>>[]},
        ],
      );

      // Verify initial setup
      expect(createdTourn.overs, equals(20));
      expect(createdTourn.name, equals('Initial Cup'));

      // 1. Edit Tournament Format to 12 overs and new ground
      db.updateTournament(
        tournamentId: createdTourn.id,
        name: 'Premier Box Cup 2026',
        shortName: 'PBC',
        location: 'Indoor Turf Arena',
        overs: 12,
        passcode: '1111',
      );

      final updatedTourn = db.tournaments.firstWhere((t) => t.id == createdTourn.id);
      expect(updatedTourn.name, equals('Premier Box Cup 2026'));
      expect(updatedTourn.shortName, equals('PBC'));
      expect(updatedTourn.location, equals('Indoor Turf Arena'));
      expect(updatedTourn.overs, equals(12));
      expect(updatedTourn.passcode, equals('1111'));

      // 2. Edit Team Details
      final tournTeams = db.teams.where((t) => t.tournamentId == createdTourn.id).toList();
      final teamToEdit = tournTeams.first;

      db.updateTeam(
        teamId: teamToEdit.id,
        name: 'Super Kings XI',
        shortName: 'SKXI',
        primaryColor: const Color(0xFFD97706),
      );

      final editedTeam = db.getTeam(teamToEdit.id);
      expect(editedTeam?.name, equals('Super Kings XI'));
      expect(editedTeam?.shortName, equals('SKXI'));
      expect(editedTeam?.primaryColor, equals(const Color(0xFFD97706)));

      // 3. Add and manage squad players with mobile numbers
      final p1 = db.addPlayerToTeam(
        teamId: teamToEdit.id,
        fullName: 'Rahul Sharma',
        mobileNumber: '9876543210',
        role: PlayerRole.batsman,
      );

      expect(p1.fullName, equals('Rahul Sharma'));
      expect(p1.mobileNumber, equals('9876543210'));
      expect(p1.teamId, equals(teamToEdit.id));

      // Update player details
      db.updatePlayer(
        playerId: p1.id,
        fullName: 'Rahul S. Sharma',
        mobileNumber: '9876500000',
        role: PlayerRole.allRounder,
      );

      final updatedPlayer = db.getPlayer(p1.id);
      expect(updatedPlayer?.fullName, equals('Rahul S. Sharma'));
      expect(updatedPlayer?.mobileNumber, equals('9876500000'));
      expect(updatedPlayer?.role, equals(PlayerRole.allRounder));

      // 4. Delete team
      final teamCountBefore = db.teams.where((t) => t.tournamentId == createdTourn.id).length;
      db.deleteTeam(teamToEdit.id);
      final teamCountAfter = db.teams.where((t) => t.tournamentId == createdTourn.id).length;
      expect(teamCountAfter, equals(teamCountBefore - 1));
      expect(db.getTeam(teamToEdit.id), isNull);
    });
  });
}
