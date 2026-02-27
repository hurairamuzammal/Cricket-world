import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/cricket_models.dart';

class CricketServerApiService {
  // Singleton pattern
  static final CricketServerApiService _instance =
      CricketServerApiService._internal();
  factory CricketServerApiService() => _instance;
  CricketServerApiService._internal();

  // Base URL for the FastAPI server
  static const String baseUrl = 'http://localhost:8001';

  // API Endpoints
  static const String _allMatchesEndpoint = '/api/v1/matches';
  static const String _liveMatchesEndpoint = '/api/v1/matches/live';
  static const String _comprehensiveEndpoint = '/api/v1/matches/comprehensive';
  static const String _statusEndpoint = '/api/v1/status';
  static const String _healthEndpoint = '/health';
  static const String _refreshEndpoint = '/api/v1/refresh';

  // Request timeout duration
  static const Duration _timeoutDuration = Duration(seconds: 10);
  static const Duration _comprehensiveTimeout = Duration(seconds: 30);

  // Check if API is available
  Future<bool> isServerAvailable() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl$_healthEndpoint'))
          .timeout(_timeoutDuration);
      return response.statusCode == 200;
    } catch (e) {
      print('⚠️ Server health check failed: $e');
      return false;
    }
  }

  // Get all matches from server API - sorted by date (older first, future at bottom)
  Future<CricketApiResponse> getAllMatches() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl$_allMatchesEndpoint'))
          .timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        final matches = jsonData
            .map((matchJson) => _convertToFlutterModel(matchJson))
            .toList();

        // Sort by date: older matches first, future matches at bottom
        matches.sort((a, b) {
          final dateA = _parseMatchDate(a.enhancedInfo?.matchDate);
          final dateB = _parseMatchDate(b.enhancedInfo?.matchDate);
          if (dateA == null && dateB == null) return 0;
          if (dateA == null) return 1; // null dates go to end
          if (dateB == null) return -1;
          return dateA.compareTo(dateB); // ascending order (older first)
        });

        return CricketApiResponse(
          success: true,
          data: matches,
          meta: CricketApiMeta(
            totalCount: matches.length,
            filteredCount: matches.length,
            filterType: 'all',
            lastUpdated: DateTime.now().toIso8601String(),
            apiVersion: 'Server-1.0',
          ),
        );
      } else {
        throw Exception('Failed to load matches: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error getting all matches from server: $e');
      return CricketApiResponse(success: false, data: [], error: e.toString());
    }
  }

  // Helper to parse match date string
  DateTime? _parseMatchDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      return null;
    }
  }

  // Get live matches from server API - sorted by date
  Future<CricketApiResponse> getLiveMatches() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl$_liveMatchesEndpoint'))
          .timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        final matches = jsonData
            .map((matchJson) => _convertToFlutterModel(matchJson))
            .toList();

        // Sort by date
        matches.sort((a, b) {
          final dateA = _parseMatchDate(a.enhancedInfo?.matchDate);
          final dateB = _parseMatchDate(b.enhancedInfo?.matchDate);
          if (dateA == null && dateB == null) return 0;
          if (dateA == null) return 1;
          if (dateB == null) return -1;
          return dateA.compareTo(dateB);
        });

        return CricketApiResponse(
          success: true,
          data: matches,
          meta: CricketApiMeta(
            totalCount: matches.length,
            filteredCount: matches.length,
            filterType: 'live',
            lastUpdated: DateTime.now().toIso8601String(),
            apiVersion: 'Server-1.0',
          ),
        );
      } else {
        throw Exception('Failed to load live matches: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error getting live matches from server: $e');
      return CricketApiResponse(success: false, data: [], error: e.toString());
    }
  }

  /// Get comprehensive match data with full details (batsmen, bowlers, scorecard, etc.)
  Future<Map<String, dynamic>> getComprehensiveMatches() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl$_comprehensiveEndpoint'))
          .timeout(_comprehensiveTimeout);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to load comprehensive matches: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error getting comprehensive matches: $e');
      return {'success': false, 'error': e.toString(), 'data': []};
    }
  }

  /// Get detailed data for a specific match including batsmen, bowlers, partnerships
  Future<Map<String, dynamic>> getMatchDetails(String matchId) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/v1/matches/$matchId/details'))
          .timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        throw Exception('Match not found');
      } else {
        throw Exception('Failed to load match details: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error getting match details: $e');
      rethrow;
    }
  }

  /// Get full scorecard for a match including all innings, batsmen, and bowlers
  Future<Map<String, dynamic>> getMatchScorecard(String matchId) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/v1/matches/$matchId/scorecard'))
          .timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        throw Exception('Match not found');
      } else {
        throw Exception('Failed to load scorecard: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error getting match scorecard: $e');
      rethrow;
    }
  }

  /// Get recent commentary for a match
  Future<Map<String, dynamic>> getMatchCommentary(String matchId) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/v1/matches/$matchId/commentary'))
          .timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        throw Exception('Match not found');
      } else {
        throw Exception('Failed to load commentary: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error getting match commentary: $e');
      rethrow;
    }
  }

  /// Get current live state of a match (quick endpoint for polling)
  Future<Map<String, dynamic>> getMatchLiveState(String matchId) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/v1/matches/$matchId/live'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        throw Exception('Match not found');
      } else {
        throw Exception('Failed to load live state: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error getting match live state: $e');
      rethrow;
    }
  }

  // Get server status
  Future<Map<String, dynamic>> getServerStatus() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl$_statusEndpoint'))
          .timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get server status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error getting server status: $e');
      return {'error': e.toString(), 'is_running': false};
    }
  }

  // Manually trigger data refresh on the server
  Future<Map<String, dynamic>> refreshServerData() async {
    try {
      final response = await http
          .post(Uri.parse('$baseUrl$_refreshEndpoint'))
          .timeout(const Duration(seconds: 30)); // Longer timeout for refresh

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to refresh data: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error refreshing server data: $e');
      return {'error': e.toString(), 'success': false};
    }
  }

  /// Register device on the server using its hash
  Future<bool> registerDevice(String deviceHash) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/v1/devices/register'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'device_hash': deviceHash}),
          )
          .timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      print('❌ Error registering device: $e');
      return false;
    }
  }

  /// Check if device is already registered on the server
  Future<bool> isDeviceRegistered(String deviceHash) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/v1/devices/check/$deviceHash'))
          .timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['is_registered'] ?? false;
      }
      return false;
    } catch (e) {
      print('❌ Error checking device registration: $e');
      return false;
    }
  }

  // Convert JSON from server API to Flutter CricketMatch model
  CricketMatch _convertToFlutterModel(Map<String, dynamic> json) {
    // Extract full team names
    final team1Name = json['team1']?.toString() ?? 'Unknown Team 1';
    final team2Name = json['team2']?.toString() ?? 'Unknown Team 2';

    // Extract scores - format as "runs/wickets" if available
    String team1Score = '';
    String team2Score = '';

    if (json['team1_score'] != null) {
      team1Score = json['team1_score'].toString();
      if (json['team1_wickets'] != null) {
        team1Score = '$team1Score/${json['team1_wickets']}';
      }
    }

    if (json['team2_score'] != null) {
      team2Score = json['team2_score'].toString();
      if (json['team2_wickets'] != null) {
        team2Score = '$team2Score/${json['team2_wickets']}';
      }
    }

    // Create teams with full data
    List<TeamData> teams = [
      TeamData(
        name: team1Name,
        score: team1Score,
        overs: '',
        wickets: json['team1_wickets']?.toString() ?? '',
        runRate: '',
      ),
      TeamData(
        name: team2Name,
        score: team2Score,
        overs: '',
        wickets: json['team2_wickets']?.toString() ?? '',
        runRate: '',
      ),
    ];

    // Determine live status
    String liveStatus = 'unknown';
    final statusRaw = json['match_status']?.toString().toLowerCase() ?? '';
    if (statusRaw == 'live' || statusRaw.contains('live')) {
      liveStatus = 'live';
    } else if (statusRaw.contains('completed') ||
        statusRaw.contains('result')) {
      liveStatus = 'completed';
    } else if (statusRaw.contains('scheduled') ||
        statusRaw.contains('upcoming')) {
      liveStatus = 'upcoming';
    }

    // Build status text - use result if available for completed matches
    String statusText = json['match_status']?.toString() ?? 'Unknown Status';
    if (liveStatus == 'completed' &&
        json['result'] != null &&
        json['result'].toString().isNotEmpty) {
      statusText = json['result'].toString();
    }

    // Get actual match start time for date grouping
    String? matchStartTime =
        json['start_time']?.toString() ??
        json['startTime']?.toString() ??
        json['match_date']?.toString() ??
        json['startDateTime']?.toString();

    // DEBUG LOG
    print(
      'DEBUG: Match ${json['match_id']} ($team1Name vs $team2Name) start_time: "$matchStartTime"',
    );

    // Create enhanced info with result and proper date
    final enhancedInfo = EnhancedMatchInfo(
      matchDate: matchStartTime, // Use start_time for date grouping
      matchTime: json['match_time']?.toString(),
      city: json['venue']?.toString(),
      state: null,
      country: null,
      result: json['result']?.toString(),
      qualityScore: null,
      originalTitle: '$team1Name vs $team2Name',
      originalDescription: json['result']?.toString() ?? statusText,
    );

    return CricketMatch(
      id:
          json['match_id']?.toString() ??
          'unknown_${DateTime.now().millisecondsSinceEpoch}',
      title: '$team1Name vs $team2Name',
      series: json['series_name']?.toString() ?? 'Unknown Series',
      status: statusText,
      teams: teams,
      venue: json['venue']?.toString() ?? 'Unknown Venue',
      matchType: json['match_format']?.toString() ?? 'Unknown Format',
      url: json['match_url']?.toString() ?? '',
      liveStatus: liveStatus,
      source: 'Cricket API Server',
      lastUpdated:
          matchStartTime ??
          DateTime.now().toIso8601String(), // Use start_time for date grouping
      enhancedInfo: enhancedInfo,
    );
  }
}
