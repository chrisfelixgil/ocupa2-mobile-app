import 'package:ocupa2/core/network/json_parsing.dart';

class UploadResponse {
  const UploadResponse({required this.url});

  final String url;

  factory UploadResponse.fromJson(Object? json) {
    final Map<String, dynamic> map = requireJsonObject(
      json,
      context: 'La imagen subida',
    );
    return UploadResponse(
      url: requireString(map, 'url', context: 'La imagen subida'),
    );
  }
}
