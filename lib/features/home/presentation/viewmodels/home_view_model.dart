import 'package:flutter/material.dart';

import '../../data/models/educational_video.dart';
import '../../data/models/news.dart';
import '../../data/repositories/home_repository.dart';
import 'home_status.dart';

class HomeViewModel extends ChangeNotifier {
  final HomeRepository repository;

  HomeViewModel(this.repository);

  HomeStatus status = HomeStatus.initial;

  List<News> news = [];
  List<EducationalVideo> videos = [];

  String? errorMessage;

  bool get isLoading => status == HomeStatus.loading;

  bool get hasError => status == HomeStatus.error;

  Future<void> loadHome() async {
    status = HomeStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        repository.getNews(limit: 12),
        repository.getVideos(),
      ]);

      news = results[0] as List<News>;
      videos = results[1] as List<EducationalVideo>;

      status = HomeStatus.success;
    } catch (e) {
      status = HomeStatus.error;

      errorMessage = e
          .toString()
          .replaceFirst('Exception: ', '');
    }

    notifyListeners();
  }

  Future<void> refresh() async {
    await loadHome();
  }
}
