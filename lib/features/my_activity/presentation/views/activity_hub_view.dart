import 'package:flutter/material.dart';
import 'package:ocupa2/core/widgets/app_bottom_nav.dart';
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
      bottomNavigationBar: const AppBottomNav(
        selected: AppBottomNavTab.activity,
      ),
    );
  }
}
