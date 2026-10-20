import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pip/main.dart' as app;

void main() {
  testWidgets(
    'обычный запуск показывает локальный макет и не отправляет заявку',
    (tester) async {
      tester.view.physicalSize = const Size(430, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Проверяем обычный запуск с DemoData из main, без подмены приложения.
      app.main();
      await tester.pumpAndSettle();
      expect(find.text('Макет · API не подключён'), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Услуги'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Сайты и веб-сервисы'), findsOneWidget);
      expect(find.text('Пример: от 150 000 ₸'), findsOneWidget);

      await tester.tap(find.byTooltip('Обсудить проект'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('brief-name')), 'Тест');
      await tester.enterText(
        find.byKey(const Key('brief-contact')),
        'hello@example.com',
      );
      final pageScroll = find
          .descendant(
            of: find.byType(ListView).last,
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.byKey(const Key('brief-submit')),
        200,
        scrollable: pageScroll,
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('brief-submit')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('brief-submit')));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('API ещё не подключён. Заявка не отправлена'),
        findsOneWidget,
      );
      expect(find.text('Заявка\nотправлена.'), findsNothing);
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('brief-contact')))
            .controller!
            .text,
        'hello@example.com',
      );
      expect(tester.takeException(), isNull);
    },
  );
}
