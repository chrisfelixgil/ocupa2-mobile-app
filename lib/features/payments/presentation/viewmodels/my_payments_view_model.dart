import 'package:flutter/foundation.dart';

import '../../data/models/payment.dart';
import '../../data/repositories/payment_repository.dart';
import 'my_payments_status.dart';

class MyPaymentsViewModel extends ChangeNotifier {
  MyPaymentsViewModel({required this._paymentRepository});

  final PaymentRepository _paymentRepository;

  MyPaymentsStatus _status = MyPaymentsStatus.idle;
  MyPaymentsStatus get status => _status;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<Payment> _payments = [];
  List<Payment> get payments => _payments;

  Future<void> loadMyPayments() async {
    _status = MyPaymentsStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _payments = await _paymentRepository.getMyPayments();
      _status = MyPaymentsStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _status = MyPaymentsStatus.error;
    }
    notifyListeners();
  }
}
