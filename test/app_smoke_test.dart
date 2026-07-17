import 'package:flutter_test/flutter_test.dart';
import 'package:ocupa2/app/app.dart';
import 'package:ocupa2/app/di/app_providers.dart';

void main() {
  testWidgets('muestra la pantalla de configuración inicial', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AppProviders(child: Ocupa2App()));

    await tester.pumpAndSettle();

    expect(find.text('Ocupa2'), findsOneWidget);
    expect(find.text('Configuración inicial completada'), findsOneWidget);
  });
}
