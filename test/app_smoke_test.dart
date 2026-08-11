import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ocupa2/app/app.dart';
import 'package:ocupa2/app/router/app_router.dart';
import 'package:ocupa2/app/router/route_paths.dart';
import 'package:ocupa2/core/session/session_event_bus.dart';
import 'package:ocupa2/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:ocupa2/features/auth/presentation/viewmodels/session_view_model.dart';
import 'package:provider/provider.dart';

import 'helpers/fake_auth_repository.dart';

void main() {
  testWidgets('permite navegar por las rutas públicas sin sesión', (
    WidgetTester tester,
  ) async {
    final SessionEventBus eventBus = SessionEventBus();

    final FakeAuthRepository repository = FakeAuthRepository(
      currentUser: buildTestUser(),
      hasSession: false,
    );

    final SessionViewModel sessionViewModel = SessionViewModel(
      authRepository: repository,
      sessionEventBus: eventBus,
    );

    await sessionViewModel.restoreSession();

    final AuthViewModel authViewModel = AuthViewModel(
      authRepository: repository,
      sessionViewModel: sessionViewModel,
    );

    final GoRouter router = createAppRouter(sessionViewModel);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SessionViewModel>.value(
            value: sessionViewModel,
          ),
          ChangeNotifierProvider<AuthViewModel>.value(value: authViewModel),
          Provider<GoRouter>.value(value: router),
        ],
        child: const Ocupa2App(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Inicia sesión en Ocupa2'), findsOneWidget);

    router.go(RoutePaths.register);
    await tester.pumpAndSettle();

    expect(find.text('Crea tu cuenta'), findsOneWidget);

    router.go(RoutePaths.forgotPassword);
    await tester.pumpAndSettle();

    expect(find.text('Recupera tu contraseña'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());

    router.dispose();
    authViewModel.dispose();
    sessionViewModel.dispose();
    eventBus.dispose();
  });

  testWidgets('redirige al área autenticada cuando existe usuario', (
    WidgetTester tester,
  ) async {
    final SessionEventBus eventBus = SessionEventBus();

    final FakeAuthRepository repository = FakeAuthRepository(
      currentUser: buildTestUser(),
      hasSession: true,
    );

    final SessionViewModel sessionViewModel = SessionViewModel(
      authRepository: repository,
      sessionEventBus: eventBus,
    );

    await sessionViewModel.restoreSession();

    final AuthViewModel authViewModel = AuthViewModel(
      authRepository: repository,
      sessionViewModel: sessionViewModel,
    );

    final GoRouter router = createAppRouter(sessionViewModel);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SessionViewModel>.value(
            value: sessionViewModel,
          ),
          ChangeNotifierProvider<AuthViewModel>.value(value: authViewModel),
          Provider<GoRouter>.value(value: router),
        ],
        child: const Ocupa2App(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Sesión activa'), findsOneWidget);
    expect(find.text('Christian Gil'), findsOneWidget);
    expect(find.text('usuario@itla.edu.do'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());

    router.dispose();
    authViewModel.dispose();
    sessionViewModel.dispose();
    eventBus.dispose();
  });

  testWidgets('obliga a completar el perfil antes de entrar al área privada', (
    WidgetTester tester,
  ) async {
    final SessionEventBus eventBus = SessionEventBus();

    final FakeAuthRepository repository = FakeAuthRepository(
      currentUser: buildTestUser(profileCompleted: false),
      completedProfileUser: buildTestUser(),
      hasSession: true,
    );

    final SessionViewModel sessionViewModel = SessionViewModel(
      authRepository: repository,
      sessionEventBus: eventBus,
    );

    await sessionViewModel.restoreSession();

    final AuthViewModel authViewModel = AuthViewModel(
      authRepository: repository,
      sessionViewModel: sessionViewModel,
    );

    final GoRouter router = createAppRouter(sessionViewModel);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SessionViewModel>.value(
            value: sessionViewModel,
          ),
          ChangeNotifierProvider<AuthViewModel>.value(value: authViewModel),
          Provider<GoRouter>.value(value: router),
        ],
        child: const Ocupa2App(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Completa tu perfil'), findsOneWidget);

    router.go(RoutePaths.home);
    await tester.pumpAndSettle();

    expect(find.text('Completa tu perfil'), findsOneWidget);

    sessionViewModel.setAuthenticatedUser(buildTestUser());
    await tester.pumpAndSettle();

    expect(find.text('Sesión activa'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());

    router.dispose();
    authViewModel.dispose();
    sessionViewModel.dispose();
    eventBus.dispose();
  });

  testWidgets('obliga a cambiar la contraseña tras login con clave temporal', (
    WidgetTester tester,
  ) async {
    final SessionEventBus eventBus = SessionEventBus();

    final FakeAuthRepository repository = FakeAuthRepository(
      currentUser: buildTestUser(),
      hasSession: false,
    );

    final SessionViewModel sessionViewModel = SessionViewModel(
      authRepository: repository,
      sessionEventBus: eventBus,
    );

    await sessionViewModel.restoreSession();

    final AuthViewModel authViewModel = AuthViewModel(
      authRepository: repository,
      sessionViewModel: sessionViewModel,
    );

    final GoRouter router = createAppRouter(sessionViewModel);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SessionViewModel>.value(
            value: sessionViewModel,
          ),
          ChangeNotifierProvider<AuthViewModel>.value(value: authViewModel),
          Provider<GoRouter>.value(value: router),
        ],
        child: const Ocupa2App(),
      ),
    );

    await tester.pumpAndSettle();

    final bool success = await authViewModel.login(
      email: 'usuario@itla.edu.do',
      password: 'EC8C71C6',
      requirePasswordChange: true,
    );

    expect(success, isTrue);
    await tester.pumpAndSettle();

    expect(find.text('Actualiza tu clave temporal'), findsOneWidget);

    router.go(RoutePaths.home);
    await tester.pumpAndSettle();

    expect(find.text('Actualiza tu clave temporal'), findsOneWidget);

    sessionViewModel.clearPasswordChangeRequirement();
    router.go(RoutePaths.home);
    await tester.pumpAndSettle();

    expect(find.text('Sesión activa'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());

    router.dispose();
    authViewModel.dispose();
    sessionViewModel.dispose();
    eventBus.dispose();
  });
}
