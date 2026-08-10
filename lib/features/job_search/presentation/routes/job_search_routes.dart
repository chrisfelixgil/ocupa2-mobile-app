import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ocupa2/app/router/app_routes.dart';
import 'package:ocupa2/app/router/route_paths.dart';
import 'package:ocupa2/features/job_search/presentation/viewmodels/offer_detail_view_model.dart';
import 'package:ocupa2/features/job_search/presentation/views/explore_offers_view.dart';
import 'package:ocupa2/features/job_search/presentation/views/offer_detail_view.dart';
import 'package:ocupa2/features/job_search/presentation/views/offer_map_view.dart';
import 'package:provider/provider.dart';

/// Rutas del módulo job_search: Explorar, Mapa, y Detalle + Aplicar.
///
/// El mapa se registra ANTES que el patrón "/offers/:id" a propósito: si
/// quedara después, go_router podría interpretar "/offers/map" como una
/// oferta con id literal "map".
List<RouteBase> jobSearchRoutes() {
  return <RouteBase>[
    GoRoute(
      path: RoutePaths.jobSearchExplore,
      name: AppRouteNames.jobSearchExplore,
      builder: (BuildContext context, GoRouterState state) {
        return const ExploreOffersView();
      },
    ),
    GoRoute(
      path: RoutePaths.jobSearchMap,
      name: AppRouteNames.jobSearchMap,
      builder: (BuildContext context, GoRouterState state) {
        return const OfferMapView();
      },
    ),
    GoRoute(
      path: RoutePaths.jobSearchOfferDetailPattern,
      name: AppRouteNames.jobSearchOfferDetail,
      builder: (BuildContext context, GoRouterState state) {
        final String offerId = state.pathParameters['id']!;

        return ChangeNotifierProvider<OfferDetailViewModel>(
          create: (BuildContext context) {
            final OfferDetailViewModel viewModel = OfferDetailViewModel(
              jobSearchRepository: context.read(),
              offerId: offerId,
            );

            viewModel.load();

            return viewModel;
          },
          child: const OfferDetailView(),
        );
      },
    ),
  ];
}
