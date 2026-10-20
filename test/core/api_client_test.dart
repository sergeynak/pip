import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pip/api/api_client.dart';
import 'package:pip/api/api_config.dart';
import 'package:pip/api/api_exception.dart';
import 'package:pip/api/api_response.dart';

void main() {
  ApiClient clientFor(
    FutureOr<http.Response> Function(http.Request) handler, {
    Duration timeout = const Duration(seconds: 15),
  }) => ApiClient(
    config: ApiConfig(
      baseUrl: 'https://example.test/api/v1/',
      timeout: timeout,
    ),
    client: MockClient((request) async => handler(request)),
  );

  Matcher failsWith(ApiErrorKind kind) =>
      throwsA(isA<ApiException>().having((error) => error.kind, 'kind', kind));

  test('missing base URL never sends a request', () async {
    var requests = 0;
    final client = ApiClient(
      config: ApiConfig(),
      client: MockClient((_) async {
        requests++;
        return http.Response('', 204);
      }),
    );

    expect(client.config.isConfigured, isFalse);
    await expectLater(
      client.get('items'),
      failsWith(ApiErrorKind.notConfigured),
    );
    expect(requests, 0);
  });

  test('keeps base path prefix and encodes query values', () async {
    final client = clientFor((request) {
      expect(request.url.pathSegments, ['api', 'v1', 'items', 'example slug']);
      expect(request.url.queryParameters, {
        'lang': 'kk',
        'q': 'сайт & приложение',
      });
      expect(request.headers['accept'], 'application/json');
      return http.Response(
        jsonEncode({
          'data': <Object?>[],
          'meta': {
            'requestId': 'request-1',
            'lang': 'kk',
            'pagination': {
              'page': 1,
              'limit': 20,
              'total': 0,
              'totalPages': 0,
              'hasNext': false,
              'hasPrevious': false,
            },
          },
        }),
        200,
      );
    });

    final result = await client.get(
      '/items/example%20slug',
      queryParameters: {'lang': 'kk', 'q': 'сайт & приложение'},
    );
    expect(result.meta.requestId, 'request-1');
    expect(result.meta.lang, 'kk');
    expect(result.meta.pagination?.totalPages, 0);
    expect(result.isEmpty, isFalse);
  });

  test('rejects an external endpoint URL before sending', () async {
    var requests = 0;
    final client = clientFor((_) {
      requests++;
      return http.Response('', 204);
    });
    await expectLater(
      client.get('https://other.test/items'),
      failsWith(ApiErrorKind.invalidRequest),
    );
    expect(requests, 0);
  });

  test('decodes UTF-8 data even without a content-type header', () async {
    final client = clientFor(
      (_) => http.Response.bytes(
        utf8.encode(
          jsonEncode({'data': 'Привет', 'meta': <String, Object?>{}}),
        ),
        200,
      ),
    );
    expect((await client.get('items')).data, 'Привет');
  });

  test('accepts an empty successful response', () async {
    final client = clientFor(
      (_) => http.Response('', 204, headers: {'x-request-id': 'empty-request'}),
    );
    final result = await client.get('items');
    expect(result.data, isNull);
    expect(result.isEmpty, isTrue);
    expect(result.meta.requestId, 'empty-request');
  });

  for (final body in [
    '<html>not JSON</html>',
    '[]',
    '{"wrong":"envelope"}',
    '{"data":[],"meta":{"pagination":{"page":"one"}}}',
  ]) {
    test('reports malformed successful response: $body', () async {
      final client = clientFor((_) => http.Response(body, 200));
      await expectLater(
        client.get('items'),
        failsWith(ApiErrorKind.invalidResponse),
      );
    });
  }

  test('preserves structured HTTP errors and retry delay', () async {
    final client = clientFor(
      (_) => http.Response(
        jsonEncode({
          'error': {'code': 'RATE_LIMITED', 'message': 'Please try later.'},
          'meta': {'requestId': 'error-request'},
        }),
        429,
        headers: {'retry-after': '42'},
      ),
    );
    await expectLater(
      client.get('items'),
      throwsA(
        isA<ApiException>()
            .having((error) => error.kind, 'kind', ApiErrorKind.http)
            .having((error) => error.statusCode, 'status', 429)
            .having((error) => error.code, 'code', 'RATE_LIMITED')
            .having((error) => error.requestId, 'request ID', 'error-request')
            .having(
              (error) => error.retryAfter,
              'retry delay',
              const Duration(seconds: 42),
            ),
      ),
    );
  });

  test('an HTML error stays an HTTP error', () async {
    final client = clientFor((_) => http.Response('<html>Gateway</html>', 502));
    await expectLater(client.get('items'), failsWith(ApiErrorKind.http));
  });

  test(
    'keeps error details and retry delay when CORS hides the header',
    () async {
      final client = clientFor(
        (_) => http.Response(
          jsonEncode({
            'error': {
              'code': 'RATE_LIMITED',
              'message': 'Попробуйте позже.',
              'details': {'retryAfter': 30},
            },
            'meta': {'requestId': 'limited-request'},
          }),
          429,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      );
      await expectLater(
        client.post('briefs', body: <String, Object?>{}),
        throwsA(
          isA<ApiException>()
              .having(
                (error) => error.retryAfter,
                'retry delay',
                const Duration(seconds: 30),
              )
              .having(
                (error) => error.details['retryAfter'],
                'error details',
                30,
              ),
        ),
      );
    },
  );

  test('reports network failures without transport details', () async {
    final client = clientFor((_) => throw http.ClientException('offline'));
    await expectLater(client.get('items'), failsWith(ApiErrorKind.network));
  });

  test('times out and does not retry', () async {
    var requests = 0;
    final pending = Completer<http.Response>();
    final client = clientFor((_) {
      requests++;
      return pending.future;
    }, timeout: const Duration(milliseconds: 5));

    await expectLater(client.get('items'), failsWith(ApiErrorKind.timeout));
    expect(requests, 1);
    pending.complete(http.Response('', 204));
  });

  test(
    'preserves the caller key and JSON body across explicit retries',
    () async {
      final seenKeys = <String?>[];
      final seenBodies = <Object?>[];
      final client = clientFor((request) {
        expect(request.method, 'POST');
        expect(request.headers['content-type'], contains('application/json'));
        seenKeys.add(request.headers['idempotency-key']);
        seenBodies.add(jsonDecode(utf8.decode(request.bodyBytes)));
        return http.Response('{"data":{"accepted":true},"meta":{}}', 201);
      });
      const key = 'submission-key-123';
      const body = {'message': 'Нужен сайт'};

      await client.post('submissions', body: body, idempotencyKey: key);
      await client.post('submissions', body: body, idempotencyKey: key);
      expect(seenKeys, [key, key]);
      expect(seenBodies, [body, body]);
    },
  );

  test('does not send an invalid idempotency key', () async {
    var requests = 0;
    final client = clientFor((_) {
      requests++;
      return http.Response('', 204);
    });
    await expectLater(
      client.post(
        'submissions',
        body: <String, Object?>{},
        idempotencyKey: 'short',
      ),
      failsWith(ApiErrorKind.invalidRequest),
    );
    expect(requests, 0);
  });

  test('field metadata preserves the actual language independently', () {
    final languages = FieldLanguages.fromJson({'title': 'kk', 'content': 'ru'});
    expect(languages['title'], 'kk');
    expect(languages['content'], 'ru');
    expect(languages['missing'], isNull);
  });
}
