// Enhanced models for the new cricket API
class MatchModel {
  final String id;
  final String name;
  final String matchType;
  final List<String> teams;
  final String status;
  final String dateTimeGMT;
  final String? series;
  final String? venue;
  final String? time;
  final String? liveScore;
  final String? runRate;
  final String? url;
  final List<TeamScoreModel> teamScores;

  MatchModel({
    required this.id,
    required this.name,
    required this.matchType,
    required this.teams,
    required this.status,
    required this.dateTimeGMT,
    this.series,
    this.venue,
    this.time,
    this.liveScore,
    this.runRate,
    this.url,
    this.teamScores = const [],
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    // Handle both old format and new enhanced API format
    List<String> teams = [];
    List<TeamScoreModel> teamScores = [];

    if (json['teams'] != null) {
      final teamsData = json['teams'] as List<dynamic>;
      for (var team in teamsData) {
        if (team is String) {
          teams.add(team);
        } else if (team is Map<String, dynamic>) {
          final teamName = team['name']?.toString() ?? '';
          final teamScore = team['score']?.toString() ?? '';
          teams.add(teamName);
          teamScores.add(TeamScoreModel(name: teamName, score: teamScore));
        }
      }
    }

    // Handle server format with team1, team2
    if (teams.isEmpty && json['team1'] != null && json['team2'] != null) {
      teams.add(json['team1'].toString());
      teams.add(json['team2'].toString());
    }

    return MatchModel(
      id: json['id']?.toString() ?? json['match_id']?.toString() ?? '',
      name:
          json['title']?.toString() ??
          json['name']?.toString() ??
          json['original_title']?.toString() ??
          'Unknown Match',
      matchType:
          json['matchType']?.toString() ??
          json['series']?.toString() ??
          json['series_name']?.toString() ??
          'Unknown',
      teams: teams,
      status:
          json['status']?.toString() ??
          json['match_status']?.toString() ??
          'Unknown Status',
      dateTimeGMT:
          json['dateTimeGMT']?.toString() ?? json['time']?.toString() ?? '',
      series: json['series']?.toString() ?? json['series_name']?.toString(),
      venue: json['venue']?.toString(),
      time: json['time']?.toString(),
      liveScore: json['live_score']?.toString(),
      runRate: json['run_rate']?.toString(),
      url: json['url']?.toString() ?? json['match_url']?.toString(),
      teamScores: teamScores,
    );
  }
}

class TeamScoreModel {
  final String name;
  final String score;

  TeamScoreModel({required this.name, required this.score});

  factory TeamScoreModel.fromJson(Map<String, dynamic> json) {
    return TeamScoreModel(
      name: json['name']?.toString() ?? '',
      score: json['score']?.toString() ?? '',
    );
  }
}

class CompletedMatchModel {
  final String matchId;
  final String title;
  final String result;
  final String date;
  final String team1;
  final String team2;
  final List<String> scores;
  final bool isCompleted;
  final String? series;
  final String? venue;
  final List<TeamScoreModel> teamScores;

  CompletedMatchModel({
    required this.matchId,
    required this.title,
    required this.result,
    required this.date,
    required this.team1,
    required this.team2,
    required this.scores,
    required this.isCompleted,
    this.series,
    this.venue,
    this.teamScores = const [],
  });

  factory CompletedMatchModel.fromJson(Map<String, dynamic> json) {
    List<String> teams = [];
    List<String> scores = [];
    List<TeamScoreModel> teamScores = [];

    if (json['teams'] != null) {
      final teamsData = json['teams'] as List<dynamic>;
      for (var team in teamsData) {
        if (team is Map<String, dynamic>) {
          final teamName = team['name']?.toString() ?? '';
          final teamScore = team['score']?.toString() ?? '';
          teams.add(teamName);
          scores.add(teamScore);
          teamScores.add(TeamScoreModel(name: teamName, score: teamScore));
        }
      }
    }

    // Handle legacy format
    if (json['scores'] != null) {
      scores = (json['scores'] as List<dynamic>)
          .map((e) => e.toString())
          .toList();
    }

    return CompletedMatchModel(
      matchId: json['id']?.toString() ?? json['match_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Unknown Match',
      result:
          json['result']?.toString() ??
          json['status']?.toString() ??
          'Unknown Result',
      date:
          json['date']?.toString() ??
          json['time']?.toString() ??
          'Date not available',
      team1: teams.isNotEmpty
          ? teams[0]
          : (json['team1']?.toString() ?? 'Team 1'),
      team2: teams.length > 1
          ? teams[1]
          : (json['team2']?.toString() ?? 'Team 2'),
      scores: scores,
      isCompleted:
          json['is_completed'] ??
          (json['status']?.toString().toLowerCase().contains('complete') ??
              false),
      series: json['series']?.toString(),
      venue: json['venue']?.toString(),
      teamScores: teamScores,
    );
  }
}

class MatchResultModel {
  final String matchId;
  final String title;
  final String result;
  final List<InningsScoreModel> inningsScores;
  final MatchDetailsModel matchDetails;
  final Map<String, String> urls;
  final String? status;
  final String? venue;
  final String? toss;
  final String? weather;
  final String? currentPartnership;
  final String? currentRunRate;
  final String? requiredRunRate;
  final List<ScorecardModel> scorecard;
  final List<TeamScoreModel> teams;

  MatchResultModel({
    required this.matchId,
    required this.title,
    required this.result,
    required this.inningsScores,
    required this.matchDetails,
    required this.urls,
    this.status,
    this.venue,
    this.toss,
    this.weather,
    this.currentPartnership,
    this.currentRunRate,
    this.requiredRunRate,
    this.scorecard = const [],
    this.teams = const [],
  });

  factory MatchResultModel.fromJson(Map<String, dynamic> json) {
    List<InningsScoreModel> inningsScores = [];
    List<ScorecardModel> scorecard = [];
    List<TeamScoreModel> teams = [];

    // Handle enhanced API scorecard format
    if (json['scorecard'] != null) {
      final scorecardData = json['scorecard'] as List<dynamic>;
      scorecard = scorecardData.map((e) => ScorecardModel.fromJson(e)).toList();
    }

    // Handle teams data
    if (json['teams'] != null) {
      final teamsData = json['teams'] as List<dynamic>;
      teams = teamsData.map((e) => TeamScoreModel.fromJson(e)).toList();
    }

    // Handle legacy innings scores
    if (json['innings_scores'] != null) {
      final inningsData = json['innings_scores'] as List<dynamic>;
      inningsScores = inningsData
          .map((e) => InningsScoreModel.fromJson(e))
          .toList();
    }

    return MatchResultModel(
      matchId: json['match_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Unknown Match',
      result: json['result']?.toString() ?? 'Unknown Result',
      inningsScores: inningsScores,
      matchDetails: MatchDetailsModel.fromJson(json['match_details'] ?? json),
      urls: Map<String, String>.from(json['urls'] ?? {}),
      status: json['status']?.toString(),
      venue: json['venue']?.toString(),
      toss: json['toss']?.toString(),
      weather: json['weather']?.toString(),
      currentPartnership: json['current_partnership']?.toString(),
      currentRunRate: json['current_run_rate']?.toString(),
      requiredRunRate: json['required_run_rate']?.toString(),
      scorecard: scorecard,
      teams: teams,
    );
  }
}

class ScorecardModel {
  final String batsman;
  final String dismissal;
  final String runs;
  final String balls;
  final String fours;
  final String sixes;
  final String strikeRate;

  ScorecardModel({
    required this.batsman,
    required this.dismissal,
    required this.runs,
    required this.balls,
    required this.fours,
    required this.sixes,
    required this.strikeRate,
  });

  factory ScorecardModel.fromJson(Map<String, dynamic> json) {
    return ScorecardModel(
      batsman: json['batsman']?.toString() ?? '',
      dismissal: json['dismissal']?.toString() ?? '',
      runs: json['runs']?.toString() ?? json['R']?.toString() ?? '',
      balls: json['balls']?.toString() ?? json['B']?.toString() ?? '',
      fours: json['fours']?.toString() ?? json['4s']?.toString() ?? '',
      sixes: json['sixes']?.toString() ?? json['6s']?.toString() ?? '',
      strikeRate:
          json['strike_rate']?.toString() ?? json['SR']?.toString() ?? '',
    );
  }
}

class InningsScoreModel {
  final String team;
  final String score;

  InningsScoreModel({required this.team, required this.score});

  factory InningsScoreModel.fromJson(Map<String, dynamic> json) {
    return InningsScoreModel(
      team: json['team']?.toString() ?? '',
      score: json['score']?.toString() ?? '',
    );
  }
}

class MatchDetailsModel {
  final String date;
  final String venue;
  final String toss;
  final String format;
  final String manOfMatch;
  final String? weather;
  final String? summary;
  final String? currentRunRate;
  final String? requiredRunRate;

  MatchDetailsModel({
    required this.date,
    required this.venue,
    required this.toss,
    required this.format,
    required this.manOfMatch,
    this.weather,
    this.summary,
    this.currentRunRate,
    this.requiredRunRate,
  });

  factory MatchDetailsModel.fromJson(Map<String, dynamic> json) {
    return MatchDetailsModel(
      date: json['date']?.toString() ?? json['time']?.toString() ?? '',
      venue: json['venue']?.toString() ?? '',
      toss: json['toss']?.toString() ?? '',
      format: json['format']?.toString() ?? json['series']?.toString() ?? '',
      manOfMatch: json['man_of_match']?.toString() ?? '',
      weather: json['weather']?.toString(),
      summary: json['summary']?.toString(),
      currentRunRate: json['current_run_rate']?.toString(),
      requiredRunRate: json['required_run_rate']?.toString(),
    );
  }
}

// For backward compatibility
typedef LiveMatchModel = MatchModel;
