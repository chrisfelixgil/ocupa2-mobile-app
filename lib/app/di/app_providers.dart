import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ocupa2/app/config/environment.dart';
import 'package:ocupa2/app/router/app_router.dart';
import 'package:ocupa2/core/network/api_client.dart';
import 'package:ocupa2/core/session/session_event_bus.dart';
import 'package:ocupa2/core/storage/secure_storage_service.dart';
import 'package:ocupa2/core/storage/token_storage.dart';
import 'package:ocupa2/features/auth/data/repositories/auth_repository.dart';
import 'package:ocupa2/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:ocupa2/features/auth/data/services/auth_service.dart';
import 'package:ocupa2/features/auth/data/services/auth_service_impl.dart';
import 'package:ocupa2/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:ocupa2/features/auth/presentation/viewmodels/session_view_model.dart';
import 'package:provider/provider.dart';

class AppProviders extends StatelessWidget {
  const AppProviders({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<TokenStorage>(create: (_) => SecureStorageService()),
        Provider<SessionEventBus>(
          create: (_) => SessionEventBus(),
          dispose: (_, SessionEventBus eventBus) {
            eventBus.dispose();
          },
        ),
        Provider<ApiClient>(
          create: (BuildContext context) {
            return ApiClient.create(
              baseUrl: Environment.apiBaseUrl,
              tokenStorage: context.read<TokenStorage>(),
              sessionEventBus: context.read<SessionEventBus>(),
            );
          },
          dispose: (_, ApiClient apiClient) {
            apiClient.close();
          },
        ),
        Provider<AuthService>(
          create: (BuildContext context) {
            return AuthServiceImpl(apiClient: context.read<ApiClient>());
          },
        ),
        Provider<AuthRepository>(
          create: (BuildContext context) {
            return AuthRepositoryImpl(
              authService: context.read<AuthService>(),
              tokenStorage: context.read<TokenStorage>(),
            );
          },
        ),
        ChangeNotifierProvider<SessionViewModel>(
          create: (BuildContext context) {
            final SessionViewModel viewModel = SessionViewModel(
              authRepository: context.read<AuthRepository>(),
              sessionEventBus: context.read<SessionEventBus>(),
            );

            unawaited(viewModel.restoreSession());

            return viewModel;
          },
        ),
        ChangeNotifierProvider<AuthViewModel>(
          create: (BuildContext context) {
            return AuthViewModel(
              authRepository: context.read<AuthRepository>(),
              sessionViewModel: context.read<SessionViewModel>(),
            );
          },
        ),
        Provider<GoRouter>(
          create: (BuildContext context) {
            return createAppRouter(context.read<SessionViewModel>());
          },
          dispose: (_, GoRouter router) {
            router.dispose();
          },
        ),
      ],
      child: child,
    );
  }
}
