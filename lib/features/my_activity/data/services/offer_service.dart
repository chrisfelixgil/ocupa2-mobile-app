import 'package:ocupa2/core/constants/api_endpoints.dart';
import 'package:ocupa2/core/network/api_client.dart';
import 'package:ocupa2/core/network/api_exception.dart';
import 'package:ocupa2/core/network/api_response.dart';
import 'package:ocupa2/core/network/request_auth.dart';
import 'package:ocupa2/features/my_activity/data/models/published_offer.dart';

abstract interface class OfferService {
  Future<List<PublishedOffer>> getMyOffers();

  Future<void> deactivateOffer({required String offerId});
  Future<void> deleteOffer({required String offerId});
}

class OfferServiceImpl implements OfferService {
  const OfferServiceImpl({required this._apiClient});

  final ApiClient _apiClient;

  @override
  Future<List<PublishedOffer>> getMyOffers() async {
    final Object? response = await _apiClient.get(
      ApiEndpoints.myOffers,
      auth: RequestAuth.protected,
    );

    return _parse(response, (Object? data) {
      final List<dynamic> items = data as List<dynamic>? ?? <dynamic>[];
      return items.map(PublishedOffer.fromJson).toList();
    });
  }

  @override
  Future<void> deactivateOffer({required String offerId}) async {
    await _apiClient.post(
      ApiEndpoints.deactivateOffer(offerId),
      auth: RequestAuth.protected,
    );
  }

  @override
  Future<void> deleteOffer({required String offerId}) async {
    await _apiClient.delete(
      ApiEndpoints.offerDetail(offerId),
      auth: RequestAuth.protected,
    );
  }

  T _parse<T>(Object? response, T Function(Object? data) parseData) {
    try {
      return ApiResponse<T>.fromJson(response, parseData: parseData).data;
    } on FormatException catch (error) {
      throw ApiException(
        type: ApiExceptionType.responseFormat,
        message: 'No fue posible leer la respuesta de ofertas.',
        originalError: error,
      );
    }
  }
}
