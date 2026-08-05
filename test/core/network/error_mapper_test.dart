import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ocupa2/core/network/api_exception.dart';
import 'package:ocupa2/core/network/error_mapper.dart';

void main() {
  group('ErrorMapper', () {
    test('convierte un 401 utilizando el mensaje del API', () {
      final RequestOptions requestOptions = RequestOptions(path: '/job-types');

      final DioException dioException = DioException(
        requestOptions: requestOptions,
        response: Response<Object?>(
          requestOptions: requestOptions,
          statusCode: 401,
          data: <String, dynamic>{
            'ok': false,
            'error': 'Token de autorización ausente.',
          },
        ),
        type: DioExceptionType.badResponse,
      );

      final ApiException result = ErrorMapper.fromDioException(dioException);

      expect(result.type, ApiExceptionType.unauthorized);
      expect(result.statusCode, 401);
      expect(result.message, 'Token de autorización ausente.');
    });

    test('convierte un error 422 con mensaje anidado', () {
      final RequestOptions requestOptions = RequestOptions(
        path: '/auth/register',
      );

      final DioException dioException = DioException(
        requestOptions: requestOptions,
        response: Response<Object?>(
          requestOptions: requestOptions,
          statusCode: 422,
          data: <String, dynamic>{
            'ok': false,
            'data': <String, dynamic>{
              'message': 'El correo no tiene un formato válido.',
            },
          },
        ),
        type: DioExceptionType.badResponse,
      );

      final ApiException result = ErrorMapper.fromDioException(dioException);

      expect(result.type, ApiExceptionType.validation);
      expect(result.statusCode, 422);
      expect(result.message, 'El correo no tiene un formato válido.');
    });

    test('convierte un error de conexión', () {
      final DioException dioException = DioException(
        requestOptions: RequestOptions(path: '/me'),
        type: DioExceptionType.connectionError,
        message: 'Connection failed',
      );

      final ApiException result = ErrorMapper.fromDioException(dioException);

      expect(result.type, ApiExceptionType.connection);
      expect(result.isConnectionProblem, isTrue);
    });

    test('convierte un timeout', () {
      final DioException dioException = DioException(
        requestOptions: RequestOptions(path: '/me'),
        type: DioExceptionType.receiveTimeout,
        message: 'Receive timeout',
      );

      final ApiException result = ErrorMapper.fromDioException(dioException);

      expect(result.type, ApiExceptionType.timeout);
      expect(result.isConnectionProblem, isTrue);
    });

    test('oculta detalles internos de un error 500', () {
      final RequestOptions requestOptions = RequestOptions(path: '/me');

      final DioException dioException = DioException(
        requestOptions: requestOptions,
        response: Response<Object?>(
          requestOptions: requestOptions,
          statusCode: 500,
          data: <String, dynamic>{
            'error': 'Database connection string failed.',
          },
        ),
        type: DioExceptionType.badResponse,
      );

      final ApiException result = ErrorMapper.fromDioException(dioException);

      expect(result.type, ApiExceptionType.server);
      expect(result.statusCode, 500);
      expect(result.message, isNot(contains('Database connection string')));
    });
  });
}
