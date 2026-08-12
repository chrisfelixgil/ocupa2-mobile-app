import 'package:flutter/foundation.dart';

import '../../data/models/offer.dart';
import '../../data/repositories/job_posting_repository.dart';
import 'my_offers_status.dart';

class MyOffersViewModel extends ChangeNotifier {
  MyOffersViewModel({required JobPostingRepository jobPostingRepository})
      : _jobPostingRepository = jobPostingRepository;

  final JobPostingRepository _jobPostingRepository;

  MyOffersStatus _status = MyOffersStatus.idle;
  MyOffersStatus get status => _status;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<Offer> _offers = [];
  List<Offer> get offers => _offers;

  /// ids en proceso de desactivación, para mostrar loading por-item.
  final Set<String> _deactivatingIds = {};
  bool isDeactivating(String id) => _deactivatingIds.contains(id);

  Future<void> loadMyOffers() async {
    _status = MyOffersStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _offers = await _jobPostingRepository.getMyOffers();
      _status = MyOffersStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _status = MyOffersStatus.error;
    }
    notifyListeners();
  }

  Future<bool> deactivate(String offerId) async {
    _deactivatingIds.add(offerId);
    notifyListeners();

    try {
      await _jobPostingRepository.deactivateOffer(offerId);
      final index = _offers.indexWhere((o) => o.id == offerId);
      if (index != -1) {
        // Refrescamos ese registro consultando el detalle actualizado.
        try {
          _offers[index] = await _jobPostingRepository.getOfferById(offerId);
        } catch (_) {
          // Si falla el refresh puntual, dejamos la lista como estaba;
          // el próximo loadMyOffers() la corrige.
        }
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _deactivatingIds.remove(offerId);
      notifyListeners();
    }
  }
}
