// Enhanced Cricket Models for unified cricket data

// Main Match Model
class CricketMatch {
  final String id;
  final String title;
  final String series;
  final String status;
  final List<TeamData> teams;
  final String venue;
  final String matchType;
  final String url;
  final String liveStatus;
  final String source;
  final String lastUpdated;
  final CricketMatchDetails? details;
  final EnhancedMatchInfo? enhancedInfo;

  CricketMatch({
    required this.id,
    required this.title,
    required this.series,
    required this.status,
    required this.teams,
    required this.venue,
    required this.matchType,
    required this.url,
    required this.liveStatus,
    required this.source,
    required this.lastUpdated,
    this.details,
    this.enhancedInfo,
  });

  factory CricketMatch.fromJson(Map<String, dynamic> json) {
    List<TeamData> teams = [];
    if (json['teams'] != null) {
      for (var team in json['teams']) {
        teams.add(TeamData.fromJson(team));
      }
    }

    return CricketMatch(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      series: json['series']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      teams: teams,
      venue: json['venue']?.toString() ?? '',
      matchType: json['match_type']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      liveStatus: json['live_status']?.toString() ?? 'unknown',
      source: json['source']?.toString() ?? 'Scraper',
      lastUpdated: json['last_updated']?.toString() ?? '',
      details: json['details'] != null
          ? CricketMatchDetails.fromJson(json['details'])
          : null,
      enhancedInfo: json['enhanced_info'] != null
          ? EnhancedMatchInfo.fromJson(json['enhanced_info'])
          : null,
    );
  }

  // Factory method for cricketdata.org API format
  factory CricketMatch.fromCricketDataOrg(Map<String, dynamic> json) {
    List<TeamData> teams = [];

    // Extract team names from 'teams' array and team info from 'teamInfo'
    if (json['teams'] != null && json['teams'] is List) {
      for (int i = 0; i < json['teams'].length; i++) {
        String teamName = json['teams'][i].toString();
        String? teamImg;
        String? shortName;

        // Get additional team info if available
        if (json['teamInfo'] != null &&
            json['teamInfo'] is List &&
            i < json['teamInfo'].length) {
          teamImg = json['teamInfo'][i]['img'];
          shortName = json['teamInfo'][i]['shortname'];
        }

        // Get team scores if available
        String score = '';
        String overs = '';
        String wickets = '';

        if (json['score'] != null &&
            json['score'] is List &&
            i < json['score'].length) {
          final teamScore = json['score'][i];
          score = '${teamScore['r'] ?? 0}';
          wickets = '${teamScore['w'] ?? 0}';
          overs = '${teamScore['o'] ?? 0}';
        }

        teams.add(
          TeamData(
            name: teamName,
            score: score,
            overs: overs,
            wickets: wickets,
            runRate: '', // Not provided in cricketdata.org format
            imageUrl: teamImg,
            shortName: shortName,
          ),
        );
      }
    }

    return CricketMatch(
      id: json['id']?.toString() ?? '',
      title: json['name']?.toString() ?? '',
      series: json['series']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      teams: teams,
      venue: json['venue']?.toString() ?? '',
      matchType: json['matchType']?.toString() ?? '',
      url: '', // Not provided in cricketdata.org format
      liveStatus: _mapMatchStatus(json['status']?.toString() ?? ''),
      source: 'CricketData.org',
      lastUpdated: json['dateTimeGMT']?.toString() ?? '',
      details: null,
      enhancedInfo: null,
    );
  }

  // Helper method to map cricketdata.org status to internal format
  static String _mapMatchStatus(String status) {
    if (status.toLowerCase().contains('not started')) return 'upcoming';
    if (status.toLowerCase().contains('won by')) return 'completed';
    return 'live';
  }

  CricketMatch copyWith({
    String? id,
    String? title,
    String? series,
    String? status,
    List<TeamData>? teams,
    String? venue,
    String? matchType,
    String? url,
    String? liveStatus,
    String? source,
    String? lastUpdated,
    CricketMatchDetails? details,
    EnhancedMatchInfo? enhancedInfo,
  }) {
    return CricketMatch(
      id: id ?? this.id,
      title: title ?? this.title,
      series: series ?? this.series,
      status: status ?? this.status,
      teams: teams ?? this.teams,
      venue: venue ?? this.venue,
      matchType: matchType ?? this.matchType,
      url: url ?? this.url,
      liveStatus: liveStatus ?? this.liveStatus,
      source: source ?? this.source,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      details: details ?? this.details,
      enhancedInfo: enhancedInfo ?? this.enhancedInfo,
    );
  }

  bool get isUpcoming {
    return liveStatus.toLowerCase() == 'upcoming';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'series': series,
      'status': status,
      'teams': teams.map((team) => team.toJson()).toList(),
      'venue': venue,
      'match_type': matchType,
      'url': url,
      'live_status': liveStatus,
      'source': source,
      'last_updated': lastUpdated,
      'details': details?.toJson(),
      'enhanced_info': enhancedInfo?.toJson(),
    };
  }
}

// Enhanced Match Information from Scrapy Data
class EnhancedMatchInfo {
  final String? matchDate;
  final String? matchTime;
  final String? dayNight;
  final String? city;
  final String? state;
  final String? country;
  final int? matchNumber;
  final int? targetScore;
  final int? ballsRemaining;
  final String? result;
  final String? margin;
  final String? tossWinner;
  final String? tossDecision;
  final double? qualityScore;
  final String? originalTitle;
  final String? originalDescription;

  EnhancedMatchInfo({
    this.matchDate,
    this.matchTime,
    this.dayNight,
    this.city,
    this.state,
    this.country,
    this.matchNumber,
    this.targetScore,
    this.ballsRemaining,
    this.result,
    this.margin,
    this.tossWinner,
    this.tossDecision,
    this.qualityScore,
    this.originalTitle,
    this.originalDescription,
  });

  factory EnhancedMatchInfo.fromJson(Map<String, dynamic> json) {
    return EnhancedMatchInfo(
      matchDate: json['match_date']?.toString(),
      matchTime: json['match_time']?.toString(),
      dayNight: json['day_night']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      country: json['country']?.toString(),
      matchNumber: json['match_number'] as int?,
      targetScore: json['target_score'] as int?,
      ballsRemaining: json['balls_remaining'] as int?,
      result: json['result']?.toString(),
      margin: json['margin']?.toString(),
      tossWinner: json['toss_winner']?.toString(),
      tossDecision: json['toss_decision']?.toString(),
      qualityScore: (json['quality_score'] as num?)?.toDouble(),
      originalTitle: json['original_title']?.toString(),
      originalDescription: json['original_description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'match_date': matchDate,
      'match_time': matchTime,
      'day_night': dayNight,
      'city': city,
      'state': state,
      'country': country,
      'match_number': matchNumber,
      'target_score': targetScore,
      'balls_remaining': ballsRemaining,
      'result': result,
      'margin': margin,
      'toss_winner': tossWinner,
      'toss_decision': tossDecision,
      'quality_score': qualityScore,
      'original_title': originalTitle,
      'original_description': originalDescription,
    };
  }

  // Helper methods for formatted display
  String get formattedDateTime {
    if (matchDate == null && matchTime == null) return '';
    final date = matchDate ?? '';
    final time = matchTime ?? '';
    return '$date $time'.trim();
  }

  String get formattedVenue {
    final parts = <String>[];
    if (city != null) parts.add(city!);
    if (state != null) parts.add(state!);
    if (country != null) parts.add(country!);
    return parts.join(', ');
  }

  String get formattedResult {
    if (result == null) return '';
    if (margin != null) {
      return '$result (margin: $margin)';
    }
    return result!;
  }

  String get formattedToss {
    if (tossWinner == null) return '';
    final decision = tossDecision ?? 'opted';
    return '$tossWinner won toss, chose to $decision';
  }
}

// Team Data Model
class TeamData {
  final String name;
  final String score;
  final String overs;
  final String wickets;
  final String runRate;
  final String? imageUrl;
  final String? shortName;

  TeamData({
    required this.name,
    required this.score,
    required this.overs,
    required this.wickets,
    required this.runRate,
    this.imageUrl,
    this.shortName,
  });

  factory TeamData.fromJson(Map<String, dynamic> json) {
    return TeamData(
      name: json['name']?.toString() ?? '',
      score: json['score']?.toString() ?? 'TBD',
      overs: json['overs']?.toString() ?? '',
      wickets: json['wickets']?.toString() ?? '',
      runRate: json['run_rate']?.toString() ?? '',
      imageUrl: json['image_url']?.toString(),
      shortName: json['short_name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'score': score,
      'overs': overs,
      'wickets': wickets,
      'run_rate': runRate,
      'image_url': imageUrl,
      'short_name': shortName,
    };
  }
}

// Detailed Match Information
class CricketMatchDetails {
  final List<BatsmanData> currentBatsmen;
  final BowlerData? currentBowler;
  final List<String> recentOvers;
  final String? result;
  final String? toss;
  final String? currentPartnership;
  final String? targetInfo;

  CricketMatchDetails({
    required this.currentBatsmen,
    this.currentBowler,
    required this.recentOvers,
    this.result,
    this.toss,
    this.currentPartnership,
    this.targetInfo,
  });

  factory CricketMatchDetails.fromJson(Map<String, dynamic> json) {
    List<BatsmanData> batsmen = [];
    if (json['current_batsmen'] != null) {
      for (var batsman in json['current_batsmen']) {
        batsmen.add(BatsmanData.fromJson(batsman));
      }
    }

    List<String> overs = [];
    if (json['recent_overs'] != null) {
      for (var over in json['recent_overs']) {
        overs.add(over.toString());
      }
    }

    return CricketMatchDetails(
      currentBatsmen: batsmen,
      currentBowler: json['current_bowler'] != null
          ? BowlerData.fromJson(json['current_bowler'])
          : null,
      recentOvers: overs,
      result: json['result']?.toString(),
      toss: json['toss']?.toString(),
      currentPartnership: json['current_partnership']?.toString(),
      targetInfo: json['target_info']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_batsmen': currentBatsmen.map((b) => b.toJson()).toList(),
      'current_bowler': currentBowler?.toJson(),
      'recent_overs': recentOvers,
      'result': result,
      'toss': toss,
      'current_partnership': currentPartnership,
      'target_info': targetInfo,
    };
  }
}

// Batsman Data Model
class BatsmanData {
  final String name;
  final String runs;
  final String balls;
  final String fours;
  final String sixes;
  final double strikeRate;

  BatsmanData({
    required this.name,
    required this.runs,
    required this.balls,
    required this.fours,
    required this.sixes,
    required this.strikeRate,
  });

  factory BatsmanData.fromJson(Map<String, dynamic> json) {
    return BatsmanData(
      name: json['name']?.toString() ?? '',
      runs: json['runs']?.toString() ?? '0',
      balls: json['balls']?.toString() ?? '0',
      fours: json['fours']?.toString() ?? '0',
      sixes: json['sixes']?.toString() ?? '0',
      strikeRate: (json['strike_rate'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'runs': runs,
      'balls': balls,
      'fours': fours,
      'sixes': sixes,
      'strike_rate': strikeRate,
    };
  }
}

// Bowler Data Model
class BowlerData {
  final String name;
  final String overs;
  final String maidens;
  final String runs;
  final String wickets;
  final double economy;

  BowlerData({
    required this.name,
    required this.overs,
    required this.maidens,
    required this.runs,
    required this.wickets,
    required this.economy,
  });

  factory BowlerData.fromJson(Map<String, dynamic> json) {
    return BowlerData(
      name: json['name']?.toString() ?? '',
      overs: json['overs']?.toString() ?? '0',
      maidens: json['maidens']?.toString() ?? '0',
      runs: json['runs']?.toString() ?? '0',
      wickets: json['wickets']?.toString() ?? '0',
      economy: (json['economy'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'overs': overs,
      'maidens': maidens,
      'runs': runs,
      'wickets': wickets,
      'economy': economy,
    };
  }
}

// API Response Model
class CricketApiResponse {
  final bool success;
  final List<CricketMatch> data;
  final CricketApiMeta? meta;
  final String? error;

  CricketApiResponse({
    required this.success,
    required this.data,
    this.meta,
    this.error,
  });

  factory CricketApiResponse.fromJson(Map<String, dynamic> json) {
    List<CricketMatch> matches = [];

    if (json['data'] != null) {
      if (json['data'] is List) {
        for (var match in json['data']) {
          matches.add(CricketMatch.fromJson(match));
        }
      } else if (json['data'] is Map<String, dynamic>) {
        matches.add(CricketMatch.fromJson(json['data']));
      }
    }

    return CricketApiResponse(
      success: json['success'] ?? false,
      data: matches,
      meta: json['meta'] != null ? CricketApiMeta.fromJson(json['meta']) : null,
      error: json['error']?.toString(),
    );
  }
}

// API Meta Information
class CricketApiMeta {
  final int totalCount;
  final int filteredCount;
  final String filterType;
  final String? lastUpdated;
  final String apiVersion;

  CricketApiMeta({
    required this.totalCount,
    required this.filteredCount,
    required this.filterType,
    this.lastUpdated,
    required this.apiVersion,
  });

  factory CricketApiMeta.fromJson(Map<String, dynamic> json) {
    return CricketApiMeta(
      totalCount: json['total_count'] ?? 0,
      filteredCount: json['filtered_count'] ?? 0,
      filterType: json['filter_type']?.toString() ?? 'all',
      lastUpdated: json['last_updated']?.toString(),
      apiVersion: json['api_version']?.toString() ?? '4.0',
    );
  }
}

// Team Statistics Model
class TeamStats {
  final String teamName;
  final int totalMatches;
  final int liveMatches;
  final int completedMatches;
  final int upcomingMatches;

  TeamStats({
    required this.teamName,
    required this.totalMatches,
    required this.liveMatches,
    required this.completedMatches,
    required this.upcomingMatches,
  });

  factory TeamStats.fromJson(String teamName, Map<String, dynamic> json) {
    return TeamStats(
      teamName: teamName,
      totalMatches: json['total_matches'] ?? 0,
      liveMatches: json['live_matches'] ?? 0,
      completedMatches: json['completed_matches'] ?? 0,
      upcomingMatches: json['upcoming_matches'] ?? 0,
    );
  }
}

// API Statistics Model
class ApiStatistics {
  final ApiOverview overview;
  final Map<String, TeamStats> teams;
  final Map<String, bool> features;

  ApiStatistics({
    required this.overview,
    required this.teams,
    required this.features,
  });

  factory ApiStatistics.fromJson(Map<String, dynamic> json) {
    Map<String, TeamStats> teams = {};
    if (json['teams'] != null) {
      final teamsData = json['teams'] as Map<String, dynamic>;
      teamsData.forEach((teamName, teamData) {
        teams[teamName] = TeamStats.fromJson(teamName, teamData);
      });
    }

    Map<String, bool> features = {};
    if (json['features'] != null) {
      final featuresData = json['features'] as Map<String, dynamic>;
      featuresData.forEach((key, value) {
        features[key] = value == true;
      });
    }

    return ApiStatistics(
      overview: ApiOverview.fromJson(json['overview'] ?? {}),
      teams: teams,
      features: features,
    );
  }
}

// API Overview Model
class ApiOverview {
  final int totalMatches;
  final int liveMatches;
  final int completedMatches;
  final int upcomingMatches;
  final int upcomingLimitedTo;
  final String? lastUpdate;
  final bool scraperRunning;
  final int updateIntervalSeconds;

  ApiOverview({
    required this.totalMatches,
    required this.liveMatches,
    required this.completedMatches,
    required this.upcomingMatches,
    required this.upcomingLimitedTo,
    this.lastUpdate,
    required this.scraperRunning,
    required this.updateIntervalSeconds,
  });

  factory ApiOverview.fromJson(Map<String, dynamic> json) {
    return ApiOverview(
      totalMatches: json['total_matches'] ?? 0,
      liveMatches: json['live_matches'] ?? 0,
      completedMatches: json['completed_matches'] ?? 0,
      upcomingMatches: json['upcoming_matches'] ?? 0,
      upcomingLimitedTo: json['upcoming_limited_to'] ?? 10,
      lastUpdate: json['last_update']?.toString(),
      scraperRunning: json['scraper_running'] ?? false,
      updateIntervalSeconds: json['update_interval_seconds'] ?? 90,
    );
  }
}

// CricketData.org API Response Models
class CricketDataOrgResponse {
  final String apikey;
  final List<CricketMatch> data;
  final String status;
  final CricketDataOrgInfo? info;

  CricketDataOrgResponse({
    required this.apikey,
    required this.data,
    required this.status,
    this.info,
  });

  factory CricketDataOrgResponse.fromJson(Map<String, dynamic> json) {
    List<CricketMatch> matches = [];
    if (json['data'] != null && json['data'] is List) {
      for (var matchData in json['data']) {
        matches.add(CricketMatch.fromCricketDataOrg(matchData));
      }
    }

    return CricketDataOrgResponse(
      apikey: json['apikey']?.toString() ?? '',
      data: matches,
      status: json['status']?.toString() ?? 'unknown',
      info: json['info'] != null
          ? CricketDataOrgInfo.fromJson(json['info'])
          : null,
    );
  }

  // Convert to standard CricketApiResponse format
  CricketApiResponse toCricketApiResponse() {
    return CricketApiResponse(
      success: status == 'success',
      data: data,
      meta: CricketApiMeta(
        totalCount: data.length,
        filteredCount: data.length,
        filterType: 'all',
        lastUpdated: DateTime.now().toIso8601String(),
        apiVersion: 'CricketData.org-1.0',
      ),
      error: status != 'success' ? 'API returned status: $status' : null,
    );
  }
}

class CricketDataOrgInfo {
  final int hitsToday;
  final int hitsUsed;
  final int hitsLimit;
  final int credits;
  final int server;
  final int offsetRows;
  final int totalRows;
  final double queryTime;

  CricketDataOrgInfo({
    required this.hitsToday,
    required this.hitsUsed,
    required this.hitsLimit,
    required this.credits,
    required this.server,
    required this.offsetRows,
    required this.totalRows,
    required this.queryTime,
  });

  factory CricketDataOrgInfo.fromJson(Map<String, dynamic> json) {
    return CricketDataOrgInfo(
      hitsToday: json['hitsToday'] ?? 0,
      hitsUsed: json['hitsUsed'] ?? 0,
      hitsLimit: json['hitsLimit'] ?? 0,
      credits: json['credits'] ?? 0,
      server: json['server'] ?? 0,
      offsetRows: json['offsetRows'] ?? 0,
      totalRows: json['totalRows'] ?? 0,
      queryTime: (json['queryTime'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
