import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ocupa2/app/router/app_routes.dart';
import 'package:ocupa2/app/router/route_paths.dart';
import 'package:ocupa2/app/theme/app_theme.dart';
import 'package:ocupa2/core/session/session_event_bus.dart';
import 'package:ocupa2/features/auth/presentation/viewmodels/auth_status.dart';
import 'package:ocupa2/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:ocupa2/features/auth/presentation/viewmodels/session_view_model.dart';
import 'package:ocupa2/features/auth/presentation/views/login_view.dart';
import 'package:provider/provider.dart';

import '../../../helpers/fake_auth_repository.dart';

void main() {
  group('LoginView', () {
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

    Future<void> buildLogin(
      WidgetTester tester, {
      String? initialEmail,
      bool fromPasswordRecovery = false,
    }) async {
      final GoRouter router = GoRouter(
        initialLocation: RoutePaths.login,
        routes: <RouteBase>[
          GoRoute(
            path: RoutePaths.login,
            name: AppRouteNames.login,
            builder: (BuildContext context, GoRouterState state) {
              return LoginView(
                initialEmail: initialEmail,
                fromPasswordRecovery: fromPasswordRecovery,
              );
            },
          ),
          GoRoute(
            path: RoutePaths.register,
            name: AppRouteNames.register,
            builder: (BuildContext context, GoRouterState state) {
              return const SizedBox.shrink();
            },
          ),
          GoRoute(
            path: RoutePaths.forgotPassword,
            name: AppRouteNames.forgotPassword,
            builder: (BuildContext context, GoRouterState state) {
              return const SizedBox.shrink();
            },
          ),
        ],
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SessionViewModel>.value(
              value: sessionViewModel,
            ),
            ChangeNotifierProvider<AuthViewModel>.value(value: authViewModel),
            Provider<GoRouter>.value(value: router),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      addTearDown(router.dispose);
    }

    testWidgets('muestra sus campos y botón', (WidgetTester tester) async {
      await buildLogin(tester);

      expect(find.text('Inicia sesión en Ocupa2'), findsOneWidget);
      expect(find.byKey(const Key('login_email_field')), findsOneWidget);
      expect(find.byKey(const Key('login_password_field')), findsOneWidget);
      expect(find.byKey(const Key('login_submit_button')), findsOneWidget);
    });

    testWidgets('muestra validaciones al enviar campos vacíos', (
      WidgetTester tester,
    ) async {
      await buildLogin(tester);

      await tester.tap(find.byKey(const Key('login_submit_button')));

      await tester.pump();

      expect(find.text('El correo es obligatorio.'), findsOneWidget);
      expect(find.text('La contraseña es obligatoria.'), findsOneWidget);
      expect(repository.loginCalls, 0);
    });

    testWidgets('envía credenciales válidas y actualiza sesión', (
      WidgetTester tester,
    ) async {
      await buildLogin(tester);

      await tester.enterText(
        find.byKey(const Key('login_email_field')),
        'usuario@itla.edu.do',
      );

      await tester.enterText(
        find.byKey(const Key('login_password_field')),
        'clave123',
      );

      await tester.tap(find.byKey(const Key('login_submit_button')));

      await tester.pumpAndSettle();

      expect(repository.loginCalls, 1);
      expect(repository.lastLoginRequest?.email, 'usuario@itla.edu.do');
      expect(sessionViewModel.status, AuthStatus.authenticated);
    });

    testWidgets('muestra guía de clave temporal tras recuperación', (
      WidgetTester tester,
    ) async {
      await buildLogin(
        tester,
        initialEmail: 'usuario@itla.edu.do',
        fromPasswordRecovery: true,
      );

      expect(
        find.text('Revisa tu correo e inicia sesión con la clave temporal.'),
        findsOneWidget,
      );
      expect(find.text('Clave temporal'), findsOneWidget);

      final FormBuilderState formState = tester.state<FormBuilderState>(
        find.byType(FormBuilder),
      );

      expect(formState.fields['email']?.value, 'usuario@itla.edu.do');
    });
  });
}
