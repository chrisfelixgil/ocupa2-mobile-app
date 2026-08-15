/// Parseo y presentación de timestamps del API de pagos.
///
/// No altera el valor almacenado: solo convierte a local al formatear
/// cuando Dart interpretó el string como UTC (`Z` u offset).
class PaymentDateTime {
  const PaymentDateTime._();

  static DateTime? parse(String? raw) {
    if (raw == null) {
      return null;
    }

    final String trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    return DateTime.tryParse(trimmed);
  }

  /// Fecha/hora para UI. Si [value] es UTC, se muestra en zona local del dispositivo.
  static String formatDisplay(DateTime? value) {
    if (value == null) {
      return 'No disponible';
    }

    final DateTime local = value.isUtc ? value.toLocal() : value;
    final int hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final String period = local.hour < 12 ? 'a. m.' : 'p. m.';

    return '${_two(local.day)}/${_two(local.month)}/${local.year} · '
        '$hour12:${_two(local.minute)} $period';
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}
