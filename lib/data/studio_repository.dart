/// Content languages are independent from the application's Russian interface.
enum ContentLocale { ru, en, kk }

class LocalizedText {
  const LocalizedText(this.values);
  final Map<ContentLocale, String> values;

  String resolve(ContentLocale locale) =>
      values[locale] ??
      values[ContentLocale.ru] ??
      values.values.firstOrNull ??
      '';
}

class StudioService {
  const StudioService({
    required this.id,
    required this.title,
    required this.description,
    required this.deliverables,
    required this.faq,
    this.startingPrice,
    this.sections = const [],
    this.projects = const [],
    this.contentLanguage,
  });
  final String id;
  final LocalizedText title;
  final LocalizedText description;
  final List<String> deliverables;
  final List<({String question, String answer})> faq;
  final String? startingPrice;
  final List<({String heading, String text})> sections;
  final List<StudioProject> projects;
  final String? contentLanguage;
}

class StudioProject {
  const StudioProject({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.serviceIds,
    required this.visual,
    this.imageUrls = const [],
    this.websiteUrl,
    String? slug,
    this.coverUrl,
    this.gallery = const [],
    this.fieldLanguages = const {},
  }) : slug = slug ?? id;
  final String id;
  final String slug;
  final LocalizedText title;
  final String category;
  final LocalizedText description;
  final List<String> serviceIds;
  final int visual;
  final List<Uri> imageUrls;
  final Uri? websiteUrl;
  final Uri? coverUrl;
  final List<ProjectImage> gallery;
  final Map<String, String> fieldLanguages;
}

class ProjectImage {
  const ProjectImage({
    required this.url,
    this.thumbnailUrl,
    this.caption = '',
    this.kind = 'current',
    this.width,
    this.height,
  });
  final Uri url;
  final Uri? thumbnailUrl;
  final String caption;
  final String kind;
  final num? width;
  final num? height;
}

class StudioArticle {
  const StudioArticle({
    required this.id,
    required this.title,
    required this.category,
    required this.paragraphs,
    String? slug,
    this.coverUrl,
    this.publishedAt,
    this.author,
    this.websiteUrl,
    this.fieldLanguages = const {},
  }) : slug = slug ?? id;
  final String id;
  final String slug;
  final LocalizedText title;
  final String category;
  final List<String> paragraphs;
  final Uri? coverUrl;
  final DateTime? publishedAt;
  final String? author;
  final Uri? websiteUrl;
  final Map<String, String> fieldLanguages;
}

class StudioContact {
  const StudioContact({this.telegram, this.email, this.about, this.websiteUrl});
  final Uri? telegram;
  final String? email;
  final LocalizedText? about;
  final Uri? websiteUrl;
}

class BriefOptions {
  const BriefOptions({
    required this.serviceOptions,
    this.nameMin = 2,
    this.nameMax = 100,
    this.contactMin = 3,
    this.contactMax = 200,
    this.messageMax = 5000,
    this.servicesMax = 6,
    this.idempotencyTtlSeconds = 86400,
  });
  final List<String> serviceOptions;
  final int nameMin;
  final int nameMax;
  final int contactMin;
  final int contactMax;
  final int messageMax;
  final int servicesMax;
  final int idempotencyTtlSeconds;
}

class ContentPage<T> {
  const ContentPage(this.items, {this.nextCursor});
  final List<T> items;
  final String? nextCursor;
}

class BriefDraft {
  const BriefDraft({
    required this.name,
    required this.contact,
    required this.serviceIds,
    required this.description,
    required this.locale,
  });
  final String name;
  final String contact;
  final List<String> serviceIds;
  final String description;
  final ContentLocale locale;
}

class BriefReceipt {
  const BriefReceipt({required this.id});
  final String id;
}

class RepositoryException implements Exception {
  const RepositoryException(
    this.message, {
    this.code,
    this.statusCode,
    this.requestId,
    this.retryAfter,
  });
  final String message;
  final String? code;
  final int? statusCode;
  final String? requestId;
  final Duration? retryAfter;
  @override
  String toString() => message;
}

/// Shared interface for the live API and explicitly selected offline examples.
abstract class StudioRepository {
  bool get isDemo;
  Future<ContentPage<StudioService>> services(ContentLocale locale);
  Future<StudioService> service(String slug, ContentLocale locale);
  Future<ContentPage<StudioProject>> projects(
    ContentLocale locale, {
    String query = '',
    String? cursor,
    bool? featured,
  });
  Future<StudioProject> project(String slug, ContentLocale locale);
  Future<ContentPage<StudioArticle>> articles(
    ContentLocale locale, {
    String? cursor,
  });
  Future<StudioArticle> article(String slug, ContentLocale locale);
  Future<StudioContact> contacts(ContentLocale locale);
  Future<BriefOptions> briefOptions(ContentLocale locale);
  Future<BriefReceipt> submitBrief(
    BriefDraft draft, {
    required String idempotencyKey,
  });
}

class DemoStudioRepository implements StudioRepository {
  const DemoStudioRepository();
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
  Future<ContentPage<StudioService>> services(ContentLocale locale) async =>
      ContentPage(demoServices);

  @override
  Future<StudioService> service(String slug, ContentLocale locale) async =>
      demoServices.firstWhere(
        (item) => item.id == slug,
        orElse: () => throw const RepositoryException('Услуга не найдена.'),
      );

  @override
  Future<ContentPage<StudioProject>> projects(
    ContentLocale locale, {
    String query = '',
    String? cursor,
    bool? featured,
  }) async {
    final normalized = query.trim().toLowerCase();
    return ContentPage(
      demoProjects
          .where(
            (p) => '${p.title.resolve(locale)} ${p.category}'
                .toLowerCase()
                .contains(normalized),
          )
          .toList(),
    );
  }

  @override
  Future<StudioProject> project(String slug, ContentLocale locale) async =>
      demoProjects.firstWhere(
        (item) => item.slug == slug,
        orElse: () => throw const RepositoryException('Проект не найден.'),
      );

  @override
  Future<ContentPage<StudioArticle>> articles(
    ContentLocale locale, {
    String? cursor,
  }) async => ContentPage(demoArticles);

  @override
  Future<StudioArticle> article(String slug, ContentLocale locale) async =>
      demoArticles.firstWhere(
        (item) => item.slug == slug,
        orElse: () => throw const RepositoryException('Статья не найдена.'),
      );

  @override
  Future<StudioContact> contacts(ContentLocale locale) async =>
      const StudioContact();

  @override
  Future<BriefOptions> briefOptions(ContentLocale locale) async =>
      const BriefOptions(
        serviceOptions: [
          'Сайт',
          'Интернет-магазин',
          'Веб-сервис',
          'Интеграция',
          'Автоматизация',
          'AI',
        ],
      );

  @override
  Future<BriefReceipt> submitBrief(
    BriefDraft draft, {
    required String idempotencyKey,
  }) async {
    throw const RepositoryException(
      'API ещё не подключён. Заявка не отправлена; введённые данные сохранены на этом экране.',
    );
  }
}
