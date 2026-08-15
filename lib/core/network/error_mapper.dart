import 'dart:io';

import 'package:dio/dio.dart';
import 'package:ocupa2/core/network/api_exception.dart';

abstract final class ErrorMapper {
  static ApiException fromDioException(DioException exception) {
    final DioExceptionType type = exception.type;

    if (type == DioExceptionType.cancel) {
      return ApiException(
        type: ApiExceptionType.cancelled,
        message: 'La solicitud fue cancelada.',
        originalError: exception,
      );
    }

    if (type == DioExceptionType.connectionTimeout ||
        type == DioExceptionType.sendTimeout ||
        type == DioExceptionType.receiveTimeout ||
        type == DioExceptionType.transformTimeout) {
      return ApiException(
        type: ApiExceptionType.timeout,
        message:
            'La operación tardó demasiado. Verifica tu conexión e inténtalo de nuevo.',
        originalError: exception,
      );
    }

    if (type == DioExceptionType.badCertificate) {
      return ApiException(
        type: ApiExceptionType.badCertificate,
        message:
            'No fue posible verificar la seguridad de la conexión con el servidor.',
        originalError: exception,
      );
    }

    if (type == DioExceptionType.connectionError ||
        exception.error is SocketException) {
      return ApiException(
        type: ApiExceptionType.connection,
        message:
            'No fue posible conectar con el servidor. Verifica tu conexión a internet.',
        originalError: exception,
      );
    }

    if (type == DioExceptionType.badResponse) {
      return _fromBadResponse(exception);
    }

    return ApiException(
      type: ApiExceptionType.unknown,
      message: 'Ocurrió un error inesperado. Inténtalo nuevamente.',
      originalError: exception,
    );
  }

  static ApiException _fromBadResponse(DioException exception) {
    final int? statusCode = exception.response?.statusCode;
    final Object? responseData = exception.response?.data;

    if (statusCode != null && statusCode >= 500) {
      return ApiException(
        type: ApiExceptionType.server,
        statusCode: statusCode,
        message:
            'El servidor presentó un problema. Inténtalo nuevamente más tarde.',
        originalError: exception,
      );
    }

    final String? serverMessage = _humanizeServerMessage(
      exception.requestOptions.path,
      _extractServerMessage(responseData),
    );

    switch (statusCode) {
      case 400:
        return ApiException(
          type: ApiExceptionType.badRequest,
          statusCode: statusCode,
          message: serverMessage ?? 'La solicitud contiene datos incorrectos.',
          originalError: exception,
        );

      case 401:
        return ApiException(
          type: ApiExceptionType.unauthorized,
          statusCode: statusCode,
          message:
              serverMessage ??
              'No fue posible autenticar la solicitud. '
                  'Verifica tus credenciales o inicia sesión nuevamente.',
          originalError: exception,
        );

      case 403:
        return ApiException(
          type: ApiExceptionType.forbidden,
          statusCode: statusCode,
          message:
              serverMessage ??
              'No tienes permiso para realizar esta operación.',
          originalError: exception,
        );

      case 404:
        return ApiException(
          type: ApiExceptionType.notFound,
          statusCode: statusCode,
          message: serverMessage ?? 'No se encontró el recurso solicitado.',
          originalError: exception,
        );

      case 409:
        return ApiException(
          type: ApiExceptionType.conflict,
          statusCode: statusCode,
          message:
              serverMessage ??
              'La operación entra en conflicto con información existente.',
          originalError: exception,
        );

      case 402:
        return ApiException(
          type: ApiExceptionType.paymentRequired,
          statusCode: statusCode,
          message: _paymentRequiredMessage(
            exception.requestOptions.path,
            serverMessage,
          ),
          originalError: exception,
        );

      case 422:
        return ApiException(
          type: ApiExceptionType.validation,
          statusCode: statusCode,
          message:
              serverMessage ??
              'Revisa los datos ingresados antes de continuar.',
          originalError: exception,
        );

      default:
        return ApiException(
          type: ApiExceptionType.unknown,
          statusCode: statusCode,
          message:
              serverMessage ??
              'No fue posible completar la solicitud. Inténtalo nuevamente.',
          originalError: exception,
        );
    }
  }

  static String _paymentRequiredMessage(String path, String? serverMessage) {
    final String normalizedPath = path.toLowerCase();
    final bool fromOffer = normalizedPath.contains('offer');
    final String fallback = fromOffer
        ? 'No se pudo publicar la oferta. El pago no es válido o es requerido.'
        : 'El pago fue rechazado. Verifica los datos de la tarjeta '
              'o utiliza otra tarjeta.';

    if (serverMessage == null) {
      return fallback;
    }

    final String lowered = serverMessage.toLowerCase();
    if (lowered.contains('error 402') ||
        lowered.contains('inesperado') ||
        lowered.contains('unexpected')) {
      return fallback;
    }

    return serverMessage;
  }

  static String? _humanizeServerMessage(String path, String? serverMessage) {
    if (serverMessage == null) {
      return null;
    }

    final String loweredPath = path.toLowerCase();
    final String loweredMessage = serverMessage.toLowerCase();
    final bool isApplyRequest = loweredPath.contains('/apply');
    final bool mentionsCommentField =
        loweredMessage.contains("'comment'") ||
        loweredMessage.contains('"comment"') ||
        loweredMessage.contains('campo comment') ||
        loweredMessage.contains('field comment');

    if (isApplyRequest && mentionsCommentField) {
      return 'Explica con más detalle por qué eres apto para este puesto. '
          'Escribe al menos unas oraciones sobre tu experiencia o habilidades.';
    }

    return serverMessage;
  }

  static String? _extractServerMessage(Object? responseData) {
    if (responseData is String) {
      return _normalizeMessage(responseData);
    }

    if (responseData is! Map) {
      return null;
    }

    final Map<String, dynamic> json = responseData.map((
      Object? key,
      Object? value,
    ) {
      return MapEntry<String, dynamic>(key.toString(), value);
    });

    final String? error = _normalizeMessage(json['error']);

    if (error != null) {
      return error;
    }

    final String? message = _normalizeMessage(json['message']);

    if (message != null) {
      return message;
    }

    final Object? data = json['data'];

    if (data is Map) {
      final Map<String, dynamic> dataJson = data.map((
        Object? key,
        Object? value,
      ) {
        return MapEntry<String, dynamic>(key.toString(), value);
      });

      final String? nestedMessage = _normalizeMessage(dataJson['message']);

      if (nestedMessage != null) {
        return nestedMessage;
      }
    }

    return _extractValidationMessage(json['errors']);
  }

  static String? _extractValidationMessage(Object? errors) {
    if (errors is String) {
      return _normalizeMessage(errors);
    }

    if (errors is List) {
      for (final Object? error in errors) {
        final String? message = _normalizeMessage(error);

        if (message != null) {
          return message;
        }
      }
    }

    if (errors is Map) {
      for (final Object? value in errors.values) {
        final String? message = _extractValidationMessage(value);

        if (message != null) {
          return message;
        }
      }
    }

    return null;
  }

  static String? _normalizeMessage(Object? value) {
    if (value is! String) {
      return null;
    }

    final String normalizedValue = value.trim();

    if (normalizedValue.isEmpty) {
      return null;
    }

    return normalizedValue;
  }
}
