import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pip/api/api_client.dart';
import 'package:pip/api/api_config.dart';
import 'package:pip/api/api_service.dart';
import 'package:pip/models.dart';

void main() {
  test('API stubs never send HTTP even with a configured client', () async {
    var requests = 0;
    final transport = MockClient((_) async {
      requests++;
      return http.Response('{"data":{},"meta":{}}', 200);
    });
    final api = ApiService(
      client: ApiClient(
        config: ApiConfig(baseUrl: 'https://example.test/api/v1'),
        client: transport,
      ),
    );
    addTearDown(api.close);
    addTearDown(transport.close);

    const locale = ContentLocale.ru;
    const draft = BriefDraft(
      name: 'Тест',
      contact: '@example',
      services: ['Сайт'],
      description: 'Проверка заготовки',
      locale: locale,
    );
    final operations = <Future<Object?> Function()>[
      () => api.getServices(locale),
      () => api.getService('example', locale),
      () => api.getProjects(locale, query: 'сайт', page: 2, featured: true),
      () => api.getProject('example', locale),
      () => api.getArticles(locale, page: 2),
      () => api.getArticle('example', locale),
      () => api.getContacts(locale),
      () => api.getBriefOptions(locale),
      () => api.sendBrief(draft, idempotencyKey: 'example-stable-key'),
    ];
    for (final operation in operations) {
      await expectLater(
        operation(),
        throwsA(
          isA<AppException>()
              .having((error) => error.code, 'code', 'API_NOT_CONNECTED')
              .having(
                (error) => error.message,
                'message',
                startsWith('API ещё не подключён.'),
              ),
        ),
      );
      expect(requests, 0);
    }
  });
}
