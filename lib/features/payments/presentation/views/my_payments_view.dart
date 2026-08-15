import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ocupa2/app/router/app_routes.dart';
import 'package:ocupa2/app/theme/app_colors.dart';
import 'package:ocupa2/app/theme/app_typography.dart';
import 'package:provider/provider.dart';

import '../viewmodels/my_payments_status.dart';
import '../viewmodels/my_payments_view_model.dart';
import '../widgets/payment_card.dart';
import '../../data/models/payment.dart';
import 'payment_detail_view.dart';

class MyPaymentsView extends StatefulWidget {
  const MyPaymentsView({super.key});

  @override
  State<MyPaymentsView> createState() => _MyPaymentsViewState();
}

class _MyPaymentsViewState extends State<MyPaymentsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MyPaymentsViewModel>().loadMyPayments();
    });
  }

  void _openDetail(BuildContext context, Payment payment) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => PaymentDetailView(payment: payment),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final MyPaymentsViewModel viewModel = context.watch<MyPaymentsViewModel>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      bottomNavigationBar: const _PaymentsBottomNav(),
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
                      'Mis pagos',
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
              child: RefreshIndicator(
                onRefresh: () =>
                    context.read<MyPaymentsViewModel>().loadMyPayments(),
                child: _buildBody(context, viewModel),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, MyPaymentsViewModel viewModel) {
    switch (viewModel.status) {
      case MyPaymentsStatus.idle:
      case MyPaymentsStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case MyPaymentsStatus.error:
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: <Widget>[
            const SizedBox(height: 40),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  viewModel.errorMessage ?? 'Error al cargar pagos',
                  style: const TextStyle(color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        );
      case MyPaymentsStatus.loaded:
        if (viewModel.payments.isEmpty) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const <Widget>[
              SizedBox(height: 40),
              Center(
                child: Text(
                  'Aún no tienes pagos',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          );
        }
        return ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          itemCount: viewModel.payments.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (BuildContext context, int index) {
            final payment = viewModel.payments[index];
            return PaymentCard(
              payment: payment,
              onTap: () => _openDetail(context, payment),
            );
          },
        );
    }
  }
}

class _PaymentsBottomNav extends StatelessWidget {
  const _PaymentsBottomNav();

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
              _NavItem(
                icon: Icons.history,
                label: 'Actividad',
                onTap: () => context.pushNamed(AppRouteNames.activityHub),
              ),
              _NavItem(
                icon: Icons.person_outline,
                label: 'Perfil',
                selected: true,
                onTap: () => context.goNamed(AppRouteNames.profile),
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
