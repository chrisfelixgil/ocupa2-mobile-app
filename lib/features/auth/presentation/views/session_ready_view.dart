import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ocupa2/app/router/app_routes.dart';
import 'package:ocupa2/app/theme/app_colors.dart';
import 'package:ocupa2/app/theme/app_spacing.dart';
import 'package:ocupa2/features/auth/data/models/user.dart';
import 'package:ocupa2/features/auth/presentation/viewmodels/session_view_model.dart';
import 'package:provider/provider.dart';

class SessionReadyView extends StatelessWidget {
  const SessionReadyView({super.key});

  Future<void> _requestLogout(
    BuildContext context,
    SessionViewModel session,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Cerrar sesión'),
          content: const Text(
            '¿Estás seguro de que deseas cerrar tu sesión '
            'en este dispositivo?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Cerrar sesión'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    final bool success = await session.logout();

    if (!success && context.mounted) {
      final String message =
          session.sessionActionErrorMessage ??
          'No fue posible cerrar la sesión.';

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final SessionViewModel session = context.watch<SessionViewModel>();

    final User? user = session.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Ocupa2')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Icon(
                    Icons.verified_user_rounded,
                    size: 76,
                    color: AppColors.terracotta,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Sesión activa',
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
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.navy,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: <Widget>[
                        const Icon(
                          Icons.security_rounded,
                          color: AppColors.terracotta,
                          size: 36,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Tu sesión fue validada mediante GET /me.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: AppColors.cream),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton.icon(
                    key: const Key('open_change_password_button'),
                    onPressed: session.isLoggingOut
                        ? null
                        : () {
                            context.pushNamed(AppRouteNames.changePassword);
                          },
                    icon: const Icon(Icons.password_rounded),
                    label: const Text('Cambiar contraseña'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // TODO(home): temporal hasta que exista la pantalla de
                  // Inicio (módulo de Kaysha) con navegación por pestañas.
                  OutlinedButton.icon(
                    key: const Key('open_explore_offers_button'),
                    onPressed: () {
                      context.pushNamed(AppRouteNames.jobSearchExplore);
                    },
                    icon: const Icon(Icons.travel_explore_rounded),
                    label: const Text('Explorar ofertas'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    key: const Key('logout_button'),
                    onPressed: session.isLoggingOut
                        ? null
                        : () {
                            _requestLogout(context, session);
                          },
                    icon: session.isLoggingOut
                        ? const SizedBox(
                            width: 19,
                            height: 19,
                            child: CircularProgressIndicator(strokeWidth: 2.3),
                          )
                        : const Icon(Icons.logout_rounded),
                    label: Text(
                      session.isLoggingOut
                          ? 'Cerrando sesión...'
                          : 'Cerrar sesión',
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
