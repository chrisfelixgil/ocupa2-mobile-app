import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ocupa2/app/router/app_routes.dart';
import 'package:ocupa2/app/router/route_paths.dart';
import 'package:ocupa2/app/theme/app_theme.dart';
import 'package:ocupa2/core/session/session_event_bus.dart';
import 'package:ocupa2/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:ocupa2/features/auth/presentation/viewmodels/session_view_model.dart';
import 'package:ocupa2/features/auth/presentation/views/forgot_password_view.dart';
import 'package:ocupa2/features/auth/presentation/views/login_view.dart';
import 'package:provider/provider.dart';

import '../../../helpers/fake_auth_repository.dart';

void main() {
  group('ForgotPasswordView', () {
    late FakeAuthRepository repository;
    late SessionEventBus eventBus;
    late SessionViewModel sessionViewModel;
    late AuthViewModel authViewModel;
    late GoRouter router;

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

      router = GoRouter(
        initialLocation: RoutePaths.forgotPassword,
        routes: <RouteBase>[
          GoRoute(
            path: RoutePaths.forgotPassword,
            name: AppRouteNames.forgotPassword,
            builder: (BuildContext context, GoRouterState state) {
              return const ForgotPasswordView();
            },
          ),
          GoRoute(
            path: RoutePaths.login,
            name: AppRouteNames.login,
            builder: (BuildContext context, GoRouterState state) {
              return LoginView(
                initialEmail: state.uri.queryParameters['email'],
                fromPasswordRecovery:
                    state.uri.queryParameters['recovered'] == '1',
              );
            },
          ),
        ],
      );
    });

    tearDown(() {
      router.dispose();
      authViewModel.dispose();
      sessionViewModel.dispose();
      eventBus.dispose();
    });

    Future<void> buildView(WidgetTester tester) async {
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
    }

    testWidgets('muestra los campos de recuperación', (
      WidgetTester tester,
    ) async {
      await buildView(tester);

      expect(find.text('Recupera tu contraseña'), findsOneWidget);
      expect(find.byKey(const Key('forgot_email_field')), findsOneWidget);
      expect(
        find.byKey(const Key('forgot_referral_matricula_field')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('forgot_submit_button')), findsOneWidget);
    });

    testWidgets(
      'tras solicitar la clave temporal redirige al login con el correo',
      (WidgetTester tester) async {
        await buildView(tester);

        await tester.enterText(
          find.byKey(const Key('forgot_email_field')),
          'usuario@itla.edu.do',
        );

        await tester.enterText(
          find.byKey(const Key('forgot_referral_matricula_field')),
          '20121036',
        );

        await tester.tap(find.byKey(const Key('forgot_submit_button')));
        await tester.pumpAndSettle();

        expect(repository.forgotPasswordCalls, 1);
        expect(find.text('Inicia sesión en Ocupa2'), findsOneWidget);
        expect(
          find.text('Revisa tu correo e inicia sesión con la clave temporal.'),
          findsOneWidget,
        );
        expect(find.text('Clave temporal'), findsOneWidget);

        final FormBuilderState formState = tester.state<FormBuilderState>(
          find.byType(FormBuilder),
        );

        expect(formState.fields['email']?.value, 'usuario@itla.edu.do');
      },
    );
  });
}
