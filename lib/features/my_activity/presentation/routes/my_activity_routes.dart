import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ocupa2/app/router/app_routes.dart';
import 'package:ocupa2/app/router/route_paths.dart';
import 'package:ocupa2/features/my_activity/presentation/viewmodels/contract_detail_view_model.dart';
import 'package:ocupa2/features/my_activity/presentation/views/contract_detail_view.dart';
import 'package:ocupa2/features/my_activity/presentation/views/experiences_view.dart';
import 'package:ocupa2/features/my_activity/presentation/views/my_applications_view.dart';
import 'package:ocupa2/features/my_activity/presentation/views/my_contracts_view.dart';
import 'package:provider/provider.dart';

List<RouteBase> myActivityRoutes() {
  return <RouteBase>[
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
      path: RoutePaths.myContracts,
      name: AppRouteNames.myContracts,
      builder: (_, _) => const MyContractsView(),
    ),
    GoRoute(
      path: RoutePaths.contractDetailPattern,
      name: AppRouteNames.contractDetail,
      builder: (BuildContext context, GoRouterState state) {
        final String contractId = state.pathParameters['id']!;

        return ChangeNotifierProvider<ContractDetailViewModel>(
          create: (BuildContext context) {
            final ContractDetailViewModel viewModel = ContractDetailViewModel(
              contractRepository: context.read(),
              uploadService: context.read(),
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
