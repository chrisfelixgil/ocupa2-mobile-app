import 'package:flutter/foundation.dart';

import '../../data/models/create_offer_request.dart';
import '../../data/models/offer.dart';
import '../../data/models/offer_location.dart';
import '../../data/models/offer_payment.dart';
import '../../data/models/offer_question.dart';
import '../../data/repositories/job_posting_repository.dart';
import 'create_offer_status.dart';

class CreateOfferViewModel extends ChangeNotifier {
  CreateOfferViewModel({
    required this._jobPostingRepository,
  });

  final JobPostingRepository _jobPostingRepository;

  CreateOfferStatus _status = CreateOfferStatus.idle;

  CreateOfferStatus get status => _status;

  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  Offer? _createdOffer;

  Offer? get createdOffer => _createdOffer;

  bool get isSubmitting =>
      _status == CreateOfferStatus.submitting;

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

        location: OfferLocation(
          lat: lat,
          lng: lng,
        ),

        payment: OfferPayment(
          amount: amount,
          currency: currency,
        ),

        deadline: deadline,

        customAnswers: customAnswers,
        questions: questions,
      );

      _createdOffer =
          await _jobPostingRepository.createOffer(
        request,
      );

      _status = CreateOfferStatus.success;

      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = e.toString();

      _status = CreateOfferStatus.error;

      notifyListeners();

      return false;
    }
  }

  void reset() {
    _status = CreateOfferStatus.idle;
    _errorMessage = null;
    _createdOffer = null;

    notifyListeners();
  }
}