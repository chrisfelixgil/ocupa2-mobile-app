import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ocupa2/app/router/app_routes.dart';
import 'package:ocupa2/app/router/route_paths.dart';
import 'package:ocupa2/features/about/presentation/views/about_view.dart';

List<RouteBase> aboutRoutes() {
  return <RouteBase>[
    GoRoute(
      path: RoutePaths.about,
      name: AppRouteNames.about,
      builder: (BuildContext context, GoRouterState state) {
        return const AboutView();
      },
    ),
  ];
}
