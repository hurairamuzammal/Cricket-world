class ApiConstants {
  // LOCAL CRICKET SERVER CONFIGURATION (YOUR SCRAPPED DATA)
  // This uses your cricket_server.py running on localhost:8001
  // Data is sourced from cleaned_cricket_data.json
  static const String cricApiBaseUrl = 'http://localhost:8001';

  // No API key needed for local server
  static const String cricApiKey = ''; // Not used for local server

  // News API (keeping existing)
  static const String newsApiKey = '2c4e8a5e0cec4fd3b52bfca006c58ea6';
  static const String newsApiBaseUrl = 'https://newsapi.org/v2';

  // LOCAL Cricket Server API Endpoints (from cricket_server.py)
  static const String allMatchesEndpoint = '/api/v1/matches';
  static const String liveMatchesEndpoint = '/api/v1/matches/live';
  static const String upcomingMatchesEndpoint =
      '/api/v1/matches'; // Filter by status
  static const String recentMatchesEndpoint =
      '/api/v1/matches'; // Filter by status
  static const String matchDetailsEndpoint = '/api/v1/matches'; // /{match_id}
  static const String serverStatusEndpoint = '/api/v1/status';
  static const String serverHealthEndpoint = '/health';
  static const String refreshDataEndpoint = '/api/v1/refresh';

  // Helper method to build complete API URLs (updated for local server)
  static String buildApiUrl(
    String endpoint, {
    Map<String, String>? queryParams,
  }) {
    String url = '$cricApiBaseUrl$endpoint';

    if (queryParams != null && queryParams.isNotEmpty) {
      final queryString = queryParams.entries
          .map((e) => '${e.key}=${e.value}')
          .join('&');
      url += '?$queryString';
    }

    return url;
  }

  // Helper to check if using local server
  static bool get isUsingLocalServer => cricApiBaseUrl.contains('localhost');

  // Legacy endpoints for backward compatibility (NOT USED with local server)
  // These are kept for old cricketdata_org_api_service.dart
  static const String currentMatchesEndpoint = '/currentMatches';
  static const String cricScoreEndpoint = '/cricScore';
}
