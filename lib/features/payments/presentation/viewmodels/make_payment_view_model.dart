import 'package:flutter/foundation.dart';
import 'package:ocupa2/core/network/api_exception.dart';

import '../../data/models/payment.dart';
import '../../data/models/payment_request.dart';
import '../../data/models/payment_status.dart';
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

  bool get isSubmitting => _status == MakePaymentStatus.submitting;

  Future<bool> pay({
    required String cardNumber,
    required String cvv,
    required int expMonth,
    required int expYear,
    String? cardholder,
  }) async {
    _status = MakePaymentStatus.submitting;
    _errorMessage = null;
    _payment = null;
    notifyListeners();

    try {
      _payment = await _paymentRepository.createPayment(
        PaymentRequest(
          cardNumber: cardNumber,
          cvv: cvv,
          expMonth: expMonth,
          expYear: expYear,
          cardholder: cardholder,
        ),
      );

      if (_payment!.status != PaymentStatus.completed) {
        final String? reason = _payment!.declineReason?.trim();
        _errorMessage = (reason != null && reason.isNotEmpty)
            ? reason
            : _defaultDeclineMessage(_payment!.status);
        _status = MakePaymentStatus.error;
        notifyListeners();
        return false;
      }

      _status = MakePaymentStatus.success;
      notifyListeners();

      return true;
    } on ApiException catch (error) {
      _payment = null;
      _errorMessage = error.message;
      _status = MakePaymentStatus.error;
      notifyListeners();

      return false;
    } catch (_) {
      _payment = null;
      _errorMessage = 'No se pudo realizar el pago. Inténtalo nuevamente.';
      _status = MakePaymentStatus.error;
      notifyListeners();

      return false;
    }
  }

  String _defaultDeclineMessage(PaymentStatus status) {
    if (status == PaymentStatus.pending) {
      return 'El pago quedó pendiente. Inténtalo de nuevo en unos minutos.';
    }
    return 'El pago fue rechazado. Verifica los datos de la tarjeta '
        'o utiliza otra tarjeta.';
  }
}
