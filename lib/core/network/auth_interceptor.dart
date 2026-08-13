import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:ocupa2/core/session/session_event_bus.dart';
import 'package:ocupa2/core/storage/token_storage.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this._tokenStorage,
    required this._sessionEventBus,
  });

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

      // DEBUG: confirma si el token existe en storage en el momento
      // exacto de la request. Quitar una vez resuelto el problema.
      debugPrint(
        '[AuthInterceptor] ${options.method} ${options.path} -> '
        'token=${token == null ? "NULL" : token.isEmpty ? "VACÍO" : "OK (${token.length} chars)"}',
      );

      if (token != null && token.isNotEmpty) {
        options.headers[_authorizationHeader] = 'Bearer $token';
      } else {
        debugPrint(
          '[AuthInterceptor] Enviando "${options.path}" SIN header Authorization.',
        );
      }

      handler.next(options);
    } catch (error, stackTrace) {
      debugPrint('[AuthInterceptor] Error leyendo el token: $error');
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
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final bool requiresAuth = err.requestOptions.extra[requiresAuthKey] == true;

    final bool isUnauthorized = err.response?.statusCode == 401;

    // DEBUG
    debugPrint(
      '[AuthInterceptor] onError: status=${err.response?.statusCode} '
      'requiresAuth=$requiresAuth path=${err.requestOptions.path}',
    );

    if (requiresAuth && isUnauthorized) {
      await _handleUnauthorized();
    }

    handler.next(err);
  }

  Future<void> _handleUnauthorized() async {
    if (_isHandlingUnauthorized) {
      return;
    }

    _isHandlingUnauthorized = true;

    try {
      debugPrint('[AuthInterceptor] Sesión expirada — borrando token y notificando.');
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