import '../models/payment.dart';
import '../models/payment_request.dart';

abstract class PaymentRepository {
  Future<Payment> createPayment(PaymentRequest request);
  Future<List<Payment>> getMyPayments();
}
