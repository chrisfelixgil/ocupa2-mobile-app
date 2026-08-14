import 'package:ocupa2/features/my_activity/data/models/published_offer.dart';
import 'package:ocupa2/features/my_activity/data/services/offer_service.dart';

class OfferRepository {
  const OfferRepository({required this._offerService});

  final OfferService _offerService;

  Future<List<PublishedOffer>> getMyOffers() {
    return _offerService.getMyOffers();
  }

  Future<void> deactivateOffer({required String offerId}) {
    return _offerService.deactivateOffer(offerId: offerId);
  }

  Future<void> deleteOffer({required String offerId}) {
    return _offerService.deleteOffer(offerId: offerId);
  }
}
