class ApiConstants {
  // Cricket Server Configuration (Read-only API gateway)
  static const String cricApiBaseUrl = String.fromEnvironment(
    'CRICKET_API_BASE_URL',
    defaultValue: 'http://localhost:8001',
  );

  // No API key needed for local server
  static const String cricApiKey = ''; // Not used for local server

  // News API - configured via compile-time environment definition
  // Pass --dart-define=NEWS_API_KEY=your_key at build or run time
  static const String newsApiKey = String.fromEnvironment(
    'NEWS_API_KEY',
    defaultValue: '2c4e8a5e0cec4fd3b52bfca006c58ea6',
  );
  static const String newsApiBaseUrl = 'https://newsapi.org/v2';

  // Cricket Server API Endpoints (Read-only cached datasets)
  static const String allMatchesEndpoint = '/api/v1/matches';
  static const String liveMatchesEndpoint = '/api/v1/matches/live';
  static const String upcomingMatchesEndpoint =
      '/api/v1/matches'; // Filter by status
  static const String recentMatchesEndpoint =
      '/api/v1/matches'; // Filter by status
  static const String matchDetailsEndpoint = '/api/v1/matches'; // /{match_id}
  static const String serverStatusEndpoint = '/api/v1/status';
  static const String serverHealthEndpoint = '/health';
  // Data refresh is orchestrated internally on the backend timer
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
