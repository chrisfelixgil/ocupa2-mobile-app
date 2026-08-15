import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ocupa2/app/router/app_routes.dart';
import 'package:ocupa2/app/theme/app_colors.dart';
import 'package:ocupa2/app/theme/app_typography.dart';
import 'package:ocupa2/features/my_activity/presentation/views/my_applications_view.dart';
import 'package:ocupa2/features/my_activity/presentation/views/my_contracts_view.dart';
import 'package:ocupa2/features/my_activity/presentation/views/my_offers_view.dart';

const Color _muted = Color(0xFF64748B);

class ActivityHubView extends StatefulWidget {
  const ActivityHubView({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<ActivityHubView> createState() => _ActivityHubViewState();
}

class _ActivityHubViewState extends State<ActivityHubView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 2),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: <Widget>[
                  const Expanded(
                    child: Text(
                      'Actividad',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 24,
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
            TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: _muted,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: AppTypography.medium,
              ),
              indicator: const UnderlineTabIndicator(
                borderSide: BorderSide(width: 3, color: AppColors.primary),
                borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: AppColors.border,
              tabs: const <Widget>[
                Tab(text: 'Aplicaciones'),
                Tab(text: 'Mis ofertas'),
                Tab(text: 'Contratos'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const <Widget>[
                  MyApplicationsView(embedded: true),
                  MyOffersView(embedded: true),
                  MyContractsView(embedded: true),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const _ActivityBottomNav(),
    );
  }
}

class _ActivityBottomNav extends StatelessWidget {
  const _ActivityBottomNav();

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
                onTap: () => context.goNamed(AppRouteNames.home),
              ),
              _NavItem(
                icon: Icons.search,
                label: 'Explorar',
                onTap: () => context.pushNamed(AppRouteNames.jobSearchExplore),
              ),
              _NavItem(
                icon: Icons.add,
                label: 'Publicar',
                prominent: true,
                onTap: () => context.pushNamed(AppRouteNames.jobPostingCreate),
              ),
              const _NavItem(
                icon: Icons.history,
                label: 'Actividad',
                selected: true,
              ),
              _NavItem(
                icon: Icons.person_outline,
                label: 'Perfil',
                onTap: () => context.pushNamed(AppRouteNames.profile),
              ),
            ],
          ),
        ),
      ),
    );
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
    final Color color = selected ? AppColors.primary : _muted;

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
                  fontWeight: selected
                      ? FontWeight.w600
                      : AppTypography.medium,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
