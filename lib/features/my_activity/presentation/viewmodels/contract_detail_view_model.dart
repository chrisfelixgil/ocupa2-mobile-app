import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ocupa2/core/network/api_exception.dart';
import 'package:ocupa2/features/my_activity/data/models/contract.dart';
import 'package:ocupa2/features/my_activity/data/models/contract_comment.dart';
import 'package:ocupa2/features/my_activity/data/models/contract_party.dart';
import 'package:ocupa2/features/my_activity/data/models/contract_photo.dart';
import 'package:ocupa2/features/my_activity/data/repositories/contract_repository.dart';
import 'package:ocupa2/features/my_activity/presentation/viewmodels/contracts_status.dart';
import 'package:ocupa2/features/uploads/data/services/upload_service.dart';

class ContractDetailViewModel extends ChangeNotifier {
  ContractDetailViewModel({
    required this._contractRepository,
    required this._uploadService,
    this._currentUser,
  });

  final ContractRepository _contractRepository;
  final UploadService _uploadService;

  static const Duration _liveUpdateInterval = Duration(seconds: 8);

  ContractsStatus _status = ContractsStatus.idle;
  Contract? _contract;
  String? _errorMessage;
  bool _isSaving = false;
  ContractParty? _currentUser;
  Timer? _liveUpdateTimer;
  bool _isRefreshing = false;
  bool _forcedActive = false;
  bool _forcedCancelled = false;

  ContractsStatus get status => _status;
  Contract? get contract => _contract;
  String? get errorMessage => _errorMessage;
  bool get isSaving => _isSaving;

  void setCurrentUser(ContractParty? user) {
    _currentUser = user;
  }

  Future<void> load(String contractId) async {
    _status = ContractsStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _contract = _withResolvedAuthors(
        await _contractRepository.getContractDetail(contractId),
      );
      _status = ContractsStatus.success;
      _startLiveUpdates();
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
      try {
        await _contractRepository.setTerms(
          id: currentContract.id,
          salary: salary,
          currency: currency,
          startDate: startDate,
          duration: duration,
        );
      } on ApiException catch (error) {
        if (error.type != ApiExceptionType.responseFormat) {
          rethrow;
        }
      }

      await _reloadCurrent();
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
      try {
        await _contractRepository.acceptContract(currentContract.id);
      } on ApiException catch (error) {
        if (error.type != ApiExceptionType.responseFormat) {
          rethrow;
        }
      }

      await _reloadCurrent();
      if (_contract != null && !_contract!.isRejected && !_contract!.isCancelled) {
        _forcedActive = true;
        if (!_contract!.isActive) {
          _contract = _contract!.copyWith(
            status: 'active',
            acceptedAt: _contract!.acceptedAt ?? DateTime.now(),
          );
        }
      }
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
      try {
        await _contractRepository.rejectContract(currentContract.id);
      } on ApiException catch (error) {
        if (error.type != ApiExceptionType.responseFormat) {
          rethrow;
        }
      }

      await _reloadCurrent();
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
      try {
        await _contractRepository.addComment(
          id: currentContract.id,
          body: body.trim(),
        );
      } on ApiException catch (error) {
        if (error.type != ApiExceptionType.responseFormat) {
          rethrow;
        }
      }

      _contract = currentContract.copyWith(
        comments: <ContractComment>[
          ...currentContract.comments,
          ContractComment(
            body: body.trim(),
            by: _currentUser,
            createdAt: DateTime.now(),
          ),
        ],
      );
      await _reloadCurrent();
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

      try {
        await _contractRepository.addPhoto(
          id: currentContract.id,
          photo: photoUrl,
          description: description,
        );
      } on ApiException catch (error) {
        if (error.type != ApiExceptionType.responseFormat) {
          rethrow;
        }
      }

      _contract = currentContract.copyWith(
        photos: <ContractPhoto>[
          ...currentContract.photos,
          ContractPhoto(
            url: photoUrl,
            description: description,
            by: _currentUser,
            createdAt: DateTime.now(),
          ),
        ],
      );
      await _reloadCurrent();
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
      try {
        await _contractRepository.cancelContract(
          id: currentContract.id,
          justification: justification.trim(),
        );
      } on ApiException catch (error) {
        if (error.type != ApiExceptionType.responseFormat) {
          rethrow;
        }
      }

      _forcedActive = false;
      _forcedCancelled = true;
      await _reloadCurrent();
      if (_contract != null && !_contract!.isCancelled) {
        _contract = _contract!.copyWith(
          status: 'cancelled',
          salary: _contract!.salary ?? currentContract.salary,
          currency: _contract!.currency ?? currentContract.currency,
          startDate: _contract!.startDate ?? currentContract.startDate,
          duration: _contract!.duration ?? currentContract.duration,
          cancelJustification: justification.trim(),
          cancelledAt: _contract!.cancelledAt ?? DateTime.now(),
        );
      }
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

  void _startLiveUpdates() {
    _liveUpdateTimer?.cancel();
    _liveUpdateTimer = Timer.periodic(_liveUpdateInterval, (_) {
      unawaited(_silentRefresh());
    });
  }

  Future<void> _silentRefresh() async {
    if (_isSaving || _contract == null) {
      return;
    }

    final Contract? before = _contract;
    try {
      await _reloadCurrent();
      if (!_sameVisibleState(before, _contract)) {
        notifyListeners();
      }
    } catch (_) {
      // Si el refresco en vivo falla, se mantiene lo que ya está en pantalla.
    }
  }

  Future<void> _reloadCurrent() async {
    while (_isRefreshing) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }

    final Contract? currentContract = _contract;
    if (currentContract == null) {
      return;
    }

    _isRefreshing = true;
    try {
      final Contract updated = await _contractRepository.getContractDetail(
        currentContract.id,
      );
      _contract = _withResolvedAuthors(
        _mergeLiveData(previous: currentContract, incoming: updated),
      );
    } finally {
      _isRefreshing = false;
    }
  }

  Contract _mergeLiveData({
    required Contract previous,
    required Contract incoming,
  }) {
    final List<ContractComment> comments = incoming.comments
        .map((ContractComment comment) => _fillComment(comment, previous.comments))
        .toList();
    for (final ContractComment item in previous.comments) {
      final bool alreadyThere = comments.any(
        (ContractComment comment) => comment.body == item.body,
      );
      if (!alreadyThere) {
        comments.add(item);
      }
    }

    final List<ContractPhoto> photos = incoming.photos
        .map((ContractPhoto photo) => _fillPhoto(photo, previous.photos))
        .toList();
    for (final ContractPhoto item in previous.photos) {
      final bool alreadyThere = photos.any((ContractPhoto photo) {
        if (item.url.isNotEmpty && photo.url == item.url) {
          return true;
        }
        return item.description.isNotEmpty && photo.description == item.description;
      });
      if (!alreadyThere) {
        photos.add(item);
      }
    }

    Contract merged = incoming.copyWith(
      comments: comments,
      photos: photos,
      salary: incoming.salary ?? previous.salary,
      currency: incoming.currency ?? previous.currency,
      startDate: incoming.startDate ?? previous.startDate,
      duration: incoming.duration ?? previous.duration,
    );

    if (_forcedCancelled && !merged.isRejected) {
      merged = merged.copyWith(
        status: 'cancelled',
        salary: merged.salary ?? previous.salary,
        currency: merged.currency ?? previous.currency,
        startDate: merged.startDate ?? previous.startDate,
        duration: merged.duration ?? previous.duration,
        cancelJustification:
            merged.cancelJustification ?? previous.cancelJustification,
        cancelledAt: merged.cancelledAt ?? previous.cancelledAt ?? DateTime.now(),
      );
    } else if (_forcedActive && merged.isPending) {
      merged = merged.copyWith(
        status: 'active',
        acceptedAt: merged.acceptedAt ?? previous.acceptedAt ?? DateTime.now(),
      );
    }

    return merged;
  }

  Contract _withResolvedAuthors(Contract contract) {
    return contract.copyWith(
      comments: contract.comments.map((ContractComment comment) {
        final ContractParty? author = _resolveAuthor(comment.by, contract);
        if (author == comment.by) {
          return comment;
        }
        return ContractComment(
          body: comment.body,
          by: author,
          createdAt: comment.createdAt,
        );
      }).toList(),
      photos: contract.photos.map((ContractPhoto photo) {
        final ContractParty? author = _resolveAuthor(photo.by, contract);
        if (author == photo.by) {
          return photo;
        }
        return ContractPhoto(
          url: photo.url,
          description: photo.description,
          by: author,
          createdAt: photo.createdAt,
        );
      }).toList(),
    );
  }

  ContractParty? _resolveAuthor(ContractParty? by, Contract contract) {
    if (_hasUsefulName(by?.nombre)) {
      return by;
    }
    if (_isCurrentUser(by)) {
      return _currentUser;
    }
    if (by == null) {
      return null;
    }
    if (contract.contratante != null && by.id == contract.contratante!.id) {
      return _hasUsefulName(contract.contratante!.nombre)
          ? contract.contratante
          : by;
    }
    if (contract.contratado != null && by.id == contract.contratado!.id) {
      return _hasUsefulName(contract.contratado!.nombre)
          ? contract.contratado
          : by;
    }
    return by;
  }

  ContractComment _fillComment(
    ContractComment incoming,
    List<ContractComment> previous,
  ) {
    if (_hasUsefulName(incoming.by?.nombre)) {
      return incoming;
    }

    for (final ContractComment item in previous) {
      if (item.body == incoming.body && _hasUsefulName(item.by?.nombre)) {
        return ContractComment(
          body: incoming.body,
          by: item.by,
          createdAt: incoming.createdAt ?? item.createdAt,
        );
      }
    }

    return incoming;
  }

  ContractPhoto _fillPhoto(
    ContractPhoto incoming,
    List<ContractPhoto> previous,
  ) {
    ContractPhoto result = incoming;
    if (incoming.url.isEmpty) {
      for (final ContractPhoto item in previous) {
        if (item.description == incoming.description && item.url.isNotEmpty) {
          result = ContractPhoto(
            url: item.url,
            description: incoming.description,
            by: incoming.by ?? item.by,
            createdAt: incoming.createdAt ?? item.createdAt,
          );
          break;
        }
      }
    }

    if (_hasUsefulName(result.by?.nombre)) {
      return result;
    }

    for (final ContractPhoto item in previous) {
      final bool samePhoto = (result.url.isNotEmpty && item.url == result.url) ||
          (result.description.isNotEmpty && item.description == result.description);
      if (samePhoto && _hasUsefulName(item.by?.nombre)) {
        return ContractPhoto(
          url: result.url,
          description: result.description,
          by: item.by,
          createdAt: result.createdAt ?? item.createdAt,
        );
      }
    }

    return result;
  }

  bool _sameVisibleState(Contract? before, Contract? after) {
    if (identical(before, after)) {
      return true;
    }
    if (before == null || after == null) {
      return false;
    }
    return before.status == after.status &&
        before.acceptedAt == after.acceptedAt &&
        before.comments.length == after.comments.length &&
        before.photos.length == after.photos.length &&
        (before.comments.isEmpty ||
            before.comments.last.body == after.comments.last.body) &&
        (before.photos.isEmpty || before.photos.last.url == after.photos.last.url);
  }

  bool _hasUsefulName(String? name) {
    final String value = name?.trim() ?? '';
    if (value.isEmpty || value == 'Usuario' || value == 'Anónimo') {
      return false;
    }
    return !RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(value);
  }

  bool _isCurrentUser(ContractParty? party) {
    if (_currentUser == null || party == null) {
      return false;
    }
    if (party.id != 'unknown-party' && party.id == _currentUser!.id) {
      return true;
    }
    final String? email = party.email?.trim().toLowerCase();
    final String? mine = _currentUser!.email?.trim().toLowerCase();
    return email != null && mine != null && email == mine;
  }

  @override
  void dispose() {
    _liveUpdateTimer?.cancel();
    super.dispose();
  }
}
