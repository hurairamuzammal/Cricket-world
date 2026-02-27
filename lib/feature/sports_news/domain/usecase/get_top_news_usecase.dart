import 'package:world_of_cricket/feature/sports_news/domain/entities/news_entity.dart';
import 'package:world_of_cricket/feature/sports_news/domain/repository/news_repository.dart';

class GetTopNewsUseCase {
  final NewsRepository repository;

  GetTopNewsUseCase(this.repository);

  Future<List<NewsEntity>> call() async {
    return await repository.getTopNews();
  }
}
