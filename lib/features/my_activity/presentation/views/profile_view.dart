import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ocupa2/app/router/app_routes.dart';
import 'package:ocupa2/core/widgets/app_bottom_nav.dart';
import 'package:ocupa2/app/theme/app_colors.dart';
import 'package:ocupa2/app/theme/app_typography.dart';
import 'package:ocupa2/features/auth/data/models/user.dart';
import 'package:ocupa2/features/auth/presentation/viewmodels/session_view_model.dart';
import 'package:ocupa2/features/my_activity/presentation/viewmodels/experiences_status.dart';
import 'package:ocupa2/features/my_activity/presentation/viewmodels/experiences_view_model.dart';
import 'package:provider/provider.dart';

const Color _discardRed = Color(0xFFEF4444);

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final ExperiencesViewModel experiences =
          context.read<ExperiencesViewModel>();
      if (experiences.status == ExperiencesStatus.idle) {
        experiences.load();
      }
    });
  }

  Future<void> _requestLogout() async {
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
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Cerrar sesión'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final SessionViewModel session = context.read<SessionViewModel>();
    final bool success = await session.logout();

    if (!success && mounted) {
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
    final User? user = context.watch<SessionViewModel>().user;
    final ExperiencesViewModel experiences =
        context.watch<ExperiencesViewModel>();
    final String name = _displayName(user);
    final String email = (user?.email ?? '').trim();
    final int? experienceCount =
        experiences.status == ExperiencesStatus.success
            ? experiences.experiences.length
            : null;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                children: <Widget>[
                  Column(
                    children: <Widget>[
                      Text(
                        name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 18,
                          fontWeight: AppTypography.bold,
                        ),
                      ),
                      if (email.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 2),
                        Text(
                          email,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 13,
                            fontWeight: AppTypography.regular,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),
                  const _SectionTitle('Mi información'),
                  const SizedBox(height: 6),
                  _MenuCard(
                    children: <Widget>[
                      _MenuRow(
                        icon: Icons.person_outline,
                        label: 'Editar perfil',
                        onTap: () =>
                            context.pushNamed(AppRouteNames.editProfile),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const _SectionTitle('Experiencias'),
                  const SizedBox(height: 6),
                  _MenuCard(
                    children: <Widget>[
                      _MenuRow(
                        icon: Icons.work_outline,
                        label: 'Mis experiencias',
                        badge: experienceCount,
                        onTap: () =>
                            context.pushNamed(AppRouteNames.myExperiences),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const _SectionTitle('Pagos'),
                  const SizedBox(height: 6),
                  _MenuCard(
                    children: <Widget>[
                      _MenuRow(
                        icon: Icons.credit_card,
                        label: 'Mis pagos',
                        onTap: () =>
                            context.pushNamed(AppRouteNames.paymentsMyPayments),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const _SectionTitle('Seguridad'),
                  const SizedBox(height: 6),
                  _MenuCard(
                    children: <Widget>[
                      _MenuRow(
                        icon: Icons.lock_outline,
                        label: 'Cambiar contraseña',
                        onTap: () =>
                            context.pushNamed(AppRouteNames.changePassword),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const _SectionTitle('Información'),
                  const SizedBox(height: 6),
                  _MenuCard(
                    children: <Widget>[
                      _MenuRow(
                        icon: Icons.info_outline,
                        label: 'Acerca de Ocupa2',
                        onTap: () => context.pushNamed(AppRouteNames.about),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const _SectionTitle('Sesión'),
                  const SizedBox(height: 6),
                  _MenuCard(
                    children: <Widget>[
                      _MenuRow(
                        icon: Icons.logout,
                        label: 'Cerrar sesión',
                        destructive: true,
                        onTap: _requestLogout,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const AppBottomNav(selected: AppBottomNavTab.profile),
          ],
        ),
      ),
    );
  }
}

String _displayName(User? user) {
  if (user == null) {
    return 'Mi perfil';
  }
  if (user.nombre.trim().isNotEmpty) {
    return user.nombre.trim();
  }
  final String composed =
      '${user.firstName.trim()} ${user.lastName.trim()}'.trim();
  return composed.isEmpty ? 'Mi perfil' : composed;
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        color: AppColors.text,
        fontSize: 12,
        fontWeight: AppTypography.bold,
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: Column(children: children),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int? badge;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final Color color = destructive ? _discardRed : AppColors.text;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: AppTypography.medium,
                  ),
                ),
              ),
              if (badge != null) ...<Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$badge',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Icon(
                Icons.chevron_right,
                size: 14,
                color: destructive ? _discardRed : AppColors.text,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
