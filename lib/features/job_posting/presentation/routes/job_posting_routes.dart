import 'package:go_router/go_router.dart';
import 'package:ocupa2/app/router/app_routes.dart';
import 'package:ocupa2/features/my_activity/data/repositories/application_repository.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/job_posting_repository.dart';

import '../viewmodels/create_offer_view_model.dart';
import '../viewmodels/my_offers_view_model.dart';
import '../viewmodels/offer_detail_view_model.dart';

import '../views/create_offer_view.dart';
import '../views/job_posting_offer_detail_view.dart';
import '../views/my_offers_view.dart';

class JobPostingRoutes {
  static const myOffersPath = '/my-offers';
  static const createPath = '/create';
  static const detailPath = '/job-posting/offers/:offerId';

  static List<RouteBase> get routes => [
        // ============================================================
        // MIS OFERTAS
        // ============================================================

        GoRoute(
          path: myOffersPath,
          name: AppRouteNames.jobPostingMyOffers,
          builder: (context, state) {
            return ChangeNotifierProvider(
              create: (context) => MyOffersViewModel(
                jobPostingRepository:
                    context.read<JobPostingRepository>(),
              ),
              child: const MyOffersView(),
            );
          },
        ),

        // ============================================================
        // CREAR OFERTA
        // ============================================================

        GoRoute(
          path: createPath,
          name: AppRouteNames.jobPostingCreate,
          builder: (context, state) {
            return ChangeNotifierProvider(
              create: (context) => CreateOfferViewModel(
                jobPostingRepository:
                    context.read<JobPostingRepository>(),
              ),
              child: const CreateOfferView(),
            );
          },
        ),

        // ============================================================
        // DETALLE DE OFERTA
        // ============================================================

        GoRoute(
          path: detailPath,
          name: AppRouteNames.jobPostingOfferDetail,
          builder: (context, state) {
            final offerId =
                state.pathParameters['offerId']!;

            return ChangeNotifierProvider(
              create: (context) =>
                  JobPostingOfferDetailViewModel(
                jobPostingRepository:
                    context.read<JobPostingRepository>(),
                applicationRepository:
                    context.read<ApplicationRepository>(),
              ),
              child: JobPostingOfferDetailView(
                offerId: offerId,
              ),
            );
          },
        ),
      ];
}