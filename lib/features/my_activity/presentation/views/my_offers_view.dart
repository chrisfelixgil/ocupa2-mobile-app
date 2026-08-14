import 'package:flutter/material.dart';
import 'package:ocupa2/app/theme/app_colors.dart';
import 'package:ocupa2/app/theme/app_spacing.dart';
import 'package:ocupa2/features/my_activity/data/models/published_offer.dart';
import 'package:ocupa2/features/my_activity/presentation/viewmodels/my_offers_status.dart';
import 'package:ocupa2/features/my_activity/presentation/viewmodels/my_offers_view_model.dart';
import 'package:ocupa2/features/my_activity/presentation/widgets/published_offer_card.dart';
import 'package:provider/provider.dart';

class MyOffersView extends StatefulWidget {
  const MyOffersView({super.key});

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

  @override
  Widget build(BuildContext context) {
    final MyOffersViewModel viewModel = context.watch<MyOffersViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis ofertas publicadas'),
      ),
      body: switch (viewModel.status) {
        MyOffersStatus.idle || MyOffersStatus.loading =>
          const Center(child: CircularProgressIndicator()),
        MyOffersStatus.error => _ErrorState(
            message: viewModel.errorMessage,
            onRetry: viewModel.load,
          ),
        MyOffersStatus.success => _OffersList(
            offers: viewModel.offers,
            isDeactivating: viewModel.isDeactivating,
            onDelete: _confirmDelete,
          ),
      },
    );
  }
}

class _OffersList extends StatelessWidget {
  const _OffersList({
    required this.offers,
    required this.isDeactivating,
    required this.onDelete,
  });

  final List<PublishedOffer> offers;
  final bool Function(String offerId) isDeactivating;
  final Future<void> Function(String offerId) onDelete;

  @override
  Widget build(BuildContext context) {
    if (offers.isEmpty) {
      return const _EmptyState();
    }

    return RefreshIndicator(
      onRefresh: context.read<MyOffersViewModel>().load,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: offers.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (BuildContext context, int index) {
          final PublishedOffer offer = offers[index];

          return PublishedOfferCard(
            offer: offer,
            isDeactivating: isDeactivating(offer.id),
            onTap: () {},
            onDelete: offer.isActive ? () => onDelete(offer.id) : null,
          );
        },
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.work_outline,
              size: 64,
              color: AppColors.terracotta,
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              'Aún no has publicado ofertas.',
              textAlign: TextAlign.center,
            ),
          ],
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
