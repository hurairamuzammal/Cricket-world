import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/cricket_models.dart';
import '../../../../core/services/cricket_api_service.dart';
import '../../../../core/services/cricket_server_api_service.dart';

// Cricket API Service Provider (uses external APIs with local fallback)
final cricketApiServiceProvider = Provider<CricketApiService>((ref) {
  return CricketApiService();
});

// Server API Service Provider (connects to your local Scrapy server)
final serverApiServiceProvider = Provider<CricketServerApiService>((ref) {
  return CricketServerApiService();
});

// All Matches Provider
final allMatchesProvider = FutureProvider<List<CricketMatch>>((ref) async {
  final apiService = ref.read(cricketApiServiceProvider);
  final response = await apiService.getAllMatches();
  if (response.success) {
    return response.data;
  } else {
    throw Exception(response.error ?? 'Failed to load matches');
  }
});

// Live Matches Provider
final liveMatchesProvider = FutureProvider<List<CricketMatch>>((ref) async {
  final apiService = ref.read(cricketApiServiceProvider);
  final response = await apiService.getLiveMatches();
  if (response.success) {
    return response.data;
  } else {
    throw Exception(response.error ?? 'Failed to load live matches');
  }
});

// Upcoming Matches Provider
final upcomingMatchesProvider = FutureProvider<List<CricketMatch>>((ref) async {
  final apiService = ref.read(cricketApiServiceProvider);
  final response = await apiService.getUpcomingMatches();
  if (response.success) {
    return response.data;
  } else {
    throw Exception(response.error ?? 'Failed to load upcoming matches');
  }
});

// Recent Matches Provider
final recentMatchesProvider = FutureProvider<List<CricketMatch>>((ref) async {
  final apiService = ref.read(cricketApiServiceProvider);
  final response = await apiService.getRecentMatches();
  if (response.success) {
    return response.data;
  } else {
    throw Exception(response.error ?? 'Failed to load recent matches');
  }
});

// Match Details Provider
final matchDetailsProvider = FutureProvider.family<CricketMatch, String>((
  ref,
  matchId,
) async {
  final apiService = ref.read(cricketApiServiceProvider);
  return await apiService.getDetailedMatchInfo(matchId);
});

// Team Matches Provider
final teamMatchesProvider = FutureProvider.family<List<CricketMatch>, String>((
  ref,
  teamName,
) async {
  final apiService = ref.read(cricketApiServiceProvider);
  final response = await apiService.getTeamMatches(teamName);
  if (response.success) {
    return response.data;
  } else {
    throw Exception(response.error ?? 'Failed to load team matches');
  }
});

// API Health Provider
final apiHealthProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final apiService = ref.read(cricketApiServiceProvider);
  return await apiService.getHealthStatus();
});

// API Statistics Provider
final apiStatsProvider = FutureProvider<ApiStatistics>((ref) async {
  final apiService = ref.read(cricketApiServiceProvider);
  return await apiService.getApiStatistics();
});

// Refresh Provider - for forcing cache refresh
final refreshProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final apiService = ref.read(cricketApiServiceProvider);
  return await apiService.refreshMatches();
});

// State Notifier for managing match refresh
class MatchRefreshNotifier extends StateNotifier<AsyncValue<void>> {
  MatchRefreshNotifier(this.ref) : super(const AsyncValue.data(null));

  final Ref ref;

  Future<void> refreshAllMatches() async {
    state = const AsyncValue.loading();
    try {
      // Invalidate all providers to force refresh
      ref.invalidate(allMatchesProvider);
      ref.invalidate(liveMatchesProvider);
      ref.invalidate(upcomingMatchesProvider);
      ref.invalidate(recentMatchesProvider);

      // Trigger refresh on API
      await ref.read(refreshProvider.future);

      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

final matchRefreshProvider =
    StateNotifierProvider<MatchRefreshNotifier, AsyncValue<void>>((ref) {
      return MatchRefreshNotifier(ref);
    });

// Auto-refresh provider for ALL matches (runs every 2 minutes)
final autoRefreshProvider = StreamProvider<int>((ref) {
  return Stream.periodic(const Duration(minutes: 2), (count) => count);
});

// FAST auto-refresh provider for LIVE matches only (runs every 10 seconds)
final liveAutoRefreshProvider = StreamProvider<int>((ref) {
  return Stream.periodic(const Duration(seconds: 10), (count) => count);
});

// Provider that automatically refreshes ALL matches when auto-refresh triggers (2 min)
final autoRefreshDataProvider = Provider<void>((ref) {
  ref.listen(autoRefreshProvider, (previous, next) {
    if (next.hasValue) {
      // Invalidate all matches provider (every 2 minutes)
      ref.invalidate(allMatchesProvider);
    }
  });
});

// Provider that automatically refreshes LIVE matches frequently (10 seconds)
final liveAutoRefreshDataProvider = Provider<void>((ref) {
  ref.listen(liveAutoRefreshProvider, (previous, next) {
    if (next.hasValue) {
      // Invalidate live matches provider only (every 10 seconds)
      ref.invalidate(liveMatchesProvider);
    }
  });
});

// Server-based live matches provider (from your Scrapy server)
final serverLiveMatchesProvider = FutureProvider<List<CricketMatch>>((
  ref,
) async {
  final serverApi = ref.read(serverApiServiceProvider);
  final response = await serverApi.getLiveMatches();
  if (response.success) {
    return response.data;
  } else {
    throw Exception(
      response.error ?? 'Failed to load live matches from server',
    );
  }
});

// Server-based all matches provider (from your Scrapy server)
final serverAllMatchesProvider = FutureProvider<List<CricketMatch>>((
  ref,
) async {
  final serverApi = ref.read(serverApiServiceProvider);
  final response = await serverApi.getAllMatches();
  if (response.success) {
    return response.data;
  } else {
    throw Exception(response.error ?? 'Failed to load matches from server');
  }
});

// Combined matches provider that combines all match types
final combinedMatchesProvider = FutureProvider<Map<String, List<CricketMatch>>>(
  (ref) async {
    final futures = await Future.wait([
      ref.read(allMatchesProvider.future),
      ref.read(liveMatchesProvider.future),
      ref.read(upcomingMatchesProvider.future),
      ref.read(recentMatchesProvider.future),
    ]);

    return {
      'all': futures[0],
      'live': futures[1],
      'upcoming': futures[2],
      'recent': futures[3],
    };
  },
);

// Filtered matches provider
final filteredMatchesProvider =
    FutureProvider.family<List<CricketMatch>, String>((ref, filter) async {
      final allMatches = await ref.read(allMatchesProvider.future);

      switch (filter.toLowerCase()) {
        case 'live':
          return allMatches.where((match) => match.isLive).toList();
        case 'upcoming':
          return allMatches.where((match) => match.isUpcoming).toList();
        case 'completed':
        case 'recent':
          return allMatches.where((match) => match.isCompleted).toList();
        default:
          return allMatches;
      }
    });

// Search matches provider
final searchMatchesProvider = FutureProvider.family<List<CricketMatch>, String>(
  (ref, query) async {
    final allMatches = await ref.read(allMatchesProvider.future);

    if (query.isEmpty) return allMatches;

    final lowerQuery = query.toLowerCase();
    return allMatches.where((match) {
      return match.title.toLowerCase().contains(lowerQuery) ||
          match.series.toLowerCase().contains(lowerQuery) ||
          match.venue.toLowerCase().contains(lowerQuery) ||
          match.teams.any(
            (team) => team.name.toLowerCase().contains(lowerQuery),
          );
    }).toList();
  },
);

/// Groups matches by date for displaying with date headers
/// Returns a Map where keys are formatted date strings and values are lists of matches
final dateGroupedMatchesProvider = FutureProvider<Map<String, List<CricketMatch>>>((
  ref,
) async {
  final matches = await ref.read(allMatchesProvider.future);

  // Group matches by date
  final Map<String, List<CricketMatch>> grouped = {};

  for (final match in matches) {
    final dateKey = _getMatchDateKey(match);
    grouped.putIfAbsent(dateKey, () => []);
    grouped[dateKey]!.add(match);
  }

  // Sort the date keys (most recent first for completed, upcoming dates for scheduled)
  final sortedKeys = grouped.keys.toList()
    ..sort((a, b) {
      final dateA = _parseDateKey(a);
      final dateB = _parseDateKey(b);
      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;
      return dateB.compareTo(dateA); // Recent dates first
    });

  // Return a LinkedHashMap to preserve order
  final Map<String, List<CricketMatch>> sortedGrouped = {};
  for (final key in sortedKeys) {
    sortedGrouped[key] = grouped[key]!;
  }

  return sortedGrouped;
});

/// Helper to extract date key from a match
String _getMatchDateKey(CricketMatch match) {
  // Try to get date from enhancedInfo
  final dateStr = match.enhancedInfo?.matchDate;
  if (dateStr != null && dateStr.isNotEmpty) {
    final parsed = _tryParseDate(dateStr);
    if (parsed != null) return _formatDateKey(parsed);
  }

  // Try to get date from lastUpdated field
  if (match.lastUpdated.isNotEmpty) {
    final parsed = _tryParseDate(match.lastUpdated);
    if (parsed != null) return _formatDateKey(parsed);
  }

  // Try to extract date from status text (e.g., "Match starts Jan 16, 2026")
  final statusDate = _extractDateFromText(match.status);
  if (statusDate != null) return _formatDateKey(statusDate);

  // DEBUG LOG
  print(
    'DEBUG: Could not determine date for match: ${match.title}, status: ${match.status}, enhancedDate: ${match.enhancedInfo?.matchDate}',
  );

  // Try to extract date from title
  final titleDate = _extractDateFromText(match.title);
  if (titleDate != null) return _formatDateKey(titleDate);

  // Categorize by match status if no date found
  if (match.isLive) {
    return 'Today'; // Live matches are happening now
  } else if (match.isUpcoming) {
    return 'Upcoming'; // Unknown future date
  } else if (match.isCompleted) {
    return 'Completed'; // Past matches without specific date
  }

  return 'Unknown Date';
}

/// Try to parse a date string in various formats
DateTime? _tryParseDate(String dateStr) {
  if (dateStr.isEmpty) return null;

  // Try ISO format first
  try {
    return DateTime.parse(dateStr);
  } catch (_) {}

  // Try common date formats
  final patterns = [
    // "Jan 16, 2026" or "January 16, 2026"
    RegExp(r'(\w+)\s+(\d{1,2}),?\s+(\d{4})'),
    // "16 Jan 2026" or "16 January 2026"
    RegExp(r'(\d{1,2})\s+(\w+)\s+(\d{4})'),
    // "2026-01-16"
    RegExp(r'(\d{4})-(\d{2})-(\d{2})'),
    // "16/01/2026" or "01/16/2026"
    RegExp(r'(\d{1,2})/(\d{1,2})/(\d{4})'),
  ];

  final months = {
    'jan': 1,
    'january': 1,
    'feb': 2,
    'february': 2,
    'mar': 3,
    'march': 3,
    'apr': 4,
    'april': 4,
    'may': 5,
    'jun': 6,
    'june': 6,
    'jul': 7,
    'july': 7,
    'aug': 8,
    'august': 8,
    'sep': 9,
    'september': 9,
    'oct': 10,
    'october': 10,
    'nov': 11,
    'november': 11,
    'dec': 12,
    'december': 12,
  };

  final lowerStr = dateStr.toLowerCase();

  // Try "Jan 16, 2026" format
  final match1 = patterns[0].firstMatch(lowerStr);
  if (match1 != null) {
    final monthName = match1.group(1)?.toLowerCase();
    final day = int.tryParse(match1.group(2) ?? '');
    final year = int.tryParse(match1.group(3) ?? '');
    if (monthName != null &&
        months.containsKey(monthName) &&
        day != null &&
        year != null) {
      return DateTime(year, months[monthName]!, day);
    }
  }

  // Try "16 Jan 2026" format
  final match2 = patterns[1].firstMatch(lowerStr);
  if (match2 != null) {
    final day = int.tryParse(match2.group(1) ?? '');
    final monthName = match2.group(2)?.toLowerCase();
    final year = int.tryParse(match2.group(3) ?? '');
    if (monthName != null &&
        months.containsKey(monthName) &&
        day != null &&
        year != null) {
      return DateTime(year, months[monthName]!, day);
    }
  }

  return null;
}

/// Extract date from text like status or title
DateTime? _extractDateFromText(String text) {
  if (text.isEmpty) return null;
  return _tryParseDate(text);
}

/// Format date as a human-readable key
String _formatDateKey(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final matchDate = DateTime(date.year, date.month, date.day);

  final difference = matchDate.difference(today).inDays;

  if (difference == 0) {
    return 'Today';
  } else if (difference == 1) {
    return 'Tomorrow';
  } else if (difference == -1) {
    return 'Yesterday';
  } else {
    // Format as "Wed, Jan 15, 2026"
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final weekday = weekdays[date.weekday - 1];
    final month = months[date.month - 1];
    return '$weekday, $month ${date.day}, ${date.year}';
  }
}

/// Parse a date key back to DateTime for sorting
DateTime? _parseDateKey(String key) {
  if (key == 'Today') return DateTime.now();
  if (key == 'Tomorrow') return DateTime.now().add(const Duration(days: 1));
  if (key == 'Yesterday')
    return DateTime.now().subtract(const Duration(days: 1));
  if (key == 'Upcoming')
    return DateTime.now().add(const Duration(days: 30)); // Future
  if (key == 'Completed')
    return DateTime.now().subtract(const Duration(days: 30)); // Past
  if (key == 'Unknown Date') return null;

  // Try to parse "Wed, Jan 15, 2026" format
  try {
    final parts = key.split(', ');
    if (parts.length >= 2) {
      final monthDay = parts[1].split(' ');
      final year = int.parse(parts[2]);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final month = months.indexOf(monthDay[0]) + 1;
      final day = int.parse(monthDay[1]);
      return DateTime(year, month, day);
    }
  } catch (_) {}

  return null;
}

/// Provider for filtered and grouped matches
final filteredDateGroupedMatchesProvider =
    FutureProvider.family<Map<String, List<CricketMatch>>, String>((
      ref,
      filter,
    ) async {
      final allMatches = await ref.read(allMatchesProvider.future);

      // Filter first
      List<CricketMatch> filtered;
      switch (filter.toLowerCase()) {
        case 'live':
          filtered = allMatches.where((match) => match.isLive).toList();
          break;
        case 'upcoming':
          filtered = allMatches.where((match) => match.isUpcoming).toList();
          break;
        case 'completed':
        case 'recent':
          filtered = allMatches.where((match) => match.isCompleted).toList();
          break;
        default:
          filtered = allMatches;
      }

      // Group by date
      final Map<String, List<CricketMatch>> grouped = {};

      for (final match in filtered) {
        final dateKey = _getMatchDateKey(match);
        grouped.putIfAbsent(dateKey, () => []);
        grouped[dateKey]!.add(match);
      }

      // Sort the date keys
      final sortedKeys = grouped.keys.toList()
        ..sort((a, b) {
          final dateA = _parseDateKey(a);
          final dateB = _parseDateKey(b);

          // Custom Sorting Logic as requested:
          // 1. Yesterday
          // 2. Today / Live
          // 3. Future dates (Ascending)
          // 4. Older Past dates (Descending)

          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);

          bool isFuture(DateTime d) => d.isAfter(today);
          bool isPast(DateTime d) => d.isBefore(today);

          // Priority 1: Yesterday
          if (a == 'Yesterday') return -1;
          if (b == 'Yesterday') return 1;

          // Priority 2: Today
          if (a == 'Today') return -1;
          if (b == 'Today') return 1;

          if (dateA == null && dateB == null) return 0;
          if (dateA == null) return 1;
          if (dateB == null) return -1;

          // Handle filters
          if (filter.toLowerCase() == 'upcoming') {
            return dateA.compareTo(dateB); // Ascending
          } else if (filter.toLowerCase() == 'recent' ||
              filter.toLowerCase() == 'completed') {
            return dateB.compareTo(dateA); // Descending
          } else {
            // 'All' Filter Logic

            bool aIsFuture = isFuture(dateA);
            bool bIsFuture = isFuture(dateB);
            bool aIsPast = isPast(dateA);
            bool bIsPast = isPast(dateB);

            // If both are Future: Ascending (Soonest first)
            if (aIsFuture && bIsFuture) {
              return dateA.compareTo(dateB);
            }

            // If both are Past (and not Yesterday, since checked above): Descending (Newest first)
            if (aIsPast && bIsPast) {
              return dateB.compareTo(dateA);
            }

            // Mixed Blocks:
            // Order: [Yesterday] -> [Today] -> [Future] -> [Older Past]

            // If one is Future and one is Past (older than yesterday)
            // We want Future to come BEFORE Older Past
            if (aIsFuture && aIsPast)
              return -1; // Impossible for same date, but logic structure
            if (aIsFuture) return -1; // Future comes first
            if (bIsFuture) return 1;

            return 0;
          }
        });

      final Map<String, List<CricketMatch>> sortedGrouped = {};
      for (final key in sortedKeys) {
        sortedGrouped[key] = grouped[key]!;
      }

      return sortedGrouped;
    });
