import '../../../../core/network/api_client.dart';
import '../job_posting_endpoints.dart';
import '../models/create_offer_request.dart';
import '../models/offer.dart';
import 'job_posting_service.dart';
import 'package:ocupa2/core/network/request_auth.dart';

class JobPostingServiceImpl implements JobPostingService {
  JobPostingServiceImpl({required this._apiClient});

  final ApiClient _apiClient;

  @override
  Future<Offer> createOffer(CreateOfferRequest request) async {
    final response = await _apiClient.post(
      JobPostingEndpoints.offers,
      auth: RequestAuth.protected,
      data: request.toJson(),
    );

    return Offer.fromJson(_asMap(response));
  }

  @override
  Future<List<Offer>> getMyOffers() async {
    final response = await _apiClient.get(
      JobPostingEndpoints.myOffers,
      auth: RequestAuth.protected,
    );

    final list = _asList(response);

    return list.map((json) => Offer.fromJson(json)).toList();
  }

  @override
  Future<Offer> getOfferById(String id) async {
    final response = await _apiClient.get(
      JobPostingEndpoints.offerById(id),
      auth: RequestAuth.protected,
    );

    return Offer.fromJson(_asMap(response));
  }

  @override
  Future<void> deactivateOffer(String id) async {
    await _apiClient.post(
      JobPostingEndpoints.deactivateOffer(id),
      auth: RequestAuth.protected,
    );
  }

  List<Map<String, dynamic>> _asList(dynamic response) {
    dynamic data = response;

    if (response is Map) {
      data = response['data'];
    }

    if (data is! List) {
      return const [];
    }

    return data
        .whereType<Map>()
        .map(
          (item) => Map<String, dynamic>.from(item),
        )
        .toList();
  }

  Map<String, dynamic> _asMap(dynamic response) {
    dynamic data = response;

    if (response is Map && response['data'] is Map) {
      data = response['data'];
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return const {};
  }
}