import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ocupa2/app/router/route_paths.dart';
import 'package:ocupa2/app/theme/app_colors.dart';
import 'package:ocupa2/app/theme/app_spacing.dart';
import 'package:ocupa2/app/theme/app_typography.dart';
import 'package:ocupa2/features/my_activity/data/models/contract.dart';
import 'package:ocupa2/features/my_activity/presentation/viewmodels/contracts_status.dart';
import 'package:ocupa2/features/my_activity/presentation/viewmodels/contracts_view_model.dart';
import 'package:ocupa2/features/my_activity/presentation/widgets/contract_list_card.dart';
import 'package:provider/provider.dart';

class MyContractsView extends StatefulWidget {
  const MyContractsView({super.key, this.embedded = false});

  final bool embedded;

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

  Future<void> _openContract(Contract contract) async {
    await context.push(RoutePaths.contractDetail(contract.id));
    if (mounted) {
      await context.read<ContractsViewModel>().refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ContractsViewModel viewModel = context.watch<ContractsViewModel>();

    final Widget body = switch (viewModel.status) {
      ContractsStatus.idle || ContractsStatus.loading =>
        const Center(child: CircularProgressIndicator()),
      ContractsStatus.error => _ErrorState(
          message: viewModel.errorMessage,
          onRetry: viewModel.load,
        ),
      ContractsStatus.success => _ContractsBody(
          showHeader: !widget.embedded,
          contracts: viewModel.contracts,
          filter: viewModel.selectedFilter,
          onFilter: viewModel.setFilter,
          onOpen: _openContract,
        ),
    };

    if (widget.embedded) {
      return body;
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text(''),
      ),
      body: body,
    );
  }
}

class _ContractsBody extends StatelessWidget {
  const _ContractsBody({
    required this.showHeader,
    required this.contracts,
    required this.filter,
    required this.onFilter,
    required this.onOpen,
  });

  final bool showHeader;
  final List<Contract> contracts;
  final String filter;
  final ValueChanged<String> onFilter;
  final Future<void> Function(Contract contract) onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (showHeader)
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Mis contratos',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 24,
                    fontWeight: AppTypography.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Historial de acuerdos y trabajos pactados',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 13,
                    fontWeight: AppTypography.regular,
                  ),
                ),
              ],
            ),
          )
        else
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Text(
              'Historial de acuerdos y trabajos pactados',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 13,
                fontWeight: AppTypography.regular,
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                _FilterChip(
                  label: 'Todos',
                  selected: filter == 'all',
                  onTap: () => onFilter('all'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Pendiente',
                  selected: filter == 'pending',
                  onTap: () => onFilter('pending'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Activo',
                  selected: filter == 'active',
                  onTap: () => onFilter('active'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Rechazado',
                  selected: filter == 'rejected',
                  onTap: () => onFilter('rejected'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Cancelado',
                  selected: filter == 'cancelled',
                  onTap: () => onFilter('cancelled'),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: contracts.isEmpty
              ? _EmptyState(filter: filter)
              : RefreshIndicator(
                  onRefresh: context.read<ContractsViewModel>().load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    itemCount: contracts.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (BuildContext context, int index) {
                      final Contract contract = contracts[index];
                      return ContractListCard(
                        contract: contract,
                        onTap: () => onOpen(contract),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : AppColors.surface,
      shape: StadiumBorder(
        side: selected
            ? BorderSide.none
            : const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.onPrimary : AppColors.text,
              fontSize: 13,
              fontWeight: selected
                  ? FontWeight.w600
                  : AppTypography.regular,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filter});

  final String filter;

  @override
  Widget build(BuildContext context) {
    final String message = switch (filter) {
      'active' => 'No tienes contratos activos.',
      'pending' => 'No tienes contratos pendientes.',
      'rejected' => 'No tienes contratos rechazados.',
      'cancelled' => 'No tienes contratos cancelados.',
      'closed' => 'No tienes contratos rechazados o cancelados.',
      _ => 'Aún no tienes contratos.',
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.text, fontSize: 14),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String? message;
  final Future<void> Function() onRetry;

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
