import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ocupa2/app/router/app_routes.dart';
import 'package:ocupa2/app/router/route_error_view.dart';
import 'package:ocupa2/app/router/route_paths.dart';
import 'package:ocupa2/features/auth/presentation/viewmodels/auth_status.dart';
import 'package:ocupa2/features/auth/presentation/viewmodels/session_view_model.dart';
import 'package:ocupa2/features/auth/presentation/views/change_password_view.dart';
import 'package:ocupa2/features/auth/presentation/views/complete_profile_view.dart';
import 'package:ocupa2/features/auth/presentation/views/forgot_password_view.dart';
import 'package:ocupa2/features/auth/presentation/views/login_view.dart';
import 'package:ocupa2/features/auth/presentation/views/register_view.dart';
import 'package:dio/dio.dart';
import 'package:ocupa2/features/home/data/repositories/home_repository_impl.dart';
import 'package:ocupa2/features/home/data/services/home_service_impl.dart';
import 'package:ocupa2/features/home/presentation/viewmodels/home_view_model.dart';
import 'package:ocupa2/features/home/presentation/views/home_view.dart';
import 'package:provider/provider.dart';
import 'package:ocupa2/features/about/presentation/routes/about_routes.dart';
import 'package:ocupa2/features/auth/presentation/views/splash_view.dart';
import 'package:ocupa2/features/job_search/presentation/routes/job_search_routes.dart';
import 'package:ocupa2/features/my_activity/presentation/routes/my_activity_routes.dart';
import 'package:ocupa2/features/job_posting/presentation/routes/job_posting_routes.dart';
import 'package:ocupa2/features/payments/presentation/routes/payment_routes.dart';

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
          return LoginView(
            initialEmail: state.uri.queryParameters['email'],
            fromPasswordRecovery:
                state.uri.queryParameters['recovered'] == '1',
          );
        },
      ),

      GoRoute(
        path: RoutePaths.register,
        name: AppRouteNames.register,
        builder: (BuildContext context, GoRouterState state) {
          return const RegisterView();
        },
      ),

      GoRoute(
        path: RoutePaths.forgotPassword,
        name: AppRouteNames.forgotPassword,
        builder: (BuildContext context, GoRouterState state) {
          return const ForgotPasswordView();
        },
      ),

      GoRoute(
        path: RoutePaths.completeProfile,
        name: AppRouteNames.completeProfile,
        builder: (BuildContext context, GoRouterState state) {
          return const CompleteProfileView();
        },
      ),

      GoRoute(
        path: RoutePaths.editProfile,
        name: AppRouteNames.editProfile,
        builder: (BuildContext context, GoRouterState state) {
          return const CompleteProfileView(editing: true);
        },
      ),

      GoRoute(
        path: RoutePaths.home,
        name: AppRouteNames.home,
        builder: (BuildContext context, GoRouterState state) {
          final Dio dio = Dio(
            BaseOptions(
              baseUrl: 'https://ocupa2.ia3x.com/apix',
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
            ),
          );

          final HomeServiceImpl service = HomeServiceImpl(dio);

          final HomeRepositoryImpl repository =
              HomeRepositoryImpl(service);

          return ChangeNotifierProvider<HomeViewModel>(
            create: (_) => HomeViewModel(repository),
            child: const HomeView(),
          );
        },
      ),

      GoRoute(
        path: RoutePaths.changePassword,
        name: AppRouteNames.changePassword,
        builder: (BuildContext context, GoRouterState state) {
          return ChangePasswordView(
            isRequired: sessionViewModel.requiresPasswordChange,
          );
        },
      ),

      ...jobSearchRoutes(),
      ...myActivityRoutes(),
      ...aboutRoutes(),
      ...JobPostingRoutes.routes,
      ...PaymentRoutes.routes,
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

  final bool isPublicAuthRoute =
      location == RoutePaths.login ||
      location == RoutePaths.register ||
      location == RoutePaths.forgotPassword;

  final bool isCompleteProfileRoute =
      location == RoutePaths.completeProfile;

  final bool isChangePasswordRoute =
      location == RoutePaths.changePassword;

  switch (sessionViewModel.status) {
    case AuthStatus.checking:
      return isSplash ? null : RoutePaths.splash;

    case AuthStatus.error:
      return isSplash ? null : RoutePaths.splash;

    case AuthStatus.unauthenticated:
      return isPublicAuthRoute ? null : RoutePaths.login;

    case AuthStatus.authenticated:
      if (sessionViewModel.requiresPasswordChange) {
        return isChangePasswordRoute
            ? null
            : RoutePaths.changePassword;
      }

      final bool profileCompleted =
          sessionViewModel.user?.profileCompleted == true;

      if (!profileCompleted) {
        return isCompleteProfileRoute
            ? null
            : RoutePaths.completeProfile;
      }

      if (isSplash ||
          isPublicAuthRoute ||
          isCompleteProfileRoute) {
        return RoutePaths.home;
      }

      return null;
  }
}