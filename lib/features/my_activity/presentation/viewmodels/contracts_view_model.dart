import 'package:flutter/foundation.dart';
import 'package:ocupa2/core/network/api_exception.dart';
import 'package:ocupa2/features/my_activity/data/models/contract.dart';
import 'package:ocupa2/features/my_activity/data/repositories/contract_repository.dart';
import 'package:ocupa2/features/my_activity/presentation/viewmodels/contracts_status.dart';

class ContractsViewModel extends ChangeNotifier {
  ContractsViewModel({
    required this._contractRepository,
  });

  final ContractRepository _contractRepository;

  ContractsStatus _status = ContractsStatus.idle;
  List<Contract> _contracts = const <Contract>[];
  String? _errorMessage;
  String _selectedFilter = 'all'; // 'all', 'active', 'pending', 'rejected', 'cancelled', 'closed'

  ContractsStatus get status => _status;
  List<Contract> get contracts => _filteredContracts;
  String? get errorMessage => _errorMessage;
  String get selectedFilter => _selectedFilter;

  List<Contract> get _filteredContracts {
    if (_selectedFilter == 'active') {
      return _contracts
          .where((Contract contract) => contract.isActive)
          .toList();
    }
    if (_selectedFilter == 'pending') {
      return _contracts
          .where((Contract contract) => contract.isPending)
          .toList();
    }
    if (_selectedFilter == 'rejected') {
      return _contracts
          .where((Contract contract) => contract.isRejected)
          .toList();
    }
    if (_selectedFilter == 'cancelled') {
      return _contracts
          .where((Contract contract) => contract.isCancelled)
          .toList();
    }
    if (_selectedFilter == 'closed') {
      return _contracts
          .where((Contract contract) => contract.isClosed)
          .toList();
    }
    return _contracts;
  }

  Future<void> load() async {
    _status = ContractsStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final List<Contract> incoming = await _contractRepository.getMyContracts();
      _contracts = _preserveKnownTerms(incoming, _contracts);
      _status = ContractsStatus.success;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      _status = ContractsStatus.error;
    } catch (_) {
      _errorMessage = 'Ocurrió un problema inesperado. Inténtalo nuevamente.';
      _status = ContractsStatus.error;
    }

    notifyListeners();
  }

  Future<void> refresh() async {
    try {
      final List<Contract> incoming = await _contractRepository.getMyContracts();
      _contracts = _preserveKnownTerms(incoming, _contracts);
      _status = ContractsStatus.success;
      _errorMessage = null;
      notifyListeners();
    } catch (_) {
      // Se mantiene la lista que ya está en pantalla.
    }
  }

  void setFilter(String filter) {
    if (_selectedFilter != filter) {
      _selectedFilter = filter;
      notifyListeners();
    }
  }

  void updateContractInList(Contract updated) {
    bool found = false;
    _contracts = _contracts.map((Contract item) {
      if (item.id != updated.id) {
        return item;
      }
      found = true;
      return updated.salary != null
          ? updated
          : updated.copyWith(
              salary: item.salary,
              currency: item.currency,
              startDate: item.startDate,
              duration: item.duration,
            );
    }).toList();
    if (!found) {
      _contracts = <Contract>[updated, ..._contracts];
    }
    notifyListeners();
  }

  List<Contract> _preserveKnownTerms(
    List<Contract> incoming,
    List<Contract> previous,
  ) {
    return incoming.map((Contract contract) {
      if (contract.salary != null) {
        return contract;
      }
      for (final Contract item in previous) {
        if (item.id == contract.id && item.salary != null) {
          return contract.copyWith(
            salary: item.salary,
            currency: item.currency,
            startDate: item.startDate,
            duration: item.duration,
          );
        }
      }
      return contract;
    }).toList();
  }
}
