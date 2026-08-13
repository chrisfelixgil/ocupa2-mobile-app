class PaymentRequest {
  const PaymentRequest({
    required this.amount,
    required this.currency,
    required this.cardNumber,
    required this.cvv,
    required this.expMonth,
    required this.expYear,
    required this.cardholder,
  });

  final double amount;
  final String currency;
  final String cardNumber;
  final String cvv;
  final int expMonth;
  final int expYear;
  final String cardholder;

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'currency': currency,
      'cardNumber': cardNumber,
      'cvv': cvv,
      'expMonth': expMonth,
      'expYear': expYear,
      'cardholder': cardholder,
    };
  }
}