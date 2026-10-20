import '../models.dart';
import 'api_client.dart';
import 'api_config.dart';
import 'api_exception.dart';
import 'api_response.dart';

/// Загружает данные PIP и преобразует JSON в модели приложения.
class ApiService {
  ApiService({ApiClient? client})
    : client = client ?? ApiClient(config: ApiConfig.fromEnvironment());

  final ApiClient client;

  bool get isDemo => false;

  void close() {
    client.close();
  }

  /// Загружает краткий список услуг.
  Future<ContentPage<StudioService>> getServices(ContentLocale locale) async {
    final response = await _get('services', locale);
    try {
      final services = <StudioService>[];
      for (final item in _list(response.data)) {
        services.add(_service(item));
      }
      return ContentPage(services);
    } on FormatException {
      throw _invalidResponse(response);
    }
  }

  /// Загружает описание услуги, ответы на вопросы и связанные проекты.
  Future<StudioService> getService(String slug, ContentLocale locale) async {
    final path = 'services/${_segment(slug)}';
    final response = await _get(path, locale);
    try {
      final data = _map(response.data);
      return _service(data, detail: true);
    } on FormatException {
      throw _invalidResponse(response);
    }
  }

  /// Загружает страницу проектов с поиском и необязательным фильтром избранных.
  Future<ContentPage<StudioProject>> getProjects(
    ContentLocale locale, {
    String query = '',
    int page = 1,
    bool? featured,
  }) async {
    _validatePage(page);
    if (query.length > 100) {
      throw const AppException(
        'Поисковый запрос должен быть не длиннее 100 символов.',
        code: 'INVALID_QUERY',
      );
    }
    final parameters = <String, String>{'page': '$page', 'limit': '20'};
    final search = query.trim();
    if (search.isNotEmpty) parameters['q'] = search;
    if (featured != null) parameters['featured'] = '$featured';

    final response = await _get('projects', locale, query: parameters);
    try {
      final projects = <StudioProject>[];
      for (final item in _list(response.data)) {
        projects.add(_project(item));
      }
      final nextPage = _nextPage(response);
      return ContentPage(projects, nextPage: nextPage);
    } on FormatException {
      throw _invalidResponse(response);
    }
  }

  /// Загружает полный текст проекта и галерею.
  Future<StudioProject> getProject(String slug, ContentLocale locale) async {
    final path = 'projects/${_segment(slug)}';
    final response = await _get(path, locale);
    try {
      final data = _map(response.data);
      return _project(data, detail: true);
    } on FormatException {
      throw _invalidResponse(response);
    }
  }

  /// Загружает одну страницу статей.
  Future<ContentPage<StudioArticle>> getArticles(
    ContentLocale locale, {
    int page = 1,
  }) async {
    _validatePage(page);
    final parameters = {'page': '$page', 'limit': '20'};
    final response = await _get('posts', locale, query: parameters);
    try {
      final articles = <StudioArticle>[];
      for (final item in _list(response.data)) {
        articles.add(_article(item));
      }
      final nextPage = _nextPage(response);
      return ContentPage(articles, nextPage: nextPage);
    } on FormatException {
      throw _invalidResponse(response);
    }
  }

  /// Загружает полный текст выбранной статьи.
  Future<StudioArticle> getArticle(String slug, ContentLocale locale) async {
    final path = 'posts/${_segment(slug)}';
    final response = await _get(path, locale);
    try {
      final data = _map(response.data);
      return _article(data, detail: true);
    } on FormatException {
      throw _invalidResponse(response);
    }
  }

  /// Берёт контакты и сведения о студии из настроек сервера.
  Future<StudioContact> getContacts(ContentLocale locale) async {
    final response = await _get('config', locale);
    try {
      final config = _map(response.data);
      final studio = _map(config['studio']);
      final name = _string(studio, 'name');
      final city = _string(studio, 'city');
      final country = _string(studio, 'countryCode');
      final aboutParts = [name, city, country];
      final about = aboutParts.where((part) => part.isNotEmpty).join(' · ');
      final language = _string(config, 'contentLanguage');

      return StudioContact(
        email: _string(studio, 'email'),
        telegram: _url(studio['telegramUrl']),
        websiteUrl: _url(studio['websiteUrl']),
        about: _text(about, language),
      );
    } on FormatException {
      throw _invalidResponse(response);
    }
  }

  /// Загружает допустимые услуги и ограничения полей заявки.
  Future<BriefOptions> getBriefOptions(ContentLocale locale) async {
    final response = await _get('config', locale);
    try {
      final config = _map(response.data);
      final brief = _map(config['brief']);
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
    } on FormatException {
      throw _invalidResponse(response);
    }
  }

  /// Отправляет заявку. При повторе экран передаёт прежний ключ и те же данные.
  Future<BriefReceipt> sendBrief(
    BriefDraft draft, {
    required String idempotencyKey,
  }) async {
    final selectedServices = draft.services.toSet().toList();
    selectedServices.sort();
    final body = {
      'name': draft.name.trim(),
      'contact': draft.contact.trim(),
      'message': draft.description.trim(),
      'services': selectedServices,
    };

    final ApiResponse response;
    try {
      response = await client.post(
        'briefs',
        queryParameters: {'lang': draft.locale.name},
        idempotencyKey: idempotencyKey,
        body: body,
      );
    } on ApiException catch (error) {
      throw _requestError(error);
    }

    // Успех показываем только после явного подтверждения сохранения сервером.
    final data = response.data;
    if (response.statusCode != 201 ||
        data is! Map<String, dynamic> ||
        data['accepted'] != true ||
        data['id'] is! String ||
        (data['id'] as String).trim().isEmpty) {
      throw AppException(
        'Сервер не подтвердил сохранение заявки. Повторите отправку с теми же данными.',
        code: 'INVALID_RESPONSE',
        statusCode: response.statusCode,
        requestId: response.meta.requestId,
      );
    }
    return BriefReceipt(id: data['id'] as String);
  }

  /// Общая часть GET-запросов: язык и преобразование сетевой ошибки.
  Future<ApiResponse> _get(
    String path,
    ContentLocale locale, {
    Map<String, String> query = const {},
  }) async {
    final parameters = {'lang': locale.name, ...query};
    try {
      return await client.get(path, queryParameters: parameters);
    } on ApiException catch (error) {
      throw _requestError(error);
    }
  }

  AppException _invalidResponse(ApiResponse response) {
    return AppException(
      'Сервер вернул данные в неподдерживаемом формате. Попробуйте обновить страницу.',
      code: 'INVALID_RESPONSE',
      statusCode: response.statusCode,
      requestId: response.meta.requestId,
    );
  }

  /// Сохраняем код, номер запроса и время ожидания для обработки в интерфейсе.
  AppException _requestError(ApiException error) {
    final message = switch (error.kind) {
      ApiErrorKind.network =>
        'Нет соединения с сервером. Проверьте интернет и повторите попытку.',
      ApiErrorKind.timeout => 'Сервер не ответил вовремя. Попробуйте ещё раз.',
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
    return AppException(
      message,
      code: error.code ?? error.kind.name,
      statusCode: error.statusCode,
      requestId: error.requestId,
      retryAfter: error.retryAfter,
    );
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

  static int? _nextPage(ApiResponse response) {
    final pagination = response.meta.pagination;
    if (pagination == null) throw const FormatException('Missing pagination.');
    return pagination.hasNext ? pagination.page + 1 : null;
  }

  static void _validatePage(int page) {
    if (page < 1 || page > 100000) {
      throw const AppException(
        'Номер страницы должен быть от 1 до 100000.',
        code: 'INVALID_QUERY',
      );
    }
  }

  static String _segment(String slug) {
    if (slug.trim().isEmpty || slug == '.' || slug == '..') {
      throw const AppException(
        'Не указан адрес материала.',
        code: 'INVALID_PATH',
      );
    }
    return Uri.encodeComponent(slug);
  }
}
