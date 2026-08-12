import 'package:ocupa2/core/constants/api_endpoints.dart';
import 'package:ocupa2/core/network/api_client.dart';
import 'package:ocupa2/core/network/api_exception.dart';
import 'package:ocupa2/core/network/api_response.dart';
import 'package:ocupa2/core/network/request_auth.dart';
import 'package:ocupa2/features/catalog/data/models/job_type.dart';

abstract interface class CatalogService {
  Future<List<JobType>> getJobTypes();
}

class CatalogServiceImpl implements CatalogService {
  const CatalogServiceImpl({required this._apiClient});

  final ApiClient _apiClient;

  @override
  Future<List<JobType>> getJobTypes() async {
    final Object? rawResponse = await _apiClient.get(
      ApiEndpoints.jobTypes,
      // Endpoint público según el Swagger, no requiere sesión.
      auth: RequestAuth.public,
    );

    try {
      final ApiResponse<List<JobType>> response =
          ApiResponse<List<JobType>>.fromJson(
            rawResponse,
            parseData: (Object? data) {
              final List<dynamic> list = data as List<dynamic>? ?? <dynamic>[];
              return list.map(JobType.fromJson).toList();
            },
          );

      return response.data;
    } on FormatException catch (error) {
      throw ApiException(
        type: ApiExceptionType.responseFormat,
        message:
            'No fue posible leer los tipos de trabajo devueltos por el servidor.',
        originalError: error,
      );
    }
  }
}
