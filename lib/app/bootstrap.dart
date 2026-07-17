import 'package:flutter/widgets.dart';
import 'package:ocupa2/app/app.dart';
import 'package:ocupa2/app/config/environment.dart';
import 'package:ocupa2/app/di/app_providers.dart';

Future<void> bootstrap() async {
  await Environment.load();

  runApp(const AppProviders(child: Ocupa2App()));
}
