import 'package:flutter_test/flutter_test.dart';
import 'package:ocupa2/features/job_posting/data/models/offer_status.dart';

void main() {
  test('published, active y status vacío se listan en Mis ofertas', () {
    expect(offerStatusFromString('published'), OfferStatus.active);
    expect(offerStatusFromString('active'), OfferStatus.active);
    expect(offerStatusFromString(null), OfferStatus.active);
    expect(offerStatusFromString(''), OfferStatus.active);
    expect(isListedInMyOffers(offerStatusFromString('published')), isTrue);
  });

  test('inactive no se lista en Mis ofertas', () {
    expect(offerStatusFromString('inactive'), OfferStatus.inactive);
    expect(isListedInMyOffers(OfferStatus.inactive), isFalse);
  });
}
