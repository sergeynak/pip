import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pip/app/pip_app.dart';
import 'package:pip/data/studio_repository.dart';

void main() {
  testWidgets('narrow layout supports enlarged text without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const PipApp());
    await tester.pumpAndSettle();
    for (final label in ['Услуги', 'Портфолио', 'Блог', 'Контакты']) {
      await _selectTab(tester, label);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
    'five destinations navigate and portfolio search filters projects',
    (tester) async {
      await _launch(tester);
      expect(find.text('Макет · API не подключён'), findsOneWidget);

      await _selectTab(tester, 'Услуги');
      expect(find.text('Услуги\nи возможности.'), findsOneWidget);
      await tester.tap(find.text('Сайты и веб-сервисы'));
      await tester.pumpAndSettle();
      expect(find.text('Что входит'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      await _selectTab(tester, 'Портфолио');
      await tester.enterText(find.byType(TextField), 'Айдентика');
      await tester.pumpAndSettle();
      expect(find.text('Система и характер'), findsOneWidget);
      expect(find.text('Цифровой опыт'), findsNothing);

      await tester.enterText(find.byType(TextField), 'нет такого проекта');
      await tester.pumpAndSettle();
      expect(find.text('Ничего не найдено'), findsOneWidget);

      await _selectTab(tester, 'Блог');
      await tester.tap(find.text('С чего начинается хороший проект'));
      await tester.pumpAndSettle();
      expect(find.text('Демонстрационный материал'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      await _selectTab(tester, 'Контакты');
      expect(find.text('Контакт пока не опубликован'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'demo never claims submission success and preserves entered draft',
    (tester) async {
      await _launch(tester);
      await _openBrief(tester);
      await _fillBrief(tester);
      await _submit(tester);
      expect(find.textContaining('Заявка не отправлена'), findsOneWidget);
      expect(find.text('Заявка\nотправлена.'), findsNothing);
      final contact = tester.widget<TextFormField>(
        find.byKey(const Key('brief-contact')),
      );
      expect(contact.controller!.text, 'client@example.com');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('required field validation stops a repository call', (
    tester,
  ) async {
    final repository = _RecordingRepository();
    await _launch(tester, repository: repository);
    await _openBrief(tester);
    await _submit(tester);
    expect(repository.keys, isEmpty);
    expect(find.text('Имя: от 2 до 100 символов'), findsOneWidget);
  });

  testWidgets(
    'retry after cursor movement reuses key; changed payload gets a new key',
    (tester) async {
      final repository = _RecordingRepository();
      await _launch(tester, repository: repository);
      await _openBrief(tester);
      await _fillBrief(tester);
      await _submit(tester);

      final description = tester
          .widget<TextFormField>(find.byKey(const Key('brief-description')))
          .controller!;
      description.selection = const TextSelection.collapsed(offset: 3);
      await tester.pumpAndSettle();
      await _submit(tester);
      expect(repository.keys, hasLength(2));
      expect(repository.keys[1], repository.keys[0]);

      await tester.enterText(
        find.byKey(const Key('brief-description')),
        'Новая задача: нужен сайт и дизайн интерфейса.',
      );
      await _submit(tester);
      expect(repository.keys, hasLength(3));
      expect(repository.keys[2], isNot(repository.keys[0]));
      expect(find.text('Заявка\nотправлена.'), findsNothing);
    },
  );

  testWidgets('only a successful repository response opens confirmation', (
    tester,
  ) async {
    final repository = _RecordingRepository(accept: true);
    await _launch(tester, repository: repository);
    await _openBrief(tester);
    await _fillBrief(tester);
    await _submit(tester);
    expect(repository.keys, hasLength(1));
    expect(find.text('Заявка\nотправлена.'), findsOneWidget);
    expect(find.text('Номер заявки: receipt-1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('config options are submitted exactly and message is optional', (
    tester,
  ) async {
    final repository = _RecordingRepository(accept: true);
    await _launch(tester, repository: repository);
    await _openBrief(tester);
    await tester.enterText(find.byKey(const Key('brief-name')), 'Тест');
    await tester.enterText(find.byKey(const Key('brief-contact')), 'abc');
    await tester.ensureVisible(find.text('Сайт'));
    await tester.tap(find.text('Сайт'));
    await _submit(tester);
    expect(repository.drafts.single.serviceIds, ['Сайт']);
    expect(repository.drafts.single.description, '');
    expect(find.text('Заявка\nотправлена.'), findsOneWidget);
  });

  testWidgets('429 blocks retry until countdown and retains the request key', (
    tester,
  ) async {
    final repository = _RateLimitRepository();
    await _launch(tester, repository: repository);
    await _openBrief(tester);
    await _fillBrief(tester);
    await _submit(tester);
    expect(find.byKey(const Key('brief-cooldown')), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('brief-submit')))
          .onPressed,
      isNull,
    );
    expect(repository.keys, hasLength(1));
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('brief-submit')))
          .onPressed,
      isNotNull,
    );
    await _submit(tester);
    expect(repository.keys, hasLength(2));
    expect(repository.keys[0], repository.keys[1]);
    expect(find.text('Заявка\nотправлена.'), findsOneWidget);
  });

  testWidgets('opening a card fetches full details; 404 can be retried', (
    tester,
  ) async {
    final repository = _DetailRepository();
    await _launch(tester, repository: repository);
    await _selectTab(tester, 'Услуги');
    await tester.tap(find.text('Сайты и веб-сервисы'));
    await tester.pumpAndSettle();
    expect(repository.serviceSlugs, ['web']);
    expect(find.text('Полное описание услуги из detail'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await _selectTab(tester, 'Портфолио');
    await tester.tap(find.text('Цифровой опыт'));
    await tester.pumpAndSettle();
    expect(find.text('Материал недоступен'), findsOneWidget);
    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();
    expect(repository.projectSlugs, ['example-web', 'example-web']);
    expect(find.text('Полный текст проекта из detail'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await _selectTab(tester, 'Блог');
    await tester.tap(find.text('С чего начинается хороший проект'));
    await tester.pumpAndSettle();
    expect(repository.articleSlugs, ['example-start']);
    expect(find.text('Полный текст статьи из detail'), findsOneWidget);
  });

  testWidgets('late search responses never replace the latest query', (
    tester,
  ) async {
    final repository = _DelayedSearchRepository();
    await _launch(tester, repository: repository);
    await _selectTab(tester, 'Портфолио');
    await tester.enterText(find.byType(TextField), 'old');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.enterText(find.byType(TextField), 'new');
    await tester.pump(const Duration(milliseconds: 350));
    repository.newResult.complete(
      ContentPage([DemoStudioRepository.demoProjects[1]]),
    );
    await tester.pumpAndSettle();
    repository.oldResult.complete(
      ContentPage([DemoStudioRepository.demoProjects[0]]),
    );
    await tester.pumpAndSettle();
    expect(find.text('Система и характер'), findsOneWidget);
    expect(find.text('Цифровой опыт'), findsNothing);
  });

  testWidgets('leaving a nonempty form asks before discarding it', (
    tester,
  ) async {
    await _launch(tester);
    await _openBrief(tester);
    await tester.enterText(find.byKey(const Key('brief-name')), 'Тест');
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Закрыть заявку?'), findsOneWidget);
    await tester.tap(find.text('Продолжить'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('brief-name')))
          .controller!
          .text,
      'Тест',
    );
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Закрыть'));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}

Future<void> _launch(
  WidgetTester tester, {
  StudioRepository repository = const DemoStudioRepository(),
}) async {
  tester.view.physicalSize = const Size(430, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(PipApp(repository: repository));
  await tester.pumpAndSettle();
}

Future<void> _selectTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

Future<void> _openBrief(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Обсудить проект'));
  await tester.pumpAndSettle();
}

Future<void> _fillBrief(WidgetTester tester) async {
  await tester.enterText(find.byKey(const Key('brief-name')), 'Тест');
  await tester.enterText(
    find.byKey(const Key('brief-contact')),
    'client@example.com',
  );
  await tester.scrollUntilVisible(
    find.byKey(const Key('brief-description')),
    200,
    scrollable: _pageScrollable(),
  );
  await tester.enterText(
    find.byKey(const Key('brief-description')),
    'Нужен сайт для нового проекта.',
  );
  await tester.pumpAndSettle();
}

Future<void> _submit(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    find.byKey(const Key('brief-submit')),
    200,
    scrollable: _pageScrollable(),
  );
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.byKey(const Key('brief-submit')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('brief-submit')));
  await tester.pumpAndSettle();
}

Finder _pageScrollable() => find
    .descendant(
      of: find.byType(ListView).last,
      matching: find.byType(Scrollable),
    )
    .first;

class _RecordingRepository extends DemoStudioRepository {
  _RecordingRepository({this.accept = false});
  final bool accept;
  final List<String> keys = [];
  final List<BriefDraft> drafts = [];

  @override
  Future<BriefOptions> briefOptions(ContentLocale locale) async =>
      const BriefOptions(serviceOptions: ['Сайт', 'UI / UX']);

  @override
  bool get isDemo => false;

  @override
  Future<BriefReceipt> submitBrief(
    BriefDraft draft, {
    required String idempotencyKey,
  }) async {
    keys.add(idempotencyKey);
    drafts.add(draft);
    if (!accept) {
      throw const RepositoryException('Временная ошибка. Повторите отправку.');
    }
    return const BriefReceipt(id: 'receipt-1');
  }
}

class _RateLimitRepository extends _RecordingRepository {
  @override
  Future<BriefReceipt> submitBrief(
    BriefDraft draft, {
    required String idempotencyKey,
  }) async {
    keys.add(idempotencyKey);
    if (keys.length == 1) {
      throw const RepositoryException(
        'Слишком много запросов.',
        statusCode: 429,
        code: 'RATE_LIMITED',
        retryAfter: Duration(seconds: 3),
      );
    }
    return const BriefReceipt(id: 'receipt-429');
  }
}

class _DetailRepository extends DemoStudioRepository {
  final serviceSlugs = <String>[];
  final projectSlugs = <String>[];
  final articleSlugs = <String>[];
  @override
  bool get isDemo => false;
  @override
  Future<StudioService> service(String slug, ContentLocale locale) async {
    serviceSlugs.add(slug);
    return const StudioService(
      id: 'web',
      title: LocalizedText({ContentLocale.ru: 'Сайты'}),
      description: LocalizedText({
        ContentLocale.ru: 'Полное описание услуги из detail',
      }),
      deliverables: [],
      faq: [],
    );
  }

  @override
  Future<StudioProject> project(String slug, ContentLocale locale) async {
    projectSlugs.add(slug);
    if (projectSlugs.length == 1) {
      throw const RepositoryException('Удалено', statusCode: 404);
    }
    return const StudioProject(
      id: 'example-web',
      title: LocalizedText({ContentLocale.ru: 'Проект'}),
      category: 'Сайт',
      description: LocalizedText({
        ContentLocale.ru: 'Полный текст проекта из detail',
      }),
      serviceIds: [],
      visual: 0,
    );
  }

  @override
  Future<StudioArticle> article(String slug, ContentLocale locale) async {
    articleSlugs.add(slug);
    return const StudioArticle(
      id: 'example-start',
      title: LocalizedText({ContentLocale.ru: 'Статья'}),
      category: 'Процесс',
      paragraphs: ['Полный текст статьи из detail'],
    );
  }
}

class _DelayedSearchRepository extends DemoStudioRepository {
  final oldResult = Completer<ContentPage<StudioProject>>();
  final newResult = Completer<ContentPage<StudioProject>>();
  @override
  Future<ContentPage<StudioProject>> projects(
    ContentLocale locale, {
    String query = '',
    String? cursor,
    bool? featured,
  }) {
    if (query == 'old') return oldResult.future;
    if (query == 'new') return newResult.future;
    return super.projects(
      locale,
      query: query,
      cursor: cursor,
      featured: featured,
    );
  }
}
