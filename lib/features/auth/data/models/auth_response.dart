import 'package:ocupa2/core/network/json_parsing.dart';
import 'package:ocupa2/features/auth/data/models/user.dart';

class AuthResponse {
  const AuthResponse({
    required this.token,
    required this.tokenType,
    required this.user,
  });

  final String token;
  final String tokenType;
  final User user;

  factory AuthResponse.fromJson(Object? json) {
    final Map<String, dynamic> data = requireJsonObject(
      json,
      context: 'La autenticación',
    );

    return AuthResponse(
      token: requireString(data, 'token', context: 'La autenticación'),
      tokenType: requireString(data, 'tokenType', context: 'La autenticación'),
      user: User.fromJson(data['user']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'token': token,
      'tokenType': tokenType,
      'user': user.toJson(),
    };
  }
}
