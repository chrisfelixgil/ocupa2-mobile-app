import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ocupa2/app/app.dart';
import 'package:ocupa2/app/router/app_router.dart';
import 'package:ocupa2/core/session/session_event_bus.dart';
import 'package:ocupa2/features/auth/presentation/viewmodels/session_view_model.dart';
import 'package:provider/provider.dart';

import 'helpers/fake_auth_repository.dart';

void main() {
  testWidgets('redirige al login cuando no existe sesión', (
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

    final GoRouter router = createAppRouter(sessionViewModel);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SessionViewModel>.value(
            value: sessionViewModel,
          ),
          Provider<GoRouter>.value(value: router),
        ],
        child: const Ocupa2App(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Inicio de sesión'), findsOneWidget);
    expect(
      find.text('No existe una sesión guardada en este dispositivo.'),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());

    router.dispose();
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

    final GoRouter router = createAppRouter(sessionViewModel);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SessionViewModel>.value(
            value: sessionViewModel,
          ),
          Provider<GoRouter>.value(value: router),
        ],
        child: const Ocupa2App(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Sesión restaurada'), findsOneWidget);
    expect(find.text('Christian Gil'), findsOneWidget);
    expect(find.text('usuario@itla.edu.do'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());

    router.dispose();
    sessionViewModel.dispose();
    eventBus.dispose();
  });
}
