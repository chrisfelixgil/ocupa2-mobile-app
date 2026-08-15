import 'package:flutter/foundation.dart';
import 'package:ocupa2/core/network/api_exception.dart';

import '../../data/models/create_offer_request.dart';
import '../../data/models/offer.dart';
import '../../data/models/offer_location.dart';
import '../../data/models/offer_payment.dart';
import '../../data/models/offer_question.dart';
import '../../data/repositories/job_posting_repository.dart';
import 'create_offer_status.dart';

class CreatedOfferVisibility {
  const CreatedOfferVisibility({
    required this.createdId,
    required this.foundInMyOffers,
    required this.myOffersCount,
    this.lookupError,
  });

  final String createdId;
  final bool foundInMyOffers;
  final int myOffersCount;
  final String? lookupError;
}

class CreateOfferViewModel extends ChangeNotifier {
  CreateOfferViewModel({required this._jobPostingRepository});

  final JobPostingRepository _jobPostingRepository;

  CreateOfferStatus _status = CreateOfferStatus.idle;

  CreateOfferStatus get status => _status;

  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  Offer? _createdOffer;

  Offer? get createdOffer => _createdOffer;

  bool get isSubmitting => _status == CreateOfferStatus.submitting;

  Future<bool> submit({
    required String jobTypeKey,
    required String contractType,
    required String description,
    required String address,

    /// URL pública de la imagen.
    ///
    /// Ejemplo:
    /// https://ocupa2.ia3x.com/media/bcd584ee8d7ef4934cb0ce68c0a2e9ed.jpg
    String? photo,

    String? paymentId,

    required double lat,
    required double lng,

    required double amount,
    required String currency,
    required DateTime deadline,

    Map<String, dynamic> customAnswers = const {},
    List<OfferQuestion> questions = const [],
  }) async {
    _status = CreateOfferStatus.submitting;
    _errorMessage = null;

    notifyListeners();

    try {
      final request = CreateOfferRequest(
        jobTypeKey: jobTypeKey,
        contractType: contractType,
        description: description,
        address: address,

        // Aquí debe llegar la URL pública,
        // NO la ruta local de la imagen.
        photo: photo,

        paymentId: paymentId,

        location: OfferLocation(lat: lat, lng: lng),

        payment: OfferPayment(amount: amount, currency: currency),

        deadline: deadline,

        customAnswers: customAnswers,
        questions: questions,
      );

      _createdOffer = await _jobPostingRepository.createOffer(request);

      _status = CreateOfferStatus.success;

      notifyListeners();

      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      _status = CreateOfferStatus.error;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'No se pudo publicar la oferta. Inténtalo nuevamente.';
      _status = CreateOfferStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Comprueba si el id de POST /offers aparece en GET /me/offers.
  ///
  /// Un reintento corto cubre consistencia eventual. No hace polling infinito.
  Future<CreatedOfferVisibility?> verifyCreatedOfferInMyOffers() async {
    final Offer? created = _createdOffer;
    if (created == null || created.id.isEmpty) {
      return null;
    }

    try {
      List<Offer> list = await _jobPostingRepository.getMyOffers();
      bool found = list.any((Offer offer) => offer.id == created.id);

      if (!found) {
        await Future<void>.delayed(const Duration(milliseconds: 800));
        list = await _jobPostingRepository.getMyOffers();
        found = list.any((Offer offer) => offer.id == created.id);
      }

      if (kDebugMode) {
        debugPrint(
          '[Publish] POST /offers id=${created.id} '
          'GET /me/offers count=${list.length} '
          'hasCreated=$found '
          'ids=${list.map((Offer offer) => offer.id).join(',')}',
        );
      }

      return CreatedOfferVisibility(
        createdId: created.id,
        foundInMyOffers: found,
        myOffersCount: list.length,
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[Publish] GET /me/offers failed after create: $error');
      }

      return CreatedOfferVisibility(
        createdId: created.id,
        foundInMyOffers: false,
        myOffersCount: 0,
        lookupError: error.toString(),
      );
    }
  }

  void reset() {
    _status = CreateOfferStatus.idle;
    _errorMessage = null;
    _createdOffer = null;

    notifyListeners();
  }
}
