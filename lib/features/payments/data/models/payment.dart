import 'package:flutter/foundation.dart';

import '../payment_datetime.dart';
import 'payment_status.dart';

class Payment {
  final String id;
  final double amount;
  final String currency;
  final PaymentStatus status;
  final String? concept;
  final String? cardLast4;
  final String? cardholder;
  final String? reference;
  final bool consumed;
  final String? offerId;
  final String? declineReason;
  final DateTime? createdAt;

  const Payment({
    required this.id,
    required this.amount,
    required this.currency,
    required this.status,
    this.concept,
    this.cardLast4,
    this.cardholder,
    this.reference,
    this.consumed = false,
    this.offerId,
    this.declineReason,
    this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: (json['id'] ?? json['_id'])?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: json['currency']?.toString() ?? 'DOP',
      status: paymentStatusFromString(json['status']?.toString()),
      concept: json['concept']?.toString(),
      cardLast4: json['cardLast4']?.toString(),
      cardholder: json['cardholder']?.toString(),
      reference: json['reference']?.toString(),
      consumed: json['consumed'] as bool? ?? false,
      offerId: json['offerId']?.toString(),
      declineReason: json['declineReason']?.toString(),
      createdAt: _parseCreatedAt(json['createdAt']),
    );
  }

  static DateTime? _parseCreatedAt(Object? rawValue) {
    final String? raw = rawValue?.toString();
    final DateTime? parsed = PaymentDateTime.parse(raw);

    assert(() {
      debugPrint(
        '[Payment] createdAt raw="$raw" '
        'isUtc=${parsed?.isUtc} '
        'timeZoneOffset=${parsed?.timeZoneOffset} '
        'parsed=$parsed',
      );
      return true;
    }());

    return parsed;
  }
}
