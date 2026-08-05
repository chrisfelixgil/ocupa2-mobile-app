import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ocupa2/app/theme/app_theme.dart';
import 'package:provider/provider.dart';

class Ocupa2App extends StatelessWidget {
  const Ocupa2App({super.key});

  @override
  Widget build(BuildContext context) {
    final GoRouter router = context.read<GoRouter>();

    return MaterialApp.router(
      title: 'Ocupa2',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
