import 'package:ocupa2/core/constants/api_endpoints.dart';
import 'package:ocupa2/core/network/api_client.dart';
import 'package:ocupa2/core/network/api_exception.dart';
import 'package:ocupa2/core/network/api_response.dart';
import 'package:ocupa2/core/network/request_auth.dart';
import 'package:ocupa2/features/auth/data/models/auth_response.dart';
import 'package:ocupa2/features/auth/data/models/change_password_request.dart';
import 'package:ocupa2/features/auth/data/models/forgot_password_request.dart';
import 'package:ocupa2/features/auth/data/models/login_request.dart';
import 'package:ocupa2/features/auth/data/models/message_response.dart';
import 'package:ocupa2/features/auth/data/models/register_request.dart';
import 'package:ocupa2/features/auth/data/models/user.dart';
import 'package:ocupa2/features/auth/data/services/auth_service.dart';

class AuthServiceImpl implements AuthService {
  const AuthServiceImpl({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<AuthResponse> register(RegisterRequest request) async {
    final Object? rawResponse = await _apiClient.post(
      ApiEndpoints.register,
      auth: RequestAuth.public,
      data: request.toJson(),
    );

    return _parseSuccess<AuthResponse>(rawResponse, AuthResponse.fromJson);
  }

  @override
  Future<AuthResponse> login(LoginRequest request) async {
    final Object? rawResponse = await _apiClient.post(
      ApiEndpoints.login,
      auth: RequestAuth.public,
      data: request.toJson(),
    );

    return _parseSuccess<AuthResponse>(rawResponse, AuthResponse.fromJson);
  }

  @override
  Future<MessageResponse> forgotPassword(ForgotPasswordRequest request) async {
    final Object? rawResponse = await _apiClient.post(
      ApiEndpoints.forgotPassword,
      auth: RequestAuth.public,
      data: request.toJson(),
    );

    return _parseSuccess<MessageResponse>(
      rawResponse,
      MessageResponse.fromJson,
    );
  }

  @override
  Future<User> getCurrentUser() async {
    final Object? rawResponse = await _apiClient.get(
      ApiEndpoints.me,
      auth: RequestAuth.protected,
    );

    return _parseSuccess<User>(rawResponse, User.fromJson);
  }

  @override
  Future<MessageResponse> changePassword(ChangePasswordRequest request) async {
    final Object? rawResponse = await _apiClient.put(
      ApiEndpoints.changePassword,
      auth: RequestAuth.protected,
      data: request.toJson(),
    );

    return _parseSuccess<MessageResponse>(
      rawResponse,
      MessageResponse.fromJson,
    );
  }

  T _parseSuccess<T>(Object? rawResponse, T Function(Object? data) parser) {
    try {
      final ApiResponse<T> response = ApiResponse<T>.fromJson(
        rawResponse,
        parseData: parser,
      );

      return response.data;
    } on FormatException catch (error) {
      throw ApiException(
        type: ApiExceptionType.responseFormat,
        message:
            'El servidor devolvió una respuesta con un formato inesperado.',
        originalError: error,
      );
    }
  }
}
