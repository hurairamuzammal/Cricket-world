import 'package:world_of_cricket/feature/matches_scores/domain/entities/match_entity.dart';
import 'package:world_of_cricket/feature/matches_scores/domain/entities/enhanced_match_entities.dart';

abstract class MatchRepository {
  /// Get all current live matches
  Future<List<MatchEntity>> getAllMatches({int offset = 0});

  /// Get detailed scores for all live matches
  Future<List<DetailedLiveScoreEntity>> getDetailedLiveScores();

  /// Get all completed matches
  Future<List<CompletedMatchEntity>> getCompletedMatches();

  /// Get detailed result for a specific match
  Future<MatchResultEntity> getMatchResult(String matchId);

  /// Test API connection
  Future<bool> testConnection();
}
