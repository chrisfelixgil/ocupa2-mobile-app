class OfferPayment {
  final double amount;
  final String currency;

  const OfferPayment({required this.amount, required this.currency});

  factory OfferPayment.fromJson(Map<String, dynamic> json) {
    return OfferPayment(
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'DOP',
    );
  }

  Map<String, dynamic> toJson() => {
        'amount': amount,
        'currency': currency,
      };
}
