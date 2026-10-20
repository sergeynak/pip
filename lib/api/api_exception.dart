enum ApiErrorKind {
  notConfigured,
  invalidRequest,
  network,
  timeout,
  http,
  invalidResponse,
}

/// Сетевая ошибка или неверный ответ сервера; тело заявки здесь не хранится.
class ApiException implements Exception {
  const ApiException({
    required this.kind,
    required this.message,
    this.statusCode,
    this.code,
    this.requestId,
    this.retryAfter,
    this.details = const {},
  });

  final ApiErrorKind kind;
  final String message;
  final int? statusCode;
  final String? code;
  final String? requestId;
  final Duration? retryAfter;
  final Map<String, Object?> details;

  @override
  String toString() =>
      'ApiException(${kind.name}, '
      'statusCode: $statusCode, code: $code): $message';
}
