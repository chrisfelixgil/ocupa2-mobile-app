import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ocupa2/app/theme/app_colors.dart';
import 'package:ocupa2/app/theme/app_spacing.dart';
import 'package:ocupa2/features/auth/presentation/viewmodels/auth_status.dart';
import 'package:ocupa2/features/auth/presentation/viewmodels/session_view_model.dart';
import 'package:provider/provider.dart';

class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    final SessionViewModel session = context.watch<SessionViewModel>();

    final bool hasError = session.status == AuthStatus.error;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      color: AppColors.navy,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.work_outline_rounded,
                      size: 48,
                      color: AppColors.cream,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Ocupa2',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (hasError)
                    const Icon(
                      Icons.cloud_off_rounded,
                      size: 42,
                      color: AppColors.terracotta,
                    )
                  else
                    const SizedBox(
                      width: 38,
                      height: 38,
                      child: CircularProgressIndicator(
                        color: AppColors.terracotta,
                      ),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    hasError
                        ? 'No pudimos verificar tu sesión'
                        : 'Verificando tu sesión',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    hasError
                        ? session.errorMessage ??
                              'Ocurrió un problema inesperado.'
                        : 'Estamos comprobando si ya habías iniciado sesión.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  if (hasError) ...<Widget>[
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton.icon(
                      onPressed: () {
                        unawaited(session.restoreSession());
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
