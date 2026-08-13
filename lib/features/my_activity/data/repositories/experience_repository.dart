import 'package:ocupa2/features/my_activity/data/models/experience.dart';
import 'package:ocupa2/features/my_activity/data/services/experience_service.dart';

class ExperienceRepository {
  const ExperienceRepository({required this._experienceService});

  final ExperienceService _experienceService;

  Future<List<Experience>> getExperiences() {
    return _experienceService.getExperiences();
  }

  Future<Experience> createExperience({
    required String title,
    required String description,
    String? certificateImage,
  }) {
    return _experienceService.createExperience(
      title: title,
      description: description,
      certificateImage: certificateImage,
    );
  }

  Future<void> deleteExperience(String id) {
    return _experienceService.deleteExperience(id);
  }
}
