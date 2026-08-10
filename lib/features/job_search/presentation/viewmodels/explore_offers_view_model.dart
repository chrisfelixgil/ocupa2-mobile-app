import 'package:flutter/foundation.dart';
import 'package:ocupa2/core/network/api_exception.dart';
import 'package:ocupa2/features/job_search/data/models/offer.dart';
import 'package:ocupa2/features/job_search/data/repositories/job_search_repository.dart';
import 'package:ocupa2/features/job_search/presentation/viewmodels/explore_offers_status.dart';

/// Lista + filtro de "Explorar ofertas". El mapa (job_search/mapa) puede
/// reusar este mismo ViewModel más adelante ya que comparten los mismos
/// datos y filtros.
class ExploreOffersViewModel extends ChangeNotifier {
  ExploreOffersViewModel({required JobSearchRepository jobSearchRepository})
      : _jobSearchRepository = jobSearchRepository;

  final JobSearchRepository _jobSearchRepository;

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

      if (_isDisposed) {
        return;
      }

      _offers = offers;
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
