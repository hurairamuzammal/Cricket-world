import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../data/data_sources/news_source.dart';
import '../../data/repository/news_repository_impl.dart';
import '../../domain/usecase/get_top_news_usecase.dart';
import '../../domain/entities/news_entity.dart';

// Provider for HTTP client
final httpClientProvider = Provider<http.Client>((ref) {
  return http.Client();
});

// Provider for news data source
final newsDataSourceProvider = Provider<NewsRemoteDataSource>((ref) {
  return NewsRemoteDataSource(ref.watch(httpClientProvider));
});

// Provider for news repository
final newsRepositoryProvider = Provider<NewsRepositoryImpl>((ref) {
  return NewsRepositoryImpl(ref.watch(newsDataSourceProvider));
});

// Provider for get top news use case
final getTopNewsUseCaseProvider = Provider<GetTopNewsUseCase>((ref) {
  return GetTopNewsUseCase(ref.watch(newsRepositoryProvider));
});

// Provider for news data
final newsProvider = FutureProvider<List<NewsEntity>>((ref) async {
  final useCase = ref.watch(getTopNewsUseCaseProvider);
  return await useCase.call();
});

// Provider for top 5 news (for cards)
final topNewsProvider = FutureProvider<List<NewsEntity>>((ref) async {
  final allNews = await ref.watch(newsProvider.future);
  return allNews.take(5).toList();
});
