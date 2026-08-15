import 'package:flutter_test/flutter_test.dart';
import 'package:ocupa2/features/payments/data/models/payment_request.dart';

void main() {
  test('POST /payments no incluye amount ni currency', () {
    final PaymentRequest request = PaymentRequest(
      cardNumber: '4242424242424242',
      cvv: '123',
      expMonth: 12,
      expYear: 2030,
      cardholder: 'Proveedor',
    );

    expect(request.toJson(), <String, dynamic>{
      'cardNumber': '4242424242424242',
      'cvv': '123',
      'expMonth': 12,
      'expYear': 2030,
      'cardholder': 'Proveedor',
    });
    expect(request.toJson().containsKey('amount'), isFalse);
    expect(request.toJson().containsKey('currency'), isFalse);
  });

  test('omite cardholder vacío', () {
    final PaymentRequest request = PaymentRequest(
      cardNumber: '4000000000000002',
      cvv: '999',
      expMonth: 1,
      expYear: 2031,
      cardholder: '  ',
    );

    expect(request.toJson().containsKey('cardholder'), isFalse);
  });
}
