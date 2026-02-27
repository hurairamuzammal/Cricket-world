import 'package:flutter/material.dart';
import 'package:world_of_cricket/feature/sports_news/domain/usecase/get_top_news_usecase.dart';
import '../../domain/entities/news_entity.dart';

class NewsProvider extends ChangeNotifier {
  final GetTopNewsUseCase useCase;

  NewsProvider(this.useCase);

  List<NewsEntity> news = [];
  bool isLoading = false;

  Future<void> fetchNews() async {
    isLoading = true;
    notifyListeners();

    news = await useCase();

    isLoading = false;
    notifyListeners();
  }
}
