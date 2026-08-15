import 'package:ocupa2/core/constants/api_endpoints.dart';
import 'package:ocupa2/core/network/api_client.dart';
import 'package:ocupa2/core/network/api_exception.dart';
import 'package:ocupa2/core/network/api_response.dart';
import 'package:ocupa2/core/network/request_auth.dart';
import 'package:ocupa2/features/job_search/data/models/apply_request.dart';
import 'package:ocupa2/features/job_search/data/models/offer.dart';
import 'package:ocupa2/features/job_search/data/services/job_search_service.dart';

class JobSearchServiceImpl implements JobSearchService {
  const JobSearchServiceImpl({required this._apiClient});

  final ApiClient _apiClient;

  @override
  Future<List<Offer>> getOffers({
    String? jobTypeKey,
    String? contractType,
  }) async {
    final Map<String, dynamic> query = <String, dynamic>{
      if (jobTypeKey != null && jobTypeKey.isNotEmpty) 'jobTypeKey': jobTypeKey,
      if (contractType != null && contractType.isNotEmpty)
        'contractType': contractType,
    };

    final Object? rawResponse = await _apiClient.get(
      ApiEndpoints.offers,
      auth: RequestAuth.protected,
      queryParameters: query.isEmpty ? null : query,
    );

    return _parseSuccess<List<Offer>>(rawResponse, (Object? data) {
      final List<dynamic> list = data as List<dynamic>? ?? <dynamic>[];
      return list.map(Offer.fromJson).toList();
    });
  }

  @override
  Future<Offer> getOfferById(String id) async {
    final Object? rawResponse = await _apiClient.get(
      ApiEndpoints.offerDetail(id),
      auth: RequestAuth.protected,
    );

    return _parseSuccess<Offer>(rawResponse, Offer.fromJson);
  }

  @override
  Future<void> applyToOffer(String offerId, ApplyRequest request) async {
    await _apiClient.post(
      ApiEndpoints.applyToOffer(offerId),
      auth: RequestAuth.protected,
      data: request.toJson(),
    );
  }

  T _parseSuccess<T>(Object? rawResponse, T Function(Object? data) parser) {
    try {
      final ApiResponse<T> response = ApiResponse<T>.fromJson(
        rawResponse,
        parseData: parser,
      );

      return response.data;
    } on FormatException catch (error) {
      throw ApiException(
        type: ApiExceptionType.responseFormat,
        message:
            'El servidor devolvió una respuesta con un formato inesperado.',
        originalError: error,
      );
    }
  }
}
