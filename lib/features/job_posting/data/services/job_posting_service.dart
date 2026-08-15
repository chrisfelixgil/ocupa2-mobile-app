import '../models/create_offer_request.dart';
import '../models/offer.dart';

abstract class JobPostingService {
  /// POST /offers
  Future<Offer> createOffer(CreateOfferRequest request);

  /// GET /me/offers
  Future<List<Offer>> getMyOffers();

  /// GET /offers/{id}
  Future<Offer> getOfferById(String id);

  /// POST /offers/{id}/deactivate
  Future<void> deactivateOffer(String id);
  Future<void> deleteOffer(String id);
}