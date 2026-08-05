import 'package:ocupa2/features/auth/data/models/auth_response.dart';
import 'package:ocupa2/features/auth/data/models/change_password_request.dart';
import 'package:ocupa2/features/auth/data/models/forgot_password_request.dart';
import 'package:ocupa2/features/auth/data/models/login_request.dart';
import 'package:ocupa2/features/auth/data/models/message_response.dart';
import 'package:ocupa2/features/auth/data/models/register_request.dart';
import 'package:ocupa2/features/auth/data/models/user.dart';
import 'package:ocupa2/features/auth/data/repositories/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    required this.currentUser,
    this.hasSession = false,
    AuthResponse? authResponse,
    MessageResponse? forgotPasswordResponse,
    MessageResponse? changePasswordResponse,
  }) : authResponse =
           authResponse ??
           AuthResponse(
             token: 'token-de-prueba',
             tokenType: 'Bearer',
             user: currentUser,
           ),
       forgotPasswordResponse =
           forgotPasswordResponse ??
           const MessageResponse(
             message:
                 'Si los datos coinciden, enviamos una clave temporal a tu correo.',
           ),
       changePasswordResponse =
           changePasswordResponse ??
           const MessageResponse(message: 'Clave actualizada.');

  bool hasSession;
  User currentUser;

  final AuthResponse authResponse;
  final MessageResponse forgotPasswordResponse;
  final MessageResponse changePasswordResponse;

  Object? registerError;
  Object? loginError;
  Object? forgotPasswordError;
  Object? getCurrentUserError;
  Object? changePasswordError;
  Object? hasStoredSessionError;
  Object? clearSessionError;

  RegisterRequest? lastRegisterRequest;
  LoginRequest? lastLoginRequest;
  ForgotPasswordRequest? lastForgotPasswordRequest;
  ChangePasswordRequest? lastChangePasswordRequest;

  int registerCalls = 0;
  int loginCalls = 0;
  int forgotPasswordCalls = 0;
  int getCurrentUserCalls = 0;
  int changePasswordCalls = 0;
  int clearSessionCalls = 0;

  @override
  Future<AuthResponse> register(RegisterRequest request) async {
    registerCalls++;
    lastRegisterRequest = request;

    final Object? error = registerError;

    if (error != null) {
      throw error;
    }

    hasSession = true;

    return authResponse;
  }

  @override
  Future<AuthResponse> login(LoginRequest request) async {
    loginCalls++;
    lastLoginRequest = request;

    final Object? error = loginError;

    if (error != null) {
      throw error;
    }

    hasSession = true;

    return authResponse;
  }

  @override
  Future<MessageResponse> forgotPassword(ForgotPasswordRequest request) async {
    forgotPasswordCalls++;
    lastForgotPasswordRequest = request;

    final Object? error = forgotPasswordError;

    if (error != null) {
      throw error;
    }

    return forgotPasswordResponse;
  }

  @override
  Future<User> getCurrentUser() async {
    getCurrentUserCalls++;

    final Object? error = getCurrentUserError;

    if (error != null) {
      throw error;
    }

    return currentUser;
  }

  @override
  Future<MessageResponse> changePassword(ChangePasswordRequest request) async {
    changePasswordCalls++;
    lastChangePasswordRequest = request;

    final Object? error = changePasswordError;

    if (error != null) {
      throw error;
    }

    return changePasswordResponse;
  }

  @override
  Future<bool> hasStoredSession() async {
    final Object? error = hasStoredSessionError;

    if (error != null) {
      throw error;
    }

    return hasSession;
  }

  @override
  Future<void> clearSession() async {
    clearSessionCalls++;

    final Object? error = clearSessionError;

    if (error != null) {
      throw error;
    }

    hasSession = false;
  }
}

User buildTestUser() {
  return User(
    id: 'usuario-123',
    email: 'usuario@itla.edu.do',
    firstName: 'Christian',
    lastName: 'Gil',
    nombre: 'Christian Gil',
    referralMatricula: '20121036',
    role: 'user',
    createdAt: DateTime.parse('2026-07-16T22:00:36+00:00'),
    lastLoginAt: DateTime.parse('2026-07-16T22:01:31+00:00'),
    updatedAt: DateTime.parse('2026-07-16T22:00:36+00:00'),
  );
}
