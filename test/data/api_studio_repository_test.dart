import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pip/core/api/api_client.dart';
import 'package:pip/core/api/api_config.dart';
import 'package:pip/data/api_studio_repository.dart';
import 'package:pip/data/studio_repository.dart';

Map<String, Object?> project({bool detail = false}) => {
  'id': 4,
  'slug': 'real-project',
  'title': 'На русском',
  'excerpt': 'Қысқаша мәтін',
  'category': 'Сайты',
  'coverUrl': 'https://images.example.test/cover.jpg',
  'url': 'https://example.test/projects/real-project',
  'websiteUrl': 'https://project.example.test/',
  'fieldLanguages': {
    'title': 'ru',
    'excerpt': 'kk',
    'category': 'ru',
    if (detail) 'content': 'en',
  },
  if (detail) ...{
    'content': 'Full English content.',
    'contentFormat': 'plain_text',
    'gallery': [
      {
        'url': 'https://images.example.test/full.webp',
        'thumbnailUrl': 'https://images.example.test/thumb.jpg',
        'caption': 'Главная',
        'kind': 'historical',
        'width': 1400,
        'height': 8000,
      },
    ],
  },
  'futureField': 'ignored',
};

Map<String, Object?> article({bool detail = false}) => {
  'id': 9,
  'slug': 'real-post',
  'title': 'Статья',
  'excerpt': 'Анонс',
  'category': 'Процесс',
  'coverUrl': null,
  'url': 'https://example.test/blog/real-post',
  'publishedAt': '2026-10-20T05:00:00.000Z',
  'author': 'PIP',
  'fieldLanguages': {
    'title': 'ru',
    'excerpt': 'ru',
    'category': 'ru',
    if (detail) 'content': 'ru',
  },
  if (detail) ...{
    'content': 'Первый абзац.\nВторая строка.\n\nНовый абзац.',
    'contentFormat': 'plain_text',
  },
};

Map<String, Object?> service({bool detail = false}) => {
  'slug': 'landing-page',
  'title': 'Разработка лендингов',
  'summary': 'Краткое описание',
  'contentLanguage': 'ru',
  'price': {'amountFrom': null, 'currency': 'KZT', 'label': 'По составу работ'},
  if (detail) ...{
    'lead': 'Подробное описание',
    'sections': [
      {'heading': 'Структура', 'text': 'Согласуем разделы.'},
    ],
    'faq': [
      {'question': 'Сколько?', 'answer': 'После оценки.'},
    ],
    'projects': [
      {
        'slug': 'related-project',
        'title': 'Работа',
        'scope': 'Описание выполненной работы.',
        'coverUrl': null,
        'url': 'https://example.test/projects/related-project',
      },
    ],
  },
};

Map<String, Object?> config() => {
  'contentLanguage': 'ru',
  'studio': {
    'name': 'PIP',
    'city': 'Алматы',
    'countryCode': 'KZ',
    'email': 'hello@example.test',
    'telegramUrl': 'https://t.me/example',
    'websiteUrl': 'https://example.test',
  },
  'brief': {
    'serviceOptions': ['Сайт', 'Интернет-магазин'],
    'limits': {
      'nameMin': 2,
      'nameMax': 100,
      'contactMin': 3,
      'contactMax': 200,
      'messageMax': 5000,
      'servicesMax': 6,
    },
    'idempotencyTtlSeconds': 86400,
  },
};

http.Response success(
  Object? data, {
  bool paginated = false,
  bool hasNext = false,
  int page = 1,
  int status = 200,
}) => http.Response.bytes(
  utf8.encode(
    jsonEncode({
      'data': data,
      'meta': {
        'requestId': 'test-request',
        'lang': 'kk',
        if (paginated)
          'pagination': {
            'page': page,
            'limit': 20,
            'total': hasNext ? 45 : 1,
            'totalPages': hasNext ? 3 : 1,
            'hasNext': hasNext,
            'hasPrevious': page > 1,
          },
      },
    }),
  ),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

ApiStudioRepository repository(
  FutureOr<http.Response> Function(http.Request) handler,
) => ApiStudioRepository(
  ApiClient(
    config: ApiConfig(baseUrl: 'https://example.test/api/v1/'),
    client: MockClient((request) async => handler(request)),
  ),
);

void main() {
  test(
    'projects maps pagination, search, featured and actual field languages',
    () async {
      final repo = repository((request) {
        expect(request.url.path, '/api/v1/projects');
        expect(request.url.queryParameters, {
          'lang': 'kk',
          'page': '2',
          'limit': '20',
          'q': 'сайт & магазин',
          'featured': 'true',
        });
        return success([project()], paginated: true, hasNext: true, page: 2);
      });
      final page = await repo.projects(
        ContentLocale.kk,
        cursor: '2',
        query: ' сайт & магазин ',
        featured: true,
      );
      expect(repo.isDemo, isFalse);
      expect(page.nextCursor, '3');
      final item = page.items.single;
      expect(item.id, '4');
      expect(item.slug, 'real-project');
      expect(item.title.values, {ContentLocale.ru: 'На русском'});
      expect(item.description.values, {ContentLocale.kk: 'Қысқаша мәтін'});
      expect(item.fieldLanguages['category'], 'ru');
      expect(item.coverUrl.toString(), 'https://images.example.test/cover.jpg');
      expect(item.gallery, isEmpty);
      expect(item.serviceIds, isEmpty);
    },
  );

  test('encodes detail slug as one segment and maps full gallery', () async {
    final repo = repository((request) {
      expect(request.url.pathSegments, ['api', 'v1', 'projects', 'case/a b']);
      expect(request.url.queryParameters, {'lang': 'en'});
      return success(project(detail: true));
    });
    final item = await repo.project('case/a b', ContentLocale.en);
    expect(item.description.resolve(ContentLocale.en), 'Full English content.');
    expect(item.fieldLanguages['content'], 'en');
    expect(item.gallery.single.kind, 'historical');
    expect(item.gallery.single.caption, 'Главная');
    expect(item.gallery.single.height, 8000);
    expect(
      item.imageUrls.single.toString(),
      'https://images.example.test/full.webp',
    );
    expect(item.websiteUrl.toString(), 'https://project.example.test/');
  });

  test(
    'service summary and detail preserve real prices, sections and related projects',
    () async {
      final repo = repository(
        (request) => request.url.path.endsWith('/services')
            ? success([service()])
            : success(service(detail: true)),
      );
      final summary = (await repo.services(ContentLocale.kk)).items.single;
      expect(summary.startingPrice, 'По составу работ');
      expect(summary.contentLanguage, 'ru');
      expect(summary.description.resolve(ContentLocale.kk), 'Краткое описание');
      final detail = await repo.service(summary.id, ContentLocale.kk);
      expect(
        detail.description.resolve(ContentLocale.kk),
        'Подробное описание',
      );
      expect(detail.sections.single, (
        heading: 'Структура',
        text: 'Согласуем разделы.',
      ));
      expect(detail.faq.single.answer, 'После оценки.');
      expect(detail.projects.single.slug, 'related-project');
      expect(detail.projects.single.category, isEmpty);
    },
  );

  test('article detail preserves paragraph line breaks and metadata', () async {
    final repo = repository((request) {
      expect(request.url.path, '/api/v1/posts/real-post');
      return success(article(detail: true));
    });
    final item = await repo.article('real-post', ContentLocale.ru);
    expect(item.paragraphs, ['Первый абзац.\nВторая строка.', 'Новый абзац.']);
    expect(item.coverUrl, isNull);
    expect(item.author, 'PIP');
    expect(item.publishedAt, DateTime.utc(2026, 10, 20, 5));
    expect(item.fieldLanguages['content'], 'ru');
    expect(item.websiteUrl.toString(), 'https://example.test/blog/real-post');
  });

  test('article list omits next cursor when final page is reached', () async {
    final repo = repository((request) {
      expect(request.url.path, '/api/v1/posts');
      expect(request.url.queryParameters, {
        'lang': 'ru',
        'page': '1',
        'limit': '20',
      });
      return success([article()], paginated: true);
    });
    expect((await repo.articles(ContentLocale.ru)).nextCursor, isNull);
  });

  test(
    'config supplies contacts and form options without invented fields',
    () async {
      final repo = repository((request) {
        expect(request.url.path, '/api/v1/config');
        return success(config());
      });
      final contacts = await repo.contacts(ContentLocale.en);
      expect(contacts.email, 'hello@example.test');
      expect(contacts.telegram.toString(), 'https://t.me/example');
      expect(contacts.about?.resolve(ContentLocale.en), 'PIP · Алматы · KZ');
      final options = await repo.briefOptions(ContentLocale.ru);
      expect(options.serviceOptions, ['Сайт', 'Интернет-магазин']);
      expect(options.nameMin, 2);
      expect(options.messageMax, 5000);
      expect(options.idempotencyTtlSeconds, 86400);
    },
  );

  const draft = BriefDraft(
    name: ' Клиент ',
    contact: ' @client ',
    description: '',
    serviceIds: ['Сайт'],
    locale: ContentLocale.kk,
  );

  test(
    'brief uses exact allowed body and stable key; only a confirmed save succeeds',
    () async {
      final keys = <String?>[];
      final repo = repository((request) {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/v1/briefs');
        expect(request.url.queryParameters, {'lang': 'kk'});
        expect(jsonDecode(utf8.decode(request.bodyBytes)), {
          'name': 'Клиент',
          'contact': '@client',
          'message': '',
          'services': ['Сайт'],
        });
        keys.add(request.headers['idempotency-key']);
        return success({'accepted': true, 'id': 'saved-id'}, status: 201);
      });
      for (var i = 0; i < 2; i++) {
        final receipt = await repo.submitBrief(
          draft,
          idempotencyKey: 'stable-key-123',
        );
        expect(receipt.id, 'saved-id');
      }
      expect(keys, ['stable-key-123', 'stable-key-123']);
    },
  );

  for (final (status, data) in <(int, Object?)>[
    (200, {'accepted': true, 'id': 'id'}),
    (201, {'accepted': false, 'id': 'id'}),
    (201, {'accepted': true, 'id': ''}),
    (201, {'accepted': true}),
    (204, null),
  ]) {
    test(
      'does not confirm a brief with invalid receipt ($status, $data)',
      () async {
        final repo = repository((_) => success(data, status: status));
        await expectLater(
          repo.submitBrief(draft, idempotencyKey: 'stable-key-123'),
          throwsA(
            isA<RepositoryException>().having(
              (e) => e.code,
              'code',
              'INVALID_RESPONSE',
            ),
          ),
        );
      },
    );
  }

  test(
    'HTTP errors preserve server message, request ID and rate-limit delay',
    () async {
      final repo = repository(
        (_) => http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'error': {
                'code': 'RATE_LIMITED',
                'message': 'Подождите.',
                'details': {'retryAfter': 30},
              },
              'meta': {'requestId': 'limited-request'},
            }),
          ),
          429,
        ),
      );
      await expectLater(
        repo.submitBrief(draft, idempotencyKey: 'stable-key-123'),
        throwsA(
          isA<RepositoryException>()
              .having((e) => e.message, 'message', 'Подождите.')
              .having((e) => e.statusCode, 'status', 429)
              .having((e) => e.code, 'code', 'RATE_LIMITED')
              .having((e) => e.requestId, 'requestId', 'limited-request')
              .having(
                (e) => e.retryAfter,
                'retryAfter',
                const Duration(seconds: 30),
              ),
        ),
      );
    },
  );

  test('network errors have a Russian user-facing message', () async {
    final repo = repository((_) => throw http.ClientException('socket failed'));
    await expectLater(
      repo.services(ContentLocale.ru),
      throwsA(
        isA<RepositoryException>().having(
          (e) => e.message,
          'message',
          contains('Проверьте интернет'),
        ),
      ),
    );
  });

  test(
    'rejects malformed DTOs, relative image URLs and missing pagination',
    () async {
      for (final data in [
        {'id': 'invalid'},
        {...project(), 'coverUrl': '/relative.jpg'},
        {
          ...project(),
          'fieldLanguages': {'title': 'ru'},
        },
      ]) {
        final repo = repository((_) => success([data], paginated: true));
        await expectLater(
          repo.projects(ContentLocale.ru),
          throwsA(
            isA<RepositoryException>().having(
              (e) => e.code,
              'code',
              'INVALID_RESPONSE',
            ),
          ),
        );
      }
      final repo = repository((_) => success([project()]));
      await expectLater(
        repo.projects(ContentLocale.ru),
        throwsA(isA<RepositoryException>()),
      );
    },
  );

  test('invalid search and page are rejected before network work', () {
    final repo = repository(
      (_) => throw StateError('Must not send a request.'),
    );
    expect(
      () => repo.projects(ContentLocale.ru, query: 'a' * 101),
      throwsA(isA<RepositoryException>()),
    );
    expect(
      () => repo.projects(ContentLocale.ru, cursor: '0'),
      throwsA(isA<RepositoryException>()),
    );
  });
}
