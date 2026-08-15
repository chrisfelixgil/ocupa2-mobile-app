import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ocupa2/app/router/route_paths.dart';
import 'package:ocupa2/app/theme/app_colors.dart';
import 'package:ocupa2/app/theme/app_spacing.dart';
import 'package:ocupa2/features/my_activity/data/models/contract.dart';
import 'package:ocupa2/features/my_activity/presentation/viewmodels/contracts_status.dart';
import 'package:ocupa2/features/my_activity/presentation/viewmodels/contracts_view_model.dart';
import 'package:provider/provider.dart';

class MyContractsView extends StatefulWidget {
  const MyContractsView({super.key});

  @override
  State<MyContractsView> createState() => _MyContractsViewState();
}

class _MyContractsViewState extends State<MyContractsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ContractsViewModel>().load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ContractsViewModel viewModel = context.watch<ContractsViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis contratos'),
      ),
      body: switch (viewModel.status) {
        ContractsStatus.idle || ContractsStatus.loading =>
          const Center(child: CircularProgressIndicator()),
        ContractsStatus.error => _ErrorState(
            message: viewModel.errorMessage,
            onRetry: viewModel.load,
          ),
        ContractsStatus.success => Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.xs,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: <Widget>[
                      ChoiceChip(
                        selected: viewModel.selectedFilter == 'all',
                        label: const Text('Todos'),
                        onSelected: (bool selected) {
                          if (selected) {
                            viewModel.setFilter('all');
                          }
                        },
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      ChoiceChip(
                        selected: viewModel.selectedFilter == 'active',
                        label: const Text('Activos'),
                        onSelected: (bool selected) {
                          if (selected) {
                            viewModel.setFilter('active');
                          }
                        },
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      ChoiceChip(
                        selected: viewModel.selectedFilter == 'pending',
                        label: const Text('Pendientes'),
                        onSelected: (bool selected) {
                          if (selected) {
                            viewModel.setFilter('pending');
                          }
                        },
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      ChoiceChip(
                        selected: viewModel.selectedFilter == 'closed',
                        label: const Text('Rechazados / Cancelados'),
                        onSelected: (bool selected) {
                          if (selected) {
                            viewModel.setFilter('closed');
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: _ContractsList(
                  contracts: viewModel.contracts,
                  selectedFilter: viewModel.selectedFilter,
                ),
              ),
            ],
          ),
      },
    );
  }
}

class _ContractsList extends StatelessWidget {
  const _ContractsList({
    required this.contracts,
    required this.selectedFilter,
  });

  final List<Contract> contracts;
  final String selectedFilter;

  @override
  Widget build(BuildContext context) {
    if (contracts.isEmpty) {
      return _EmptyState(selectedFilter: selectedFilter);
    }

    return RefreshIndicator(
      onRefresh: context.read<ContractsViewModel>().load,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: contracts.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (BuildContext context, int index) {
          final Contract contract = contracts[index];
          return _ContractCard(contract: contract);
        },
      ),
    );
  }
}

class _ContractCard extends StatelessWidget {
  const _ContractCard({required this.contract});

  final Contract contract;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          await context.push(RoutePaths.contractDetail(contract.id));
          if (context.mounted) {
            await context.read<ContractsViewModel>().refresh();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          contract.displayTitle,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        if (contract.otherParty != null)
                          Text(
                            contract.isContratante
                                ? 'Contratado: ${contract.otherParty?.nombre ?? 'Sin información'}'
                                : 'Contratante: ${contract.otherParty?.nombre ?? 'Sin información'}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                      ],
                    ),
                  ),
                  _StatusChip(
                    status: contract.status,
                    label: contract.displayStatusLabel,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: <Widget>[
                  _RoleBadge(isContratante: contract.isContratante),
                  const Spacer(),
                  if (contract.salary != null)
                    Text(
                      '${contract.currency ?? 'DOP'} ${contract.salary}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.navy,
                      ),
                    ),
                  const SizedBox(width: AppSpacing.xs),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.grey,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.isContratante});

  final bool isContratante;

  @override
  Widget build(BuildContext context) {
    final Color color = isContratante ? AppColors.navy : AppColors.terracotta;
    final IconData icon =
        isContratante ? Icons.business_center_outlined : Icons.person_outline;
    final String label = isContratante ? 'Soy contratante' : 'Soy contratado';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs + 2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.label});

  final String status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final (Color bgColor, Color fgColor, IconData icon) =
        switch (Contract.normalizeStatus(status)) {
      'active' => (
          AppColors.successSurface,
          AppColors.success,
          Icons.check_circle_outline_rounded
        ),
      'pending' => (
          const Color(0xFFFFF8E1),
          const Color(0xFFF57F17),
          Icons.schedule_rounded
        ),
      'rejected' => (
          AppColors.errorSurface,
          AppColors.error,
          Icons.highlight_off_rounded
        ),
      'cancelled' => (
          const Color(0xFFEEEEEE),
          Colors.grey.shade700,
          Icons.cancel_outlined
        ),
      _ => (
          const Color(0xFFEEEEEE),
          Colors.grey.shade700,
          Icons.cancel_outlined
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: fgColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: fgColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.selectedFilter});

  final String selectedFilter;

  @override
  Widget build(BuildContext context) {
    final String message = switch (selectedFilter) {
      'active' => 'No tienes contratos activos.',
      'pending' => 'No tienes contratos pendientes.',
      'closed' => 'No tienes contratos rechazados o cancelados.',
      _ => 'No tienes contratos en esta sección.',
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.gavel_outlined,
              size: 64,
              color: AppColors.terracotta,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Los contratos se generan automáticamente al seleccionar un ganador en una oferta.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message ?? 'No fue posible cargar tus contratos.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
