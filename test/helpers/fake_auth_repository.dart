import 'package:ocupa2/features/auth/data/models/auth_response.dart';
import 'package:ocupa2/features/auth/data/models/change_password_request.dart';
import 'package:ocupa2/features/auth/data/models/forgot_password_request.dart';
import 'package:ocupa2/features/auth/data/models/login_request.dart';
import 'package:ocupa2/features/auth/data/models/message_response.dart';
import 'package:ocupa2/features/auth/data/models/register_request.dart';
import 'package:ocupa2/features/auth/data/models/user.dart';
import 'package:ocupa2/features/auth/data/repositories/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({required this.currentUser, this.hasSession = false});

  bool hasSession;
  User currentUser;

  Object? hasStoredSessionError;
  Object? getCurrentUserError;
  Object? clearSessionError;

  int getCurrentUserCalls = 0;
  int clearSessionCalls = 0;

  @override
  Future<bool> hasStoredSession() async {
    final Object? error = hasStoredSessionError;

    if (error != null) {
      throw error;
    }

    return hasSession;
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
  Future<void> clearSession() async {
    clearSessionCalls++;

    final Object? error = clearSessionError;

    if (error != null) {
      throw error;
    }

    hasSession = false;
  }

  @override
  Future<AuthResponse> register(RegisterRequest request) {
    throw UnimplementedError();
  }

  @override
  Future<AuthResponse> login(LoginRequest request) {
    throw UnimplementedError();
  }

  @override
  Future<MessageResponse> forgotPassword(ForgotPasswordRequest request) {
    throw UnimplementedError();
  }

  @override
  Future<MessageResponse> changePassword(ChangePasswordRequest request) {
    throw UnimplementedError();
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
