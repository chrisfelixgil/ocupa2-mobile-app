import 'package:ocupa2/features/my_activity/data/models/application.dart';
import 'package:ocupa2/features/my_activity/data/services/application_service.dart';

class ApplicationRepository {
  const ApplicationRepository({required this._applicationService});

  final ApplicationService _applicationService;

  Future<List<Application>> getMyApplications() {
    return _applicationService.getMyApplications();
  }

  Future<Application> updateApplication({
    required String id,
    int? rating,
    String? status,
    num? salary,
    String? currency,
    String? startDate,
    String? duration,
  }) {
    return _applicationService.updateApplication(
      id: id,
      rating: rating,
      status: status,
      salary: salary,
      currency: currency,
      startDate: startDate,
      duration: duration,
    );
  }
}
