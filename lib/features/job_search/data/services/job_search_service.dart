import 'package:ocupa2/features/job_search/data/models/apply_request.dart';
import 'package:ocupa2/features/job_search/data/models/offer.dart';

abstract interface class JobSearchService {
  Future<List<Offer>> getOffers({String? jobTypeKey, String? contractType});

  Future<Offer> getOfferById(String id);

  Future<void> applyToOffer(String offerId, ApplyRequest request);
}
