import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:world_of_cricket/core/constants/api_constants.dart';
import '../models/news_model.dart';

class NewsRemoteDataSource {
  final http.Client client;

  NewsRemoteDataSource(this.client);

  Future<List<NewsModel>> fetchTopNews() async {
    final response = await client.get(
      // temprary turning off
      Uri.parse(
        // '${ApiConstants.newsApiBaseUrl}/everything?q=&pageSize=15&sortBy=publishedAt&language=en&apiKey=${ApiConstants.newsApiKey}',
        '${ApiConstants.newsApiBaseUrl}/everything?q=cricket&pageSize=15&sortBy=publishedAt&language=en&apiKey=${ApiConstants.newsApiKey}',
      ),
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final List articles = jsonData['articles'];
      return articles.map((json) => NewsModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch news');
    }
  }
}
