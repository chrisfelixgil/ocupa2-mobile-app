import 'package:flutter_test/flutter_test.dart';
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
import 'package:ocupa2/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:ocupa2/features/auth/data/services/auth_service.dart';

void main() {
  group('AuthRepositoryImpl', () {
    late User user;
    late AuthResponse authResponse;
    late FakeAuthService authService;
    late FakeTokenStorage tokenStorage;
    late AuthRepository repository;

    setUp(() {
      user = User(
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

      authResponse = AuthResponse(
        token: 'token-de-prueba',
        tokenType: 'Bearer',
        user: user,
      );

      authService = FakeAuthService(
        authResponse: authResponse,
        currentUser: user,
        forgotPasswordResponse: const MessageResponse(
          message: 'Solicitud procesada.',
        ),
        changePasswordResponse: const MessageResponse(
          message: 'Clave actualizada.',
        ),
      );

      tokenStorage = FakeTokenStorage();

      repository = AuthRepositoryImpl(
        authService: authService,
        tokenStorage: tokenStorage,
      );
    });

    test('registro guarda el token y devuelve la respuesta', () async {
      const RegisterRequest request = RegisterRequest(
        email: 'usuario@itla.edu.do',
        firstName: 'Christian',
        lastName: 'Gil',
        password: 'clave123',
        referralMatricula: '20121036',
      );

      final AuthResponse result = await repository.register(request);

      expect(result, same(authResponse));
      expect(tokenStorage.token, 'token-de-prueba');
      expect(authService.lastRegisterRequest, same(request));
    });

    test('login guarda el token y devuelve la respuesta', () async {
      const LoginRequest request = LoginRequest(
        email: 'usuario@itla.edu.do',
        password: 'clave123',
      );

      final AuthResponse result = await repository.login(request);

      expect(result, same(authResponse));
      expect(tokenStorage.token, 'token-de-prueba');
      expect(authService.lastLoginRequest, same(request));
    });

    test('recuperación no modifica el token', () async {
      tokenStorage.token = 'token-existente';

      const ForgotPasswordRequest request = ForgotPasswordRequest(
        email: 'usuario@itla.edu.do',
        referralMatricula: '20121036',
      );

      final MessageResponse result = await repository.forgotPassword(request);

      expect(result.message, 'Solicitud procesada.');
      expect(tokenStorage.token, 'token-existente');
      expect(authService.lastForgotPasswordRequest, same(request));
    });

    test('obtiene el usuario autenticado', () async {
      final User result = await repository.getCurrentUser();

      expect(result, same(user));
    });

    test('cambia la contraseña mediante el servicio', () async {
      const ChangePasswordRequest request = ChangePasswordRequest(
        password: 'nuevaClave123',
      );

      final MessageResponse result = await repository.changePassword(request);

      expect(result.message, 'Clave actualizada.');
      expect(authService.lastChangePasswordRequest, same(request));
    });

    test('detecta una sesión almacenada', () async {
      tokenStorage.token = 'token-de-prueba';

      final bool result = await repository.hasStoredSession();

      expect(result, isTrue);
    });

    test('indica que no existe sesión almacenada', () async {
      tokenStorage.token = null;

      final bool result = await repository.hasStoredSession();

      expect(result, isFalse);
    });

    test('elimina la sesión local', () async {
      tokenStorage.token = 'token-de-prueba';

      await repository.clearSession();

      expect(tokenStorage.token, isNull);
    });

    test('no guarda token cuando login falla', () async {
      authService.loginError = const ApiException(
        type: ApiExceptionType.unauthorized,
        message: 'Correo o clave incorrectos.',
        statusCode: 401,
      );

      const LoginRequest request = LoginRequest(
        email: 'usuario@itla.edu.do',
        password: 'incorrecta',
      );

      await expectLater(
        repository.login(request),
        throwsA(
          isA<ApiException>().having(
            (ApiException error) => error.type,
            'type',
            ApiExceptionType.unauthorized,
          ),
        ),
      );

      expect(tokenStorage.token, isNull);
    });

    test('convierte fallo de almacenamiento en ApiException', () async {
      tokenStorage.saveError = StateError('Almacenamiento no disponible');

      const LoginRequest request = LoginRequest(
        email: 'usuario@itla.edu.do',
        password: 'clave123',
      );

      await expectLater(
        repository.login(request),
        throwsA(
          isA<ApiException>().having(
            (ApiException error) => error.type,
            'type',
            ApiExceptionType.storage,
          ),
        ),
      );
    });
  });
}

class FakeAuthService implements AuthService {
  FakeAuthService({
    required this.authResponse,
    required this.currentUser,
    required this.forgotPasswordResponse,
    required this.changePasswordResponse,
  });

  final AuthResponse authResponse;
  final User currentUser;
  final MessageResponse forgotPasswordResponse;
  final MessageResponse changePasswordResponse;

  RegisterRequest? lastRegisterRequest;
  LoginRequest? lastLoginRequest;
  ForgotPasswordRequest? lastForgotPasswordRequest;
  ChangePasswordRequest? lastChangePasswordRequest;

  Object? loginError;

  @override
  Future<AuthResponse> register(RegisterRequest request) async {
    lastRegisterRequest = request;
    return authResponse;
  }

  @override
  Future<AuthResponse> login(LoginRequest request) async {
    lastLoginRequest = request;

    final Object? error = loginError;

    if (error != null) {
      throw error;
    }

    return authResponse;
  }

  @override
  Future<MessageResponse> forgotPassword(ForgotPasswordRequest request) async {
    lastForgotPasswordRequest = request;
    return forgotPasswordResponse;
  }

  @override
  Future<User> getCurrentUser() async {
    return currentUser;
  }

  @override
  Future<MessageResponse> changePassword(ChangePasswordRequest request) async {
    lastChangePasswordRequest = request;
    return changePasswordResponse;
  }
}

class FakeTokenStorage implements TokenStorage {
  String? token;

  Object? saveError;
  Object? readError;
  Object? deleteError;

  @override
  Future<void> saveToken(String token) async {
    final Object? error = saveError;

    if (error != null) {
      throw error;
    }

    this.token = token;
  }

  @override
  Future<String?> readToken() async {
    final Object? error = readError;

    if (error != null) {
      throw error;
    }

    return token;
  }

  @override
  Future<void> deleteToken() async {
    final Object? error = deleteError;

    if (error != null) {
      throw error;
    }

    token = null;
  }
}
