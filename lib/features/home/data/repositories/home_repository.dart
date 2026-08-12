import '../models/educational_video.dart';
import '../models/news.dart';

abstract class HomeRepository {
  Future<List<News>> getNews({
    int limit = 12,
  });

  Future<List<EducationalVideo>> getVideos();
}
