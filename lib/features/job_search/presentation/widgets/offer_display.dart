import 'package:ocupa2/features/job_search/data/models/offer.dart';

/// Etiquetas de pantalla para una oferta (lista, detalle y mapa).
abstract final class OfferDisplay {
  static const List<String> _months = <String>[
    'Ene',
    'Feb',
    'Mar',
    'Abr',
    'May',
    'Jun',
    'Jul',
    'Ago',
    'Sep',
    'Oct',
    'Nov',
    'Dic',
  ];

  static String contractLabel(String contractType) {
    switch (contractType.toLowerCase()) {
      case 'temporal':
        return 'Temporal';
      case 'fijo':
        return 'Fijo';
      case 'horas':
        return 'Por horas';
      default:
        return contractType;
    }
  }

  static String paymentFrequency(String contractType) {
    switch (contractType.toLowerCase()) {
      case 'horas':
        return 'Por horas';
      case 'fijo':
        return 'Fijo';
      default:
        return 'Por servicio';
    }
  }

  static String paymentLabel(Offer offer) {
    if (offer.paymentAmount == null) {
      return 'A convenir';
    }

    final String amount = _group(offer.paymentAmount!.round());
    final String currency = (offer.paymentCurrency ?? 'DOP').toUpperCase();

    if (currency == 'DOP' || currency == 'RD' || currency == 'RD\$') {
      return 'RD\$$amount';
    }

    if (currency == 'USD' || currency == 'US\$') {
      return 'US\$$amount';
    }

    return '$currency $amount';
  }

  static String? deadlineLabel(DateTime? deadline) {
    if (deadline == null) {
      return null;
    }

    return 'Límite: ${deadline.day} ${_months[deadline.month - 1]}';
  }

  static String _group(int value) {
    final String digits = value.abs().toString();
    final StringBuffer buffer = StringBuffer();

    for (int i = 0; i < digits.length; i++) {
      final int remaining = digits.length - i;
      if (i > 0 && remaining % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(digits[i]);
    }

    if (value < 0) {
      return '-$buffer';
    }

    return buffer.toString();
  }
}
