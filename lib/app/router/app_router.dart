import 'package:go_router/go_router.dart';
import 'package:ocupa2/app/router/app_routes.dart';
import 'package:ocupa2/app/router/route_paths.dart';
import 'package:ocupa2/features/auth/presentation/views/splash_view.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: RoutePaths.splash,
  routes: <RouteBase>[
    GoRoute(
      path: RoutePaths.splash,
      name: AppRouteNames.splash,
      builder: (context, state) => const SplashView(),
    ),
  ],
);
