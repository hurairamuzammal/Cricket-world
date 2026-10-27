import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import '../models/cricket_models.dart';

class LocalCricketDataService {
  static const String _dataFilePath =
      'assets/data/cleaned_cricket_data.json';

  // Singleton pattern
  static final LocalCricketDataService _instance =
      LocalCricketDataService._internal();
  factory LocalCricketDataService() => _instance;
  LocalCricketDataService._internal();

  List<CricketMatch>? _cachedMatches;
  DateTime? _lastLoadTime;
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  /// Load cricket data from the local JSON file
  Future<List<CricketMatch>> _loadMatchesFromFile() async {
    try {
      // Check if we need to reload data
      if (_cachedMatches != null &&
          _lastLoadTime != null &&
          DateTime.now().difference(_lastLoadTime!) < _cacheValidDuration) {
        return _cachedMatches!;
      }

      String jsonContent = '';
      try {
        // Try multiple paths in order of preference - prioritize assets for Flutter
        final paths = [
          'assets/data/cleaned_cricket_data.json',
          _dataFilePath,
        ];

        bool fileFound = false;
        for (String path in paths) {
          try {
            if (path.startsWith('assets/')) {
              jsonContent = await rootBundle.loadString(path);
              print('✅ Successfully loaded data from assets: $path');
              fileFound = true;
              break;
            } else {
              final currentDir = Directory.current;
              final dataFile = File('${currentDir.path}/$path');
              if (await dataFile.exists()) {
                jsonContent = await dataFile.readAsString();
                print('✅ Successfully loaded data from: ${dataFile.path}');
                fileFound = true;
                break;
              } else {
                print('⚠️ File not found: ${dataFile.path}');
                continue;
              }
            }
          } catch (e) {
            print('⚠️ Failed to load from $path: $e');
            continue;
          }
        }

        if (!fileFound || jsonContent.trim().isEmpty) {
          print('ℹ️ No local data file found');
          return [];
        }
      } catch (e) {
        print('⚠️ Error reading data file: $e');
        return [];
      }

      final List<dynamic> jsonData = json.decode(jsonContent);

      final matches = jsonData
          .map((matchJson) => _convertToFlutterModel(matchJson))
          .toList();

      // Cache the results
      _cachedMatches = matches;
      _lastLoadTime = DateTime.now();

      return matches;
    } catch (e) {
      print('❌ Critical error in _loadMatchesFromFile: $e');
      throw Exception('Failed to load cricket data: $e');
    }
  }

  /// Convert JSON from local match dataset to Flutter CricketMatch model with AI-enhanced mapping
  CricketMatch _convertToFlutterModel(Map<String, dynamic> json) {
    // Smart team extraction
    final teams = _extractTeamsWithScores(json);

    // Smart venue extraction
    final venue = _extractVenue(json);

    // Smart title generation
    final title = _generateTitle(json, teams);

    // Smart status determination
    final liveStatus = _determineLiveStatus(json);

    // Smart series extraction
    final series = _extractSeries(json);

    // Smart match type extraction
    final matchType = _extractMatchType(json);

    // Create enhanced info object
    final enhancedInfo = EnhancedMatchInfo(
      matchDate: json['match_date']?.toString(),
      matchTime: json['match_time']?.toString(),
      dayNight: json['day_night']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      country: json['country']?.toString(),
      matchNumber: _parseToInt(json['match_number']),
      targetScore: _parseToInt(json['target_score']),
      ballsRemaining: _parseToInt(json['balls_remaining']),
      result: json['result']?.toString(),
      margin: json['margin']?.toString(),
      tossWinner: json['toss_winner']?.toString(),
      tossDecision: json['toss_decision']?.toString(),
      qualityScore: _parseToDouble(json['quality_score']),
      originalTitle: json['original_title']?.toString(),
      originalDescription: json['original_description']?.toString(),
    );

    return CricketMatch(
      id: json['match_id']?.toString() ?? _generateId(),
      title: title,
      series: series,
      status: _getFormattedStatus(json, enhancedInfo),
      teams: teams,
      venue: venue,
      matchType: matchType,
      url: json['match_url']?.toString() ?? '',
      liveStatus: liveStatus,
      source: 'ESPNCricinfo Scrapy (AI-Enhanced)',
      lastUpdated:
          json['extraction_timestamp']?.toString() ??
          DateTime.now().toIso8601String(),
      enhancedInfo: enhancedInfo,
    );
  }

  /// Extract teams with intelligent score parsing
  List<TeamData> _extractTeamsWithScores(Map<String, dynamic> json) {
    final teams = <TeamData>[];

    // Primary team extraction
    String team1 = _cleanTeamName(json['team1']?.toString() ?? '');
    String team2 = _cleanTeamName(json['team2']?.toString() ?? '');

    // Fallback: Extract from title if teams are missing
    if (team1.isEmpty || team2.isEmpty) {
      final extractedTeams = _extractTeamsFromTitle(json);
      if (extractedTeams.length >= 2) {
        team1 = team1.isEmpty ? extractedTeams[0] : team1;
        team2 = team2.isEmpty ? extractedTeams[1] : team2;
      }
    }

    // Extract scores from description if available
    final scoreData = _extractScoresFromDescription(
      json['original_description']?.toString() ?? '',
    );

    if (team1.isNotEmpty) {
      teams.add(
        TeamData(
          name: team1,
          score: scoreData['team1_score'] ?? '',
          overs: scoreData['team1_overs'] ?? '',
          wickets: scoreData['team1_wickets'] ?? '',
          runRate: scoreData['team1_rate'] ?? '',
        ),
      );
    }

    if (team2.isNotEmpty) {
      teams.add(
        TeamData(
          name: team2,
          score: scoreData['team2_score'] ?? '',
          overs: scoreData['team2_overs'] ?? '',
          wickets: scoreData['team2_wickets'] ?? '',
          runRate: scoreData['team2_rate'] ?? '',
        ),
      );
    }

    return teams;
  }

  /// Clean and normalize team names
  String _cleanTeamName(String teamName) {
    if (teamName.isEmpty) return '';

    // Remove common suffixes and prefixes
    teamName = teamName
        .replaceAll(RegExp(r'\s+vs\s+.*', caseSensitive: false), '')
        .replaceAll(RegExp(r'^\s*vs\s+', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+XI$', caseSensitive: false), '')
        .replaceAll(' 2nd XI', '')
        .trim();

    // Handle specific cases
    if (teamName.contains('Antigua')) return 'Antigua Falcons';
    if (teamName.contains('Barbados')) return 'Barbados Royals';
    if (teamName.contains('Hampshire')) return 'Hampshire';
    if (teamName.contains('Durham')) return 'Durham';
    if (teamName.contains('Surrey')) return 'Surrey';
    if (teamName.contains('Yorkshire')) return 'Yorkshire';
    if (teamName.contains('Leicestershire')) return 'Leicestershire';
    if (teamName.contains('Lancashire')) return 'Lancashire';
    if (teamName.contains('South Zone')) return 'South Zone';
    if (teamName.contains('North Zone')) return 'North Zone';
    if (teamName.contains('Central Zone')) return 'Central Zone';
    if (teamName.contains('West Zone')) return 'West Zone';
    if (teamName.contains('United Arab Emirates')) return 'UAE';
    if (teamName.contains('Afghanistan')) return 'Afghanistan';
    if (teamName.contains('Pakistan')) return 'Pakistan';
    if (teamName.contains('South Africa')) return 'South Africa';
    if (teamName.contains('England')) return 'England';

    return teamName;
  }

  /// Extract teams from title or description
  List<String> _extractTeamsFromTitle(Map<String, dynamic> json) {
    final title = json['original_title']?.toString() ?? '';
    final description = json['original_description']?.toString() ?? '';

    // Look for "vs" pattern
    final vsPattern = RegExp(
      r'([A-Za-z\s]+?)\s+vs\s+([A-Za-z\s]+)',
      caseSensitive: false,
    );
    final match =
        vsPattern.firstMatch(title) ?? vsPattern.firstMatch(description);

    if (match != null) {
      return [
        _cleanTeamName(match.group(1) ?? ''),
        _cleanTeamName(match.group(2) ?? ''),
      ];
    }

    return [];
  }

  /// Extract scores from description text
  Map<String, String> _extractScoresFromDescription(String description) {
    final scoreData = <String, String>{};

    // Pattern for scores like "165/6", "330/8", etc.
    final scorePattern = RegExp(r'(\d+)/(\d+)');
    final scores = scorePattern.allMatches(description).toList();

    if (scores.isNotEmpty) {
      scoreData['team1_score'] = scores[0].group(0) ?? '';
    }
    if (scores.length > 1) {
      scoreData['team2_score'] = scores[1].group(0) ?? '';
    }

    // Pattern for overs like "(19.4/20 ov)", "(50 ov)"
    final oversPattern = RegExp(r'\(([0-9.]+(?:/\d+)?)\s*ov[^)]*\)');
    final overs = oversPattern.allMatches(description).toList();

    if (overs.isNotEmpty) {
      scoreData['team1_overs'] = overs[0].group(1) ?? '';
    }
    if (overs.length > 1) {
      scoreData['team2_overs'] = overs[1].group(1) ?? '';
    }

    return scoreData;
  }

  /// Smart venue extraction
  String _extractVenue(Map<String, dynamic> json) {
    // Priority order for venue information
    if (json['venue'] != null && json['venue'].toString().isNotEmpty) {
      return json['venue'].toString();
    }

    // Build venue from city, state, country
    final parts = <String>[];
    if (json['city'] != null && json['city'].toString().isNotEmpty) {
      parts.add(json['city'].toString());
    }
    if (json['state'] != null && json['state'].toString().isNotEmpty) {
      parts.add(json['state'].toString());
    }
    if (json['country'] != null && json['country'].toString().isNotEmpty) {
      parts.add(json['country'].toString());
    }

    if (parts.isNotEmpty) {
      return parts.join(', ');
    }

    // Extract from title or description
    final title = json['original_title']?.toString() ?? '';
    final venueMatch = RegExp(
      r'([A-Za-z\s]+ Ground|[A-Za-z\s]+ Stadium|Lords|Oval)',
      caseSensitive: false,
    ).firstMatch(title);

    if (venueMatch != null) {
      return venueMatch.group(0) ?? '';
    }

    return 'Venue TBD';
  }

  /// Generate intelligent title
  String _generateTitle(Map<String, dynamic> json, List<TeamData> teams) {
    // If we have teams, create vs format
    if (teams.length >= 2) {
      final match = '${teams[0].name} vs ${teams[1].name}';

      // Add match number if available
      if (json['match_number'] != null) {
        return 'Match ${json['match_number']}: $match';
      }

      // Add match type if available
      if (json['match_type'] != null &&
          json['match_type'].toString().isNotEmpty) {
        return '${json['match_type']} - $match';
      }

      return match;
    }

    // Fallback to original title
    final originalTitle = json['original_title']?.toString() ?? '';
    if (originalTitle.isNotEmpty) {
      return originalTitle.length > 60
          ? '${originalTitle.substring(0, 57)}...'
          : originalTitle;
    }

    return 'Cricket Match';
  }

  /// Determine live status with intelligence
  String _determineLiveStatus(Map<String, dynamic> json) {
    final status = json['match_status']?.toString().toLowerCase() ?? '';
    final description =
        json['original_description']?.toString().toLowerCase() ?? '';

    // Check for live indicators - Enhanced to catch 'Live' status
    if (status == 'live' ||
        status.contains('live') ||
        description.contains('live') ||
        description.contains('in progress') ||
        description.contains('innings break') ||
        description.contains('day 2') ||
        description.contains('batting') ||
        description.contains('bowling')) {
      return 'live';
    }

    // Check for completed indicators
    if (status.contains('completed') ||
        status.contains('result') ||
        description.contains('won by') ||
        description.contains('result') ||
        json['result'] != null && json['result'].toString().isNotEmpty) {
      return 'completed';
    }

    // Check for scheduled/upcoming indicators
    if (status.contains('scheduled') ||
        status.contains('upcoming') ||
        description.contains('yet to begin') ||
        description.contains('match yet to begin') ||
        description.contains('tomorrow') ||
        description.contains('today') ||
        description.contains('starts in')) {
      return 'upcoming';
    }

    // Check for unknown status but might be live based on other indicators
    if (status == 'unknown' && description.contains('innings break')) {
      return 'live';
    }

    return 'unknown';
  }

  /// Extract series name intelligently
  String _extractSeries(Map<String, dynamic> json) {
    if (json['series_name'] != null &&
        json['series_name'].toString().isNotEmpty) {
      return json['series_name'].toString();
    }

    // Extract from title
    final title = json['original_title']?.toString() ?? '';

    if (title.contains('Caribbean Premier League')) {
      return 'Caribbean Premier League';
    }
    if (title.contains('Vitality Blast')) return 'Vitality Blast Men';
    if (title.contains('Second Eleven Championship')) {
      return 'Second Eleven Championship';
    }
    if (title.contains('Duleep Trophy')) return 'Duleep Trophy';
    if (title.contains('T20I Tri-Series')) return 'UAE T20I Tri-Series';
    if (title.contains('South Africa') && title.contains('England')) {
      return 'South Africa tour of England';
    }

    return 'Domestic Cricket';
  }

  /// Extract match type/format
  String _extractMatchType(Map<String, dynamic> json) {
    if (json['match_format'] != null &&
        json['match_format'].toString().isNotEmpty) {
      return json['match_format'].toString();
    }

    if (json['match_type'] != null &&
        json['match_type'].toString().isNotEmpty) {
      return json['match_type'].toString();
    }

    // Determine from title/description
    final title = json['original_title']?.toString().toLowerCase() ?? '';
    final description =
        json['original_description']?.toString().toLowerCase() ?? '';

    if (title.contains('t20') || description.contains('t20')) return 'T20';
    if (title.contains('odi') || description.contains('odi')) return 'ODI';
    if (title.contains('test') || description.contains('test')) return 'Test';
    if (title.contains('final') || description.contains('final')) {
      return 'Final';
    }
    if (title.contains('semi') || description.contains('semi')) {
      return 'Semi-Final';
    }

    return 'Limited Overs';
  }

  /// Get formatted status with enhanced information
  String _getFormattedStatus(
    Map<String, dynamic> json,
    EnhancedMatchInfo enhancedInfo,
  ) {
    final baseStatus = json['match_status']?.toString() ?? '';

    // For live matches, add more context
    if (enhancedInfo.result != null && enhancedInfo.result!.isNotEmpty) {
      return enhancedInfo.result!;
    }

    // For scheduled matches, add time info
    if (baseStatus.toLowerCase().contains('scheduled') ||
        baseStatus.toLowerCase().contains('upcoming')) {
      if (enhancedInfo.matchTime != null) {
        return 'Scheduled - ${enhancedInfo.matchTime}';
      }
    }

    return baseStatus.isNotEmpty ? baseStatus : 'Status Unknown';
  }

  /// Utility methods
  int? _parseToInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  double? _parseToDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  String _generateId() {
    return 'match_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Get all matches
  Future<CricketApiResponse> getAllMatches({bool refresh = false}) async {
    try {
      if (refresh) {
        _cachedMatches = null; // Force reload
      }

      final matches = await _loadMatchesFromFile();
      return CricketApiResponse(
        success: true,
        data: matches,
        meta: CricketApiMeta(
          totalCount: matches.length,
          filteredCount: matches.length,
          filterType: 'all',
          lastUpdated: _lastLoadTime?.toIso8601String(),
          apiVersion: 'Local-1.0',
        ),
      );
    } catch (e) {
      return CricketApiResponse(success: false, data: [], error: e.toString());
    }
  }

  /// Get live matches
  Future<CricketApiResponse> getLiveMatches() async {
    try {
      final allMatches = await _loadMatchesFromFile();
      final liveMatches = allMatches
          .where((match) => match.liveStatus == 'live')
          .toList();

      return CricketApiResponse(
        success: true,
        data: liveMatches,
        meta: CricketApiMeta(
          totalCount: allMatches.length,
          filteredCount: liveMatches.length,
          filterType: 'live',
          lastUpdated: _lastLoadTime?.toIso8601String(),
          apiVersion: 'Local-1.0',
        ),
      );
    } catch (e) {
      return CricketApiResponse(success: false, data: [], error: e.toString());
    }
  }

  /// Get live matches with enhanced error handling for UI
  Future<CricketApiResponse> getLiveMatchesSafe() async {
    try {
      print('🔄 Fetching live matches...');
      final allMatches = await _loadMatchesFromFile();
      print('📊 Total matches loaded: ${allMatches.length}');

      final liveMatches = allMatches.where((match) {
        final isLive = match.liveStatus.toLowerCase() == 'live';
        print(
          '🔍 Match: ${match.title} - Status: ${match.liveStatus} - IsLive: $isLive',
        );
        if (isLive) {
          print('🔴 Live match found: ${match.title}');
        }
        return isLive;
      }).toList();

      print('🎯 Live matches found: ${liveMatches.length}');

      // Return live matches if found, otherwise return empty list
      if (liveMatches.isNotEmpty) {
        return CricketApiResponse(
          success: true,
          data: liveMatches,
          meta: CricketApiMeta(
            totalCount: allMatches.length,
            filteredCount: liveMatches.length,
            filterType: 'live',
            lastUpdated: _lastLoadTime?.toIso8601String(),
            apiVersion: 'Local-1.0',
          ),
        );
      }

      print('ℹ️ No live matches currently found');
      return CricketApiResponse(
        success: true,
        data: [],
        meta: CricketApiMeta(
          totalCount: allMatches.length,
          filteredCount: 0,
          filterType: 'live',
          lastUpdated: DateTime.now().toIso8601String(),
          apiVersion: 'Local-1.0',
        ),
      );
    } catch (e) {
      print('❌ Error in getLiveMatchesSafe: $e');
      return CricketApiResponse(
        success: false,
        data: [],
        error: e.toString(),
        meta: CricketApiMeta(
          totalCount: 0,
          filteredCount: 0,
          filterType: 'error',
          lastUpdated: DateTime.now().toIso8601String(),
          apiVersion: 'Local-1.0',
        ),
      );
    }
  }

  /// Get upcoming matches
  Future<CricketApiResponse> getUpcomingMatches() async {
    try {
      final allMatches = await _loadMatchesFromFile();
      final upcomingMatches = allMatches
          .where((match) => match.liveStatus == 'upcoming')
          .toList();

      return CricketApiResponse(
        success: true,
        data: upcomingMatches,
        meta: CricketApiMeta(
          totalCount: allMatches.length,
          filteredCount: upcomingMatches.length,
          filterType: 'upcoming',
          lastUpdated: _lastLoadTime?.toIso8601String(),
          apiVersion: 'Local-1.0',
        ),
      );
    } catch (e) {
      return CricketApiResponse(success: false, data: [], error: e.toString());
    }
  }

  /// Get recent/completed matches
  Future<CricketApiResponse> getRecentMatches() async {
    try {
      final allMatches = await _loadMatchesFromFile();
      final recentMatches = allMatches
          .where((match) => match.liveStatus == 'completed')
          .toList();

      return CricketApiResponse(
        success: true,
        data: recentMatches,
        meta: CricketApiMeta(
          totalCount: allMatches.length,
          filteredCount: recentMatches.length,
          filterType: 'recent',
          lastUpdated: _lastLoadTime?.toIso8601String(),
          apiVersion: 'Local-1.0',
        ),
      );
    } catch (e) {
      return CricketApiResponse(success: false, data: [], error: e.toString());
    }
  }

  /// Get match details by ID
  Future<CricketMatch> getMatchDetails(String matchId) async {
    try {
      final allMatches = await _loadMatchesFromFile();
      final match = allMatches.firstWhere(
        (match) => match.id == matchId,
        orElse: () => throw Exception('Match not found'),
      );
      return match;
    } catch (e) {
      throw Exception('Failed to get match details: $e');
    }
  }

  /// Get matches for a specific team
  Future<CricketApiResponse> getTeamMatches(String teamName) async {
    try {
      final allMatches = await _loadMatchesFromFile();
      final teamMatches = allMatches.where((match) {
        return match.teams.any(
          (team) => team.name.toLowerCase().contains(teamName.toLowerCase()),
        );
      }).toList();

      return CricketApiResponse(
        success: true,
        data: teamMatches,
        meta: CricketApiMeta(
          totalCount: allMatches.length,
          filteredCount: teamMatches.length,
          filterType: 'team:$teamName',
          lastUpdated: _lastLoadTime?.toIso8601String(),
          apiVersion: 'Local-1.0',
        ),
      );
    } catch (e) {
      return CricketApiResponse(success: false, data: [], error: e.toString());
    }
  }

  /// Refresh data (reload from file)
  Future<Map<String, dynamic>> refreshMatches() async {
    try {
      _cachedMatches = null; // Clear cache
      final matches = await _loadMatchesFromFile();
      return {
        'success': true,
        'message': 'Data refreshed successfully',
        'matches_count': matches.length,
        'last_updated': _lastLoadTime?.toIso8601String(),
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get health status
  Future<Map<String, dynamic>> getHealthStatus() async {
    try {
      final currentDir = Directory.current;
      final file = File('${currentDir.path}/$_dataFilePath');
      final fileExists = await file.exists();
      final lastModified = fileExists
          ? (await file.lastModified()).toIso8601String()
          : null;

      return {
        'status': 'healthy',
        'data_source': 'Local JSON File',
        'file_exists': fileExists,
        'file_path': file.path,
        'last_modified': lastModified,
        'cached_matches': _cachedMatches?.length ?? 0,
        'cache_valid':
            _lastLoadTime != null &&
            DateTime.now().difference(_lastLoadTime!) < _cacheValidDuration,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {'status': 'error', 'error': e.toString()};
    }
  }

  /// Get API statistics
  Future<ApiStatistics> getApiStatistics() async {
    try {
      final allMatches = await _loadMatchesFromFile();
      final liveCount = allMatches.where((m) => m.liveStatus == 'live').length;
      final completedCount = allMatches
          .where((m) => m.liveStatus == 'completed')
          .length;
      final upcomingCount = allMatches
          .where((m) => m.liveStatus == 'upcoming')
          .length;

      final overview = ApiOverview(
        totalMatches: allMatches.length,
        liveMatches: liveCount,
        completedMatches: completedCount,
        upcomingMatches: upcomingCount,
        upcomingLimitedTo: 10,
        lastUpdate: _lastLoadTime?.toIso8601String(),
        scraperRunning: false, // Not applicable for local data
        updateIntervalSeconds: 0, // Not applicable for local data
      );

      return ApiStatistics(
        overview: overview,
        teams: {}, // Can be implemented if needed
        features: {
          'local_data': true,
          'dataset_integration': true,
          'llm_cleaned': true,
        },
      );
    } catch (e) {
      throw Exception('Failed to get statistics: $e');
    }
  }

  /// Check if API is available (always true for local data)
  Future<bool> isApiAvailable() async {
    try {
      final currentDir = Directory.current;
      final file = File('${currentDir.path}/$_dataFilePath');
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Get sample JSON data as fallback (returns empty list)
  String _getSampleJsonData() {
    return '[]';
  }

  /// Create sample live matches (returns empty list - no dummy data)
  List<CricketMatch> _createSampleLiveMatches() {
    return [];
  }

  /// Debug method to check data loading
  Future<Map<String, dynamic>> debugDataLoading() async {
    final debugInfo = <String, dynamic>{};

    try {
      // Check file existence
      final currentDir = Directory.current;
      final dataFile = File('${currentDir.path}/$_dataFilePath');
      debugInfo['file_exists'] = await dataFile.exists();
      debugInfo['file_path'] = dataFile.path;
      debugInfo['current_directory'] = currentDir.path;

      // Try loading data
      final matches = await _loadMatchesFromFile();
      debugInfo['matches_loaded'] = matches.length;
      debugInfo['live_matches'] = matches
          .where((m) => m.liveStatus == 'live')
          .length;
      debugInfo['cache_status'] = _cachedMatches != null
          ? 'cached'
          : 'not_cached';

      return debugInfo;
    } catch (e) {
      debugInfo['error'] = e.toString();
      return debugInfo;
    }
  }
}
