import 'package:world_of_cricket/feature/matches_scores/domain/repository/match_repository.dart';
import 'package:world_of_cricket/feature/matches_scores/domain/entities/enhanced_match_entities.dart';

class GetCompletedMatches {
  final MatchRepository repository;

  GetCompletedMatches(this.repository);

  Future<List<CompletedMatchEntity>> call() {
    return repository.getCompletedMatches();
  }
}
