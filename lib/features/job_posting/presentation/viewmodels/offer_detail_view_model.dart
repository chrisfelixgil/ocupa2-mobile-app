import 'package:flutter/foundation.dart';

import '../../data/models/offer.dart';
import '../../data/repositories/job_posting_repository.dart';
import 'offer_detail_status.dart';

class JobPostingOfferDetailViewModel extends ChangeNotifier {
  JobPostingOfferDetailViewModel({
    required this._jobPostingRepository,
  });

  final JobPostingRepository _jobPostingRepository;

  JobPostingOfferDetailStatus _status = JobPostingOfferDetailStatus.idle;

  JobPostingOfferDetailStatus get status => _status;

  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  Offer? _offer;

  Offer? get offer => _offer;

  Future<void> load(String offerId) async {
    _status = JobPostingOfferDetailStatus.loading;
    _errorMessage = null;

    notifyListeners();

    try {
      _offer = await _jobPostingRepository.getOfferById(offerId);

      _status = JobPostingOfferDetailStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString();

      _status = JobPostingOfferDetailStatus.error;
    }

    notifyListeners();
  }

  Future<bool> deactivate() async {
    final current = _offer;

    if (current == null) {
      return false;
    }

    try {
      await _jobPostingRepository.deactivateOffer(current.id);

      _offer = await _jobPostingRepository.getOfferById(
        current.id,
      );

      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = e.toString();

      notifyListeners();

      return false;
    }
  }
}