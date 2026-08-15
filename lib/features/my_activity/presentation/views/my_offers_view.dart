import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ocupa2/app/router/app_routes.dart';
import 'package:ocupa2/app/theme/app_colors.dart';
import 'package:ocupa2/app/theme/app_spacing.dart';
import 'package:ocupa2/app/theme/app_typography.dart';
import 'package:ocupa2/features/my_activity/data/models/published_offer.dart';
import 'package:ocupa2/features/my_activity/presentation/viewmodels/my_offers_status.dart';
import 'package:ocupa2/features/my_activity/presentation/viewmodels/my_offers_view_model.dart';
import 'package:ocupa2/features/my_activity/presentation/widgets/published_offer_card.dart';
import 'package:provider/provider.dart';

class MyOffersView extends StatefulWidget {
  const MyOffersView({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<MyOffersView> createState() => _MyOffersViewState();
}

class _MyOffersViewState extends State<MyOffersView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<MyOffersViewModel>().load();
      }
    });
  }

  Future<void> _confirmDelete(String offerId) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar oferta'),
          content: const Text('¿Deseas eliminar esta oferta?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final bool success =
        await context.read<MyOffersViewModel>().delete(offerId);

    if (!mounted || success) {
      return;
    }

    final String? message = context.read<MyOffersViewModel>().errorMessage;
    if (message == null) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _openApplicants(PublishedOffer offer) {
    context.pushNamed(
      AppRouteNames.applicantsList,
      pathParameters: <String, String>{'offerId': offer.id},
      extra: offer.displayTitle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final MyOffersViewModel viewModel = context.watch<MyOffersViewModel>();

    final Widget body = switch (viewModel.status) {
      MyOffersStatus.idle || MyOffersStatus.loading =>
        const Center(child: CircularProgressIndicator()),
      MyOffersStatus.error => _ErrorState(
          message: viewModel.errorMessage,
          onRetry: viewModel.load,
        ),
      MyOffersStatus.success => _OffersBody(
          showHeader: !widget.embedded,
          offers: viewModel.visibleOffers,
          filter: viewModel.statusFilter,
          isDeactivating: viewModel.isDeactivating,
          onFilter: viewModel.setStatusFilter,
          onOpen: _openApplicants,
          onDelete: _confirmDelete,
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

class _OffersBody extends StatelessWidget {
  const _OffersBody({
    required this.showHeader,
    required this.offers,
    required this.filter,
    required this.isDeactivating,
    required this.onFilter,
    required this.onOpen,
    required this.onDelete,
  });

  final bool showHeader;
  final List<PublishedOffer> offers;
  final String filter;
  final bool Function(String offerId) isDeactivating;
  final ValueChanged<String> onFilter;
  final ValueChanged<PublishedOffer> onOpen;
  final Future<void> Function(String offerId) onDelete;

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
                  'Mis publicaciones',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 24,
                    fontWeight: AppTypography.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Administra tus vacantes y encuentra talentos',
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
              'Administra tus vacantes y encuentra talentos',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 13,
                fontWeight: AppTypography.regular,
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: Row(
            children: <Widget>[
              _FilterChip(
                label: 'Todas',
                selected: filter == 'all',
                onTap: () => onFilter('all'),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Activas',
                selected: filter == 'active',
                onTap: () => onFilter('active'),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Finalizadas',
                selected: filter == 'finished',
                onTap: () => onFilter('finished'),
              ),
            ],
          ),
        ),
        Expanded(
          child: offers.isEmpty
              ? const _EmptyState()
              : RefreshIndicator(
                  onRefresh: context.read<MyOffersViewModel>().load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    itemCount: offers.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (BuildContext context, int index) {
                      final PublishedOffer offer = offers[index];
                      return PublishedOfferCard(
                        offer: offer,
                        isDeactivating: isDeactivating(offer.id),
                        onTap: () => onOpen(offer),
                        onDelete: offer.isActive
                            ? () => onDelete(offer.id)
                            : null,
                      );
                    },
                  ),
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: FilledButton.icon(
            onPressed: () {
              context.pushNamed(AppRouteNames.jobPostingCreate);
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Nueva publicación'),
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
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Text(
          'Aún no has publicado ofertas.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.text, fontSize: 14),
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
              message ?? 'No fue posible cargar tus ofertas.',
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
