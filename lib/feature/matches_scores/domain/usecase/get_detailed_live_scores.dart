import 'package:world_of_cricket/feature/matches_scores/domain/repository/match_repository.dart';
import 'package:world_of_cricket/feature/matches_scores/domain/entities/enhanced_match_entities.dart';

class GetDetailedLiveScores {
  final MatchRepository repository;

  GetDetailedLiveScores(this.repository);

  Future<List<DetailedLiveScoreEntity>> call() {
    return repository.getDetailedLiveScores();
  }
}
