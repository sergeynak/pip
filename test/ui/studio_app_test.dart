import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:pip/api/api_service.dart';
import 'package:pip/api/demo_api_service.dart';
import 'package:pip/app.dart';
import 'package:pip/models.dart';

void main() {
  // Проверяем экраны на поддельном API: тесты не отправляют реальные заявки.
  testWidgets('narrow layout supports enlarged text without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(PipApp(api: DemoApiService()));
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

  testWidgets('required field validation stops a api call', (tester) async {
    final api = _RecordingApi();
    await _launch(tester, api: api);
    await _openBrief(tester);
    await _submit(tester);
    expect(api.keys, isEmpty);
    expect(find.text('Имя: от 2 до 100 символов'), findsOneWidget);
  });

  testWidgets(
    'retry after cursor movement reuses key; changed payload gets a new key',
    (tester) async {
      final api = _RecordingApi();
      await _launch(tester, api: api);
      await _openBrief(tester);
      await _fillBrief(tester);
      await _submit(tester);

      final description = tester
          .widget<TextFormField>(find.byKey(const Key('brief-description')))
          .controller!;
      description.selection = const TextSelection.collapsed(offset: 3);
      await tester.pumpAndSettle();
      await _submit(tester);
      expect(api.keys, hasLength(2));
      expect(api.keys[1], api.keys[0]);

      await tester.enterText(
        find.byKey(const Key('brief-description')),
        'Новая задача: нужен сайт и дизайн интерфейса.',
      );
      await _submit(tester);
      expect(api.keys, hasLength(3));
      expect(api.keys[2], isNot(api.keys[0]));
      expect(find.text('Заявка\nотправлена.'), findsNothing);
    },
  );

  testWidgets('only a successful api response opens confirmation', (
    tester,
  ) async {
    final api = _RecordingApi(accept: true);
    await _launch(tester, api: api);
    await _openBrief(tester);
    await _fillBrief(tester);
    await _submit(tester);
    expect(api.keys, hasLength(1));
    expect(find.text('Заявка\nотправлена.'), findsOneWidget);
    expect(find.text('Номер заявки: receipt-1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('config options are submitted exactly and message is optional', (
    tester,
  ) async {
    final api = _RecordingApi(accept: true);
    await _launch(tester, api: api);
    await _openBrief(tester);
    await tester.enterText(find.byKey(const Key('brief-name')), 'Тест');
    await tester.enterText(find.byKey(const Key('brief-contact')), 'abc');
    await tester.ensureVisible(find.text('Сайт'));
    await tester.tap(find.text('Сайт'));
    await _submit(tester);
    expect(api.drafts.single.services, ['Сайт']);
    expect(api.drafts.single.description, '');
    expect(find.text('Заявка\nотправлена.'), findsOneWidget);
  });

  testWidgets('429 blocks retry until countdown and retains the request key', (
    tester,
  ) async {
    final api = _RateLimitApi();
    await _launch(tester, api: api);
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
    expect(api.keys, hasLength(1));
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('brief-submit')))
          .onPressed,
      isNotNull,
    );
    await _submit(tester);
    expect(api.keys, hasLength(2));
    expect(api.keys[0], api.keys[1]);
    expect(find.text('Заявка\nотправлена.'), findsOneWidget);
  });

  testWidgets('opening a card fetches full details; 404 can be retried', (
    tester,
  ) async {
    final api = _DetailApi();
    await _launch(tester, api: api);
    await _selectTab(tester, 'Услуги');
    await tester.tap(find.text('Сайты и веб-сервисы'));
    await tester.pumpAndSettle();
    expect(api.serviceSlugs, ['web']);
    expect(find.text('Полное описание услуги из detail'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await _selectTab(tester, 'Портфолио');
    await tester.tap(find.text('Цифровой опыт'));
    await tester.pumpAndSettle();
    expect(find.text('Материал недоступен'), findsOneWidget);
    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();
    expect(api.projectSlugs, ['example-web', 'example-web']);
    expect(find.text('Полный текст проекта из detail'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await _selectTab(tester, 'Блог');
    await tester.tap(find.text('С чего начинается хороший проект'));
    await tester.pumpAndSettle();
    expect(api.articleSlugs, ['example-start']);
    expect(find.text('Полный текст статьи из detail'), findsOneWidget);
  });

  testWidgets('late search responses never replace the latest query', (
    tester,
  ) async {
    final api = _DelayedSearchApi();
    await _launch(tester, api: api);
    await _selectTab(tester, 'Портфолио');
    await tester.enterText(find.byType(TextField), 'old');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.enterText(find.byType(TextField), 'new');
    await tester.pump(const Duration(milliseconds: 350));
    api.newResult.complete(ContentPage([DemoApiService.demoProjects[1]]));
    await tester.pumpAndSettle();
    api.oldResult.complete(ContentPage([DemoApiService.demoProjects[0]]));
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

Future<void> _launch(WidgetTester tester, {ApiService? api}) async {
  tester.view.physicalSize = const Size(430, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(PipApp(api: api ?? DemoApiService()));
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

class _RecordingApi extends DemoApiService {
  _RecordingApi({this.accept = false});
  final bool accept;
  final List<String> keys = [];
  final List<BriefDraft> drafts = [];

  @override
  Future<BriefOptions> getBriefOptions(ContentLocale locale) async =>
      const BriefOptions(serviceOptions: ['Сайт', 'UI / UX']);

  @override
  bool get isDemo => false;

  @override
  Future<BriefReceipt> sendBrief(
    BriefDraft draft, {
    required String idempotencyKey,
  }) async {
    keys.add(idempotencyKey);
    drafts.add(draft);
    if (!accept) {
      throw const AppException('Временная ошибка. Повторите отправку.');
    }
    return const BriefReceipt(id: 'receipt-1');
  }
}

class _RateLimitApi extends _RecordingApi {
  @override
  Future<BriefReceipt> sendBrief(
    BriefDraft draft, {
    required String idempotencyKey,
  }) async {
    keys.add(idempotencyKey);
    if (keys.length == 1) {
      throw const AppException(
        'Слишком много запросов.',
        statusCode: 429,
        code: 'RATE_LIMITED',
        retryAfter: Duration(seconds: 3),
      );
    }
    return const BriefReceipt(id: 'receipt-429');
  }
}

class _DetailApi extends DemoApiService {
  final serviceSlugs = <String>[];
  final projectSlugs = <String>[];
  final articleSlugs = <String>[];
  @override
  bool get isDemo => false;
  @override
  Future<StudioService> getService(String slug, ContentLocale locale) async {
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
  Future<StudioProject> getProject(String slug, ContentLocale locale) async {
    projectSlugs.add(slug);
    if (projectSlugs.length == 1) {
      throw const AppException('Удалено', statusCode: 404);
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
  Future<StudioArticle> getArticle(String slug, ContentLocale locale) async {
    articleSlugs.add(slug);
    return const StudioArticle(
      id: 'example-start',
      title: LocalizedText({ContentLocale.ru: 'Статья'}),
      category: 'Процесс',
      paragraphs: ['Полный текст статьи из detail'],
    );
  }
}

class _DelayedSearchApi extends DemoApiService {
  final oldResult = Completer<ContentPage<StudioProject>>();
  final newResult = Completer<ContentPage<StudioProject>>();
  @override
  Future<ContentPage<StudioProject>> getProjects(
    ContentLocale locale, {
    String query = '',
    int page = 1,
    bool? featured,
  }) {
    if (query == 'old') return oldResult.future;
    if (query == 'new') return newResult.future;
    return super.getProjects(
      locale,
      query: query,
      page: page,
      featured: featured,
    );
  }
}
