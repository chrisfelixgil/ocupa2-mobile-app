import 'package:flutter/foundation.dart';
import 'package:ocupa2/core/network/api_exception.dart';
import 'package:ocupa2/features/job_posting/data/models/offer.dart'
    as posting_offer;
import 'package:ocupa2/features/job_posting/data/repositories/job_posting_repository.dart';
import 'package:ocupa2/features/job_search/data/models/offer.dart';
import 'package:ocupa2/features/job_search/data/repositories/job_search_repository.dart';
import 'package:ocupa2/features/job_search/presentation/viewmodels/explore_offers_status.dart';
import 'package:ocupa2/features/my_activity/data/models/application.dart';
import 'package:ocupa2/features/my_activity/data/repositories/application_repository.dart';

/// Lista + filtro de "Explorar ofertas". El mapa (job_search/mapa) puede
/// reusar este mismo ViewModel más adelante ya que comparten los mismos
/// datos y filtros.
class ExploreOffersViewModel extends ChangeNotifier {
  ExploreOffersViewModel({
    required JobSearchRepository jobSearchRepository,
    required ApplicationRepository applicationRepository,
    required JobPostingRepository jobPostingRepository,
  })  : _jobSearchRepository = jobSearchRepository,
        _applicationRepository = applicationRepository,
        _jobPostingRepository = jobPostingRepository;

  final JobSearchRepository _jobSearchRepository;
  final ApplicationRepository _applicationRepository;
  final JobPostingRepository _jobPostingRepository;

  ExploreOffersStatus _status = ExploreOffersStatus.idle;
  List<Offer> _offers = const <Offer>[];
  String? _errorMessage;
  String? _jobTypeFilter;
  String? _contractTypeFilter;
  bool _isDisposed = false;

  ExploreOffersStatus get status => _status;

  List<Offer> get offers => _offers;

  String? get errorMessage => _errorMessage;

  String? get jobTypeFilter => _jobTypeFilter;

  String? get contractTypeFilter => _contractTypeFilter;

  bool get isLoading => _status == ExploreOffersStatus.loading;

  Future<void> load() async {
    if (_isDisposed) {
      return;
    }

    _status = ExploreOffersStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final List<Offer> offers = await _jobSearchRepository.getOffers(
        jobTypeKey: _jobTypeFilter,
        contractType: _contractTypeFilter,
      );

      List<Application> myApplications = const <Application>[];
      List<posting_offer.Offer> myOffers = const <posting_offer.Offer>[];

      try {
        myApplications = await _applicationRepository.getMyApplications();
      } catch (error) {
        debugPrint('No se pudieron cargar mis aplicaciones: $error');
      }

      try {
        myOffers = await _jobPostingRepository.getMyOffers();
      } catch (error) {
        debugPrint('No se pudieron cargar mis ofertas: $error');
      }

      if (_isDisposed) {
        return;
      }

      final Set<String> appliedOfferIds = myApplications
          .map((Application application) => application.offerId)
          .whereType<String>()
          .toSet();
      final Set<String> myOfferIds = myOffers
          .map((posting_offer.Offer offer) => offer.id)
          .toSet();

      _offers = offers
          .where(
            (Offer offer) =>
                !appliedOfferIds.contains(offer.id) &&
                !myOfferIds.contains(offer.id),
          )
          .toList();
      _status = ExploreOffersStatus.success;
      notifyListeners();
    } on ApiException catch (error) {
      if (_isDisposed) {
        return;
      }

      _errorMessage = error.message;
      _status = ExploreOffersStatus.error;
      notifyListeners();
    } catch (_) {
      if (_isDisposed) {
        return;
      }

      _errorMessage = 'Ocurrió un problema inesperado. Inténtalo nuevamente.';
      _status = ExploreOffersStatus.error;
      notifyListeners();
    }
  }

  Future<void> setJobTypeFilter(String? jobTypeKey) {
    _jobTypeFilter = (jobTypeKey == null || jobTypeKey.isEmpty)
        ? null
        : jobTypeKey;
    return load();
  }

  Future<void> setContractTypeFilter(String? contractType) {
    _contractTypeFilter = (contractType == null || contractType.isEmpty)
        ? null
        : contractType;
    return load();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
