import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:ocupa2/core/network/api_client.dart';
import 'package:ocupa2/core/network/request_auth.dart';

class UploadService {
  UploadService({required this._apiClient});

  final ApiClient _apiClient;

  /// Sube una imagen al servidor y devuelve su URL pública.
  ///
  /// POST /uploads
  /// `{ "image": "<base64>", "filename": "imagen.jpg" }`
  ///
  /// Recibe bytes (no [File]) para funcionar en Android y en Chrome.
  Future<String> uploadImage({
    required Uint8List bytes,
    required String filename,
  }) async {
    if (bytes.isEmpty) {
      throw Exception('El archivo de imagen está vacío.');
    }

    // El API permite máximo 8 MB.
    if (bytes.length > 8 * 1024 * 1024) {
      throw Exception('La imagen supera el tamaño máximo permitido de 8 MB.');
    }

    final String fileName = filename.trim().isEmpty ? 'image.jpg' : filename;
    final String base64Image = base64Encode(bytes);

    debugPrint(
      '[UploadService] Subiendo imagen: $fileName (${bytes.length} bytes)',
    );

    final Object? response = await _apiClient.post(
      '/uploads',
      auth: RequestAuth.protected,
      contentType: 'application/json',
      headers: <String, dynamic>{'accept': 'application/json'},
      data: <String, String>{'image': base64Image, 'filename': fileName},
    );

    debugPrint('[UploadService] Respuesta cruda: $response');

    if (response is! Map) {
      throw Exception('Respuesta inválida del servidor al subir la imagen.');
    }

    final Map<String, dynamic> responseMap = Map<String, dynamic>.from(
      response,
    );

    if (responseMap['ok'] != true) {
      debugPrint(
        '[UploadService] Servidor devolvió ok=false. '
        'message="${responseMap['message']}"',
      );
      throw Exception(
        responseMap['message']?.toString() ?? 'No se pudo subir la imagen.',
      );
    }

    final Object? data = responseMap['data'];

    if (data is! Map) {
      throw Exception('La respuesta no contiene los datos de la imagen.');
    }

    final Map<String, dynamic> dataMap = Map<String, dynamic>.from(data);
    final String? url = dataMap['url']?.toString();

    if (url == null || url.isEmpty) {
      throw Exception('El servidor no devolvió la URL pública de la imagen.');
    }

    return url;
  }
}
