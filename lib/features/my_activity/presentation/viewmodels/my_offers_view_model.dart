import 'package:flutter/foundation.dart';
import 'package:ocupa2/core/network/api_exception.dart';
import 'package:ocupa2/features/my_activity/data/models/published_offer.dart';
import 'package:ocupa2/features/my_activity/data/repositories/offer_repository.dart';
import 'package:ocupa2/features/my_activity/presentation/viewmodels/my_offers_status.dart';

class MyOffersViewModel extends ChangeNotifier {
  MyOffersViewModel({required this._offerRepository});

  final OfferRepository _offerRepository;

  MyOffersStatus _status = MyOffersStatus.idle;
  List<PublishedOffer> _offers = const <PublishedOffer>[];
  String? _errorMessage;
  final Set<String> _deactivatingIds = <String>{};
  String _statusFilter = 'all';

  MyOffersStatus get status => _status;
  List<PublishedOffer> get offers => _offers;
  String? get errorMessage => _errorMessage;
  String get statusFilter => _statusFilter;

  List<PublishedOffer> get visibleOffers {
    return switch (_statusFilter) {
      'active' =>
        _offers.where((PublishedOffer offer) => offer.isActive).toList(),
      'finished' =>
        _offers.where((PublishedOffer offer) => !offer.isActive).toList(),
      _ => _offers,
    };
  }

  void setStatusFilter(String filter) {
    if (_statusFilter == filter) {
      return;
    }
    _statusFilter = filter;
    notifyListeners();
  }

  bool isDeactivating(String offerId) => _deactivatingIds.contains(offerId);

  Future<void> load() async {
    _status = MyOffersStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _offers = await _offerRepository.getMyOffers();
      _status = MyOffersStatus.success;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      _status = MyOffersStatus.error;
    } catch (_) {
      _errorMessage = 'Ocurrió un problema inesperado. Inténtalo nuevamente.';
      _status = MyOffersStatus.error;
    }

    notifyListeners();
  }

  Future<bool> deactivate(String offerId) async {
    if (_deactivatingIds.contains(offerId)) {
      return false;
    }

    _deactivatingIds.add(offerId);
    _errorMessage = null;
    notifyListeners();

    try {
      await _offerRepository.deactivateOffer(offerId: offerId);
      _offers =
          _offers.where((PublishedOffer offer) => offer.id != offerId).toList();
      _deactivatingIds.remove(offerId);
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'No fue posible eliminar la oferta.';
    }

    _deactivatingIds.remove(offerId);
    notifyListeners();
    return false;
  }

  // NEW: Delete offer permanently
  Future<bool> delete(String offerId) async {
    if (_deactivatingIds.contains(offerId)) {
      return false;
    }
    _deactivatingIds.add(offerId);
    _errorMessage = null;
    notifyListeners();
    try {
      await _offerRepository.deleteOffer(offerId: offerId);
      _offers = _offers.where((PublishedOffer offer) => offer.id != offerId).toList();
      _deactivatingIds.remove(offerId);
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'No fue posible eliminar la oferta.';
    }
    _deactivatingIds.remove(offerId);
    notifyListeners();
    return false;
  }
}
