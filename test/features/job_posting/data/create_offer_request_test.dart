import 'package:flutter_test/flutter_test.dart';
import 'package:ocupa2/features/job_posting/data/models/create_offer_request.dart';
import 'package:ocupa2/features/job_posting/data/models/offer_location.dart';
import 'package:ocupa2/features/job_posting/data/models/offer_payment.dart';
import 'package:ocupa2/features/job_posting/data/models/offer_question.dart';

void main() {
  test('POST /offers manda customAnswers reales y payment de la oferta', () {
    final CreateOfferRequest request = CreateOfferRequest(
      jobTypeKey: 'chofer',
      contractType: 'temporal',
      description: 'Traslado de personal',
      address: 'Santo Domingo',
      photo: 'https://ocupa2.ia3x.com/media/foto.jpg',
      paymentId: 'pay_123',
      location: const OfferLocation(lat: 18.48, lng: -69.89),
      payment: const OfferPayment(amount: 1500, currency: 'DOP'),
      deadline: DateTime(2026, 8, 30),
      customAnswers: const <String, dynamic>{'categoria_licencia': '03'},
      questions: const <OfferQuestion>[
        OfferQuestion(
          label: '¿Tienes vehículo propio?',
          type: 'check',
          required: true,
        ),
      ],
    );

    final Map<String, dynamic> json = request.toJson();

    expect(json['customAnswers'], <String, dynamic>{
      'categoria_licencia': '03',
    });
    expect(json['payment'], <String, dynamic>{
      'amount': 1500,
      'currency': 'DOP',
    });
    expect(json['paymentId'], 'pay_123');
    expect(json['questions'], <Map<String, dynamic>>[
      <String, dynamic>{
        'label': '¿Tienes vehículo propio?',
        'type': 'check',
        'required': true,
        'options': <String>[],
      },
    ]);
    expect(json.containsKey('cardNumber'), isFalse);
  });
}
