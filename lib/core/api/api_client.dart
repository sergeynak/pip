import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_exception.dart';
import 'api_response.dart';

/// Route-agnostic JSON transport. It never retries requests automatically.
///
/// An injected [client] remains owned by its caller. Without injection, call
/// [close] when this client is no longer needed.
class ApiClient {
  ApiClient({required this.config, http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  final ApiConfig config;
  final http.Client _client;
  final bool _ownsClient;

  Future<ApiResponse> get(
    String path, {
    Map<String, String>? queryParameters,
  }) => _request('GET', path, queryParameters: queryParameters);

  /// Reuse the same [idempotencyKey] and body for retries of one submission.
  /// Create a new key for a new submission. The transport never creates keys.
  Future<ApiResponse> post(
    String path, {
    Object? body,
    Map<String, String>? queryParameters,
    String? idempotencyKey,
  }) => _request(
    'POST',
    path,
    body: body,
    queryParameters: queryParameters,
    idempotencyKey: idempotencyKey,
  );

  Future<ApiResponse> _request(
    String method,
    String path, {
    Object? body,
    Map<String, String>? queryParameters,
    String? idempotencyKey,
  }) async {
    final uri = _uri(path, queryParameters);
    final headers = <String, String>{'Accept': 'application/json'};
    if (idempotencyKey != null) {
      if (!RegExp(r'^[A-Za-z0-9_-]{8,128}$').hasMatch(idempotencyKey)) {
        throw const ApiException(
          kind: ApiErrorKind.invalidRequest,
          message:
              'Idempotency key must contain 8–128 letters, digits, '
              'underscores, or hyphens.',
        );
      }
      headers['Idempotency-Key'] = idempotencyKey;
    }
    String? encodedBody;
    if (method == 'POST') {
      headers['Content-Type'] = 'application/json; charset=utf-8';
      try {
        encodedBody = jsonEncode(body);
      } on JsonUnsupportedObjectError {
        throw const ApiException(
          kind: ApiErrorKind.invalidRequest,
          message: 'Request body must be JSON-compatible.',
        );
      }
    }

    final http.Response response;
    try {
      response =
          await (method == 'POST'
                  ? _client.post(uri, headers: headers, body: encodedBody)
                  : _client.get(uri, headers: headers))
              .timeout(config.timeout);
    } on TimeoutException {
      throw const ApiException(
        kind: ApiErrorKind.timeout,
        message: 'The server did not respond in time.',
      );
    } on Exception {
      throw const ApiException(
        kind: ApiErrorKind.network,
        message: 'Could not connect to the server.',
      );
    }
    return _parse(response);
  }

  Uri _uri(String path, Map<String, String>? queryParameters) {
    final base = config.baseUri;
    if (base == null) {
      throw const ApiException(
        kind: ApiErrorKind.notConfigured,
        message: 'API_BASE_URL has not been configured.',
      );
    }
    final route = Uri.tryParse(path);
    if (route == null ||
        route.hasScheme ||
        route.hasAuthority ||
        route.hasQuery ||
        route.hasFragment ||
        route.pathSegments.any((part) => part == '.' || part == '..')) {
      throw const ApiException(
        kind: ApiErrorKind.invalidRequest,
        message: 'Use a relative API path and separate query parameters.',
      );
    }
    return base.replace(
      pathSegments: [
        ...base.pathSegments.where((segment) => segment.isNotEmpty),
        ...route.pathSegments.where((segment) => segment.isNotEmpty),
      ],
      queryParameters: queryParameters?.isEmpty == true
          ? null
          : queryParameters,
    );
  }

  ApiResponse _parse(http.Response response) {
    Object? decoded;
    String? text;
    try {
      text = utf8.decode(response.bodyBytes).trim();
      if (text.isNotEmpty) decoded = jsonDecode(text);
    } on FormatException {
      // HTTP errors must remain HTTP errors, even with a proxy's HTML body.
    }
    final envelope = decoded is Map<String, dynamic> ? decoded : null;
    final meta = envelope?['meta'];
    final requestId =
        meta is Map<String, dynamic> && meta['requestId'] is String
        ? meta['requestId'] as String
        : response.headers['x-request-id'];
    final error = envelope?['error'];
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        error != null) {
      final details = error is Map<String, dynamic> ? error : null;
      final rawErrorDetails = details?['details'];
      final errorDetails = rawErrorDetails is Map<String, dynamic>
          ? Map<String, Object?>.unmodifiable(rawErrorDetails)
          : const <String, Object?>{};
      final retryFromBody = errorDetails['retryAfter'];
      // Browser CORS policies may hide Retry-After, while the same value in
      // the documented JSON body remains available to the web client.
      final retrySeconds =
          int.tryParse(response.headers['retry-after'] ?? '') ??
          (retryFromBody is int ? retryFromBody : null);
      throw ApiException(
        kind: ApiErrorKind.http,
        message: details?['message'] is String
            ? details!['message'] as String
            : 'Server request failed (HTTP ${response.statusCode}).',
        statusCode: response.statusCode,
        code: details?['code'] is String ? details!['code'] as String : null,
        requestId: requestId,
        details: errorDetails,
        retryAfter: retrySeconds != null && retrySeconds >= 0
            ? Duration(seconds: retrySeconds)
            : null,
      );
    }
    if (text != null && text.isEmpty) {
      return ApiResponse(
        data: null,
        meta: ApiMeta(requestId: requestId),
        statusCode: response.statusCode,
        isEmpty: true,
      );
    }
    try {
      if (envelope == null ||
          !envelope.containsKey('data') ||
          (meta != null && meta is! Map<String, dynamic>)) {
        throw const FormatException('Invalid response envelope.');
      }
      final parsedMeta = meta == null
          ? ApiMeta(requestId: requestId)
          : ApiMeta.fromJson(meta as Map<String, dynamic>);
      return ApiResponse(
        data: envelope['data'],
        meta: ApiMeta(
          requestId: parsedMeta.requestId ?? requestId,
          lang: parsedMeta.lang,
          pagination: parsedMeta.pagination,
        ),
        statusCode: response.statusCode,
      );
    } on FormatException {
      throw ApiException(
        kind: ApiErrorKind.invalidResponse,
        message: 'The server returned an invalid JSON response.',
        statusCode: response.statusCode,
        requestId: requestId,
      );
    }
  }

  void close() {
    if (_ownsClient) _client.close();
  }
}
