import 'package:dio/dio.dart';
import 'package:ocupa2/core/network/api_exception.dart';
import 'package:ocupa2/core/network/auth_interceptor.dart';
import 'package:ocupa2/core/network/error_mapper.dart';
import 'package:ocupa2/core/network/request_auth.dart';
import 'package:ocupa2/core/session/session_event_bus.dart';
import 'package:ocupa2/core/storage/token_storage.dart';

class ApiClient {
  ApiClient._(this._dio);

  factory ApiClient.create({
    required String baseUrl,
    required TokenStorage tokenStorage,
    required SessionEventBus sessionEventBus,
  }) {
    final Dio dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        transformTimeout: const Duration(seconds: 10),
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
        headers: <String, dynamic>{'Accept': Headers.jsonContentType},
      ),
    );

    dio.interceptors.add(
      AuthInterceptor(
        tokenStorage: tokenStorage,
        sessionEventBus: sessionEventBus,
      ),
    );

    return ApiClient._(dio);
  }

  final Dio _dio;

  Future<Object?> get(
    String path, {
    required RequestAuth auth,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
  }) {
    return _execute(() {
      return _dio.get<Object?>(
        path,
        queryParameters: queryParameters,
        options: _buildOptions(auth: auth, headers: headers),
        cancelToken: cancelToken,
      );
    });
  }

  Future<Object?> post(
    String path, {
    required RequestAuth auth,
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    String? contentType,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) {
    return _execute(() {
      return _dio.post<Object?>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _buildOptions(
          auth: auth,
          headers: headers,
          contentType: contentType,
        ),
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
      );
    });
  }

  Future<Object?> put(
    String path, {
    required RequestAuth auth,
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    String? contentType,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) {
    return _execute(() {
      return _dio.put<Object?>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _buildOptions(
          auth: auth,
          headers: headers,
          contentType: contentType,
        ),
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
      );
    });
  }

  Future<Object?> patch(
    String path, {
    required RequestAuth auth,
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    String? contentType,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) {
    return _execute(() {
      return _dio.patch<Object?>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _buildOptions(
          auth: auth,
          headers: headers,
          contentType: contentType,
        ),
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
      );
    });
  }

  Future<Object?> delete(
    String path, {
    required RequestAuth auth,
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
  }) {
    return _execute(() {
      return _dio.delete<Object?>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _buildOptions(auth: auth, headers: headers),
        cancelToken: cancelToken,
      );
    });
  }

  Options _buildOptions({
    required RequestAuth auth,
    Map<String, dynamic>? headers,
    String? contentType,
  }) {
    return Options(
      headers: headers,
      contentType: contentType,
      extra: <String, dynamic>{
        AuthInterceptor.requiresAuthKey: auth == RequestAuth.protected,
      },
    );
  }

  Future<Object?> _execute(Future<Response<Object?>> Function() request) async {
    try {
      final Response<Object?> response = await request();
      return response.data;
    } on ApiException {
      rethrow;
    } on DioException catch (error) {
      throw ErrorMapper.fromDioException(error);
    } catch (error) {
      throw ApiException(
        type: ApiExceptionType.unknown,
        message: 'Ocurrió un error inesperado. Inténtalo nuevamente.',
        originalError: error,
      );
    }
  }

  void close() {
    _dio.close(force: true);
  }
}
