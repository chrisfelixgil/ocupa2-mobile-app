import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ocupa2/app/router/app_routes.dart';
import 'package:ocupa2/app/router/route_error_view.dart';
import 'package:ocupa2/app/router/route_paths.dart';
import 'package:ocupa2/features/auth/presentation/viewmodels/auth_status.dart';
import 'package:ocupa2/features/auth/presentation/viewmodels/session_view_model.dart';
import 'package:ocupa2/features/auth/presentation/views/login_view.dart';
import 'package:ocupa2/features/auth/presentation/views/session_ready_view.dart';
import 'package:ocupa2/features/auth/presentation/views/splash_view.dart';

GoRouter createAppRouter(SessionViewModel sessionViewModel) {
  return GoRouter(
    initialLocation: RoutePaths.splash,
    refreshListenable: sessionViewModel,
    redirect: (BuildContext context, GoRouterState state) {
      return _redirectForSession(
        sessionViewModel: sessionViewModel,
        state: state,
      );
    },
    routes: <RouteBase>[
      GoRoute(
        path: RoutePaths.splash,
        name: AppRouteNames.splash,
        builder: (BuildContext context, GoRouterState state) {
          return const SplashView();
        },
      ),
      GoRoute(
        path: RoutePaths.login,
        name: AppRouteNames.login,
        builder: (BuildContext context, GoRouterState state) {
          return const LoginView();
        },
      ),
      GoRoute(
        path: RoutePaths.home,
        name: AppRouteNames.home,
        builder: (BuildContext context, GoRouterState state) {
          return const SessionReadyView();
        },
      ),
    ],
    errorBuilder: (BuildContext context, GoRouterState state) {
      return const RouteErrorView();
    },
  );
}

String? _redirectForSession({
  required SessionViewModel sessionViewModel,
  required GoRouterState state,
}) {
  final String location = state.matchedLocation;

  final bool isSplash = location == RoutePaths.splash;
  final bool isLogin = location == RoutePaths.login;

  switch (sessionViewModel.status) {
    case AuthStatus.checking:
      return isSplash ? null : RoutePaths.splash;

    case AuthStatus.error:
      return isSplash ? null : RoutePaths.splash;

    case AuthStatus.unauthenticated:
      return isLogin ? null : RoutePaths.login;

    case AuthStatus.authenticated:
      if (isSplash || isLogin) {
        return RoutePaths.home;
      }

      return null;
  }
}
