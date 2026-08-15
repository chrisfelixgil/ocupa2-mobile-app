/// Body de POST /payments según OpenAPI.
///
/// No incluye amount ni currency: el cobro simulado es siempre 1.00 USD.
class PaymentRequest {
  const PaymentRequest({
    required this.cardNumber,
    required this.cvv,
    required this.expMonth,
    required this.expYear,
    this.cardholder,
  });

  final String cardNumber;
  final String cvv;
  final int expMonth;
  final int expYear;
  final String? cardholder;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'cardNumber': cardNumber,
      'cvv': cvv,
      'expMonth': expMonth,
      'expYear': expYear,
      if (cardholder != null && cardholder!.trim().isNotEmpty)
        'cardholder': cardholder!.trim(),
    };
  }
}
