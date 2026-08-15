enum ApiExceptionType {
  badRequest,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  validation,
  paymentRequired,
  server,
  connection,
  timeout,
  cancelled,
  badCertificate,
  storage,
  responseFormat,
  unknown,
}

class ApiException implements Exception {
  const ApiException({
    required this.type,
    required this.message,
    this.statusCode,
    this.originalError,
  });

  final ApiExceptionType type;
  final String message;
  final int? statusCode;
  final Object? originalError;

  bool get isUnauthorized {
    return type == ApiExceptionType.unauthorized;
  }

  bool get isConnectionProblem {
    return type == ApiExceptionType.connection ||
        type == ApiExceptionType.timeout;
  }

  bool get isStorageProblem {
    return type == ApiExceptionType.storage;
  }

  @override
  String toString() {
    return 'ApiException('
        'type: $type, '
        'statusCode: $statusCode, '
        'message: $message'
        ')';
  }
}
