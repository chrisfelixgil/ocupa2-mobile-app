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
    if (_contract == null) return false;
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _contract = await _contractRepository.setTerms(
        id: _contract!.id,
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
    if (_contract == null) return false;
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _contract = await _contractRepository.acceptContract(_contract!.id);
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
    if (_contract == null) return false;
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _contract = await _contractRepository.rejectContract(_contract!.id);
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
    if (_contract == null || body.trim().isEmpty) return false;
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final ContractComment comment = await _contractRepository.addComment(
        id: _contract!.id,
        body: body.trim(),
      );
      _contract = Contract(
        id: _contract!.id,
        myRole: _contract!.myRole,
        status: _contract!.status,
        offerId: _contract!.offerId,
        jobTypeName: _contract!.jobTypeName,
        contratante: _contract!.contratante,
        contratado: _contract!.contratado,
        salary: _contract!.salary,
        currency: _contract!.currency,
        startDate: _contract!.startDate,
        duration: _contract!.duration,
        createdAt: _contract!.createdAt,
        acceptedAt: _contract!.acceptedAt,
        cancelJustification: _contract!.cancelJustification,
        cancelledBy: _contract!.cancelledBy,
        cancelledAt: _contract!.cancelledAt,
        comments: <ContractComment>[..._contract!.comments, comment],
        photos: _contract!.photos,
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
    if (_contract == null) return false;
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final String photoUrl = await _uploadService.uploadImage(
        bytes: await photoFile.readAsBytes(),
        filename: photoFile.name,
      );

      final ContractPhoto photo = await _contractRepository.addPhoto(
        id: _contract!.id,
        photo: photoUrl,
        description: description,
      );

      _contract = Contract(
        id: _contract!.id,
        myRole: _contract!.myRole,
        status: _contract!.status,
        offerId: _contract!.offerId,
        jobTypeName: _contract!.jobTypeName,
        contratante: _contract!.contratante,
        contratado: _contract!.contratado,
        salary: _contract!.salary,
        currency: _contract!.currency,
        startDate: _contract!.startDate,
        duration: _contract!.duration,
        createdAt: _contract!.createdAt,
        acceptedAt: _contract!.acceptedAt,
        cancelJustification: _contract!.cancelJustification,
        cancelledBy: _contract!.cancelledBy,
        cancelledAt: _contract!.cancelledAt,
        comments: _contract!.comments,
        photos: <ContractPhoto>[..._contract!.photos, photo],
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
    if (_contract == null || justification.trim().isEmpty) return false;
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _contract = await _contractRepository.cancelContract(
        id: _contract!.id,
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
