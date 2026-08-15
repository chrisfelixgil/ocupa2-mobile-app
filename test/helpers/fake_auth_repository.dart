import 'package:ocupa2/features/auth/data/models/auth_response.dart';
import 'package:ocupa2/features/auth/data/models/change_password_request.dart';
import 'package:ocupa2/features/auth/data/models/complete_profile_request.dart';
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
    User? completedProfileUser,
    MessageResponse? forgotPasswordResponse,
    MessageResponse? changePasswordResponse,
  }) : authResponse =
           authResponse ??
           AuthResponse(
             token: 'token-de-prueba',
             tokenType: 'Bearer',
             user: currentUser,
           ),
       completedProfileUser = completedProfileUser ?? currentUser,
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
  User completedProfileUser;

  final AuthResponse authResponse;
  final MessageResponse forgotPasswordResponse;
  final MessageResponse changePasswordResponse;

  Object? registerError;
  Object? loginError;
  Object? forgotPasswordError;
  Object? getCurrentUserError;
  Object? completeProfileError;
  Object? changePasswordError;
  Object? hasStoredSessionError;
  Object? clearSessionError;

  RegisterRequest? lastRegisterRequest;
  LoginRequest? lastLoginRequest;
  ForgotPasswordRequest? lastForgotPasswordRequest;
  ChangePasswordRequest? lastChangePasswordRequest;
  CompleteProfileRequest? lastCompleteProfileRequest;

  int registerCalls = 0;
  int loginCalls = 0;
  int forgotPasswordCalls = 0;
  int getCurrentUserCalls = 0;
  int changePasswordCalls = 0;
  int completeProfileCalls = 0;
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
  Future<User> completeProfile(CompleteProfileRequest request) async {
    completeProfileCalls++;
    lastCompleteProfileRequest = request;

    final Object? error = completeProfileError;

    if (error != null) {
      throw error;
    }

    currentUser = completedProfileUser;

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

User buildTestUser({bool profileCompleted = true}) {
  return User(
    id: 'usuario-123',
    email: 'usuario@itla.edu.do',
    firstName: 'Christian',
    lastName: 'Gil',
    nombre: 'Christian Gil',
    cedula: profileCompleted ? '40212345678' : null,
    gender: profileCompleted ? 'masculino' : null,
    birthDate: profileCompleted ? DateTime(2004, 5, 17) : null,
    profileCompleted: profileCompleted,
    referralMatricula: '20121036',
    role: 'user',
    createdAt: DateTime.parse('2026-07-16T22:00:36+00:00'),
    lastLoginAt: DateTime.parse('2026-07-16T22:01:31+00:00'),
  );
}
