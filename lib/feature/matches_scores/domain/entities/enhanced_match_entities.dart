import 'package:world_of_cricket/feature/matches_scores/domain/entities/match_entity.dart';
import '../../data/model/cricket_api_models.dart';

/// Enhanced match entity for live matches with additional details
class LiveMatchEntity extends MatchEntity {
  @override
  final String url;

  LiveMatchEntity({
    required super.id,
    required super.name,
    required super.matchType,
    required super.teams,
    required super.status,
    required super.dateTimeGMT,
    required this.url,
    super.liveScore,
    super.runRate,
    super.series,
    super.venue,
    super.time,
  });

  factory LiveMatchEntity.fromModel(MatchModel model) {
    return LiveMatchEntity(
      id: model.id,
      name: model.name,
      matchType: model.matchType,
      teams: model.teams,
      status: model.status,
      dateTimeGMT: model.dateTimeGMT,
      url: model.url ?? '',
      liveScore: model.liveScore,
      runRate: model.runRate,
      series: model.series,
      venue: model.venue,
      time: model.time,
    );
  }
}

/// Entity for detailed live score with batting/bowling info
class DetailedLiveScoreEntity {
  final String matchId;
  final String title;
  final String status;
  final String liveScore;
  final String runRate;
  final String batsman1Name;
  final String batsman1Runs;
  final String batsman2Name;
  final String batsman2Runs;
  final String bowler1;
  final String bowler2;
  final String url;

  DetailedLiveScoreEntity({
    required this.matchId,
    required this.title,
    required this.status,
    required this.liveScore,
    required this.runRate,
    required this.batsman1Name,
    required this.batsman1Runs,
    required this.batsman2Name,
    required this.batsman2Runs,
    required this.bowler1,
    required this.bowler2,
    required this.url,
  });
}

/// Entity for completed matches
class CompletedMatchEntity extends MatchEntity {
  final String result;
  final String date;
  final List<String> scores;
  @override
  final String url;
  final bool isCompleted;

  CompletedMatchEntity({
    required super.id,
    required super.name,
    required super.matchType,
    required super.teams,
    required super.status,
    required super.dateTimeGMT,
    required this.result,
    required this.date,
    required this.scores,
    required this.url,
    required this.isCompleted,
    super.liveScore,
    super.runRate,
    super.series,
    super.venue,
    super.time,
  });

  factory CompletedMatchEntity.fromModel(CompletedMatchModel model) {
    return CompletedMatchEntity(
      id: model.matchId,
      name: model.title,
      matchType: model.series ?? 'Cricket',
      teams: [model.team1, model.team2],
      status: model.isCompleted ? 'Completed' : 'In Progress',
      dateTimeGMT: model.date,
      result: model.result,
      date: model.date,
      scores: model.scores,
      url: '',
      isCompleted: model.isCompleted,
      series: model.series,
      venue: model.venue,
    );
  }
}

/// Entity for detailed match results
class MatchResultEntity {
  final String matchId;
  final String title;
  final String result;
  final List<InningsScoreEntity> inningsScores;
  final String date;
  final String venue;
  final String toss;
  final String format;
  final String manOfMatch;
  final String matchPageUrl;
  final String scorecardUrl;
  final String? status;
  final String? weather;
  final String? currentPartnership;
  final String? currentRunRate;
  final String? requiredRunRate;
  final List<ScorecardEntity> scorecard;

  MatchResultEntity({
    required this.matchId,
    required this.title,
    required this.result,
    required this.inningsScores,
    required this.date,
    required this.venue,
    required this.toss,
    required this.format,
    required this.manOfMatch,
    required this.matchPageUrl,
    required this.scorecardUrl,
    this.status,
    this.weather,
    this.currentPartnership,
    this.currentRunRate,
    this.requiredRunRate,
    this.scorecard = const [],
  });

  factory MatchResultEntity.fromModel(MatchResultModel model) {
    return MatchResultEntity(
      matchId: model.matchId,
      title: model.title,
      result: model.result,
      inningsScores: model.inningsScores
          .map((e) => InningsScoreEntity(team: e.team, score: e.score))
          .toList(),
      date: model.matchDetails.date,
      venue: model.venue ?? model.matchDetails.venue,
      toss: model.toss ?? model.matchDetails.toss,
      format: model.matchDetails.format,
      manOfMatch: model.matchDetails.manOfMatch,
      matchPageUrl: model.urls['match'] ?? '',
      scorecardUrl: model.urls['scorecard'] ?? '',
      status: model.status,
      weather: model.weather,
      currentPartnership: model.currentPartnership,
      currentRunRate: model.currentRunRate,
      requiredRunRate: model.requiredRunRate,
      scorecard: model.scorecard
          .map((e) => ScorecardEntity.fromModel(e))
          .toList(),
    );
  }
}

class ScorecardEntity {
  final String batsman;
  final String dismissal;
  final String runs;
  final String balls;
  final String fours;
  final String sixes;
  final String strikeRate;

  ScorecardEntity({
    required this.batsman,
    required this.dismissal,
    required this.runs,
    required this.balls,
    required this.fours,
    required this.sixes,
    required this.strikeRate,
  });

  factory ScorecardEntity.fromModel(ScorecardModel model) {
    return ScorecardEntity(
      batsman: model.batsman,
      dismissal: model.dismissal,
      runs: model.runs,
      balls: model.balls,
      fours: model.fours,
      sixes: model.sixes,
      strikeRate: model.strikeRate,
    );
  }
}

class InningsScoreEntity {
  final String team;
  final String score;

  InningsScoreEntity({required this.team, required this.score});
}
