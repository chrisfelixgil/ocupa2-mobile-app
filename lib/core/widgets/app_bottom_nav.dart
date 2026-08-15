import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ocupa2/app/router/app_routes.dart';
import 'package:ocupa2/app/theme/app_colors.dart';
import 'package:ocupa2/app/theme/app_typography.dart';

enum AppBottomNavTab { home, explore, publish, activity, profile }

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.selected});

  final AppBottomNavTab selected;

  static const double height = 64;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: height,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              _NavItem(
                icon: Icons.home_outlined,
                label: 'Inicio',
                selected: selected == AppBottomNavTab.home,
                onTap: () => _open(context, AppBottomNavTab.home),
              ),
              _NavItem(
                icon: Icons.search,
                label: 'Explorar',
                selected: selected == AppBottomNavTab.explore,
                onTap: () => _open(context, AppBottomNavTab.explore),
              ),
              _NavItem(
                icon: Icons.add,
                label: 'Publicar',
                selected: selected == AppBottomNavTab.publish,
                prominent: true,
                onTap: () => _open(context, AppBottomNavTab.publish),
              ),
              _NavItem(
                icon: Icons.history,
                label: 'Actividad',
                selected: selected == AppBottomNavTab.activity,
                onTap: () => _open(context, AppBottomNavTab.activity),
              ),
              _NavItem(
                icon: Icons.person_outline,
                label: 'Perfil',
                selected: selected == AppBottomNavTab.profile,
                onTap: () => _open(context, AppBottomNavTab.profile),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context, AppBottomNavTab tab) {
    if (tab == selected) {
      return;
    }

    final GoRouter? router = GoRouter.maybeOf(context);
    if (router == null) {
      return;
    }

    switch (tab) {
      case AppBottomNavTab.home:
        router.goNamed(AppRouteNames.home);
      case AppBottomNavTab.explore:
        router.goNamed(AppRouteNames.jobSearchExplore);
      case AppBottomNavTab.publish:
        router.goNamed(AppRouteNames.jobPostingCreate);
      case AppBottomNavTab.activity:
        router.goNamed(AppRouteNames.activityHub);
      case AppBottomNavTab.profile:
        router.goNamed(AppRouteNames.profile);
    }
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
        height: AppBottomNav.height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (prominent)
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 24, color: AppColors.primary),
              )
            else
              Icon(icon, size: 22, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.clip,
              softWrap: false,
              style: TextStyle(
                color: color,
                fontSize: 11,
                height: 1.1,
                fontWeight: selected
                    ? AppTypography.medium
                    : AppTypography.regular,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
