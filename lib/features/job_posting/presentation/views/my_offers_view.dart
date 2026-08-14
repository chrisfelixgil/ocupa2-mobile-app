import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:ocupa2/app/router/app_routes.dart';

import '../viewmodels/my_offers_status.dart';
import '../viewmodels/my_offers_view_model.dart';
import '../widgets/my_offer_card.dart';

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
      context.read<MyOffersViewModel>().loadMyOffers();
    });
  }

  Future<void> _confirmDelete(String offerId) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar oferta'),
        content: const Text('¿Seguro que deseas eliminar esta oferta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final bool success = await context.read<MyOffersViewModel>().delete(offerId);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Oferta eliminada')),
      );
    } else {
      final String? message = context.read<MyOffersViewModel>().errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message ?? 'No fue posible eliminar la oferta')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MyOffersViewModel>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.goNamed(AppRouteNames.home);
          },
        ),
        title: const Text('Mis ofertas'),
      ),
      body: RefreshIndicator(
        onRefresh: () {
          return context.read<MyOffersViewModel>().loadMyOffers();
        },
        child: Builder(
          builder: (_) {
            switch (viewModel.status) {
              case MyOffersStatus.idle:
              case MyOffersStatus.loading:
                return const Center(
                  child: CircularProgressIndicator(),
                );

              case MyOffersStatus.error:
                return ListView(
                  children: [
                    const SizedBox(height: 40),
                    Center(
                      child: Text(
                        viewModel.errorMessage ??
                            'Error al cargar ofertas',
                        style: const TextStyle(
                          color: Colors.red,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                );

              case MyOffersStatus.loaded:
                if (viewModel.offers.isEmpty) {
                  return ListView(
                    children: const [
                      SizedBox(height: 40),
                      Center(
                        child: Text(
                          'Aún no has publicado ofertas',
                        ),
                      ),
                    ],
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: viewModel.offers.length,
                  itemBuilder: (context, index) {
                    final offer = viewModel.offers[index];

                    return MyOfferCard(
                      offer: offer,
                      isDeactivating:
                          viewModel.isDeactivating(offer.id),
                      onTap: () {
                        context.pushNamed(
                          AppRouteNames.jobPostingOfferDetail,
                          pathParameters: {
                            'offerId': offer.id,
                          },
                        );
                      },
                      onDeactivate: () => _confirmDelete(offer.id),
                    );
                  },
                );
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.pushNamed(
            AppRouteNames.jobPostingCreate,
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Publicar'),
      ),
    );
  }
}