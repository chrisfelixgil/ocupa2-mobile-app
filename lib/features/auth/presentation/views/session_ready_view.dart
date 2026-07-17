import 'package:flutter/material.dart';
import 'package:ocupa2/app/theme/app_colors.dart';
import 'package:ocupa2/app/theme/app_spacing.dart';
import 'package:ocupa2/features/auth/data/models/user.dart';
import 'package:ocupa2/features/auth/presentation/viewmodels/session_view_model.dart';
import 'package:provider/provider.dart';

class SessionReadyView extends StatelessWidget {
  const SessionReadyView({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = context.watch<SessionViewModel>().user;

    return Scaffold(
      appBar: AppBar(title: const Text('Ocupa2')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                children: <Widget>[
                  const Icon(
                    Icons.verified_user_rounded,
                    size: 76,
                    color: AppColors.terracotta,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Sesión restaurada',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    user?.nombre ?? 'Usuario de Ocupa2',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (user != null) ...<Widget>[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      user.email,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.navy,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'El token guardado fue validado correctamente '
                      'mediante GET /me.',
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: AppColors.cream),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
