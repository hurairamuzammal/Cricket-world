// ignore: file_names
import 'package:world_of_cricket/feature/matches_scores/data/source/data_source.dart';
import 'package:world_of_cricket/feature/matches_scores/domain/entities/match_entity.dart';
import 'package:world_of_cricket/feature/matches_scores/domain/entities/enhanced_match_entities.dart'
    as entities;
import 'package:world_of_cricket/feature/matches_scores/domain/repository/match_repository.dart';

/// Repository implementation that uses LOCAL cricket server data
/// Data source: cleaned_cricket_data.json via cricket_server.py (localhost:8000)
class MatchRepositoryImpl extends MatchRepository {
  final MatchRemoteDataSource dataSource;

  MatchRepositoryImpl({required this.dataSource});

  @override
  Future<List<MatchEntity>> getAllMatches({int offset = 0}) async {
    print('📡 Repository: Getting all matches from LOCAL server');
    try {
      final models = await dataSource.fetchMatches(offset: offset);
      print('✅ Repository: Converted ${models.length} matches to entities');
      
      return models
          .map(
            (m) => MatchEntity(
              id: m.id,
              name: m.name,
              matchType: m.matchType,
              teams: m.teams,
              status: m.status,
              dateTimeGMT: m.dateTimeGMT,
              venue: m.venue,
              series: m.series,
              url: m.url,
            ),
          )
          .toList();
    } catch (e) {
      print('❌ Repository: Error getting all matches: $e');
      rethrow;
    }
  }

  @override
  Future<List<entities.DetailedLiveScoreEntity>> getDetailedLiveScores() async {
    print('📡 Repository: Getting detailed live scores from LOCAL server');
    try {
      final allDetailedScores = await dataSource.fetchAllDetailedScores();
      
      // Parse the response and filter for live matches
      if (allDetailedScores['matches'] != null) {
        final matches = allDetailedScores['matches'] as List;
        final liveMatches = matches.where((match) {
          final status = (match['match_status'] ?? match['status'] ?? '').toString().toLowerCase();
          return status == 'live' || status.contains('live');
        }).toList();
        
        print('✅ Repository: Found ${liveMatches.length} live matches with detailed scores');
        
        // Convert to DetailedLiveScoreEntity (basic conversion for now)
        return [];
      }
      
      return [];
    } catch (e) {
      print('❌ Repository: Error getting detailed live scores: $e');
      return [];
    }
  }

  @override
  Future<List<entities.CompletedMatchEntity>> getCompletedMatches() async {
    print('📡 Repository: Getting completed matches from LOCAL server');
    try {
      final models = await dataSource.fetchCompletedMatches();
      print('✅ Repository: Converted ${models.length} completed matches to entities');
      
      return models
          .map(
            (model) => entities.CompletedMatchEntity(
              id: model.matchId,
              name: model.title,
              matchType: model.series ?? 'Unknown',
              teams: [model.team1, model.team2],
              status: 'Completed',
              dateTimeGMT: model.date,
              result: model.result,
              date: model.date,
              scores: model.scores,
              url: '', // LOCAL server data may not have URLs
              isCompleted: model.isCompleted,
              venue: model.venue,
              series: model.series,
            ),
          )
          .toList();
    } catch (e) {
      print('❌ Repository: Error getting completed matches: $e');
      rethrow;
    }
  }

  @override
  Future<entities.MatchResultEntity> getMatchResult(String matchId) async {
    print('📡 Repository: Getting match result for $matchId from LOCAL server');
    try {
      final model = await dataSource.fetchMatchResult(matchId);
      print('✅ Repository: Converted match result to entity');
      
      return entities.MatchResultEntity(
        matchId: model.matchId,
        title: model.title,
        result: model.result,
        inningsScores: model.inningsScores
            .map(
              (innings) => entities.InningsScoreEntity(
                team: innings.team,
                score: innings.score,
              ),
            )
            .toList(),
        date: model.matchDetails.date,
        venue: model.matchDetails.venue,
        toss: model.matchDetails.toss,
        format: model.matchDetails.format,
        manOfMatch: model.matchDetails.manOfMatch,
        matchPageUrl: model.urls['match_page'] ?? '',
        scorecardUrl: model.urls['scorecard'] ?? '',
      );
    } catch (e) {
      print('❌ Repository: Error getting match result: $e');
      rethrow;
    }
  }

  @override
  Future<bool> testConnection() async {
    print('🔌 Repository: Testing LOCAL server connection');
    try {
      final result = await dataSource.testConnection();
      if (result) {
        print('✅ Repository: LOCAL server connection successful');
      } else {
        print('❌ Repository: LOCAL server connection failed');
      }
      return result;
    } catch (e) {
      print('❌ Repository: Error testing connection: $e');
      return false;
    }
  }

  /// Get detailed score for a specific match (additional method not in interface)
  Future<Map<String, dynamic>> getMatchScore(String matchId) async {
    print('📡 Repository: Getting detailed match score for $matchId');
    return await dataSource.fetchMatchScore(matchId);
  }
}
