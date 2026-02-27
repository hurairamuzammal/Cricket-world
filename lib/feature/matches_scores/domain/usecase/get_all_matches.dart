import 'package:world_of_cricket/feature/matches_scores/domain/repository/match_repository.dart';

import '../entities/match_entity.dart';

class GetAllMatches {
  final MatchRepository repository;

  GetAllMatches(this.repository);

  Future<List<MatchEntity>> call({int offset = 0}) {
    return repository.getAllMatches(offset: offset);
  }
}
