import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/cricket_models.dart';
import '../constants/api_constants.dart';

class CricketDataOrgApiService {
  // Singleton pattern
  static final CricketDataOrgApiService _instance =
      CricketDataOrgApiService._internal();
  factory CricketDataOrgApiService() => _instance;
  CricketDataOrgApiService._internal();

  // Request timeout duration
  static const Duration _timeoutDuration = Duration(seconds: 10);

  /// Get all current matches from cricketdata.org
  Future<CricketApiResponse> getCurrentMatches({int offset = 0}) async {
    try {
      final url = ApiConstants.buildApiUrl(
        ApiConstants.currentMatchesEndpoint,
        queryParams: {'offset': offset.toString()},
      );

      final response = await http.get(Uri.parse(url)).timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final cricketDataResponse = CricketDataOrgResponse.fromJson(jsonData);
        return cricketDataResponse.toCricketApiResponse();
      } else {
        throw Exception('HTTP ${response.statusCode}: Failed to fetch matches');
      }
    } catch (e) {
      throw Exception('Error fetching current matches: $e');
    }
  }

  /// Get live matches (filter current matches for live ones)
  Future<CricketApiResponse> getLiveMatches({int offset = 0}) async {
    try {
      final allMatches = await getCurrentMatches(offset: offset);
      final liveMatches = allMatches.data
          .where(
            (match) =>
                match.liveStatus == 'live' ||
                match.status.toLowerCase().contains('live') ||
                (!match.status.toLowerCase().contains('not started') &&
                    !match.status.toLowerCase().contains('won by')),
          )
          .toList();

      return CricketApiResponse(
        success: true,
        data: liveMatches,
        meta: CricketApiMeta(
          totalCount: liveMatches.length,
          filteredCount: liveMatches.length,
          filterType: 'live',
          lastUpdated: DateTime.now().toIso8601String(),
          apiVersion: 'CricketData.org-1.0',
        ),
      );
    } catch (e) {
      throw Exception('Error fetching live matches: $e');
    }
  }

  /// Get upcoming matches (filter current matches for upcoming ones)
  Future<CricketApiResponse> getUpcomingMatches({int offset = 0}) async {
    try {
      final allMatches = await getCurrentMatches(offset: offset);
      final upcomingMatches = allMatches.data
          .where(
            (match) =>
                match.liveStatus == 'upcoming' ||
                match.status.toLowerCase().contains('not started'),
          )
          .toList();

      return CricketApiResponse(
        success: true,
        data: upcomingMatches,
        meta: CricketApiMeta(
          totalCount: upcomingMatches.length,
          filteredCount: upcomingMatches.length,
          filterType: 'upcoming',
          lastUpdated: DateTime.now().toIso8601String(),
          apiVersion: 'CricketData.org-1.0',
        ),
      );
    } catch (e) {
      throw Exception('Error fetching upcoming matches: $e');
    }
  }

  /// Get recent/completed matches (filter current matches for completed ones)
  Future<CricketApiResponse> getRecentMatches({int offset = 0}) async {
    try {
      final allMatches = await getCurrentMatches(offset: offset);
      final recentMatches = allMatches.data
          .where(
            (match) =>
                match.liveStatus == 'completed' ||
                match.status.toLowerCase().contains('won by'),
          )
          .toList();

      return CricketApiResponse(
        success: true,
        data: recentMatches,
        meta: CricketApiMeta(
          totalCount: recentMatches.length,
          filteredCount: recentMatches.length,
          filterType: 'completed',
          lastUpdated: DateTime.now().toIso8601String(),
          apiVersion: 'CricketData.org-1.0',
        ),
      );
    } catch (e) {
      throw Exception('Error fetching recent matches: $e');
    }
  }

  /// Get detailed match information using cricScore endpoint
  Future<CricketMatch> getMatchDetails(String matchId) async {
    try {
      final url = ApiConstants.buildApiUrl(
        ApiConstants.cricScoreEndpoint,
        queryParams: {'unique_id': matchId},
      );

      final response = await http.get(Uri.parse(url)).timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData['data'] != null &&
            jsonData['data'] is List &&
            jsonData['data'].isNotEmpty) {
          // Find the match with the matching ID
          for (var matchData in jsonData['data']) {
            if (matchData['id'] == matchId) {
              return CricketMatch.fromCricketDataOrg(matchData);
            }
          }
          // If no exact match found, return the first one (fallback)
          return CricketMatch.fromCricketDataOrg(jsonData['data'][0]);
        } else {
          throw Exception('No match data found for ID: $matchId');
        }
      } else {
        throw Exception(
          'HTTP ${response.statusCode}: Failed to fetch match details',
        );
      }
    } catch (e) {
      throw Exception('Error fetching match details: $e');
    }
  }

  /// Get team matches (filter all matches by team name)
  Future<CricketApiResponse> getTeamMatches(String teamName) async {
    try {
      final allMatches = await getCurrentMatches();
      final teamMatches = allMatches.data
          .where(
            (match) => match.teams.any(
              (team) =>
                  team.name.toLowerCase().contains(teamName.toLowerCase()) ||
                  (team.shortName?.toLowerCase().contains(
                        teamName.toLowerCase(),
                      ) ??
                      false),
            ),
          )
          .toList();

      return CricketApiResponse(
        success: true,
        data: teamMatches,
        meta: CricketApiMeta(
          totalCount: teamMatches.length,
          filteredCount: teamMatches.length,
          filterType: 'team:$teamName',
          lastUpdated: DateTime.now().toIso8601String(),
          apiVersion: 'CricketData.org-1.0',
        ),
      );
    } catch (e) {
      throw Exception('Error fetching team matches: $e');
    }
  }

  /// Check API health status
  Future<Map<String, dynamic>> getHealthStatus() async {
    try {
      // Test the API by making a simple request
      final response = await getCurrentMatches();
      return {
        'status': 'healthy',
        'api_available': true,
        'total_matches': response.data.length,
        'last_check': DateTime.now().toIso8601String(),
        'source': 'CricketData.org',
      };
    } catch (e) {
      return {
        'status': 'unhealthy',
        'api_available': false,
        'error': e.toString(),
        'last_check': DateTime.now().toIso8601String(),
        'source': 'CricketData.org',
      };
    }
  }

  /// Check if API is available
  Future<bool> isApiAvailable() async {
    try {
      await getCurrentMatches();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Get API statistics (mock implementation)
  Future<ApiStatistics> getApiStatistics() async {
    try {
      final allMatches = await getCurrentMatches();
      final liveMatches = await getLiveMatches();
      final upcomingMatches = await getUpcomingMatches();
      final recentMatches = await getRecentMatches();

      return ApiStatistics(
        overview: ApiOverview(
          totalMatches: allMatches.data.length,
          liveMatches: liveMatches.data.length,
          completedMatches: recentMatches.data.length,
          upcomingMatches: upcomingMatches.data.length,
          upcomingLimitedTo: 50,
          lastUpdate: DateTime.now().toIso8601String(),
          scraperRunning: true, // Assume cricketdata.org is always running
          updateIntervalSeconds: 300, // 5 minutes
        ),
        teams: {},
        features: {
          'live_scores': true,
          'upcoming_matches': true,
          'recent_matches': true,
          'team_filters': true,
        },
      );
    } catch (e) {
      throw Exception('Error fetching API statistics: $e');
    }
  }

  /// Refresh matches (no-op for cricketdata.org as it's always live)
  Future<Map<String, dynamic>> refreshMatches() async {
    return {
      'success': true,
      'message': 'CricketData.org API is always live, no refresh needed',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
