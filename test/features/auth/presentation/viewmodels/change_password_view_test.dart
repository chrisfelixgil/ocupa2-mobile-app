import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ocupa2/app/theme/app_theme.dart';
import 'package:ocupa2/core/session/session_event_bus.dart';
import 'package:ocupa2/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:ocupa2/features/auth/presentation/viewmodels/session_view_model.dart';
import 'package:ocupa2/features/auth/presentation/views/change_password_view.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/fake_auth_repository.dart';

void main() {
  group('ChangePasswordView', () {
    late FakeAuthRepository repository;
    late SessionEventBus eventBus;
    late SessionViewModel sessionViewModel;
    late AuthViewModel authViewModel;

    setUp(() {
      repository = FakeAuthRepository(
        currentUser: buildTestUser(),
        hasSession: true,
      );

      eventBus = SessionEventBus();

      sessionViewModel = SessionViewModel(
        authRepository: repository,
        sessionEventBus: eventBus,
      );

      sessionViewModel.setAuthenticatedUser(repository.currentUser);

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

    Future<void> buildView(WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SessionViewModel>.value(
              value: sessionViewModel,
            ),
            ChangeNotifierProvider<AuthViewModel>.value(value: authViewModel),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const ChangePasswordView(),
          ),
        ),
      );

      await tester.pump();
    }

    testWidgets('muestra los dos campos y el botón', (
      WidgetTester tester,
    ) async {
      await buildView(tester);

      expect(find.text('Cambiar contraseña'), findsOneWidget);
      expect(find.byKey(const Key('change_password_field')), findsOneWidget);
      expect(
        find.byKey(const Key('change_confirm_password_field')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('change_password_submit_button')),
        findsOneWidget,
      );
    });

    testWidgets('valida campos vacíos', (WidgetTester tester) async {
      await buildView(tester);

      await tester.tap(find.byKey(const Key('change_password_submit_button')));

      await tester.pump();

      expect(find.text('La contraseña es obligatoria.'), findsOneWidget);
      expect(find.text('Confirma la contraseña.'), findsOneWidget);
      expect(repository.changePasswordCalls, 0);
    });

    testWidgets('impide enviar contraseñas diferentes', (
      WidgetTester tester,
    ) async {
      await buildView(tester);

      await tester.enterText(
        find.byKey(const Key('change_password_field')),
        'nuevaClave123',
      );

      await tester.enterText(
        find.byKey(const Key('change_confirm_password_field')),
        'otraClave123',
      );

      await tester.tap(find.byKey(const Key('change_password_submit_button')));

      await tester.pump();

      expect(find.text('Las contraseñas no coinciden.'), findsOneWidget);
      expect(repository.changePasswordCalls, 0);
    });

    testWidgets('envía una contraseña válida', (WidgetTester tester) async {
      await buildView(tester);

      await tester.enterText(
        find.byKey(const Key('change_password_field')),
        'nuevaClave123',
      );

      await tester.enterText(
        find.byKey(const Key('change_confirm_password_field')),
        'nuevaClave123',
      );

      await tester.tap(find.byKey(const Key('change_password_submit_button')));

      await tester.pumpAndSettle();

      expect(repository.changePasswordCalls, 1);
      expect(repository.lastChangePasswordRequest?.password, 'nuevaClave123');
      expect(find.text('Clave actualizada.'), findsOneWidget);
    });
  });
}
