import '../models/create_offer_request.dart';
import '../models/offer.dart';

abstract class JobPostingRepository {
  Future<Offer> createOffer(CreateOfferRequest request);
  Future<List<Offer>> getMyOffers();
  Future<Offer> getOfferById(String id);
  Future<void> deactivateOffer(String id);
}
