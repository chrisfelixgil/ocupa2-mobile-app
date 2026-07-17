import 'package:ocupa2/core/network/api_exception.dart';
import 'package:ocupa2/core/storage/token_storage.dart';
import 'package:ocupa2/features/auth/data/models/auth_response.dart';
import 'package:ocupa2/features/auth/data/models/change_password_request.dart';
import 'package:ocupa2/features/auth/data/models/forgot_password_request.dart';
import 'package:ocupa2/features/auth/data/models/login_request.dart';
import 'package:ocupa2/features/auth/data/models/message_response.dart';
import 'package:ocupa2/features/auth/data/models/register_request.dart';
import 'package:ocupa2/features/auth/data/models/user.dart';
import 'package:ocupa2/features/auth/data/repositories/auth_repository.dart';
import 'package:ocupa2/features/auth/data/services/auth_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required this._authService,
    required this._tokenStorage,
  });

  final AuthService _authService;
  final TokenStorage _tokenStorage;

  @override
  Future<AuthResponse> register(RegisterRequest request) async {
    final AuthResponse response = await _authService.register(request);

    await _saveToken(
      response.token,
      failureMessage:
          'La cuenta fue creada, pero no fue posible guardar la sesión. '
          'Inicia sesión con tu correo y contraseña.',
    );

    return response;
  }

  @override
  Future<AuthResponse> login(LoginRequest request) async {
    final AuthResponse response = await _authService.login(request);

    await _saveToken(
      response.token,
      failureMessage:
          'El inicio de sesión fue correcto, pero no fue posible guardar '
          'la sesión de forma segura.',
    );

    return response;
  }

  @override
  Future<MessageResponse> forgotPassword(ForgotPasswordRequest request) {
    return _authService.forgotPassword(request);
  }

  @override
  Future<User> getCurrentUser() {
    return _authService.getCurrentUser();
  }

  @override
  Future<MessageResponse> changePassword(ChangePasswordRequest request) {
    return _authService.changePassword(request);
  }

  @override
  Future<bool> hasStoredSession() async {
    try {
      final String? token = await _tokenStorage.readToken();
      return token != null;
    } catch (error) {
      throw ApiException(
        type: ApiExceptionType.storage,
        message:
            'No fue posible comprobar la sesión guardada en el dispositivo.',
        originalError: error,
      );
    }
  }

  @override
  Future<void> clearSession() async {
    try {
      await _tokenStorage.deleteToken();
    } catch (error) {
      throw ApiException(
        type: ApiExceptionType.storage,
        message:
            'No fue posible eliminar la sesión guardada en el dispositivo.',
        originalError: error,
      );
    }
  }

  Future<void> _saveToken(
    String token, {
    required String failureMessage,
  }) async {
    try {
      await _tokenStorage.saveToken(token);
    } catch (error) {
      throw ApiException(
        type: ApiExceptionType.storage,
        message: failureMessage,
        originalError: error,
      );
    }
  }
}
