import 'package:flutter/foundation.dart';
import 'package:ocupa2/core/network/api_exception.dart';
import 'package:ocupa2/features/my_activity/data/models/application.dart';
import 'package:ocupa2/features/my_activity/data/repositories/application_repository.dart';
import 'package:ocupa2/features/my_activity/presentation/viewmodels/applications_status.dart';

class ApplicationsViewModel extends ChangeNotifier {
  ApplicationsViewModel({
    required ApplicationRepository applicationRepository,
  }) : _applicationRepository = applicationRepository;

  final ApplicationRepository _applicationRepository;
  ApplicationsStatus _status = ApplicationsStatus.idle;
  List<Application> _applications = const <Application>[];
  String? _errorMessage;
  bool _isUpdating = false;

  ApplicationsStatus get status => _status;
  List<Application> get applications => _applications;
  String? get errorMessage => _errorMessage;
  bool get isUpdating => _isUpdating;

  Future<void> load() async {
    _status = ApplicationsStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _applications = await _applicationRepository.getMyApplications();
      _status = ApplicationsStatus.success;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      _status = ApplicationsStatus.error;
    } catch (_) {
      _errorMessage = 'Ocurrió un problema inesperado. Inténtalo nuevamente.';
      _status = ApplicationsStatus.error;
    }

    notifyListeners();
  }

  Future<bool> updateApplicationStatus({
    required String applicationId,
    required String status,
    num? salary,
    String? currency,
    String? startDate,
    String? duration,
  }) async {
    _isUpdating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final Application updated =
          await _applicationRepository.updateApplication(
        id: applicationId,
        status: status,
        salary: salary,
        currency: currency,
        startDate: startDate,
        duration: duration,
      );
      _replaceItem(updated);
      _isUpdating = false;
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'No fue posible actualizar el estado de la aplicación.';
    }

    _isUpdating = false;
    notifyListeners();
    return false;
  }

  Future<bool> rateApplication({
    required String applicationId,
    required int rating,
  }) async {
    _isUpdating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final Application updated =
          await _applicationRepository.updateApplication(
        id: applicationId,
        rating: rating,
      );
      _replaceItem(updated);
      _isUpdating = false;
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'No fue posible guardar la calificación.';
    }

    _isUpdating = false;
    notifyListeners();
    return false;
  }

  void _replaceItem(Application updated) {
    _applications = _applications.map((Application item) {
      return item.id == updated.id ? updated : item;
    }).toList();
  }
}
