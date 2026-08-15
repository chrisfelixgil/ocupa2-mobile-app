import '../../../../core/network/api_client.dart';
import '../../../../core/network/request_auth.dart';
import '../models/payment.dart';
import '../models/payment_request.dart';
import '../payment_endpoints.dart';
import 'payment_service.dart';

class PaymentServiceImpl implements PaymentService {
  PaymentServiceImpl({required this._apiClient});

  final ApiClient _apiClient;

  @override
  Future<Payment> createPayment(PaymentRequest request) async {
    final response = await _apiClient.post(
      PaymentEndpoints.payments,
      data: request.toJson(),
      auth: RequestAuth.protected,
    );

    final data = _asMap(response);

    return Payment.fromJson(data);
  }

  @override
  Future<List<Payment>> getMyPayments() async {
    final response = await _apiClient.get(
      PaymentEndpoints.myPayments,
      auth: RequestAuth.protected,
    );

    return _asList(response)
        .map(Payment.fromJson)
        .toList();
  }

  Map<String, dynamic> _asMap(dynamic response) {
    if (response is Map<String, dynamic>) {
      if (response['data'] is Map) {
        return (response['data'] as Map).cast<String, dynamic>();
      }

      return response;
    }

    if (response is Map && response['data'] is Map) {
      return (response['data'] as Map).cast<String, dynamic>();
    }

    throw const FormatException(
      'Respuesta de pago inválida',
    );
  }

  List<Map<String, dynamic>> _asList(dynamic response) {
    if (response is List) {
      return response
          .map((item) => (item as Map).cast<String, dynamic>())
          .toList();
    }

    if (response is Map && response['data'] is List) {
      return (response['data'] as List)
          .map((item) => (item as Map).cast<String, dynamic>())
          .toList();
    }

    return const [];
  }
}