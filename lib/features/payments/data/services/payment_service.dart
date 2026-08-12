import '../models/payment.dart';
import '../models/payment_request.dart';

abstract class PaymentService {
  /// POST /payments
  Future<Payment> createPayment(PaymentRequest request);

  /// GET /me/payments
  Future<List<Payment>> getMyPayments();
}
