import '../../data/model/cricket_api_models.dart';

class MatchEntity {
  final String id;
  final String name;
  final String matchType;
  final List<String> teams;
  final String status;
  final String dateTimeGMT;
  final String? liveScore;
  final String? runRate;
  final String? series;
  final String? venue;
  final String? time;
  final String? url;

  MatchEntity({
    required this.id,
    required this.name,
    required this.matchType,
    required this.teams,
    required this.status,
    required this.dateTimeGMT,
    this.liveScore,
    this.runRate,
    this.series,
    this.venue,
    this.time,
    this.url,
  });

  factory MatchEntity.fromModel(MatchModel model) {
    return MatchEntity(
      id: model.id,
      name: model.name,
      matchType: model.matchType,
      teams: model.teams,
      status: model.status,
      dateTimeGMT: model.dateTimeGMT,
      liveScore: model.liveScore,
      runRate: model.runRate,
      series: model.series,
      venue: model.venue,
      time: model.time,
      url: model.url,
    );
  }
}

// Extension methods for MatchEntity to determine match status
extension MatchEntityExtensions on MatchEntity {
  bool get isLive {
    final statusLower = status.toLowerCase();
    return statusLower.contains('in progress') ||
        statusLower.contains('live') ||
        statusLower.contains('ongoing') ||
        statusLower.contains('innings break') ||
        statusLower.contains('batting') ||
        statusLower.contains('bowling') ||
        statusLower.contains('rain delay') ||
        statusLower.contains('drinks break');
  }

  bool get isUpcoming {
    final statusLower = status.toLowerCase();
    return statusLower.contains('upcoming') ||
        statusLower.contains('scheduled') ||
        statusLower.contains('fixture') ||
        statusLower.contains('not started') ||
        statusLower.contains('match not started') ||
        statusLower == 'tbd' ||
        statusLower == 'to be decided';
  }

  bool get isCompleted {
    // If not live and not upcoming, then it's completed
    return !isLive && !isUpcoming;
  }

  String get formattedTeams {
    if (teams.length >= 2) return '${teams[0]} vs ${teams[1]}';
    if (teams.isNotEmpty) return teams[0];
    return 'Unknown Teams';
  }
}
