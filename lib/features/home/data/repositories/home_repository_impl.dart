import '../models/educational_video.dart';
import '../models/news.dart';
import '../services/home_service.dart';
import 'home_repository.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeService service;

  HomeRepositoryImpl(this.service);

  @override
  Future<List<News>> getNews({
    int limit = 12,
  }) {
    return service.getNews(
      limit: limit,
    );
  }

  @override
  Future<List<EducationalVideo>> getVideos() {
    return service.getVideos();
  }
}
