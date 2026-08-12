import 'package:ocupa2/features/my_activity/data/models/contract.dart';
import 'package:ocupa2/features/my_activity/data/models/contract_comment.dart';
import 'package:ocupa2/features/my_activity/data/models/contract_photo.dart';
import 'package:ocupa2/features/my_activity/data/services/contract_service.dart';

class ContractRepository {
  const ContractRepository({required ContractService contractService})
      : _contractService = contractService;

  final ContractService _contractService;

  Future<List<Contract>> getMyContracts({String? status}) {
    return _contractService.getMyContracts(status: status);
  }

  Future<Contract> getContractDetail(String id) {
    return _contractService.getContractDetail(id);
  }

  Future<Contract> setTerms({
    required String id,
    required num salary,
    String? currency,
    required String startDate,
    required String duration,
  }) {
    return _contractService.setTerms(
      id: id,
      salary: salary,
      currency: currency,
      startDate: startDate,
      duration: duration,
    );
  }

  Future<Contract> acceptContract(String id) {
    return _contractService.acceptContract(id);
  }

  Future<Contract> rejectContract(String id) {
    return _contractService.rejectContract(id);
  }

  Future<ContractComment> addComment({
    required String id,
    required String body,
  }) {
    return _contractService.addComment(id: id, body: body);
  }

  Future<ContractPhoto> addPhoto({
    required String id,
    required String photo,
    required String description,
  }) {
    return _contractService.addPhoto(
      id: id,
      photo: photo,
      description: description,
    );
  }

  Future<Contract> cancelContract({
    required String id,
    required String justification,
  }) {
    return _contractService.cancelContract(id: id, justification: justification);
  }
}
