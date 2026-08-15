import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ocupa2/app/router/app_routes.dart';
import 'package:ocupa2/app/theme/app_colors.dart';
import 'package:ocupa2/app/theme/app_typography.dart';
import 'package:ocupa2/core/utils/app_url_launcher.dart';
import 'package:ocupa2/features/about/data/team_members.dart';
import 'package:ocupa2/features/about/presentation/widgets/team_member_card.dart';

class AboutView extends StatelessWidget {
  const AboutView({this.onLaunchUri = launchAppUri, super.key});

  final AppUriLauncher onLaunchUri;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      bottomNavigationBar: const _AboutBottomNav(),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Row(
                children: <Widget>[
                  Material(
                    color: AppColors.surface,
                    shape: const CircleBorder(
                      side: BorderSide(color: AppColors.border),
                    ),
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      customBorder: const CircleBorder(),
                      child: const SizedBox(
                        width: 36,
                        height: 36,
                        child: Icon(
                          Icons.chevron_left,
                          size: 16,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Acerca de Ocupa2',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 18,
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Ocupa2',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          children: <Widget>[
                            SizedBox(
                              width: 64,
                              height: 64,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Color(0x142563EB),
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(16),
                                  ),
                                ),
                                child: Icon(
                                  Icons.work_outline,
                                  size: 36,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Ocupa2',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.text,
                                fontSize: 24,
                                fontWeight: AppTypography.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Versión 1.0.0',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.text,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Nuestra misión es conectar el talento técnico '
                              'dominicano con hogares y empresas locales que '
                              'necesitan soluciones rápidas, confiables y seguras.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.text,
                                fontSize: 13,
                                fontWeight: AppTypography.regular,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Equipo de desarrollo',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 16,
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...TeamMembers.all.map(
                      (member) => TeamMemberCard(
                        member: member,
                        onLaunchUri: onLaunchUri,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutBottomNav extends StatelessWidget {
  const _AboutBottomNav();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              _NavItem(
                icon: Icons.home_outlined,
                label: 'Inicio',
                onTap: () => _goNamed(context, AppRouteNames.home),
              ),
              _NavItem(
                icon: Icons.search,
                label: 'Explorar',
                onTap: () =>
                    _pushNamed(context, AppRouteNames.jobSearchExplore),
              ),
              _NavItem(
                icon: Icons.add,
                label: 'Publicar',
                prominent: true,
                onTap: () =>
                    _pushNamed(context, AppRouteNames.jobPostingCreate),
              ),
              _NavItem(
                icon: Icons.history,
                label: 'Actividad',
                onTap: () => _pushNamed(context, AppRouteNames.activityHub),
              ),
              _NavItem(
                icon: Icons.person_outline,
                label: 'Perfil',
                selected: true,
                onTap: () => _goNamed(context, AppRouteNames.profile),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _goNamed(BuildContext context, String name) {
    GoRouter.maybeOf(context)?.goNamed(name);
  }

  void _pushNamed(BuildContext context, String name) {
    GoRouter.maybeOf(context)?.pushNamed(name);
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    this.selected = false,
    this.prominent = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool prominent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = selected ? AppColors.primary : AppColors.text;

    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 64,
        height: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (prominent)
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(icon, size: 24, color: AppColors.onPrimary),
              )
            else
              Icon(icon, size: 22, color: color),
            if (!prominent) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w600 : AppTypography.medium,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
