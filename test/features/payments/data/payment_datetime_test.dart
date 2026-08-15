import 'package:flutter_test/flutter_test.dart';
import 'package:ocupa2/features/payments/data/payment_datetime.dart';

void main() {
  test('UTC con Z se convierte a local solo para mostrar', () {
    const String raw = '2026-08-15T00:35:12.000Z';
    final DateTime? parsed = PaymentDateTime.parse(raw);

    expect(parsed, isNotNull);
    expect(parsed!.isUtc, isTrue);
    expect(
      PaymentDateTime.formatDisplay(parsed),
      PaymentDateTime.formatDisplay(parsed.toLocal()),
    );
    expect(PaymentDateTime.formatDisplay(parsed), contains('/2026'));
    expect(PaymentDateTime.formatDisplay(parsed), contains('·'));
  });

  test('offset explícito se parsea como UTC y se muestra en local', () {
    const String raw = '2026-08-14T20:35:12-04:00';
    final DateTime? parsed = PaymentDateTime.parse(raw);

    expect(parsed, isNotNull);
    expect(parsed!.isUtc, isTrue);
    expect(PaymentDateTime.formatDisplay(parsed), isNot(contains('Error')));
  });

  test('timestamp sin zona no se reconvierte', () {
    final DateTime naive = DateTime(2026, 8, 14, 20, 35);
    expect(naive.isUtc, isFalse);
    expect(PaymentDateTime.formatDisplay(naive), '14/08/2026 · 8:35 p. m.');
  });
}
