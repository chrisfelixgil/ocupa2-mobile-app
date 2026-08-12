import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:ocupa2/core/network/api_client.dart';
import 'package:ocupa2/core/network/request_auth.dart';

class UploadService {
  UploadService({
    required this._apiClient,
  });

  final ApiClient _apiClient;

  /// Sube una imagen al servidor y devuelve su URL pública.
  ///
  /// POST /uploads
  ///
  /// El servidor espera:
  /// {
  ///   "image": "<base64>",
  ///   "filename": "imagen.jpg"
  /// }
  Future<String> uploadImage(String filePath) async {
    final file = File(filePath);

    if (!await file.exists()) {
      throw Exception(
        'El archivo de imagen no existe.',
      );
    }

    final bytes = await file.readAsBytes();

    // El API permite máximo 8 MB.
    if (bytes.length > 8 * 1024 * 1024) {
      throw Exception(
        'La imagen supera el tamaño máximo permitido de 8 MB.',
      );
    }

    final base64Image = base64Encode(bytes);

    final fileName = file.uri.pathSegments.isNotEmpty
        ? file.uri.pathSegments.last
        : 'image.jpg';

    print('[UploadService] Subiendo imagen: $fileName (${bytes.length} bytes)');

    final response = await _apiClient.post(
      '/uploads',
      auth: RequestAuth.protected,
      contentType: 'application/json',
      headers: {
        'accept': 'application/json',
      },
      data: {
        'image': base64Image,
        'filename': fileName,
      },
    );

    // DEBUG: ver la respuesta cruda del servidor tal cual llega.
    debugPrint('[UploadService] Respuesta cruda: $response');

    if (response is! Map) {
      throw Exception(
        'Respuesta inválida del servidor al subir la imagen.',
      );
    }

    final responseMap =
        Map<String, dynamic>.from(response);

    if (responseMap['ok'] != true) {
      // DEBUG: confirmar que el mensaje viene del servidor, no de Dart.
      debugPrint(
        '[UploadService] Servidor devolvió ok=false. '
        'message="${responseMap['message']}" '
        'body completo=$responseMap',
      );
      throw Exception(
        responseMap['message']?.toString() ??
            'No se pudo subir la imagen.',
      );
    }

    final data = responseMap['data'];

    if (data is! Map) {
      throw Exception(
        'La respuesta no contiene los datos de la imagen.',
      );
    }

    final dataMap =
        Map<String, dynamic>.from(data);

    final url = dataMap['url']?.toString();

    if (url == null || url.isEmpty) {
      throw Exception(
        'El servidor no devolvió la URL pública de la imagen.',
      );
    }

    return url;
  }
}