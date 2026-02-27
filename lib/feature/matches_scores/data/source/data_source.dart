import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:world_of_cricket/core/constants/api_constants.dart';
import 'package:world_of_cricket/feature/matches_scores/data/model/cricket_api_models.dart';

class MatchRemoteDataSource {
  final http.Client client;

  MatchRemoteDataSource({required this.client});

  /// Fetch all matches from LOCAL cricket server (localhost:8000)
  /// This uses your cleaned_cricket_data.json via cricket_server.py
  Future<List<MatchModel>> fetchMatches({int offset = 0}) async {
    try {
      print('🔄 Fetching matches from LOCAL server: ${ApiConstants.cricApiBaseUrl}${ApiConstants.allMatchesEndpoint}');
      
      final response = await client
          .get(
            Uri.parse(
              '${ApiConstants.cricApiBaseUrl}${ApiConstants.allMatchesEndpoint}',
            ),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Handle LOCAL server response (returns List directly from cleaned_cricket_data.json)
        if (data is List) {
          print('✅ Loaded ${data.length} matches from LOCAL server');
          return data.map((match) => MatchModel.fromJson(match)).toList();
        } else if (data is Map && data['matches'] != null) {
          // Fallback for wrapped format
          final matchesList = data['matches'] as List;
          print('✅ Loaded ${matchesList.length} matches from LOCAL server (wrapped)');
          return matchesList
              .map((match) => MatchModel.fromJson(match))
              .toList();
        }
        print('⚠️ No matches found in LOCAL server response');
        return [];
      } else {
        print('❌ LOCAL server returned status code: ${response.statusCode}');
        throw Exception('Failed to load matches from LOCAL server: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching matches from LOCAL server: $e');
      throw Exception('Failed to fetch matches from LOCAL server: $e');
    }
  }

  /// Fetch live matches from LOCAL cricket server
  /// Uses the /api/v1/matches/live endpoint
  Future<List<MatchModel>> fetchLiveMatches() async {
    try {
      print('🔴 Fetching LIVE matches from LOCAL server: ${ApiConstants.cricApiBaseUrl}${ApiConstants.liveMatchesEndpoint}');
      
      final response = await client
          .get(
            Uri.parse(
              '${ApiConstants.cricApiBaseUrl}${ApiConstants.liveMatchesEndpoint}',
            ),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is List) {
          print('✅ Loaded ${data.length} LIVE matches from LOCAL server');
          return data.map((match) => MatchModel.fromJson(match)).toList();
        } else if (data is Map && data['matches'] != null) {
          final matchesList = data['matches'] as List;
          print('✅ Loaded ${matchesList.length} LIVE matches from LOCAL server (wrapped)');
          return matchesList
              .map((match) => MatchModel.fromJson(match))
              .toList();
        }
        print('⚠️ No LIVE matches found in LOCAL server response');
        return [];
      } else {
        print('❌ LOCAL server returned status code: ${response.statusCode}');
        throw Exception('Failed to load live matches from LOCAL server: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching live matches from LOCAL server: $e');
      throw Exception('Failed to fetch live matches from LOCAL server: $e');
    }
  }

  /// Fetch upcoming matches from LOCAL cricket server
  /// Filters matches by status='upcoming' or 'scheduled'
  Future<List<MatchModel>> fetchUpcomingMatches() async {
    try {
      print('📅 Fetching UPCOMING matches from LOCAL server');
      
      final response = await client
          .get(
            Uri.parse(
              '${ApiConstants.cricApiBaseUrl}${ApiConstants.allMatchesEndpoint}',
            ),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<MatchModel> allMatches = [];

        if (data is List) {
          allMatches = data.map((match) => MatchModel.fromJson(match)).toList();
        } else if (data is Map && data['matches'] != null) {
          final matchesList = data['matches'] as List;
          allMatches = matchesList
              .map((match) => MatchModel.fromJson(match))
              .toList();
        }

        // Filter for upcoming/scheduled matches
        final upcomingMatches = allMatches.where((match) {
          final status = match.status.toLowerCase();
          return status.contains('upcoming') || 
                 status.contains('scheduled') ||
                 status.contains('yet to begin');
        }).toList();

        print('✅ Loaded ${upcomingMatches.length} UPCOMING matches from LOCAL server');
        return upcomingMatches;
      } else {
        print('❌ LOCAL server returned status code: ${response.statusCode}');
        throw Exception('Failed to load upcoming matches from LOCAL server: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching upcoming matches from LOCAL server: $e');
      throw Exception('Failed to fetch upcoming matches from LOCAL server: $e');
    }
  }

  /// Fetch completed matches from LOCAL cricket server
  /// Filters matches by status='completed'
  Future<List<CompletedMatchModel>> fetchCompletedMatches() async {
    try {
      print('✔️ Fetching COMPLETED matches from LOCAL server');
      
      final response = await client
          .get(
            Uri.parse(
              '${ApiConstants.cricApiBaseUrl}${ApiConstants.allMatchesEndpoint}',
            ),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> matchesList = [];

        if (data is List) {
          matchesList = data;
        } else if (data is Map && data['matches'] != null) {
          matchesList = data['matches'] as List;
        }

        // Filter for completed matches and convert to CompletedMatchModel
        final completedMatches = matchesList.where((matchJson) {
          final status = (matchJson['match_status'] ?? matchJson['status'] ?? '').toString().toLowerCase();
          return status.contains('completed') || 
                 status.contains('result') ||
                 matchJson['result'] != null;
        }).map((match) => CompletedMatchModel.fromJson(match)).toList();

        print('✅ Loaded ${completedMatches.length} COMPLETED matches from LOCAL server');
        return completedMatches;
      } else {
        print('❌ LOCAL server returned status code: ${response.statusCode}');
        throw Exception('Failed to load completed matches from LOCAL server: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching completed matches from LOCAL server: $e');
      throw Exception('Failed to fetch completed matches from LOCAL server: $e');
    }
  }

  /// Fetch specific match score/details from LOCAL cricket server
  /// Uses the /api/v1/matches/{match_id} endpoint
  Future<Map<String, dynamic>> fetchMatchScore(String matchId) async {
    try {
      print('🔍 Fetching match details for ID: $matchId from LOCAL server');
      
      final response = await client
          .get(
            Uri.parse(
              '${ApiConstants.cricApiBaseUrl}${ApiConstants.matchDetailsEndpoint}/$matchId',
            ),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Loaded match details for $matchId from LOCAL server');
        return data;
      } else {
        print('❌ LOCAL server returned status code: ${response.statusCode}');
        throw Exception('Failed to load match score from LOCAL server: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching match score from LOCAL server: $e');
      throw Exception('Failed to fetch match score from LOCAL server: $e');
    }
  }

  /// Fetch all detailed scores from LOCAL cricket server
  Future<Map<String, dynamic>> fetchAllDetailedScores() async {
    try {
      print('📊 Fetching all detailed scores from LOCAL server');
      
      final response = await client
          .get(
            Uri.parse(
              '${ApiConstants.cricApiBaseUrl}${ApiConstants.allMatchesEndpoint}',
            ),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Loaded all detailed scores from LOCAL server');
        
        // Return in expected format
        if (data is List) {
          return {'matches': data};
        }
        return data;
      } else {
        print('❌ LOCAL server returned status code: ${response.statusCode}');
        throw Exception('Failed to load detailed scores from LOCAL server: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching detailed scores from LOCAL server: $e');
      throw Exception('Failed to fetch detailed scores from LOCAL server: $e');
    }
  }

  /// Fetch match result from LOCAL cricket server
  Future<MatchResultModel> fetchMatchResult(String matchId) async {
    try {
      print('🏆 Fetching match result for ID: $matchId from LOCAL server');
      
      // Use the match details endpoint to get result information
      final response = await client
          .get(
            Uri.parse(
              '${ApiConstants.cricApiBaseUrl}${ApiConstants.matchDetailsEndpoint}/$matchId',
            ),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Loaded match result for $matchId from LOCAL server');
        return MatchResultModel.fromJson(data);
      } else {
        print('❌ LOCAL server returned status code: ${response.statusCode}');
        throw Exception('Failed to load match result from LOCAL server: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching match result from LOCAL server: $e');
      throw Exception('Failed to fetch match result from LOCAL server: $e');
    }
  }

  /// Test connection to LOCAL cricket server
  Future<bool> testConnection() async {
    try {
      print('🔌 Testing connection to LOCAL cricket server...');
      
      final response = await client
          .get(
            Uri.parse(
              '${ApiConstants.cricApiBaseUrl}${ApiConstants.serverHealthEndpoint}',
            ),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      final isConnected = response.statusCode == 200;
      if (isConnected) {
        print('✅ LOCAL cricket server is ONLINE');
      } else {
        print('❌ LOCAL cricket server returned status: ${response.statusCode}');
      }
      return isConnected;
    } catch (e) {
      print('❌ LOCAL cricket server is OFFLINE or unreachable: $e');
      return false;
    }
  }
}
