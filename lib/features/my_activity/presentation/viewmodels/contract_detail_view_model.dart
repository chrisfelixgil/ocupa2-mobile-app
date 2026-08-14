import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ocupa2/core/network/api_exception.dart';
import 'package:ocupa2/features/my_activity/data/models/contract.dart';
import 'package:ocupa2/features/my_activity/data/models/contract_comment.dart';
import 'package:ocupa2/features/my_activity/data/models/contract_photo.dart';
import 'package:ocupa2/features/my_activity/data/repositories/contract_repository.dart';
import 'package:ocupa2/features/my_activity/presentation/viewmodels/contracts_status.dart';
import 'package:ocupa2/features/uploads/data/services/upload_service.dart';

class ContractDetailViewModel extends ChangeNotifier {
  ContractDetailViewModel({
    required this._contractRepository,
    required this._uploadService,
  });

  final ContractRepository _contractRepository;
  final UploadService _uploadService;

  ContractsStatus _status = ContractsStatus.idle;
  Contract? _contract;
  String? _errorMessage;
  bool _isSaving = false;

  ContractsStatus get status => _status;
  Contract? get contract => _contract;
  String? get errorMessage => _errorMessage;
  bool get isSaving => _isSaving;

  Future<void> load(String contractId) async {
    _status = ContractsStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _contract = await _contractRepository.getContractDetail(contractId);
      _status = ContractsStatus.success;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      _status = ContractsStatus.error;
    } catch (_) {
      _errorMessage = 'No fue posible cargar el detalle del contrato.';
      _status = ContractsStatus.error;
    }

    notifyListeners();
  }

  Future<bool> setTerms({
    required num salary,
    String? currency,
    required String startDate,
    required String duration,
  }) async {
    final Contract? currentContract = _contract;
    if (currentContract == null) return false;
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _contract = await _contractRepository.setTerms(
        id: currentContract.id,
        salary: salary,
        currency: currency,
        startDate: startDate,
        duration: duration,
      );
      _isSaving = false;
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'No fue posible fijar los términos del contrato.';
    }

    _isSaving = false;
    notifyListeners();
    return false;
  }

  Future<bool> acceptContract() async {
    final Contract? currentContract = _contract;
    if (currentContract == null) return false;
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _contract = await _contractRepository.acceptContract(currentContract.id);
      _isSaving = false;
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'No fue posible aceptar el contrato.';
    }

    _isSaving = false;
    notifyListeners();
    return false;
  }

  Future<bool> rejectContract() async {
    final Contract? currentContract = _contract;
    if (currentContract == null) return false;
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _contract = await _contractRepository.rejectContract(currentContract.id);
      _isSaving = false;
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'No fue posible rechazar el contrato.';
    }

    _isSaving = false;
    notifyListeners();
    return false;
  }

  Future<bool> addComment(String body) async {
    final Contract? currentContract = _contract;
    if (currentContract == null || body.trim().isEmpty) return false;
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final ContractComment comment = await _contractRepository.addComment(
        id: currentContract.id,
        body: body.trim(),
      );
      _contract = Contract(
        id: currentContract.id,
        myRole: currentContract.myRole,
        status: currentContract.status,
        offerId: currentContract.offerId,
        jobTypeName: currentContract.jobTypeName,
        contratante: currentContract.contratante,
        contratado: currentContract.contratado,
        salary: currentContract.salary,
        currency: currentContract.currency,
        startDate: currentContract.startDate,
        duration: currentContract.duration,
        createdAt: currentContract.createdAt,
        acceptedAt: currentContract.acceptedAt,
        cancelJustification: currentContract.cancelJustification,
        cancelledBy: currentContract.cancelledBy,
        cancelledAt: currentContract.cancelledAt,
        comments: <ContractComment>[...currentContract.comments, comment],
        photos: currentContract.photos,
      );
      _isSaving = false;
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'No fue posible agregar el comentario.';
    }

    _isSaving = false;
    notifyListeners();
    return false;
  }

  Future<bool> addPhoto({
    required XFile photoFile,
    required String description,
  }) async {
    final Contract? currentContract = _contract;
    if (currentContract == null) return false;
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final String photoUrl = await _uploadService.uploadImage(
        bytes: await photoFile.readAsBytes(),
        filename: photoFile.name,
      );

      final ContractPhoto photo = await _contractRepository.addPhoto(
        id: currentContract.id,
        photo: photoUrl,
        description: description,
      );

      _contract = Contract(
        id: currentContract.id,
        myRole: currentContract.myRole,
        status: currentContract.status,
        offerId: currentContract.offerId,
        jobTypeName: currentContract.jobTypeName,
        contratante: currentContract.contratante,
        contratado: currentContract.contratado,
        salary: currentContract.salary,
        currency: currentContract.currency,
        startDate: currentContract.startDate,
        duration: currentContract.duration,
        createdAt: currentContract.createdAt,
        acceptedAt: currentContract.acceptedAt,
        cancelJustification: currentContract.cancelJustification,
        cancelledBy: currentContract.cancelledBy,
        cancelledAt: currentContract.cancelledAt,
        comments: currentContract.comments,
        photos: <ContractPhoto>[...currentContract.photos, photo],
      );
      _isSaving = false;
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'No fue posible agregar la foto.';
    }

    _isSaving = false;
    notifyListeners();
    return false;
  }

  Future<bool> cancelContract(String justification) async {
    final Contract? currentContract = _contract;
    if (currentContract == null || justification.trim().isEmpty) return false;
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _contract = await _contractRepository.cancelContract(
        id: currentContract.id,
        justification: justification.trim(),
      );
      _isSaving = false;
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'No fue posible cancelar el contrato.';
    }

    _isSaving = false;
    notifyListeners();
    return false;
  }
}
