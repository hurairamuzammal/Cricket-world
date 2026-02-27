import '../models/cricket_models.dart';
import 'cricket_server_api_service.dart';
import 'local_cricket_data_service.dart';

class CricketApiService {
  // Singleton
  static final CricketApiService _instance = CricketApiService._internal();
  factory CricketApiService() => _instance;
  CricketApiService._internal();

  // PRIMARY: Your local Scrapy server (fresh data!)
  final CricketServerApiService _serverApiService = CricketServerApiService();

  // FALLBACK: Local asset files (only if server is down)
  final LocalCricketDataService _localDataService = LocalCricketDataService();

  // Flag to track server availability
  bool _serverAvailable = true;
  DateTime? _lastServerCheck;
  static const Duration _serverCheckInterval = Duration(seconds: 30);

  // Check if server is available
  Future<bool> _checkServerAvailable() async {
    // Only check every 30 seconds
    if (_lastServerCheck != null &&
        DateTime.now().difference(_lastServerCheck!) < _serverCheckInterval) {
      return _serverAvailable;
    }

    try {
      _serverAvailable = await _serverApiService.isServerAvailable();
      _lastServerCheck = DateTime.now();
      print(
        _serverAvailable
            ? '✅ Server is available at localhost:8001'
            : '⚠️ Server is not available, using fallback',
      );
      return _serverAvailable;
    } catch (e) {
      print('⚠️ Server check failed: $e');
      _serverAvailable = false;
      _lastServerCheck = DateTime.now();
      return false;
    }
  }

  // Get all matches - SERVER FIRST, then fallback
  Future<CricketApiResponse> getAllMatches({bool refresh = false}) async {
    try {
      // Always try server first
      if (await _checkServerAvailable()) {
        try {
          print('🌐 Fetching ALL matches from server (localhost:8001)');
          return await _serverApiService.getAllMatches();
        } catch (e) {
          print('⚠️ Server failed: $e');
          _serverAvailable = false;
        }
      }

      // Fallback to local data
      print('📂 Using local fallback data');
      return await _localDataService.getAllMatches(refresh: refresh);
    } catch (e) {
      throw Exception('Error getting matches: $e');
    }
  }

  // Get live matches - SERVER FIRST (fresh every 10 seconds!)
  Future<CricketApiResponse> getLiveMatches() async {
    try {
      // Always try server first for live matches
      if (await _checkServerAvailable()) {
        try {
          print('🔴 Fetching LIVE matches from server');
          return await _serverApiService.getLiveMatches();
        } catch (e) {
          print('⚠️ Server failed for live matches: $e');
          _serverAvailable = false;
        }
      }

      // Fallback
      print('📂 Using local fallback for live matches');
      return await _localDataService.getLiveMatches();
    } catch (e) {
      throw Exception('Error getting live matches: $e');
    }
  }

  // Get upcoming matches
  Future<CricketApiResponse> getUpcomingMatches() async {
    try {
      if (await _checkServerAvailable()) {
        try {
          // Server returns all matches, filter for upcoming
          final response = await _serverApiService.getAllMatches();
          if (response.success) {
            final upcoming = response.data
                .where(
                  (m) =>
                      m.liveStatus.toLowerCase() == 'upcoming' ||
                      m.status.toLowerCase().contains('scheduled'),
                )
                .toList();
            return CricketApiResponse(
              success: true,
              data: upcoming,
              meta: CricketApiMeta(
                totalCount: response.data.length,
                filteredCount: upcoming.length,
                filterType: 'upcoming',
                lastUpdated: DateTime.now().toIso8601String(),
                apiVersion: 'Server-1.0',
              ),
            );
          }
        } catch (e) {
          print('⚠️ Server failed for upcoming: $e');
        }
      }

      return await _localDataService.getUpcomingMatches();
    } catch (e) {
      throw Exception('Error getting upcoming matches: $e');
    }
  }

  // Get recent/completed matches
  Future<CricketApiResponse> getRecentMatches() async {
    try {
      if (await _checkServerAvailable()) {
        try {
          final response = await _serverApiService.getAllMatches();
          if (response.success) {
            final recent = response.data
                .where(
                  (m) =>
                      m.liveStatus.toLowerCase() == 'completed' ||
                      m.status.toLowerCase().contains('won') ||
                      m.status.toLowerCase().contains('result'),
                )
                .toList();
            return CricketApiResponse(
              success: true,
              data: recent,
              meta: CricketApiMeta(
                totalCount: response.data.length,
                filteredCount: recent.length,
                filterType: 'recent',
                lastUpdated: DateTime.now().toIso8601String(),
                apiVersion: 'Server-1.0',
              ),
            );
          }
        } catch (e) {
          print('⚠️ Server failed for recent: $e');
        }
      }

      return await _localDataService.getRecentMatches();
    } catch (e) {
      throw Exception('Error getting recent matches: $e');
    }
  }

  // Get match details
  Future<CricketMatch> getMatchDetails(String matchId) async {
    try {
      if (await _checkServerAvailable()) {
        try {
          final response = await _serverApiService.getAllMatches();
          if (response.success) {
            final match = response.data.firstWhere(
              (m) => m.id == matchId,
              orElse: () => throw Exception('Match not found'),
            );
            return match;
          }
        } catch (e) {
          print('⚠️ Server failed for match details: $e');
        }
      }

      return await _localDataService.getMatchDetails(matchId);
    } catch (e) {
      throw Exception('Error getting match details: $e');
    }
  }

  Future<CricketMatch> getDetailedMatchInfo(String matchId) async {
    return getMatchDetails(matchId);
  }

  // Get team matches
  Future<CricketApiResponse> getTeamMatches(String teamName) async {
    try {
      if (await _checkServerAvailable()) {
        try {
          final response = await _serverApiService.getAllMatches();
          if (response.success) {
            final teamMatches = response.data
                .where(
                  (m) => m.teams.any(
                    (t) =>
                        t.name.toLowerCase().contains(teamName.toLowerCase()),
                  ),
                )
                .toList();
            return CricketApiResponse(
              success: true,
              data: teamMatches,
              meta: CricketApiMeta(
                totalCount: response.data.length,
                filteredCount: teamMatches.length,
                filterType: 'team:$teamName',
                lastUpdated: DateTime.now().toIso8601String(),
                apiVersion: 'Server-1.0',
              ),
            );
          }
        } catch (e) {
          print('⚠️ Server failed for team matches: $e');
        }
      }

      return await _localDataService.getTeamMatches(teamName);
    } catch (e) {
      throw Exception('Error getting team matches: $e');
    }
  }

  // Refresh - triggers server refresh
  Future<Map<String, dynamic>> refreshMatches() async {
    try {
      if (await _checkServerAvailable()) {
        return await _serverApiService.refreshServerData();
      }
      return await _localDataService.refreshMatches();
    } catch (e) {
      throw Exception('Error refreshing: $e');
    }
  }

  // Health status
  Future<Map<String, dynamic>> getHealthStatus() async {
    try {
      if (await _checkServerAvailable()) {
        return await _serverApiService.getServerStatus();
      }
      return await _localDataService.getHealthStatus();
    } catch (e) {
      throw Exception('Error getting health: $e');
    }
  }

  // API statistics
  Future<ApiStatistics> getApiStatistics() async {
    try {
      if (await _checkServerAvailable()) {
        final status = await _serverApiService.getServerStatus();
        return ApiStatistics(
          overview: ApiOverview(
            totalMatches: status['total_matches'] ?? 0,
            liveMatches: status['live_matches'] ?? 0,
            completedMatches: 0,
            upcomingMatches: 0,
            upcomingLimitedTo: 10,
            lastUpdate: status['last_full_update'] ?? status['last_update'],
            scraperRunning: status['is_running'] ?? false,
            updateIntervalSeconds: 10,
          ),
          teams: {},
          features: {
            'server_connected': true,
            'live_updates': true,
            'dual_pipeline': true,
          },
        );
      }
      return await _localDataService.getApiStatistics();
    } catch (e) {
      throw Exception('Error getting stats: $e');
    }
  }

  // Check API availability
  Future<bool> isApiAvailable() async {
    return await _checkServerAvailable();
  }

  // Helper: safe retrieval
  Future<List<CricketMatch>> getMatchesSafely({String type = 'all'}) async {
    try {
      final CricketApiResponse response;
      switch (type) {
        case 'live':
          response = await getLiveMatches();
          break;
        case 'upcoming':
          response = await getUpcomingMatches();
          break;
        case 'recent':
          response = await getRecentMatches();
          break;
        default:
          response = await getAllMatches();
      }
      if (response.success) return response.data;
      throw Exception(response.error ?? 'Unknown error');
    } catch (_) {
      return [];
    }
  }
}

// Extensions
extension CricketMatchExtensions on CricketMatch {
  bool get isLive {
    if (liveStatus.toLowerCase() == 'live') return true;
    final statusLower = status.toLowerCase();
    return statusLower.contains('in progress') ||
        statusLower.contains('live') ||
        statusLower.contains('ongoing') ||
        statusLower.contains('innings') ||
        statusLower.contains('batting');
  }

  bool get isUpcoming {
    if (liveStatus.toLowerCase() == 'upcoming') return true;
    final statusLower = status.toLowerCase();
    return statusLower.contains('upcoming') ||
        statusLower.contains('scheduled') ||
        statusLower.contains('fixture');
  }

  bool get isCompleted {
    if (liveStatus.toLowerCase() == 'completed') return true;
    return !isLive && !isUpcoming;
  }

  String get formattedTeams {
    if (teams.length >= 2) return '${teams[0].name} vs ${teams[1].name}';
    if (teams.isNotEmpty) return teams[0].name;
    return 'Unknown Teams';
  }

  String get currentScore {
    if (teams.isEmpty) return 'No score available';
    return teams.map((t) => '${t.name}: ${t.score}').join('\n');
  }
}
