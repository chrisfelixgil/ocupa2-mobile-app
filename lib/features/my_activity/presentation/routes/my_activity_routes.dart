import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ocupa2/app/router/app_routes.dart';
import 'package:ocupa2/app/router/route_paths.dart';
import 'package:ocupa2/features/auth/data/models/user.dart';
import 'package:ocupa2/features/auth/presentation/viewmodels/session_view_model.dart';
import 'package:ocupa2/features/job_posting/data/repositories/job_posting_repository.dart';
import 'package:ocupa2/features/job_posting/presentation/viewmodels/offer_detail_view_model.dart';
import 'package:ocupa2/features/my_activity/data/models/application.dart';
import 'package:ocupa2/features/my_activity/data/models/contract_party.dart';
import 'package:ocupa2/features/my_activity/data/repositories/application_repository.dart';
import 'package:ocupa2/features/my_activity/presentation/viewmodels/contract_detail_view_model.dart';
import 'package:ocupa2/features/my_activity/presentation/views/activity_hub_view.dart';
import 'package:ocupa2/features/my_activity/presentation/views/applicant_detail_view.dart';
import 'package:ocupa2/features/my_activity/presentation/views/applicants_list_view.dart';
import 'package:ocupa2/features/my_activity/presentation/views/contract_detail_view.dart';
import 'package:ocupa2/features/my_activity/presentation/views/experiences_view.dart';
import 'package:ocupa2/features/my_activity/presentation/views/my_application_detail_view.dart';
import 'package:ocupa2/features/my_activity/presentation/views/my_applications_view.dart';
import 'package:ocupa2/features/my_activity/presentation/views/my_contracts_view.dart';
import 'package:ocupa2/features/my_activity/presentation/views/my_offers_view.dart';
import 'package:ocupa2/features/my_activity/presentation/views/profile_view.dart';
import 'package:provider/provider.dart';

ContractParty? _sessionParty(BuildContext context) {
  final User? user = context.read<SessionViewModel>().user;
  if (user == null) {
    return null;
  }

  final String name = user.nombre.trim().isNotEmpty
      ? user.nombre.trim()
      : '${user.firstName} ${user.lastName}'.trim();

  return ContractParty(
    id: user.id,
    nombre: name.isNotEmpty ? name : user.email,
    email: user.email,
  );
}

List<RouteBase> myActivityRoutes() {
  return <RouteBase>[
    GoRoute(
      path: RoutePaths.activityHub,
      name: AppRouteNames.activityHub,
      builder: (_, _) => const ActivityHubView(),
    ),
    GoRoute(
      path: RoutePaths.profile,
      name: AppRouteNames.profile,
      builder: (_, _) => const ProfileView(),
    ),
    GoRoute(
      path: RoutePaths.myExperiences,
      name: AppRouteNames.myExperiences,
      builder: (_, _) => const ExperiencesView(),
    ),
    GoRoute(
      path: RoutePaths.myApplications,
      name: AppRouteNames.myApplications,
      builder: (_, _) => const MyApplicationsView(),
    ),
    GoRoute(
      path: RoutePaths.myApplicationDetailPattern,
      name: AppRouteNames.myApplicationDetail,
      builder: (BuildContext context, GoRouterState state) {
        final String applicationId =
            state.pathParameters['id']?.trim() ?? '';

        if (applicationId.isEmpty) {
          return const Scaffold(
            body: Center(
              child: Text(
                'No se pudo abrir la aplicación porque faltó su identificador.',
              ),
            ),
          );
        }

        final Object? extra = state.extra;
        final Application? initial =
            extra is Application ? extra : null;

        return MyApplicationDetailView(
          applicationId: applicationId,
          initialApplication: initial,
        );
      },
    ),
    GoRoute(
      path: RoutePaths.applicantDetailPattern,
      name: AppRouteNames.applicantDetail,
      builder: (BuildContext context, GoRouterState state) {
        final String offerId = state.pathParameters['offerId']?.trim() ?? '';
        final String applicationId =
            state.pathParameters['applicationId']?.trim() ?? '';

        if (offerId.isEmpty || applicationId.isEmpty) {
          return const Scaffold(
            body: Center(
              child: Text(
                'No se pudo abrir el candidato porque faltó su identificador.',
              ),
            ),
          );
        }

        return ChangeNotifierProvider<JobPostingOfferDetailViewModel>(
          create: (BuildContext context) =>
              _offerApplicantsViewModel(context, offerId),
          child: ApplicantDetailView(
            offerId: offerId,
            applicationId: applicationId,
          ),
        );
      },
    ),
    GoRoute(
      path: RoutePaths.applicantsListPattern,
      name: AppRouteNames.applicantsList,
      builder: (BuildContext context, GoRouterState state) {
        final String offerId = state.pathParameters['offerId']?.trim() ?? '';

        if (offerId.isEmpty) {
          return const Scaffold(
            body: Center(
              child: Text(
                'No se pudo abrir los candidatos porque faltó el identificador de la oferta.',
              ),
            ),
          );
        }

        final Object? extra = state.extra;
        final String? offerTitle = extra is String ? extra : null;

        return ChangeNotifierProvider<JobPostingOfferDetailViewModel>(
          create: (BuildContext context) =>
              _offerApplicantsViewModel(context, offerId),
          child: ApplicantsListView(
            offerId: offerId,
            offerTitle: offerTitle,
          ),
        );
      },
    ),
    GoRoute(
      path: RoutePaths.myOffers,
      name: AppRouteNames.myOffers,
      builder: (_, _) => const MyOffersView(),
    ),
    GoRoute(
      path: RoutePaths.myContracts,
      name: AppRouteNames.myContracts,
      builder: (_, _) => const MyContractsView(),
    ),
    GoRoute(
      path: RoutePaths.contractDetailPattern,
      name: AppRouteNames.contractDetail,
      builder: (BuildContext context, GoRouterState state) {
        final String? contractId = state.pathParameters['id']?.trim();

        if (contractId == null || contractId.isEmpty) {
          return const Scaffold(
            body: Center(
              child: Text('No se pudo abrir el contrato porque faltó su identificador.'),
            ),
          );
        }

        return ChangeNotifierProvider<ContractDetailViewModel>(
          create: (BuildContext context) {
            final ContractDetailViewModel viewModel = ContractDetailViewModel(
              contractRepository: context.read(),
              uploadService: context.read(),
              currentUser: _sessionParty(context),
            );

            viewModel.load(contractId);
            return viewModel;
          },
          child: const ContractDetailView(),
        );
      },
    ),
  ];
}

JobPostingOfferDetailViewModel _offerApplicantsViewModel(
  BuildContext context,
  String offerId,
) {
  final JobPostingOfferDetailViewModel viewModel =
      JobPostingOfferDetailViewModel(
    jobPostingRepository: context.read<JobPostingRepository>(),
    applicationRepository: context.read<ApplicationRepository>(),
  );
  viewModel.load(offerId);
  return viewModel;
}
