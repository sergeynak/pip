import '../models.dart';
import 'api_service.dart';

/// Демонстрационные данные для запуска без обращения к серверу.
class DemoApiService extends ApiService {
  DemoApiService();
  @override
  bool get isDemo => true;

  static LocalizedText _ru(String text) =>
      LocalizedText({ContentLocale.ru: text});

  static final demoServices = [
    StudioService(
      id: 'web',
      title: _ru('Сайты и веб-сервисы'),
      description: _ru(
        'Пример направления: от первого экрана до удобного цифрового продукта. Описание и состав работ будут загружаться из CMS.',
      ),
      deliverables: const [
        'Структура и пользовательские сценарии',
        'Дизайн интерфейса',
        'Разработка и запуск',
      ],
      faq: const [
        (
          question: 'Как формируется стоимость?',
          answer:
              'Здесь появится ответ студии из CMS. Стоимость пока не опубликована.',
        ),
      ],
    ),
    StudioService(
      id: 'design',
      title: _ru('Дизайн интерфейсов'),
      description: _ru(
        'Пример направления: понятные интерфейсы для повседневных задач. Это демонстрационное наполнение каркаса.',
      ),
      deliverables: const [
        'Исследование задачи',
        'Прототипирование',
        'Визуальная система',
      ],
      faq: const [
        (
          question: 'Что нужно для начала?',
          answer:
              'Здесь появится актуальный список материалов и этапов работы.',
        ),
      ],
    ),
    StudioService(
      id: 'brand',
      title: _ru('Айдентика'),
      description: _ru(
        'Пример направления: визуальный язык бренда. Точные условия и материалы будут доступны после подключения API.',
      ),
      deliverables: const [
        'Визуальная концепция',
        'Основные носители',
        'Рекомендации по использованию',
      ],
      faq: const [
        (
          question: 'Что входит в результат?',
          answer: 'Состав результата будет опубликован студией в CMS.',
        ),
      ],
    ),
  ];

  static final demoProjects = [
    StudioProject(
      id: 'example-web',
      title: _ru('Цифровой опыт'),
      category: 'Веб-дизайн',
      description: _ru(
        'Пример карточки проекта. Здесь появятся задача, подход и результат реального кейса из CMS.',
      ),
      serviceIds: const ['web', 'design'],
      visual: 0,
    ),
    StudioProject(
      id: 'example-brand',
      title: _ru('Система и характер'),
      category: 'Айдентика',
      description: _ru(
        'Пример карточки проекта. Галерея, описание и ссылка на сайт будут предоставлены API.',
      ),
      serviceIds: const ['brand'],
      visual: 1,
    ),
    StudioProject(
      id: 'example-product',
      title: _ru('Продукт в деталях'),
      category: 'Интерфейсы',
      description: _ru(
        'Пример карточки проекта. Эти материалы показывают структуру будущего портфолио.',
      ),
      serviceIds: const ['design'],
      visual: 2,
    ),
  ];

  static final demoArticles = [
    StudioArticle(
      id: 'example-start',
      title: _ru('С чего начинается хороший проект'),
      category: 'Процесс',
      paragraphs: const [
        'Это пример экрана статьи, а не публикация студии.',
        'Здесь будет текст из CMS: заголовок, вводная часть, изображения и основной материал. Экран уже поддерживает комфортное чтение на телефоне.',
        'После подключения API демонстрационные материалы заменятся актуальными публикациями.',
      ],
    ),
    StudioArticle(
      id: 'example-details',
      title: _ru('Внимание к деталям'),
      category: 'Дизайн',
      paragraphs: const [
        'Это демонстрационная статья для проверки структуры приложения.',
        'Реальные тексты и метаданные будут приходить из той же CMS, что и на сайт.',
      ],
    ),
  ];

  @override
  Future<ContentPage<StudioService>> getServices(ContentLocale locale) async {
    return ContentPage(demoServices);
  }

  @override
  Future<StudioService> getService(String slug, ContentLocale locale) async {
    for (final service in demoServices) {
      if (service.id == slug) return service;
    }
    throw const AppException('Услуга не найдена.');
  }

  @override
  Future<ContentPage<StudioProject>> getProjects(
    ContentLocale locale, {
    String query = '',
    int page = 1,
    bool? featured,
  }) async {
    _checkPage(page);
    if (page > 1) return const ContentPage([]);
    final normalized = query.trim().toLowerCase();
    final projects = <StudioProject>[];
    for (final project in demoProjects) {
      final title = project.title.resolve(locale);
      final searchableText = '$title ${project.category}'.toLowerCase();
      if (searchableText.contains(normalized)) projects.add(project);
    }
    return ContentPage(projects);
  }

  @override
  Future<StudioProject> getProject(String slug, ContentLocale locale) async {
    for (final project in demoProjects) {
      if (project.slug == slug) return project;
    }
    throw const AppException('Проект не найден.');
  }

  @override
  Future<ContentPage<StudioArticle>> getArticles(
    ContentLocale locale, {
    int page = 1,
  }) async {
    _checkPage(page);
    if (page > 1) return const ContentPage([]);
    return ContentPage(demoArticles);
  }

  @override
  Future<StudioArticle> getArticle(String slug, ContentLocale locale) async {
    for (final article in demoArticles) {
      if (article.slug == slug) return article;
    }
    throw const AppException('Статья не найдена.');
  }

  @override
  Future<StudioContact> getContacts(ContentLocale locale) async {
    return const StudioContact();
  }

  @override
  Future<BriefOptions> getBriefOptions(ContentLocale locale) async {
    return const BriefOptions(
      serviceOptions: [
        'Сайт',
        'Интернет-магазин',
        'Веб-сервис',
        'Интеграция',
        'Автоматизация',
        'AI',
      ],
    );
  }

  @override
  Future<BriefReceipt> sendBrief(
    BriefDraft draft, {
    required String idempotencyKey,
  }) async {
    throw const AppException(
      'API ещё не подключён. Заявка не отправлена; введённые данные сохранены на этом экране.',
    );
  }

  void _checkPage(int page) {
    if (page < 1 || page > 100000) {
      throw const AppException('Номер страницы должен быть от 1 до 100000.');
    }
  }
}
