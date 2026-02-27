import 'package:intl/intl.dart';
import '../../domain/entities/match_entity.dart';

class MatchSortingUtils {
  /// Organizes matches for optimal viewing:
  /// - Finished matches at the top (scroll up to view recent history)
  /// - Live matches prominently displayed in center
  /// - Upcoming matches at the bottom (scroll down to view future matches)
  /// - Grouped by date with date separators
  static MatchesLayout organizeMatchesForDisplay(List<MatchEntity> matches) {
    final Map<String, List<MatchEntity>> finishedByDate = {};
    final Map<String, List<MatchEntity>> liveByDate = {};
    final Map<String, List<MatchEntity>> upcomingByDate = {};

    for (final match in matches) {
      final dateKey = _getDateKey(match.dateTimeGMT);

      // Use extension methods for better consistency
      if (match.isLive) {
        liveByDate.putIfAbsent(dateKey, () => []).add(match);
      } else if (match.isUpcoming) {
        upcomingByDate.putIfAbsent(dateKey, () => []).add(match);
      } else {
        finishedByDate.putIfAbsent(dateKey, () => []).add(match);
      }
    }

    // Sort dates for each category
    final sortedFinishedDates = finishedByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // Recent finished first (reverse order)

    final sortedLiveDates = liveByDate.keys.toList()
      ..sort((a, b) => a.compareTo(b));

    final sortedUpcomingDates = upcomingByDate.keys.toList()
      ..sort((a, b) => a.compareTo(b)); // Upcoming in chronological order

    return MatchesLayout(
      finishedMatchesByDate: Map.fromEntries(
        sortedFinishedDates.map(
          (date) => MapEntry(date, finishedByDate[date]!),
        ),
      ),
      liveMatchesByDate: Map.fromEntries(
        sortedLiveDates.map((date) => MapEntry(date, liveByDate[date]!)),
      ),
      upcomingMatchesByDate: Map.fromEntries(
        sortedUpcomingDates.map(
          (date) => MapEntry(date, upcomingByDate[date]!),
        ),
      ),
    );
  }

  static String _getDateKey(String dateTimeGMT) {
    try {
      final dateTime = DateTime.parse(dateTimeGMT);
      return DateFormat('yyyy-MM-dd').format(dateTime);
    } catch (e) {
      return 'unknown-date';
    }
  }

  static String formatDateForDisplay(String dateKey) {
    try {
      final date = DateTime.parse('${dateKey}T00:00:00Z');
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
      } else if (difference > 1 && difference <= 7) {
        return DateFormat('EEEE').format(date); // Day name
      } else {
        return DateFormat('MMM dd, yyyy').format(date);
      }
    } catch (e) {
      return dateKey;
    }
  }

  static MatchStatusType getStatusType(String status) {
    final lowerStatus = status.toLowerCase();

    // Check for live match indicators
    if (lowerStatus.contains('in progress') ||
        lowerStatus.contains('live') ||
        lowerStatus.contains('ongoing') ||
        lowerStatus.contains('started') ||
        lowerStatus.contains('innings break') ||
        lowerStatus.contains('batting') ||
        lowerStatus.contains('bowling') ||
        lowerStatus.contains('rain delay') ||
        lowerStatus.contains('drinks break')) {
      return MatchStatusType.live;
    }
    // Check for upcoming match indicators
    else if (lowerStatus.contains('upcoming') ||
        lowerStatus.contains('scheduled') ||
        lowerStatus.contains('fixture') ||
        lowerStatus.contains('not started') ||
        lowerStatus.contains('match not started') ||
        lowerStatus == 'tbd' ||
        lowerStatus == 'to be decided') {
      return MatchStatusType.upcoming;
    }
    // Everything else is considered completed
    else {
      return MatchStatusType.completed;
    }
  }
}

class MatchesLayout {
  final Map<String, List<MatchEntity>> finishedMatchesByDate;
  final Map<String, List<MatchEntity>> liveMatchesByDate;
  final Map<String, List<MatchEntity>> upcomingMatchesByDate;

  MatchesLayout({
    required this.finishedMatchesByDate,
    required this.liveMatchesByDate,
    required this.upcomingMatchesByDate,
  });

  bool get hasLiveMatches => liveMatchesByDate.isNotEmpty;
  bool get hasFinishedMatches => finishedMatchesByDate.isNotEmpty;
  bool get hasUpcomingMatches => upcomingMatchesByDate.isNotEmpty;
}

enum MatchStatusType { live, completed, upcoming }
