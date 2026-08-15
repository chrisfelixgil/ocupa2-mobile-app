import 'package:flutter_test/flutter_test.dart';
import 'package:ocupa2/features/job_posting/data/custom_field_date.dart';
import 'package:ocupa2/features/job_posting/data/models/create_offer_request.dart';
import 'package:ocupa2/features/job_posting/data/models/offer_location.dart';
import 'package:ocupa2/features/job_posting/data/models/offer_payment.dart';

void main() {
  test('serializa custom field date como yyyy-MM-dd sin hora', () {
    final DateTime picked = DateTime(2026, 8, 30, 18, 45);

    expect(CustomFieldDate.toApi(picked), '2026-08-30');
    expect(CustomFieldDate.toDisplay(picked), '30/08/2026');
    expect(CustomFieldDate.toApi(picked), isNot(contains('T')));
    expect(
      CustomFieldDate.toApi(picked),
      isNot(CustomFieldDate.toDisplay(picked)),
    );
  });

  test('customAnswers manda la fecha ISO y no el texto visual', () {
    final CreateOfferRequest request = CreateOfferRequest(
      jobTypeKey: 'niñera',
      contractType: 'temporal',
      description: 'Cuidado',
      address: 'Santo Domingo',
      photo: 'https://ocupa2.ia3x.com/media/foto.jpg',
      paymentId: 'pay_1',
      location: const OfferLocation(lat: 18.48, lng: -69.89),
      payment: const OfferPayment(amount: 800, currency: 'DOP'),
      deadline: DateTime(2026, 9, 1),
      customAnswers: <String, dynamic>{
        'fecha_inicio': CustomFieldDate.toApi(DateTime(2026, 8, 30)),
      },
    );

    expect(request.toJson()['customAnswers'], <String, dynamic>{
      'fecha_inicio': '2026-08-30',
    });
  });
}
