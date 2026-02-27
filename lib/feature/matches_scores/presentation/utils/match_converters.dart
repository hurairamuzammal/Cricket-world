import 'package:world_of_cricket/core/models/cricket_models.dart';

import '../../domain/entities/match_entity.dart';

extension MatchEntityToCricketMatch on MatchEntity {
  CricketMatch toCricketMatch() {
    final teamsData = teams
        .map(
          (teamName) => TeamData(
            name: teamName,
            score: '',
            overs: '',
            wickets: '',
            runRate: '',
            imageUrl: null,
            shortName: null,
          ),
        )
        .toList();

    final liveStatus = isLive
        ? 'live'
        : isUpcoming
        ? 'upcoming'
        : 'completed';

    final lastUpdatedValue = dateTimeGMT.isNotEmpty
        ? dateTimeGMT
        : DateTime.now().toUtc().toIso8601String();

    return CricketMatch(
      id: id,
      title: name,
      series: series ?? '',
      status: status,
      teams: teamsData,
      venue: venue ?? '',
      matchType: matchType,
      url: url ?? '',
      liveStatus: liveStatus,
      source: 'legacy',
      lastUpdated: lastUpdatedValue,
      details: null,
      enhancedInfo: null,
    );
  }
}
