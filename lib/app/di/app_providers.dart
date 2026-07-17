import 'package:flutter/material.dart';
import 'package:ocupa2/app/config/environment.dart';
import 'package:ocupa2/core/network/api_client.dart';
import 'package:ocupa2/core/session/session_event_bus.dart';
import 'package:ocupa2/core/storage/secure_storage_service.dart';
import 'package:ocupa2/core/storage/token_storage.dart';
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
      ],
      child: child,
    );
  }
}
