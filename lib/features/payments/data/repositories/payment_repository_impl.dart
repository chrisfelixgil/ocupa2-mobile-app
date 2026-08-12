import '../models/payment.dart';
import '../models/payment_request.dart';
import '../services/payment_service.dart';
import 'payment_repository.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  PaymentRepositoryImpl({required PaymentService paymentService})
      : _paymentService = paymentService;

  final PaymentService _paymentService;

  @override
  Future<Payment> createPayment(PaymentRequest request) {
    return _paymentService.createPayment(request);
  }

  @override
  Future<List<Payment>> getMyPayments() {
    return _paymentService.getMyPayments();
  }
}
