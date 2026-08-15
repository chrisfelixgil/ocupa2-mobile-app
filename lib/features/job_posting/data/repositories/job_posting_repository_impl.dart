import '../models/create_offer_request.dart';
import '../models/offer.dart';
import '../services/job_posting_service.dart';
import 'job_posting_repository.dart';

class JobPostingRepositoryImpl implements JobPostingRepository {
  JobPostingRepositoryImpl({required this._jobPostingService});

  final JobPostingService _jobPostingService;

  @override
  Future<Offer> createOffer(CreateOfferRequest request) {
    return _jobPostingService.createOffer(request);
  }

  @override
  Future<List<Offer>> getMyOffers() {
    return _jobPostingService.getMyOffers();
  }

  @override
  Future<Offer> getOfferById(String id) {
    return _jobPostingService.getOfferById(id);
  }

  @override
  Future<void> deactivateOffer(String id) {
    return _jobPostingService.deactivateOffer(id);
  }

  @override
  Future<void> deleteOffer(String id) {
    return _jobPostingService.deleteOffer(id);
  }
}
