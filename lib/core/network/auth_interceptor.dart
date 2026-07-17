import 'package:dio/dio.dart';
import 'package:ocupa2/core/session/session_event_bus.dart';
import 'package:ocupa2/core/storage/token_storage.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required TokenStorage tokenStorage,
    required SessionEventBus sessionEventBus,
  }) : _tokenStorage = tokenStorage,
       _sessionEventBus = sessionEventBus;

  static const String requiresAuthKey = 'requiresAuth';
  static const String _authorizationHeader = 'Authorization';

  final TokenStorage _tokenStorage;
  final SessionEventBus _sessionEventBus;

  bool _isHandlingUnauthorized = false;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final bool requiresAuth = options.extra[requiresAuthKey] == true;

    if (!requiresAuth) {
      options.headers.remove(_authorizationHeader);
      handler.next(options);
      return;
    }

    try {
      final String? token = await _tokenStorage.readToken();

      if (token != null && token.isNotEmpty) {
        options.headers[_authorizationHeader] = 'Bearer $token';
      }

      handler.next(options);
    } catch (error, stackTrace) {
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.unknown,
          error: error,
          stackTrace: stackTrace,
          message: 'No fue posible acceder al almacenamiento seguro.',
        ),
      );
    }
  }

  @override
  Future<void> onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final bool requiresAuth =
        error.requestOptions.extra[requiresAuthKey] == true;

    final bool isUnauthorized = error.response?.statusCode == 401;

    if (requiresAuth && isUnauthorized) {
      await _handleUnauthorized();
    }

    handler.next(error);
  }

  Future<void> _handleUnauthorized() async {
    if (_isHandlingUnauthorized) {
      return;
    }

    _isHandlingUnauthorized = true;

    try {
      try {
        await _tokenStorage.deleteToken();
      } catch (_) {
        // El SessionViewModel volverá a intentar limpiar la sesión
        // cuando reciba el evento en la Fase 5.
      }

      _sessionEventBus.notifySessionExpired();
    } finally {
      _isHandlingUnauthorized = false;
    }
  }
}
