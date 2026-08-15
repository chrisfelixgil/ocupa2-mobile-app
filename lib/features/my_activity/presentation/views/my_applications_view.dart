import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ocupa2/app/router/app_routes.dart';
import 'package:ocupa2/app/theme/app_colors.dart';
import 'package:ocupa2/app/theme/app_spacing.dart';
import 'package:ocupa2/app/theme/app_typography.dart';
import 'package:ocupa2/features/my_activity/data/models/application.dart';
import 'package:ocupa2/features/my_activity/presentation/viewmodels/applications_status.dart';
import 'package:ocupa2/features/my_activity/presentation/viewmodels/applications_view_model.dart';
import 'package:ocupa2/features/my_activity/presentation/widgets/my_application_card.dart';
import 'package:provider/provider.dart';

class MyApplicationsView extends StatefulWidget {
  const MyApplicationsView({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<MyApplicationsView> createState() => _MyApplicationsViewState();
}

class _MyApplicationsViewState extends State<MyApplicationsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ApplicationsViewModel>().load();
      }
    });
  }

  void _openApplication(Application application) {
    context.pushNamed(
      AppRouteNames.myApplicationDetail,
      pathParameters: <String, String>{'id': application.id},
      extra: application,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ApplicationsViewModel viewModel =
        context.watch<ApplicationsViewModel>();

    final Widget body = switch (viewModel.status) {
      ApplicationsStatus.idle || ApplicationsStatus.loading =>
        const Center(child: CircularProgressIndicator()),
      ApplicationsStatus.error => _ErrorState(
          message: viewModel.errorMessage,
          onRetry: viewModel.load,
        ),
      ApplicationsStatus.success => _ApplicationsBody(
          showHeader: !widget.embedded,
          applications: viewModel.visibleApplications,
          filter: viewModel.statusFilter,
          onFilter: viewModel.setStatusFilter,
          onOpen: _openApplication,
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

class _ApplicationsBody extends StatelessWidget {
  const _ApplicationsBody({
    required this.showHeader,
    required this.applications,
    required this.filter,
    required this.onFilter,
    required this.onOpen,
  });

  final bool showHeader;
  final List<Application> applications;
  final String filter;
  final ValueChanged<String> onFilter;
  final ValueChanged<Application> onOpen;

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
                  'Mis aplicaciones',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 24,
                    fontWeight: AppTypography.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Seguimiento de las ofertas a las que has aplicado',
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
              'Seguimiento de las ofertas a las que has aplicado',
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
                  label: 'Todas',
                  selected: filter == 'all',
                  onTap: () => onFilter('all'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'En revisión',
                  selected: filter == 'applied',
                  onTap: () => onFilter('applied'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Finalistas',
                  selected: filter == 'finalist',
                  onTap: () => onFilter('finalist'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Ganador',
                  selected: filter == 'winner',
                  onTap: () => onFilter('winner'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Descartado',
                  selected: filter == 'discarded',
                  onTap: () => onFilter('discarded'),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: applications.isEmpty
              ? _EmptyState(filtered: filter != 'all')
              : RefreshIndicator(
                  onRefresh: context.read<ApplicationsViewModel>().load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    itemCount: applications.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (BuildContext context, int index) {
                      final Application application = applications[index];
                      return MyApplicationCard(
                        application: application,
                        onTap: () => onOpen(application),
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
  const _EmptyState({this.filtered = false});

  final bool filtered;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(
          filtered
              ? 'No hay aplicaciones en este filtro.'
              : 'Aún no has aplicado a ninguna oferta.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.text, fontSize: 14),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

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
              message ?? 'No fue posible cargar tus aplicaciones.',
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
