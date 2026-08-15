import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ocupa2/app/theme/app_theme.dart';
import 'package:ocupa2/core/session/session_event_bus.dart';
import 'package:ocupa2/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:ocupa2/features/auth/presentation/viewmodels/session_view_model.dart';
import 'package:ocupa2/features/auth/presentation/views/complete_profile_view.dart';
import 'package:provider/provider.dart';

import '../../../helpers/fake_auth_repository.dart';

void main() {
  group('CompleteProfileView', () {
    late FakeAuthRepository repository;
    late SessionEventBus eventBus;
    late SessionViewModel sessionViewModel;
    late AuthViewModel authViewModel;

    setUp(() {
      repository = FakeAuthRepository(
        currentUser: buildTestUser(profileCompleted: false),
        completedProfileUser: buildTestUser(),
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
            home: const CompleteProfileView(),
          ),
        ),
      );

      await tester.pump();
    }

    testWidgets('muestra todos los campos requeridos', (
      WidgetTester tester,
    ) async {
      await buildView(tester);

      expect(find.text('Completa tu perfil'), findsOneWidget);
      expect(
        find.byKey(const Key('complete_profile_first_name_field')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('complete_profile_last_name_field')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('complete_profile_cedula_field')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('complete_profile_gender_field')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('complete_profile_birth_date_field')),
        findsOneWidget,
      );
    });

    testWidgets('valida los datos obligatorios del perfil', (
      WidgetTester tester,
    ) async {
      await buildView(tester);

      await tester.ensureVisible(
        find.byKey(const Key('complete_profile_submit_button')),
      );
      await tester.tap(find.byKey(const Key('complete_profile_submit_button')));
      await tester.pump();

      expect(find.text('La cédula es obligatoria.'), findsOneWidget);
      expect(find.text('El género es obligatorio.'), findsOneWidget);
      expect(
        find.text('La fecha de nacimiento es obligatoria.'),
        findsOneWidget,
      );
      expect(repository.completeProfileCalls, 0);
    });

    testWidgets('envía el perfil y actualiza la sesión', (
      WidgetTester tester,
    ) async {
      await buildView(tester);

      await tester.enterText(
        find.byKey(const Key('complete_profile_cedula_field')),
        '40212345678',
      );

      final FormBuilderState formState = tester.state<FormBuilderState>(
        find.byType(FormBuilder),
      );

      formState.fields['gender']?.didChange('masculino');
      formState.fields['birthDate']?.didChange(DateTime(2004, 5, 17));

      await tester.ensureVisible(
        find.byKey(const Key('complete_profile_submit_button')),
      );
      await tester.tap(find.byKey(const Key('complete_profile_submit_button')));
      await tester.pumpAndSettle();

      expect(repository.completeProfileCalls, 1);
      expect(repository.lastCompleteProfileRequest?.cedula, '40212345678');
      expect(repository.lastCompleteProfileRequest?.gender, 'masculino');
      expect(sessionViewModel.user?.profileCompleted, isTrue);
    });
  });
}
