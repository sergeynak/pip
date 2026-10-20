import '../models.dart';
import 'api_client.dart';
import 'api_config.dart';

/// Заготовка для будущего API. Сейчас методы не отправляют запросы.
class ApiService {
  ApiService({ApiClient? client})
    : client = client ?? ApiClient(config: ApiConfig.fromEnvironment());

  final ApiClient client;

  bool get isDemo => false;

  void close() {
    client.close();
  }

  Future<ContentPage<StudioService>> getServices(ContentLocale locale) async {
    // TODO: подключить GET /services и разобрать список услуг.
    throw const AppException(
      'API ещё не подключён. Данные услуг пока недоступны.',
      code: 'API_NOT_CONNECTED',
    );
  }

  Future<StudioService> getService(String slug, ContentLocale locale) async {
    // TODO: подключить GET /services/{slug} для подробного описания услуги.
    throw const AppException(
      'API ещё не подключён. Описание услуги пока недоступно.',
      code: 'API_NOT_CONNECTED',
    );
  }

  Future<ContentPage<StudioProject>> getProjects(
    ContentLocale locale, {
    String query = '',
    int page = 1,
    bool? featured,
  }) async {
    // TODO: подключить GET /projects с поиском и номером страницы.
    throw const AppException(
      'API ещё не подключён. Данные проектов пока недоступны.',
      code: 'API_NOT_CONNECTED',
    );
  }

  Future<StudioProject> getProject(String slug, ContentLocale locale) async {
    // TODO: подключить GET /projects/{slug} для текста и галереи проекта.
    throw const AppException(
      'API ещё не подключён. Описание проекта пока недоступно.',
      code: 'API_NOT_CONNECTED',
    );
  }

  Future<ContentPage<StudioArticle>> getArticles(
    ContentLocale locale, {
    int page = 1,
  }) async {
    // TODO: подключить GET /posts с номером страницы.
    throw const AppException(
      'API ещё не подключён. Статьи пока недоступны.',
      code: 'API_NOT_CONNECTED',
    );
  }

  Future<StudioArticle> getArticle(String slug, ContentLocale locale) async {
    // TODO: подключить GET /posts/{slug} для полного текста статьи.
    throw const AppException(
      'API ещё не подключён. Текст статьи пока недоступен.',
      code: 'API_NOT_CONNECTED',
    );
  }

  Future<StudioContact> getContacts(ContentLocale locale) async {
    // TODO: получить контакты студии через GET /config.
    throw const AppException(
      'API ещё не подключён. Контакты пока недоступны.',
      code: 'API_NOT_CONNECTED',
    );
  }

  Future<BriefOptions> getBriefOptions(ContentLocale locale) async {
    // TODO: получить варианты услуг и ограничения формы через GET /config.
    throw const AppException(
      'API ещё не подключён. Настройки формы пока недоступны.',
      code: 'API_NOT_CONNECTED',
    );
  }

  Future<BriefReceipt> sendBrief(
    BriefDraft draft, {
    required String idempotencyKey,
  }) async {
    // TODO: подключить POST /briefs с прежним ключом при повторной отправке.
    throw const AppException(
      'API ещё не подключён. Заявка не отправлена.',
      code: 'API_NOT_CONNECTED',
    );
  }
}
