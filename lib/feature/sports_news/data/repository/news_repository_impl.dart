import '../../domain/entities/news_entity.dart';
import '../../domain/repository/news_repository.dart';
import '../data_sources/news_source.dart';

class NewsRepositoryImpl implements NewsRepository {
  final NewsRemoteDataSource dataSource;

  NewsRepositoryImpl(this.dataSource);

  @override
  Future<List<NewsEntity>> getTopNews() async {
    final models = await dataSource.fetchTopNews();
    return models.map((e) => e.toEntity()).toList();
  }
}
