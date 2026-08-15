import 'package:flutter_test/flutter_test.dart';
import 'package:ocupa2/core/network/api_exception.dart';
import 'package:ocupa2/core/session/session_event_bus.dart';
import 'package:ocupa2/features/auth/presentation/viewmodels/auth_status.dart';
import 'package:ocupa2/features/auth/presentation/viewmodels/session_view_model.dart';

import '../../../../helpers/fake_auth_repository.dart';

void main() {
  group('SessionViewModel', () {
    late FakeAuthRepository repository;
    late SessionEventBus eventBus;
    late SessionViewModel viewModel;

    setUp(() {
      repository = FakeAuthRepository(currentUser: buildTestUser());

      eventBus = SessionEventBus();

      viewModel = SessionViewModel(
        authRepository: repository,
        sessionEventBus: eventBus,
      );
    });

    tearDown(() {
      viewModel.dispose();
      eventBus.dispose();
    });

    test('inicia en estado checking', () {
      expect(viewModel.status, AuthStatus.checking);
      expect(viewModel.user, isNull);
      expect(viewModel.errorMessage, isNull);
    });

    test('queda unauthenticated cuando no existe token', () async {
      repository.hasSession = false;

      await viewModel.restoreSession();

      expect(viewModel.status, AuthStatus.unauthenticated);
      expect(viewModel.user, isNull);
      expect(repository.getCurrentUserCalls, 0);
    });

    test('restaura usuario cuando existe sesión válida', () async {
      repository.hasSession = true;

      await viewModel.restoreSession();

      expect(viewModel.status, AuthStatus.authenticated);
      expect(viewModel.user, same(repository.currentUser));
      expect(viewModel.errorMessage, isNull);
      expect(repository.getCurrentUserCalls, 1);
    });

    test('elimina sesión ante respuesta 401', () async {
      repository.hasSession = true;
      repository.getCurrentUserError = const ApiException(
        type: ApiExceptionType.unauthorized,
        message: 'Token inválido.',
        statusCode: 401,
      );

      await viewModel.restoreSession();

      expect(viewModel.status, AuthStatus.unauthenticated);
      expect(viewModel.user, isNull);
      expect(repository.clearSessionCalls, 1);
      expect(repository.hasSession, isFalse);
    });

    test('conserva token y muestra error de conexión', () async {
      repository.hasSession = true;
      repository.getCurrentUserError = const ApiException(
        type: ApiExceptionType.connection,
        message: 'No fue posible conectar con el servidor.',
      );

      await viewModel.restoreSession();

      expect(viewModel.status, AuthStatus.error);
      expect(
        viewModel.errorMessage,
        'No fue posible conectar con el servidor.',
      );
      expect(repository.clearSessionCalls, 0);
      expect(repository.hasSession, isTrue);
    });

    test('procesa el evento de sesión expirada', () async {
      viewModel.setAuthenticatedUser(repository.currentUser);

      repository.hasSession = true;

      eventBus.notifySessionExpired();

      await Future<void>.delayed(Duration.zero);

      expect(viewModel.status, AuthStatus.unauthenticated);
      expect(viewModel.user, isNull);
      expect(repository.clearSessionCalls, 1);
    });

    test('acepta un usuario después de login o registro', () {
      viewModel.setAuthenticatedUser(repository.currentUser);

      expect(viewModel.status, AuthStatus.authenticated);
      expect(viewModel.user, same(repository.currentUser));
      expect(viewModel.requiresPasswordChange, isFalse);
    });

    test('marca el cambio de contraseña obligatorio tras recuperación', () {
      viewModel.setAuthenticatedUser(
        repository.currentUser,
        requirePasswordChange: true,
      );

      expect(viewModel.requiresPasswordChange, isTrue);

      viewModel.clearPasswordChangeRequirement();

      expect(viewModel.requiresPasswordChange, isFalse);
    });

    test('permite reintentar después de un error', () async {
      repository.hasStoredSessionError = const ApiException(
        type: ApiExceptionType.storage,
        message: 'No fue posible leer la sesión.',
      );

      await viewModel.restoreSession();

      expect(viewModel.status, AuthStatus.error);

      repository.hasStoredSessionError = null;
      repository.hasSession = false;

      await viewModel.restoreSession();

      expect(viewModel.status, AuthStatus.unauthenticated);
      expect(viewModel.errorMessage, isNull);
    });

    test('logout elimina la sesión y el usuario', () async {
      repository.hasSession = true;

      viewModel.setAuthenticatedUser(repository.currentUser);

      final bool result = await viewModel.logout();

      expect(result, isTrue);
      expect(viewModel.isLoggingOut, isFalse);
      expect(viewModel.status, AuthStatus.unauthenticated);
      expect(viewModel.user, isNull);
      expect(repository.clearSessionCalls, 1);
      expect(repository.hasSession, isFalse);
    });

    test('logout fallido conserva el usuario autenticado', () async {
      repository.hasSession = true;

      viewModel.setAuthenticatedUser(repository.currentUser);

      repository.clearSessionError = const ApiException(
        type: ApiExceptionType.storage,
        message: 'No fue posible eliminar la sesión.',
      );

      final bool result = await viewModel.logout();

      expect(result, isFalse);
      expect(viewModel.isLoggingOut, isFalse);
      expect(viewModel.status, AuthStatus.authenticated);
      expect(viewModel.user, same(repository.currentUser));
      expect(
        viewModel.sessionActionErrorMessage,
        'No fue posible eliminar la sesión.',
      );
    });
  });
}
