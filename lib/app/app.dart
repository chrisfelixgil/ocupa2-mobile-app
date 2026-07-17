import 'package:flutter/material.dart';
import 'package:ocupa2/app/router/app_router.dart';
import 'package:ocupa2/app/theme/app_theme.dart';

class Ocupa2App extends StatelessWidget {
  const Ocupa2App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Ocupa2',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
