import 'package:flutter/foundation.dart';
import 'package:ocupa2/core/network/api_exception.dart';
import 'package:ocupa2/features/my_activity/data/models/contract.dart';
import 'package:ocupa2/features/my_activity/data/repositories/contract_repository.dart';
import 'package:ocupa2/features/my_activity/presentation/viewmodels/contracts_status.dart';

class ContractsViewModel extends ChangeNotifier {
  ContractsViewModel({
    required ContractRepository contractRepository,
  }) : _contractRepository = contractRepository;

  final ContractRepository _contractRepository;

  ContractsStatus _status = ContractsStatus.idle;
  List<Contract> _contracts = const <Contract>[];
  String? _errorMessage;
  String _selectedFilter = 'all'; // 'all', 'active', 'inactive'

  ContractsStatus get status => _status;
  List<Contract> get contracts => _filteredContracts;
  String? get errorMessage => _errorMessage;
  String get selectedFilter => _selectedFilter;

  List<Contract> get _filteredContracts {
    if (_selectedFilter == 'active') {
      return _contracts.where((Contract c) => c.isActive).toList();
    }
    if (_selectedFilter == 'inactive') {
      return _contracts.where((Contract c) => !c.isActive).toList();
    }
    return _contracts;
  }

  Future<void> load() async {
    _status = ContractsStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _contracts = await _contractRepository.getMyContracts();
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

  void setFilter(String filter) {
    if (_selectedFilter != filter) {
      _selectedFilter = filter;
      notifyListeners();
    }
  }

  void updateContractInList(Contract updated) {
    _contracts = _contracts.map((Contract item) {
      return item.id == updated.id ? updated : item;
    }).toList();
    notifyListeners();
  }
}
