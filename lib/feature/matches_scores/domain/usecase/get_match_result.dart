import 'package:world_of_cricket/feature/matches_scores/domain/repository/match_repository.dart';
import 'package:world_of_cricket/feature/matches_scores/domain/entities/enhanced_match_entities.dart';

class GetMatchResult {
  final MatchRepository repository;

  GetMatchResult(this.repository);

  Future<MatchResultEntity> call(String matchId) {
    return repository.getMatchResult(matchId);
  }
}
