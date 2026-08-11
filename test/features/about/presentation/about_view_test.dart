import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ocupa2/app/app.dart';
import 'package:ocupa2/app/router/app_router.dart';
import 'package:ocupa2/app/router/route_paths.dart';
import 'package:ocupa2/core/session/session_event_bus.dart';
import 'package:ocupa2/features/about/data/team_members.dart';
import 'package:ocupa2/features/about/presentation/views/about_view.dart';
import 'package:ocupa2/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:ocupa2/features/auth/presentation/viewmodels/session_view_model.dart';
import 'package:provider/provider.dart';

import '../../../helpers/fake_auth_repository.dart';

void main() {
  testWidgets('muestra el equipo con foto, matrícula, teléfono y Telegram', (
    WidgetTester tester,
  ) async {
    final List<Uri> launchedUris = <Uri>[];

    await tester.pumpWidget(
      MaterialApp(
        home: AboutView(
          onLaunchUri: (Uri uri) async {
            launchedUris.add(uri);
            return true;
          },
        ),
      ),
    );

    expect(find.text('Equipo de desarrollo'), findsOneWidget);

    for (final member in TeamMembers.all) {
      expect(find.text(member.name), findsOneWidget);
      expect(find.text('Matrícula: ${member.matricula}'), findsOneWidget);
      expect(find.text(member.phoneDisplay), findsOneWidget);
      expect(find.byKey(Key('call_${member.matricula}')), findsOneWidget);
      expect(find.byKey(Key('telegram_${member.matricula}')), findsOneWidget);
    }

    await tester.tap(
      find.byKey(Key('call_${TeamMembers.all.first.matricula}')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(Key('telegram_${TeamMembers.all.first.matricula}')),
    );
    await tester.pump();

    expect(launchedUris, <Uri>[
      TeamMembers.all.first.phoneUri,
      TeamMembers.all.first.telegramUrl,
    ]);
  });

  testWidgets('permite abrir Acerca de desde la sesión activa', (
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

    await tester.scrollUntilVisible(
      find.byKey(const Key('open_about_button')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('open_about_button')));
    await tester.pumpAndSettle();

    expect(find.text('Equipo de desarrollo'), findsOneWidget);
    expect(router.state.uri.toString(), RoutePaths.about);

    await tester.pumpWidget(const SizedBox.shrink());

    router.dispose();
    authViewModel.dispose();
    sessionViewModel.dispose();
    eventBus.dispose();
  });
}
