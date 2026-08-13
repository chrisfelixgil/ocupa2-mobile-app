import 'package:ocupa2/core/constants/api_endpoints.dart';
import 'package:ocupa2/core/network/api_client.dart';
import 'package:ocupa2/core/network/api_exception.dart';
import 'package:ocupa2/core/network/api_response.dart';
import 'package:ocupa2/core/network/request_auth.dart';
import 'package:ocupa2/features/my_activity/data/models/application.dart';

abstract interface class ApplicationService {
  Future<List<Application>> getMyApplications();

  Future<Application> updateApplication({
    required String id,
    int? rating,
    String? status,
    num? salary,
    String? currency,
    String? startDate,
    String? duration,
  });
}

class ApplicationServiceImpl implements ApplicationService {
  const ApplicationServiceImpl({required this._apiClient});

  final ApiClient _apiClient;

  @override
  Future<List<Application>> getMyApplications() async {
    final Object? response = await _apiClient.get(
      ApiEndpoints.myApplications,
      auth: RequestAuth.protected,
    );

    return _parse(response, (Object? data) {
      final List<dynamic> items = data as List<dynamic>? ?? <dynamic>[];
      return items.map(Application.fromJson).toList();
    });
  }

  @override
  Future<Application> updateApplication({
    required String id,
    int? rating,
    String? status,
    num? salary,
    String? currency,
    String? startDate,
    String? duration,
  }) async {
    final Object? response = await _apiClient.patch(
      ApiEndpoints.applicationById(id),
      auth: RequestAuth.protected,
      data: <String, dynamic>{
        'rating': ?rating,
        'status': ?status,
        'salary': ?salary,
        'currency': ?currency,
        'startDate': ?startDate,
        'duration': ?duration,
      },
    );

    return _parse(response, Application.fromJson);
  }

  T _parse<T>(Object? response, T Function(Object? data) parseData) {
    try {
      return ApiResponse<T>.fromJson(response, parseData: parseData).data;
    } on FormatException catch (error) {
      throw ApiException(
        type: ApiExceptionType.responseFormat,
        message: 'No fue posible leer la respuesta de aplicaciones.',
        originalError: error,
      );
    }
  }
}
