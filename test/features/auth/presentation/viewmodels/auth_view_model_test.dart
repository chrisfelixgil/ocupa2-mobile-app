import 'package:flutter_test/flutter_test.dart';
import 'package:ocupa2/core/network/api_exception.dart';
import 'package:ocupa2/core/session/session_event_bus.dart';
import 'package:ocupa2/features/auth/presentation/viewmodels/auth_action_status.dart';
import 'package:ocupa2/features/auth/presentation/viewmodels/auth_status.dart';
import 'package:ocupa2/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:ocupa2/features/auth/presentation/viewmodels/session_view_model.dart';

import '../../../../helpers/fake_auth_repository.dart';

void main() {
  group('AuthViewModel', () {
    late FakeAuthRepository repository;
    late SessionEventBus eventBus;
    late SessionViewModel sessionViewModel;
    late AuthViewModel authViewModel;

    setUp(() {
      repository = FakeAuthRepository(currentUser: buildTestUser());

      eventBus = SessionEventBus();

      sessionViewModel = SessionViewModel(
        authRepository: repository,
        sessionEventBus: eventBus,
      );

      authViewModel = AuthViewModel(
        authRepository: repository,
        sessionViewModel: sessionViewModel,
      );
    });

    tearDown(() {
      authViewModel.dispose();
      sessionViewModel.dispose();
      eventBus.dispose();
    });

    test('inicia en estado idle', () {
      expect(authViewModel.status, AuthActionStatus.idle);
      expect(authViewModel.errorMessage, isNull);
      expect(authViewModel.successMessage, isNull);
    });

    test('login exitoso actualiza la sesión', () async {
      final bool result = await authViewModel.login(
        email: 'usuario@itla.edu.do',
        password: 'clave123',
      );

      expect(result, isTrue);
      expect(authViewModel.status, AuthActionStatus.success);
      expect(sessionViewModel.status, AuthStatus.authenticated);
      expect(sessionViewModel.user, same(repository.currentUser));
      expect(repository.loginCalls, 1);
      expect(repository.lastLoginRequest?.email, 'usuario@itla.edu.do');
    });

    test('registro exitoso actualiza la sesión', () async {
      final bool result = await authViewModel.register(
        email: 'usuario@itla.edu.do',
        firstName: 'Christian',
        lastName: 'Gil',
        password: 'clave123',
        referralMatricula: '20121036',
      );

      expect(result, isTrue);
      expect(authViewModel.status, AuthActionStatus.success);
      expect(sessionViewModel.status, AuthStatus.authenticated);
      expect(repository.registerCalls, 1);
      expect(repository.lastRegisterRequest?.referralMatricula, '20121036');
    });

    test('login incorrecto muestra error del API', () async {
      repository.loginError = const ApiException(
        type: ApiExceptionType.unauthorized,
        statusCode: 401,
        message: 'Correo o clave incorrectos.',
      );

      final bool result = await authViewModel.login(
        email: 'usuario@itla.edu.do',
        password: 'incorrecta',
      );

      expect(result, isFalse);
      expect(authViewModel.status, AuthActionStatus.error);
      expect(authViewModel.errorMessage, 'Correo o clave incorrectos.');
      expect(sessionViewModel.user, isNull);
    });

    test('recuperación muestra el mensaje del servidor', () async {
      final bool result = await authViewModel.forgotPassword(
        email: 'usuario@itla.edu.do',
        referralMatricula: '20121036',
      );

      expect(result, isTrue);
      expect(authViewModel.status, AuthActionStatus.success);
      expect(authViewModel.successMessage, contains('clave temporal'));
      expect(repository.forgotPasswordCalls, 1);
    });

    test('registro duplicado muestra error de conflicto', () async {
      repository.registerError = const ApiException(
        type: ApiExceptionType.conflict,
        statusCode: 409,
        message: 'El correo ya está registrado.',
      );

      final bool result = await authViewModel.register(
        email: 'usuario@itla.edu.do',
        firstName: 'Christian',
        lastName: 'Gil',
        password: 'clave123',
        referralMatricula: '20121036',
      );

      expect(result, isFalse);
      expect(authViewModel.status, AuthActionStatus.error);
      expect(authViewModel.errorMessage, 'El correo ya está registrado.');
    });

    test('resetFeedback limpia los mensajes', () async {
      await authViewModel.forgotPassword(
        email: 'usuario@itla.edu.do',
        referralMatricula: '20121036',
      );

      expect(authViewModel.successMessage, isNotNull);

      authViewModel.resetFeedback();

      expect(authViewModel.status, AuthActionStatus.idle);
      expect(authViewModel.successMessage, isNull);
      expect(authViewModel.errorMessage, isNull);
    });
  });
}
