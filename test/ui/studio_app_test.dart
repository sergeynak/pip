import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pip/app.dart';
import 'package:pip/data/demo_data.dart';
import 'package:pip/models.dart';
import 'package:pip/widgets/common_widgets.dart';

void main() {
  // Все проверки используют локальные примеры, без обращения к серверу.
  testWidgets('узкий экран выдерживает увеличенный текст', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(PipApp(data: DemoData()));
    await tester.pumpAndSettle();

    for (final label in ['Услуги', 'Портфолио', 'Блог', 'Контакты']) {
      await _selectTab(tester, label);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('вкладки и детали открываются, поиск фильтрует примеры', (
    tester,
  ) async {
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
    await tester.tap(find.text('Система и характер'));
    await tester.pumpAndSettle();
    expect(find.text('Пример экрана 1'), findsOneWidget);
    expect(find.text('Пример экрана 2'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

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
    expect(find.text('Пример контакта'), findsNWidgets(2));
    expect(find.text('@pip_example'), findsOneWidget);
    expect(find.text('hello@example.com'), findsOneWidget);
    final emailCard = tester.widget<Panel>(
      find
          .ancestor(
            of: find.text('hello@example.com'),
            matching: find.byType(Panel),
          )
          .first,
    );
    final telegramCard = tester.widget<Panel>(
      find
          .ancestor(of: find.text('@pip_example'), matching: find.byType(Panel))
          .first,
    );
    expect(emailCard.onTap, isNull);
    expect(telegramCard.onTap, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('форма не сообщает об успехе и сохраняет введённый текст', (
    tester,
  ) async {
    await _launch(tester);
    await _openBrief(tester);
    await _fillBrief(tester);
    await _submit(tester);

    expect(find.textContaining('Заявка не отправлена'), findsOneWidget);
    expect(find.text('Заявка\nотправлена.'), findsNothing);
    expect(
      _field(tester, 'brief-contact').controller!.text,
      'client@example.com',
    );
    expect(
      _field(tester, 'brief-description').controller!.text,
      'Нужен сайт для нового проекта.',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('пустые обязательные поля показывают ошибки проверки', (
    tester,
  ) async {
    await _launch(tester);
    await _openBrief(tester);
    await _submit(tester);

    expect(find.text('Имя: от 2 до 100 символов'), findsOneWidget);
    expect(
      find.text('Контакт: от 3 до 200 символов, с буквами или цифрами'),
      findsOneWidget,
    );
    expect(find.textContaining('Заявка не отправлена'), findsNothing);
    expect(find.text('Заявка\nотправлена.'), findsNothing);
  });

  testWidgets('услуги можно выбрать и убрать, описание необязательно', (
    tester,
  ) async {
    await _launch(tester);
    await _openBrief(tester);
    await tester.enterText(find.byKey(const Key('brief-name')), 'Тест');
    await tester.enterText(find.byKey(const Key('brief-contact')), 'abc');

    final siteChip = find.widgetWithText(FilterChip, 'Сайт');
    final integrationChip = find.widgetWithText(FilterChip, 'Интеграция');
    await tester.ensureVisible(siteChip);
    await tester.tap(siteChip);
    await tester.pumpAndSettle();
    expect(tester.widget<FilterChip>(siteChip).selected, isTrue);

    await tester.ensureVisible(integrationChip);
    await tester.tap(integrationChip);
    await tester.pumpAndSettle();
    expect(tester.widget<FilterChip>(integrationChip).selected, isTrue);

    await tester.ensureVisible(siteChip);
    await tester.tap(siteChip);
    await tester.pumpAndSettle();
    expect(tester.widget<FilterChip>(siteChip).selected, isFalse);

    await _submit(tester);
    expect(find.textContaining('Заявка не отправлена'), findsOneWidget);
    expect(_field(tester, 'brief-description').controller!.text, isEmpty);
    expect(tester.widget<FilterChip>(integrationChip).selected, isTrue);
    expect(find.text('Заявка\nотправлена.'), findsNothing);
  });

  testWidgets('детали читают нужный пример, ошибку можно повторить', (
    tester,
  ) async {
    final data = _DetailData();
    await _launch(tester, data: data);
    await _selectTab(tester, 'Услуги');
    await tester.tap(find.text('Сайты и веб-сервисы'));
    await tester.pumpAndSettle();
    expect(data.serviceSlugs, ['web']);
    expect(find.text('Подробное описание примера услуги'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await _selectTab(tester, 'Портфолио');
    await tester.tap(find.text('Цифровой опыт'));
    await tester.pumpAndSettle();
    expect(find.text('Не удалось показать данные'), findsOneWidget);
    expect(find.text('Не удалось открыть пример проекта.'), findsOneWidget);
    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();
    expect(data.projectSlugs, ['example-web', 'example-web']);
    expect(find.text('Полный текст примера проекта'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await _selectTab(tester, 'Блог');
    await tester.tap(find.text('С чего начинается хороший проект'));
    await tester.pumpAndSettle();
    expect(data.articleSlugs, ['example-start']);
    expect(find.text('Полный текст примера статьи'), findsOneWidget);
  });

  testWidgets('запоздалый результат поиска не заменяет новый', (tester) async {
    final data = _DelayedSearchData();
    await _launch(tester, data: data);
    await _selectTab(tester, 'Портфолио');
    await tester.enterText(find.byType(TextField), 'old');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.enterText(find.byType(TextField), 'new');
    await tester.pump(const Duration(milliseconds: 350));

    data.newResult.complete(ContentPage([DemoData.demoProjects[1]]));
    await tester.pumpAndSettle();
    data.oldResult.complete(ContentPage([DemoData.demoProjects[0]]));
    await tester.pumpAndSettle();
    expect(find.text('Система и характер'), findsOneWidget);
    expect(find.text('Цифровой опыт'), findsNothing);
  });

  testWidgets('закрытие заполненной формы требует подтверждения', (
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
    expect(_field(tester, 'brief-name').controller!.text, 'Тест');

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Закрыть'));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}

Future<void> _launch(WidgetTester tester, {DemoData? data}) async {
  tester.view.physicalSize = const Size(430, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(PipApp(data: data ?? DemoData()));
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

TextFormField _field(WidgetTester tester, String key) {
  return tester.widget<TextFormField>(find.byKey(Key(key)));
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

// Локальный источник для проверки повторного открытия подробностей.
class _DetailData extends DemoData {
  final serviceSlugs = <String>[];
  final projectSlugs = <String>[];
  final articleSlugs = <String>[];

  @override
  Future<StudioService> getService(String slug, ContentLocale locale) async {
    serviceSlugs.add(slug);
    return const StudioService(
      id: 'web',
      title: LocalizedText({ContentLocale.ru: 'Сайты'}),
      description: LocalizedText({
        ContentLocale.ru: 'Подробное описание примера услуги',
      }),
      deliverables: [],
      faq: [],
    );
  }

  @override
  Future<StudioProject> getProject(String slug, ContentLocale locale) async {
    projectSlugs.add(slug);
    if (projectSlugs.length == 1) {
      throw const AppException('Не удалось открыть пример проекта.');
    }
    return const StudioProject(
      id: 'example-web',
      title: LocalizedText({ContentLocale.ru: 'Проект'}),
      category: 'Сайт',
      description: LocalizedText({
        ContentLocale.ru: 'Полный текст примера проекта',
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
      paragraphs: ['Полный текст примера статьи'],
    );
  }
}

// Управляем завершением Future, чтобы проверить порядок результатов поиска.
class _DelayedSearchData extends DemoData {
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
