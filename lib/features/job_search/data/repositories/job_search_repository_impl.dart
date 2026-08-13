import 'package:ocupa2/features/job_search/data/models/apply_request.dart';
import 'package:ocupa2/features/job_search/data/models/offer.dart';
import 'package:ocupa2/features/job_search/data/repositories/job_search_repository.dart';
import 'package:ocupa2/features/job_search/data/services/job_search_service.dart';

class JobSearchRepositoryImpl implements JobSearchRepository {
  const JobSearchRepositoryImpl({required this._jobSearchService});

  final JobSearchService _jobSearchService;

  @override
  Future<List<Offer>> getOffers({String? jobTypeKey, String? contractType}) {
    return _jobSearchService.getOffers(
      jobTypeKey: jobTypeKey,
      contractType: contractType,
    );
  }

  @override
  Future<Offer> getOfferById(String id) {
    return _jobSearchService.getOfferById(id);
  }

  @override
  Future<void> applyToOffer(String offerId, ApplyRequest request) {
    return _jobSearchService.applyToOffer(offerId, request);
  }
}
