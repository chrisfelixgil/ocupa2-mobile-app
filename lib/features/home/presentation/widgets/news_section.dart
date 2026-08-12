import 'package:flutter/material.dart';

import '../../data/models/news.dart';
import 'news_card.dart';

class NewsSection extends StatelessWidget {
  final List<News> news;

  const NewsSection({
    super.key,
    required this.news,
  });

  @override
  Widget build(BuildContext context) {
    if (news.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 20,
        ),
        child: Center(
          child: Text(
            'No hay noticias disponibles.',
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      child: Column(
        children: news.map((item) {
          return NewsCard(
            news: item,
          );
        }).toList(),
      ),
    );
  }
}
