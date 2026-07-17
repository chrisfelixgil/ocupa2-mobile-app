import 'package:ocupa2/core/network/json_parsing.dart';

class MessageResponse {
  const MessageResponse({required this.message});

  final String message;

  factory MessageResponse.fromJson(Object? json) {
    final Map<String, dynamic> data = requireJsonObject(
      json,
      context: 'La respuesta de mensaje',
    );

    return MessageResponse(
      message: requireString(
        data,
        'message',
        context: 'La respuesta de mensaje',
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'message': message};
  }
}
