import 'dart:convert';
import 'dart:typed_data';

import 'package:ocupa2/core/constants/api_endpoints.dart';
import 'package:ocupa2/core/network/api_client.dart';
import 'package:ocupa2/core/network/api_exception.dart';
import 'package:ocupa2/core/network/api_response.dart';
import 'package:ocupa2/core/network/request_auth.dart';
import 'package:ocupa2/features/uploads/data/models/upload_response.dart';

abstract interface class UploadService {
  Future<String> uploadImage({
    required Uint8List bytes,
    required String filename,
  });
}

class UploadServiceImpl implements UploadService {
  const UploadServiceImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<String> uploadImage({
    required Uint8List bytes,
    required String filename,
  }) async {
    final Object? response = await _apiClient.post(
      ApiEndpoints.uploads,
      auth: RequestAuth.protected,
      data: <String, String>{
        'image': base64Encode(bytes),
        'filename': filename,
      },
    );

    try {
      return ApiResponse<UploadResponse>.fromJson(
        response,
        parseData: UploadResponse.fromJson,
      ).data.url;
    } on FormatException catch (error) {
      throw ApiException(
        type: ApiExceptionType.responseFormat,
        message: 'No fue posible leer la respuesta de la imagen subida.',
        originalError: error,
      );
    }
  }
}
