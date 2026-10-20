import '../core/api/api_client.dart';
import '../core/api/api_exception.dart';
import '../core/api/api_response.dart';
import 'studio_repository.dart';

/// Converts the public PIP v1 wire contract into the application's models.
/// Administrative credentials, browser cookies and automatic retries are unused.
class ApiStudioRepository implements StudioRepository {
  const ApiStudioRepository(this.client);
  final ApiClient client;

  @override
  bool get isDemo => false;

  @override
  Future<ContentPage<StudioService>> services(ContentLocale locale) => _read(
    'services',
    locale,
    (response) => ContentPage(_list(response.data).map(_service).toList()),
  );

  @override
  Future<StudioService> service(String slug, ContentLocale locale) => _read(
    'services/${_segment(slug)}',
    locale,
    (response) => _service(_map(response.data), detail: true),
  );

  @override
  Future<ContentPage<StudioProject>> projects(
    ContentLocale locale, {
    String query = '',
    String? cursor,
    bool? featured,
  }) {
    if (query.length > 100) {
      throw const RepositoryException(
        'Поисковый запрос должен быть не длиннее 100 символов.',
        code: 'INVALID_QUERY',
      );
    }
    return _read(
      'projects',
      locale,
      (response) => ContentPage(
        _list(response.data).map(_project).toList(),
        nextCursor: _nextPage(response),
      ),
      query: {
        'page': _page(cursor),
        'limit': '20',
        if (query.trim().isNotEmpty) 'q': query.trim(),
        if (featured != null) 'featured': '$featured',
      },
    );
  }

  @override
  Future<StudioProject> project(String slug, ContentLocale locale) => _read(
    'projects/${_segment(slug)}',
    locale,
    (response) => _project(_map(response.data), detail: true),
  );

  @override
  Future<ContentPage<StudioArticle>> articles(
    ContentLocale locale, {
    String? cursor,
  }) => _read(
    'posts',
    locale,
    (response) => ContentPage(
      _list(response.data).map(_article).toList(),
      nextCursor: _nextPage(response),
    ),
    query: {'page': _page(cursor), 'limit': '20'},
  );

  @override
  Future<StudioArticle> article(String slug, ContentLocale locale) => _read(
    'posts/${_segment(slug)}',
    locale,
    (response) => _article(_map(response.data), detail: true),
  );

  @override
  Future<StudioContact> contacts(ContentLocale locale) =>
      _read('config', locale, (response) {
        final config = _map(response.data);
        final studio = _map(config['studio']);
        final name = _string(studio, 'name');
        final city = _string(studio, 'city');
        final country = _string(studio, 'countryCode');
        return StudioContact(
          email: _string(studio, 'email'),
          telegram: _url(studio['telegramUrl']),
          websiteUrl: _url(studio['websiteUrl']),
          about: _text(
            [name, city, country].where((part) => part.isNotEmpty).join(' · '),
            _string(config, 'contentLanguage'),
          ),
        );
      });

  @override
  Future<BriefOptions> briefOptions(ContentLocale locale) =>
      _read('config', locale, (response) {
        final brief = _map(_map(response.data)['brief']);
        final limits = _map(brief['limits']);
        final options = BriefOptions(
          serviceOptions: _strings(brief['serviceOptions']),
          nameMin: _integer(limits, 'nameMin'),
          nameMax: _integer(limits, 'nameMax'),
          contactMin: _integer(limits, 'contactMin'),
          contactMax: _integer(limits, 'contactMax'),
          messageMax: _integer(limits, 'messageMax', minimum: 0),
          servicesMax: _integer(limits, 'servicesMax', minimum: 0),
          idempotencyTtlSeconds: _integer(brief, 'idempotencyTtlSeconds'),
        );
        if (options.nameMin > options.nameMax ||
            options.contactMin > options.contactMax) {
          throw const FormatException('Invalid form limits.');
        }
        return options;
      });

  @override
  Future<BriefReceipt> submitBrief(
    BriefDraft draft, {
    required String idempotencyKey,
  }) => _guard(() async {
    final response = await client.post(
      'briefs',
      queryParameters: {'lang': draft.locale.name},
      idempotencyKey: idempotencyKey,
      body: {
        'name': draft.name.trim(),
        'contact': draft.contact.trim(),
        'message': draft.description.trim(),
        'services': draft.serviceIds.toSet().toList()..sort(),
      },
    );
    final data = response.data;
    if (response.statusCode != 201 ||
        data is! Map<String, dynamic> ||
        data['accepted'] != true ||
        data['id'] is! String ||
        (data['id'] as String).trim().isEmpty) {
      throw RepositoryException(
        'Сервер не подтвердил сохранение заявки. Повторите отправку с теми же данными.',
        code: 'INVALID_RESPONSE',
        statusCode: response.statusCode,
        requestId: response.meta.requestId,
      );
    }
    return BriefReceipt(id: data['id'] as String);
  });

  Future<T> _read<T>(
    String path,
    ContentLocale locale,
    T Function(ApiResponse) decode, {
    Map<String, String> query = const {},
  }) => _guard(() async {
    final response = await client.get(
      path,
      queryParameters: {'lang': locale.name, ...query},
    );
    try {
      return decode(response);
    } on FormatException {
      throw RepositoryException(
        'Сервер вернул данные в неподдерживаемом формате. Попробуйте обновить страницу.',
        code: 'INVALID_RESPONSE',
        statusCode: response.statusCode,
        requestId: response.meta.requestId,
      );
    }
  });

  Future<T> _guard<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on ApiException catch (error) {
      final message = switch (error.kind) {
        ApiErrorKind.network =>
          'Нет соединения с сервером. Проверьте интернет и повторите попытку.',
        ApiErrorKind.timeout =>
          'Сервер не ответил вовремя. Попробуйте ещё раз.',
        ApiErrorKind.notConfigured => 'Адрес API не настроен.',
        ApiErrorKind.invalidRequest =>
          'Не удалось подготовить запрос. Проверьте введённые данные.',
        ApiErrorKind.invalidResponse =>
          'Сервер вернул некорректный ответ. Попробуйте ещё раз.',
        ApiErrorKind.http =>
          error.code == null
              ? 'Сервер временно недоступен. Попробуйте ещё раз.'
              : error.message,
      };
      throw RepositoryException(
        message,
        code: error.code ?? error.kind.name,
        statusCode: error.statusCode,
        requestId: error.requestId,
        retryAfter: error.retryAfter,
      );
    }
  }

  static StudioService _service(
    Map<String, dynamic> data, {
    bool detail = false,
  }) {
    final language = _string(data, 'contentLanguage');
    final sections = detail
        ? _list(data['sections'])
              .map(
                (section) => (
                  heading: _string(section, 'heading'),
                  text: _string(section, 'text'),
                ),
              )
              .toList()
        : <({String heading, String text})>[];
    return StudioService(
      id: _slug(data),
      title: _text(_string(data, 'title'), language),
      description: _text(_string(data, detail ? 'lead' : 'summary'), language),
      startingPrice: _string(_map(data['price']), 'label'),
      contentLanguage: language,
      deliverables: const [],
      sections: sections,
      faq: detail
          ? _list(data['faq'])
                .map(
                  (item) => (
                    question: _string(item, 'question'),
                    answer: _string(item, 'answer'),
                  ),
                )
                .toList()
          : const [],
      projects: detail
          ? _list(data['projects'])
                .map(
                  (item) => StudioProject(
                    id: _slug(item),
                    slug: _slug(item),
                    title: _text(_string(item, 'title'), language),
                    description: _text(_string(item, 'scope'), language),
                    category: '',
                    serviceIds: const [],
                    visual: 0,
                    coverUrl: _optionalUrl(item['coverUrl']),
                    fieldLanguages: {'title': language, 'excerpt': language},
                  ),
                )
                .toList()
          : const [],
    );
  }

  static StudioProject _project(
    Map<String, dynamic> data, {
    bool detail = false,
  }) {
    final languages = _languages(data['fieldLanguages']);
    final descriptionKey = detail ? 'content' : 'excerpt';
    if (detail && data['contentFormat'] != 'plain_text') {
      throw const FormatException('Unsupported project content format.');
    }
    final gallery = detail
        ? _list(data['gallery']).map((item) {
            final kind = _string(item, 'kind');
            if (kind != 'current' && kind != 'historical') {
              throw const FormatException('Unsupported image kind.');
            }
            return ProjectImage(
              url: _url(item['url']),
              thumbnailUrl: _optionalUrl(item['thumbnailUrl']),
              caption: _string(item, 'caption'),
              kind: kind,
              width: _dimension(item['width']),
              height: _dimension(item['height']),
            );
          }).toList()
        : <ProjectImage>[];
    return StudioProject(
      id: '${_integer(data, 'id')}',
      slug: _slug(data),
      title: _fieldText(data, 'title', languages),
      category: _string(data, 'category'),
      description: _fieldText(data, descriptionKey, languages),
      serviceIds: const [],
      visual: 0,
      coverUrl: _optionalUrl(data['coverUrl']),
      websiteUrl: _optionalUrl(data['websiteUrl']),
      gallery: gallery,
      imageUrls: gallery.map((image) => image.url).toList(),
      fieldLanguages: languages,
    );
  }

  static StudioArticle _article(
    Map<String, dynamic> data, {
    bool detail = false,
  }) {
    final languages = _languages(data['fieldLanguages']);
    if (detail && data['contentFormat'] != 'plain_text') {
      throw const FormatException('Unsupported article content format.');
    }
    final content = _string(data, detail ? 'content' : 'excerpt');
    return StudioArticle(
      id: '${_integer(data, 'id')}',
      slug: _slug(data),
      title: _fieldText(data, 'title', languages),
      category: _string(data, 'category'),
      paragraphs: content.isEmpty
          ? const []
          : content.split(RegExp(r'\r?\n[ \t]*\r?\n')),
      coverUrl: _optionalUrl(data['coverUrl']),
      publishedAt: _date(data['publishedAt']),
      author: _string(data, 'author'),
      websiteUrl: _url(data['url']),
      fieldLanguages: languages,
    );
  }

  static Map<String, dynamic> _map(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Expected object.');
    }
    return value;
  }

  static List<Map<String, dynamic>> _list(Object? value) {
    if (value is! List) throw const FormatException('Expected array.');
    return value.map((Object? item) => _map(item)).toList();
  }

  static List<String> _strings(Object? value) {
    if (value is! List || value.any((Object? item) => item is! String)) {
      throw const FormatException('Expected string array.');
    }
    return value.cast<String>();
  }

  static String _string(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is! String) throw FormatException('Invalid string: $key.');
    return value;
  }

  static String _slug(Map<String, dynamic> data) {
    final slug = _string(data, 'slug');
    if (slug.trim().isEmpty) throw const FormatException('Empty slug.');
    return slug;
  }

  static int _integer(
    Map<String, dynamic> data,
    String key, {
    int minimum = 1,
  }) {
    final value = data[key];
    if (value is! int || value < minimum) {
      throw FormatException('Invalid integer: $key.');
    }
    return value;
  }

  static Uri _url(Object? value) {
    final uri = value is String ? Uri.tryParse(value) : null;
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        !['https', 'http'].contains(uri.scheme) ||
        uri.userInfo.isNotEmpty) {
      throw const FormatException('Expected absolute HTTP(S) URL.');
    }
    return uri;
  }

  static Uri? _optionalUrl(Object? value) => value == null ? null : _url(value);

  static DateTime? _date(Object? value) {
    if (value == null) return null;
    final date = value is String ? DateTime.tryParse(value) : null;
    if (date == null) throw const FormatException('Invalid date.');
    return date;
  }

  static num? _dimension(Object? value) {
    if (value == null) return null;
    if (value is! num || !value.isFinite || value <= 0) {
      throw const FormatException('Invalid image dimensions.');
    }
    return value;
  }

  static ContentLocale _locale(String value) => switch (value) {
    'ru' => ContentLocale.ru,
    'en' => ContentLocale.en,
    'kk' || 'kz' => ContentLocale.kk,
    _ => throw const FormatException('Unsupported content language.'),
  };

  static LocalizedText _text(String value, String language) =>
      LocalizedText({_locale(language): value});

  static Map<String, String> _languages(Object? value) {
    final result = <String, String>{};
    for (final entry in _map(value).entries) {
      if (entry.value is! String) {
        throw const FormatException('Invalid field language.');
      }
      final language = entry.value as String;
      _locale(language);
      result[entry.key] = language;
    }
    return Map.unmodifiable(result);
  }

  static LocalizedText _fieldText(
    Map<String, dynamic> data,
    String field,
    Map<String, String> languages,
  ) {
    final language = languages[field];
    if (language == null) throw FormatException('Missing language for $field.');
    return _text(_string(data, field), language);
  }

  static String? _nextPage(ApiResponse response) {
    final pagination = response.meta.pagination;
    if (pagination == null) throw const FormatException('Missing pagination.');
    return pagination.hasNext ? '${pagination.page + 1}' : null;
  }

  static String _page(String? cursor) {
    if (cursor == null) return '1';
    final page = int.tryParse(cursor);
    if (page == null || page < 1 || page > 100000 || '$page' != cursor) {
      throw const RepositoryException(
        'Некорректный номер страницы.',
        code: 'INVALID_QUERY',
      );
    }
    return cursor;
  }

  static String _segment(String slug) {
    if (slug.trim().isEmpty || slug == '.' || slug == '..') {
      throw const RepositoryException(
        'Не указан адрес материала.',
        code: 'INVALID_PATH',
      );
    }
    return Uri.encodeComponent(slug);
  }
}
