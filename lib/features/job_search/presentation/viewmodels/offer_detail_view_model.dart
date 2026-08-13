import 'package:flutter/foundation.dart';
import 'package:ocupa2/core/network/api_exception.dart';
import 'package:ocupa2/features/job_search/data/models/apply_request.dart';
import 'package:ocupa2/features/job_search/data/models/offer.dart';
import 'package:ocupa2/features/job_search/data/repositories/job_search_repository.dart';
import 'package:ocupa2/features/job_search/presentation/viewmodels/offer_detail_status.dart';

class OfferDetailViewModel extends ChangeNotifier {
  OfferDetailViewModel({
    required this._jobSearchRepository,
    required this._offerId,
  });

  final JobSearchRepository _jobSearchRepository;
  final String _offerId;

  OfferDetailStatus _status = OfferDetailStatus.idle;
  Offer? _offer;
  String? _errorMessage;

  ApplyStatus _applyStatus = ApplyStatus.idle;
  String? _applyErrorMessage;

  bool _isDisposed = false;

  OfferDetailStatus get status => _status;

  Offer? get offer => _offer;

  String? get errorMessage => _errorMessage;

  ApplyStatus get applyStatus => _applyStatus;

  String? get applyErrorMessage => _applyErrorMessage;

  bool get isLoading => _status == OfferDetailStatus.loading;

  bool get isSubmittingApplication => _applyStatus == ApplyStatus.submitting;

  bool get applicationSubmitted => _applyStatus == ApplyStatus.success;

  Future<void> load() async {
    if (_isDisposed) {
      return;
    }

    _status = OfferDetailStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final Offer offer = await _jobSearchRepository.getOfferById(_offerId);

      if (_isDisposed) {
        return;
      }

      _offer = offer;
      _status = OfferDetailStatus.loaded;
      notifyListeners();
    } on ApiException catch (error) {
      if (_isDisposed) {
        return;
      }

      _errorMessage = error.message;
      _status = OfferDetailStatus.error;
      notifyListeners();
    } catch (_) {
      if (_isDisposed) {
        return;
      }

      _errorMessage = 'Ocurrió un problema inesperado. Inténtalo nuevamente.';
      _status = OfferDetailStatus.error;
      notifyListeners();
    }
  }

  Future<bool> apply({
    required String comment,
    required List<ApplyAnswer> answers,
  }) async {
    if (_isDisposed || isSubmittingApplication) {
      return false;
    }

    _applyStatus = ApplyStatus.submitting;
    _applyErrorMessage = null;
    notifyListeners();

    try {
      await _jobSearchRepository.applyToOffer(
        _offerId,
        ApplyRequest(comment: comment, answers: answers),
      );

      if (_isDisposed) {
        return false;
      }

      _applyStatus = ApplyStatus.success;
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      if (_isDisposed) {
        return false;
      }

      _applyErrorMessage = error.message;
      _applyStatus = ApplyStatus.error;
      notifyListeners();
      return false;
    } catch (_) {
      if (_isDisposed) {
        return false;
      }

      _applyErrorMessage =
          'Ocurrió un problema inesperado. Inténtalo nuevamente.';
      _applyStatus = ApplyStatus.error;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
