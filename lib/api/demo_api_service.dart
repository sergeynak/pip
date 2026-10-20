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
        'Пример направления: от первого экрана до удобного цифрового продукта. Показываем, как будет выглядеть описание услуги.',
      ),
      startingPrice: 'Пример: от 150 000 ₸',
      sections: const [
        (
          heading: 'От идеи до запуска',
          text:
              'В этом примере работа делится на три этапа: обсуждение задачи, создание интерфейса и подготовка к запуску.',
        ),
      ],
      projects: [demoProjects[0]],
      deliverables: const [
        'Структура и пользовательские сценарии',
        'Дизайн интерфейса',
        'Разработка и запуск',
      ],
      faq: const [
        (
          question: 'Как формируется стоимость?',
          answer:
              'В демонстрационном примере цена зависит от числа страниц и сложности функций. Указанная сумма нужна только для макета.',
        ),
      ],
    ),
    StudioService(
      id: 'design',
      title: _ru('Дизайн интерфейсов'),
      description: _ru(
        'Пример направления: понятные интерфейсы для повседневных задач. Это демонстрационное наполнение каркаса.',
      ),
      startingPrice: 'Пример: от 80 000 ₸',
      projects: [demoProjects[2]],
      deliverables: const [
        'Исследование задачи',
        'Прототипирование',
        'Визуальная система',
      ],
      faq: const [
        (
          question: 'Что нужно для начала?',
          answer:
              'Для примера: краткое описание задачи, пожелания к интерфейсу и несколько визуальных ориентиров.',
        ),
      ],
    ),
    StudioService(
      id: 'brand',
      title: _ru('Айдентика'),
      description: _ru(
        'Пример направления: визуальный язык бренда — цвета, типографика и узнаваемые графические элементы.',
      ),
      startingPrice: 'Пример: от 100 000 ₸',
      projects: [demoProjects[1]],
      deliverables: const [
        'Визуальная концепция',
        'Основные носители',
        'Рекомендации по использованию',
      ],
      faq: const [
        (
          question: 'Что входит в результат?',
          answer:
              'В этом примере результат включает визуальную концепцию и рекомендации по её применению.',
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
        'Демонстрационный проект о простом и понятном интерфейсе. Задача примера — показать структуру кейса: идею, визуальное решение и галерею экранов.',
      ),
      serviceIds: const ['web', 'design'],
      visual: 0,
    ),
    StudioProject(
      id: 'example-brand',
      title: _ru('Система и характер'),
      category: 'Айдентика',
      description: _ru(
        'Демонстрационный проект о визуальном характере бренда. Тёплая палитра, крупная типографика и единый подход к оформлению объединяют элементы этой концепции.',
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
    return StudioContact(
      email: 'hello@example.com',
      about: _ru(
        'Пример описания студии. Здесь можно рассказать о команде, подходе к дизайну и разработке. Все материалы на этом экране показывают будущую верстку.',
      ),
    );
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
      code: 'API_NOT_CONNECTED',
    );
  }

  void _checkPage(int page) {
    if (page < 1 || page > 100000) {
      throw const AppException('Номер страницы должен быть от 1 до 100000.');
    }
  }
}
