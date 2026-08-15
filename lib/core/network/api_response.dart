import 'package:ocupa2/core/network/json_parsing.dart';

class ApiResponse<T> {
  const ApiResponse({required this.ok, required this.data});

  final bool ok;
  final T data;

  factory ApiResponse.fromJson(
    Object? json, {
    required T Function(Object? data) parseData,
  }) {
    final Map<String, dynamic> response = requireJsonObject(
      json,
      context: 'La respuesta del API',
    );

    final bool ok = requireBool(
      response,
      'ok',
      context: 'La respuesta del API',
    );

    if (!ok) {
      throw const FormatException(
        'El servidor indicó que la operación no fue exitosa.',
      );
    }

    if (!response.containsKey('data')) {
      throw const FormatException(
        'La respuesta del API no contiene el campo "data".',
      );
    }

    return ApiResponse<T>(ok: ok, data: parseData(response['data']));
  }
}
