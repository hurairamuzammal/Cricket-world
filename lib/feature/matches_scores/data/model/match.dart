class MatchModel {
  final String id;
  final String name;
  final String matchType;
  final String status;
  final List<String> teams;
  final String dateTimeGMT;

  MatchModel({
    required this.id,
    required this.name,
    required this.matchType,
    required this.status,
    required this.teams,
    required this.dateTimeGMT,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Match',
      matchType:
          json['matchType']?.toString() ??
          json['format']?.toString() ??
          'Unknown',
      teams: _parseTeams(json),
      status: json['status']?.toString() ?? 'Unknown',
      dateTimeGMT:
          json['dateTimeGMT']?.toString() ?? json['date']?.toString() ?? '',
    );
  }

  static List<String> _parseTeams(Map<String, dynamic> json) {
    // Try different possible team field structures
    if (json['teams'] != null && json['teams'] is List) {
      return List<String>.from(json['teams']);
    } else if (json['teamInfo'] != null && json['teamInfo'] is List) {
      return (json['teamInfo'] as List)
          .map(
            (team) =>
                team['name']?.toString() ??
                team['shortname']?.toString() ??
                'Unknown Team',
          )
          .toList();
    } else if (json['team1'] != null && json['team2'] != null) {
      return [
        json['team1']?.toString() ?? 'Team 1',
        json['team2']?.toString() ?? 'Team 2',
      ];
    } else {
      return ['Team 1', 'Team 2'];
    }
  }
}
