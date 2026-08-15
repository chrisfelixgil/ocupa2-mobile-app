import 'package:flutter/foundation.dart';
import 'package:ocupa2/features/my_activity/data/models/application.dart';
import 'package:ocupa2/features/my_activity/data/repositories/application_repository.dart';

import '../../data/models/offer.dart';
import '../../data/repositories/job_posting_repository.dart';
import 'offer_detail_status.dart';

class JobPostingOfferDetailViewModel extends ChangeNotifier {
  JobPostingOfferDetailViewModel({
    required this._jobPostingRepository,
    required this._applicationRepository,
  });

  final JobPostingRepository _jobPostingRepository;
  final ApplicationRepository _applicationRepository;

  JobPostingOfferDetailStatus _status = JobPostingOfferDetailStatus.idle;

  JobPostingOfferDetailStatus get status => _status;

  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  Offer? _offer;

  Offer? get offer => _offer;

  List<Application> _applicants = const <Application>[];

  List<Application> get applicants => _applicants;

  bool get hasWinner => _applicants.any(
        (Application applicant) =>
            applicant.status.toLowerCase().trim() == 'winner',
      );

  bool _isUpdatingApplicant = false;

  bool get isUpdatingApplicant => _isUpdatingApplicant;

  Future<void> load(String offerId) async {
    _status = JobPostingOfferDetailStatus.loading;
    _errorMessage = null;
    _applicants = const <Application>[];

    notifyListeners();

    try {
      final Offer loadedOffer = await _jobPostingRepository.getOfferById(offerId);
      final List<Application> loadedApplicants =
          await _applicationRepository.getOfferApplications(offerId: offerId);

      _offer = loadedOffer;
      _applicants = loadedApplicants;
      _status = JobPostingOfferDetailStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _status = JobPostingOfferDetailStatus.error;
    }

    notifyListeners();
  }

  Future<bool> updateApplicantStatus({
    required String applicationId,
    required String status,
    int? rating,
  }) async {
    _isUpdatingApplicant = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final Application updated =
          await _applicationRepository.updateApplication(
        id: applicationId,
        status: status,
        rating: rating,
      );

      _applicants = _applicants.map((Application item) {
        if (item.id != updated.id) {
          return item;
        }

        return item.copyWith(
          status: updated.status,
          comment: updated.comment ?? item.comment,
          rating: updated.rating ?? item.rating,
          applicantFirstName:
              updated.applicantFirstName ?? item.applicantFirstName,
          applicantLastName:
              updated.applicantLastName ?? item.applicantLastName,
          applicantEmail: updated.applicantEmail ?? item.applicantEmail,
          applicantAddress: updated.applicantAddress ?? item.applicantAddress,
          applicantExperiences: updated.applicantExperiences.isNotEmpty
              ? updated.applicantExperiences
              : item.applicantExperiences,
          answers: updated.answers.isNotEmpty ? updated.answers : item.answers,
        );
      }).toList();

      _isUpdatingApplicant = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isUpdatingApplicant = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> rateApplicant({
    required String applicationId,
    required int rating,
  }) async {
    _isUpdatingApplicant = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final Application updated =
          await _applicationRepository.updateApplication(
        id: applicationId,
        rating: rating,
      );

      _applicants = _applicants.map((Application item) {
        if (item.id != updated.id) {
          return item;
        }

        return item.copyWith(
          comment: updated.comment ?? item.comment,
          rating: updated.rating ?? rating,
          applicantFirstName:
              updated.applicantFirstName ?? item.applicantFirstName,
          applicantLastName:
              updated.applicantLastName ?? item.applicantLastName,
          applicantEmail: updated.applicantEmail ?? item.applicantEmail,
          applicantAddress: updated.applicantAddress ?? item.applicantAddress,
          applicantExperiences: updated.applicantExperiences.isNotEmpty
              ? updated.applicantExperiences
              : item.applicantExperiences,
          answers: updated.answers.isNotEmpty ? updated.answers : item.answers,
        );
      }).toList();

      _isUpdatingApplicant = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isUpdatingApplicant = false;
      notifyListeners();
      return false;
    }
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