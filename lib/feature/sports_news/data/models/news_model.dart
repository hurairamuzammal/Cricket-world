import 'package:world_of_cricket/feature/sports_news/domain/entities/news_entity.dart';

class NewsModel {
  final String title;
  final String urlToImage;
  final String description;
  final String url;

  NewsModel({
    required this.title,
    required this.urlToImage,
    required this.description,
    required this.url,
  });

  factory NewsModel.fromJson(Map<String, dynamic> json) {
    return NewsModel(
      title: json['title'] ?? '',
      urlToImage: json['urlToImage'] ?? '',
      description: json['description'] ?? '',
      url: json['url'] ?? '',
    );
  }

  NewsEntity toEntity() => NewsEntity(
    title: title,
    imageUrl: urlToImage,
    description: description,
    url: url,
  );
}
