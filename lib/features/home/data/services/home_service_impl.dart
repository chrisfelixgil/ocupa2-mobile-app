import 'package:dio/dio.dart';

import '../models/educational_video.dart';
import '../models/news.dart';
import 'home_service.dart';

class HomeServiceImpl implements HomeService {
  final Dio dio;

  HomeServiceImpl(this.dio);

  // IMPORTANTE:
  // Cambia estos dos paths si Swagger muestra otros.
  static const String newsEndpoint = '/news';
  static const String videosEndpoint = '/videos';

  @override
  Future<List<News>> getNews({
    int limit = 12,
  }) async {
    try {
      final response = await dio.get(
        newsEndpoint,
        queryParameters: {
          'limit': limit,
        },
      );

      final responseData = response.data;

      if (responseData is! Map<String, dynamic>) {
        throw Exception(
          'Formato de respuesta inválido para noticias.',
        );
      }

      if (responseData['ok'] != true) {
        throw Exception(
          'No se pudieron obtener las noticias.',
        );
      }

      final data = responseData['data'];

      if (data is! List) {
        return [];
      }

      return data
          .whereType<Map>()
          .map(
            (item) => News.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    } on DioException catch (e) {
      throw Exception(
        _getDioErrorMessage(
          e,
          'No se pudieron cargar las noticias.',
        ),
      );
    }
  }

  @override
  Future<List<EducationalVideo>> getVideos() async {
    try {
      final response = await dio.get(videosEndpoint);

      final responseData = response.data;

      if (responseData is! Map<String, dynamic>) {
        throw Exception(
          'Formato de respuesta inválido para videos.',
        );
      }

      if (responseData['ok'] != true) {
        throw Exception(
          'No se pudieron obtener los videos.',
        );
      }

      final data = responseData['data'];

      if (data is! List) {
        return [];
      }

      final videos = data
          .whereType<Map>()
          .map(
            (item) => EducationalVideo.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();

      videos.sort(
        (a, b) => a.order.compareTo(b.order),
      );

      return videos;
    } on DioException catch (e) {
      throw Exception(
        _getDioErrorMessage(
          e,
          'No se pudieron cargar los videos.',
        ),
      );
    }
  }

  String _getDioErrorMessage(
    DioException error,
    String defaultMessage,
  ) {
    if (error.response?.statusCode != null) {
      return '$defaultMessage Código: ${error.response!.statusCode}';
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'La conexión con el servidor tardó demasiado.';
    }

    if (error.type == DioExceptionType.connectionError) {
      return 'No fue posible conectarse al servidor.';
    }

    return defaultMessage;
  }
}
