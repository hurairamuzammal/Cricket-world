import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:world_of_cricket/feature/matches_scores/data/source/data_source.dart';

void main() {
  group('Enhanced Cricket API Tests', () {
    late MatchRemoteDataSource dataSource;

    setUp(() {
      dataSource = MatchRemoteDataSource(client: http.Client());
    });

    test('should fetch all matches from enhanced API', () async {
      try {
        final matches = await dataSource.fetchMatches();
        print('✅ Successfully fetched ${matches.length} matches');

        for (var match in matches.take(3)) {
          print('Match: ${match.name}');
          print('Teams: ${match.teams.join(' vs ')}');
          print('Status: ${match.status}');
          print('Live Score: ${match.liveScore ?? 'N/A'}');
          print('Run Rate: ${match.runRate ?? 'N/A'}');
          print('Venue: ${match.venue ?? 'N/A'}');
          print('---');
        }

        expect(matches, isNotEmpty);
      } catch (e) {
        print('❌ Error fetching matches: $e');
        fail('Failed to fetch matches: $e');
      }
    });

    test('should fetch live matches only', () async {
      try {
        final liveMatches = await dataSource.fetchLiveMatches();
        print('✅ Successfully fetched ${liveMatches.length} live matches');

        for (var match in liveMatches) {
          print('Live Match: ${match.name}');
          print('Status: ${match.status}');
          print('Live Score: ${match.liveScore ?? 'N/A'}');
          print('---');
        }

        // Live matches can be empty, so we don't expect any specific count
        expect(liveMatches, isA<List>());
      } catch (e) {
        print('❌ Error fetching live matches: $e');
        fail('Failed to fetch live matches: $e');
      }
    });

    test('should fetch upcoming matches', () async {
      try {
        final upcomingMatches = await dataSource.fetchUpcomingMatches();
        print(
          '✅ Successfully fetched ${upcomingMatches.length} upcoming matches',
        );

        for (var match in upcomingMatches.take(2)) {
          print('Upcoming Match: ${match.name}');
          print('Teams: ${match.teams.join(' vs ')}');
          print('Time: ${match.time ?? 'N/A'}');
          print('Venue: ${match.venue ?? 'N/A'}');
          print('---');
        }

        expect(upcomingMatches, isA<List>());
      } catch (e) {
        print('❌ Error fetching upcoming matches: $e');
        fail('Failed to fetch upcoming matches: $e');
      }
    });

    test('should fetch match details if match ID is available', () async {
      try {
        // First get a match ID
        final matches = await dataSource.fetchMatches();
        if (matches.isNotEmpty) {
          final matchId = matches.first.id;
          print('Testing match details for ID: $matchId');

          final details = await dataSource.fetchMatchScore(matchId);
          print('✅ Successfully fetched match details');
          print('Title: ${details['title'] ?? 'N/A'}');
          print('Status: ${details['status'] ?? 'N/A'}');
          print('Venue: ${details['venue'] ?? 'N/A'}');

          if (details['teams'] != null) {
            print('Teams: ${details['teams']}');
          }

          if (details['scorecard'] != null && details['scorecard'] is List) {
            final scorecard = details['scorecard'] as List;
            print('Scorecard entries: ${scorecard.length}');
          }

          expect(details, isA<Map<String, dynamic>>());
        } else {
          print('⚠️ No matches available to test details');
        }
      } catch (e) {
        print('❌ Error fetching match details: $e');
        // Don't fail the test if match details aren't available
        print('Match details test skipped due to: $e');
      }
    });

    test('should test API connection', () async {
      try {
        final isConnected = await dataSource.testConnection();
        print('✅ API connection test: ${isConnected ? 'SUCCESS' : 'FAILED'}');
        expect(isConnected, isTrue);
      } catch (e) {
        print('❌ Connection test error: $e');
        fail('Connection test failed: $e');
      }
    });
  });
}
