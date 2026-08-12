import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ocupa2/core/network/api_exception.dart';
import 'package:ocupa2/features/my_activity/data/models/experience.dart';
import 'package:ocupa2/features/my_activity/data/repositories/experience_repository.dart';
import 'package:ocupa2/features/my_activity/presentation/viewmodels/experiences_status.dart';
import 'package:ocupa2/features/uploads/data/services/upload_service.dart';

class ExperiencesViewModel extends ChangeNotifier {
  ExperiencesViewModel({
    required this._experienceRepository,
    required UploadService uploadService,
  })  : _uploadService = uploadService;

  final ExperienceRepository _experienceRepository;
  final UploadService _uploadService;
  ExperiencesStatus _status = ExperiencesStatus.idle;
  List<Experience> _experiences = const <Experience>[];
  String? _errorMessage;
  bool _isSaving = false;

  ExperiencesStatus get status => _status;
  List<Experience> get experiences => _experiences;
  String? get errorMessage => _errorMessage;
  bool get isSaving => _isSaving;

  Future<void> load() async {
    _status = ExperiencesStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      _experiences = await _experienceRepository.getExperiences();
      _status = ExperiencesStatus.success;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      _status = ExperiencesStatus.error;
    } catch (_) {
      _errorMessage = 'Ocurrió un problema inesperado. Inténtalo nuevamente.';
      _status = ExperiencesStatus.error;
    }
    notifyListeners();
  }

  Future<bool> addExperience({
    required String title,
    required String description,
    XFile? certificate,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      String? certificateImage;
      if (certificate != null) {
        certificateImage = await _uploadService.uploadImage(
          bytes: await certificate.readAsBytes(),
          filename: certificate.name,
        );
      }
      final Experience experience = await _experienceRepository.createExperience(
        title: title,
        description: description,
        certificateImage: certificateImage,
      );
      _experiences = <Experience>[experience, ..._experiences];
      _isSaving = false;
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'No fue posible guardar la experiencia.';
    }
    _isSaving = false;
    notifyListeners();
    return false;
  }

  Future<bool> deleteExperience(Experience experience) async {
    try {
      await _experienceRepository.deleteExperience(experience.id);
      _experiences = _experiences
          .where((Experience item) => item.id != experience.id)
          .toList();
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'No fue posible eliminar la experiencia.';
    }
    notifyListeners();
    return false;
  }
}
