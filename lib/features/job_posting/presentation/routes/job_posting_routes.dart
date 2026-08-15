import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ocupa2/app/router/app_routes.dart';
import 'package:ocupa2/app/router/route_paths.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/job_posting_repository.dart';

import '../viewmodels/create_offer_view_model.dart';

import '../views/create_offer_view.dart';

class JobPostingRoutes {
  static const myOffersPath = '/my-offers';
  static const createPath = '/create';
  static const detailPath = '/job-posting/offers/:offerId';

  static List<RouteBase> get routes => [
        // La lista Figma vive en Actividad → Mis ofertas.
        GoRoute(
          path: myOffersPath,
          name: AppRouteNames.jobPostingMyOffers,
          redirect: (BuildContext context, GoRouterState state) {
            return '${RoutePaths.activityHub}?tab=offers';
          },
        ),

        GoRoute(
          path: createPath,
          name: AppRouteNames.jobPostingCreate,
          builder: (context, state) {
            return ChangeNotifierProvider(
              create: (context) => CreateOfferViewModel(
                jobPostingRepository: context.read<JobPostingRepository>(),
              ),
              child: const CreateOfferView(),
            );
          },
        ),

        // El detalle Figma de una oferta propia es la lista de aplicantes.
        GoRoute(
          path: detailPath,
          name: AppRouteNames.jobPostingOfferDetail,
          redirect: (BuildContext context, GoRouterState state) {
            final String? offerId = state.pathParameters['offerId']?.trim();
            if (offerId == null || offerId.isEmpty) {
              return '${RoutePaths.activityHub}?tab=offers';
            }
            return '/my-activity/offers/$offerId/applicants';
          },
        ),
      ];
}
