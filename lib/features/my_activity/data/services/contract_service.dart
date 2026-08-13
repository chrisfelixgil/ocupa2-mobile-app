import 'package:ocupa2/core/constants/api_endpoints.dart';
import 'package:ocupa2/core/network/api_client.dart';
import 'package:ocupa2/core/network/api_exception.dart';
import 'package:ocupa2/core/network/api_response.dart';
import 'package:ocupa2/core/network/request_auth.dart';
import 'package:ocupa2/features/my_activity/data/models/contract.dart';
import 'package:ocupa2/features/my_activity/data/models/contract_comment.dart';
import 'package:ocupa2/features/my_activity/data/models/contract_photo.dart';

abstract interface class ContractService {
  Future<List<Contract>> getMyContracts({String? status});

  Future<Contract> getContractDetail(String id);

  Future<Contract> setTerms({
    required String id,
    required num salary,
    String? currency,
    required String startDate,
    required String duration,
  });

  Future<Contract> acceptContract(String id);

  Future<Contract> rejectContract(String id);

  Future<ContractComment> addComment({
    required String id,
    required String body,
  });

  Future<ContractPhoto> addPhoto({
    required String id,
    required String photo,
    required String description,
  });

  Future<Contract> cancelContract({
    required String id,
    required String justification,
  });
}

class ContractServiceImpl implements ContractService {
  const ContractServiceImpl({required this._apiClient});

  final ApiClient _apiClient;

  @override
  Future<List<Contract>> getMyContracts({String? status}) async {
    final Object? response = await _apiClient.get(
      ApiEndpoints.myContracts,
      auth: RequestAuth.protected,
      queryParameters: <String, dynamic>{
        if (status != null && status.trim().isNotEmpty) 'status': status,
      },
    );

    return _parse(response, (Object? data) {
      final List<dynamic> items = data as List<dynamic>? ?? <dynamic>[];
      return items.map(Contract.fromJson).toList();
    });
  }

  @override
  Future<Contract> getContractDetail(String id) async {
    final Object? response = await _apiClient.get(
      ApiEndpoints.contractDetail(id),
      auth: RequestAuth.protected,
    );

    return _parse(response, Contract.fromJson);
  }

  @override
  Future<Contract> setTerms({
    required String id,
    required num salary,
    String? currency,
    required String startDate,
    required String duration,
  }) async {
    final Object? response = await _apiClient.put(
      ApiEndpoints.contractTerms(id),
      auth: RequestAuth.protected,
      data: <String, dynamic>{
        'salary': salary,
        'currency': currency ?? 'DOP',
        'startDate': startDate,
        'duration': duration,
      },
    );

    return _parse(response, Contract.fromJson);
  }

  @override
  Future<Contract> acceptContract(String id) async {
    final Object? response = await _apiClient.post(
      ApiEndpoints.contractAccept(id),
      auth: RequestAuth.protected,
    );

    return _parse(response, Contract.fromJson);
  }

  @override
  Future<Contract> rejectContract(String id) async {
    final Object? response = await _apiClient.post(
      ApiEndpoints.contractReject(id),
      auth: RequestAuth.protected,
    );

    return _parse(response, Contract.fromJson);
  }

  @override
  Future<ContractComment> addComment({
    required String id,
    required String body,
  }) async {
    final Object? response = await _apiClient.post(
      ApiEndpoints.contractComments(id),
      auth: RequestAuth.protected,
      data: <String, String>{
        'body': body,
      },
    );

    return _parse(response, ContractComment.fromJson);
  }

  @override
  Future<ContractPhoto> addPhoto({
    required String id,
    required String photo,
    required String description,
  }) async {
    final Object? response = await _apiClient.post(
      ApiEndpoints.contractPhotos(id),
      auth: RequestAuth.protected,
      data: <String, String>{
        'photo': photo,
        'description': description,
      },
    );

    return _parse(response, ContractPhoto.fromJson);
  }

  @override
  Future<Contract> cancelContract({
    required String id,
    required String justification,
  }) async {
    final Object? response = await _apiClient.post(
      ApiEndpoints.contractCancel(id),
      auth: RequestAuth.protected,
      data: <String, String>{
        'justification': justification,
      },
    );

    return _parse(response, Contract.fromJson);
  }

  T _parse<T>(Object? response, T Function(Object? data) parseData) {
    try {
      return ApiResponse<T>.fromJson(response, parseData: parseData).data;
    } on FormatException catch (error) {
      throw ApiException(
        type: ApiExceptionType.responseFormat,
        message: 'No fue posible leer la respuesta del contrato.',
        originalError: error,
      );
    }
  }
}
