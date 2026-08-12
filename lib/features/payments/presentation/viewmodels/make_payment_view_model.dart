import 'package:flutter/foundation.dart';

import '../../data/models/payment.dart';
import '../../data/models/payment_request.dart';
import '../../data/repositories/payment_repository.dart';
import 'make_payment_status.dart';

class MakePaymentViewModel extends ChangeNotifier {
  MakePaymentViewModel({required this._paymentRepository});

  final PaymentRepository _paymentRepository;

  MakePaymentStatus _status = MakePaymentStatus.idle;
  MakePaymentStatus get status => _status;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Payment? _payment;
  Payment? get payment => _payment;

  bool get isSubmitting =>
      _status == MakePaymentStatus.submitting;

  Future<bool> pay({
    required double amount,
    String currency = 'DOP',
    required String cardNumber,
    required String cvv,
    required int expMonth,
    required int expYear,
    required String cardholder,
  }) async {
    _status = MakePaymentStatus.submitting;
    _errorMessage = null;
    notifyListeners();

    try {
      _payment = await _paymentRepository.createPayment(
        PaymentRequest(
          amount: amount,
          currency: currency,
          cardNumber: cardNumber,
          cvv: cvv,
          expMonth: expMonth,
          expYear: expYear,
          cardholder: cardholder,
        ),
      );

      _status = MakePaymentStatus.success;
      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _status = MakePaymentStatus.error;
      notifyListeners();

      return false;
    }
  }
}