import 'package:ocupa2/core/constants/api_endpoints.dart';
import 'package:ocupa2/core/network/api_client.dart';
import 'package:ocupa2/core/network/api_exception.dart';
import 'package:ocupa2/core/network/api_response.dart';
import 'package:ocupa2/core/network/request_auth.dart';
import 'package:ocupa2/features/my_activity/data/models/experience.dart';

abstract interface class ExperienceService {
  Future<List<Experience>> getExperiences();

  Future<Experience> createExperience({
    required String title,
    required String description,
    String? certificateImage,
  });

  Future<void> deleteExperience(String id);
}

class ExperienceServiceImpl implements ExperienceService {
  const ExperienceServiceImpl({required this._apiClient});

  final ApiClient _apiClient;

  @override
  Future<List<Experience>> getExperiences() async {
    final Object? response = await _apiClient.get(
      ApiEndpoints.myExperiences,
      auth: RequestAuth.protected,
    );

    return _parse(response, (Object? data) {
      final List<dynamic> items = data as List<dynamic>? ?? <dynamic>[];
      return items.map(Experience.fromJson).toList();
    });
  }

  @override
  Future<Experience> createExperience({
    required String title,
    required String description,
    String? certificateImage,
  }) async {
    final Map<String, String> data = <String, String>{
      'title': title,
      'description': description,
    };
    if (certificateImage != null && certificateImage.trim().isNotEmpty) {
      data['certificateImage'] = certificateImage;
    }

    final Object? response = await _apiClient.post(
      ApiEndpoints.myExperiences,
      auth: RequestAuth.protected,
      data: data,
    );

    return _parse(response, Experience.fromJson);
  }

  @override
  Future<void> deleteExperience(String id) async {
    await _apiClient.delete(
      ApiEndpoints.experienceById(id),
      auth: RequestAuth.protected,
    );
  }

  T _parse<T>(Object? response, T Function(Object? data) parseData) {
    try {
      return ApiResponse<T>.fromJson(response, parseData: parseData).data;
    } on FormatException catch (error) {
      throw ApiException(
        type: ApiExceptionType.responseFormat,
        message: 'No fue posible leer la respuesta de experiencias.',
        originalError: error,
      );
    }
  }
}
