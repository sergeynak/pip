import 'package:flutter/material.dart';

import '../data/demo_data.dart';
import '../models.dart';
import '../widgets/brief_callout.dart';
import '../widgets/common_widgets.dart';
import '../widgets/service_card.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key, required this.data});
  final DemoData data;
  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  late Future<ContentPage<StudioService>> _servicesFuture;
  @override
  void initState() {
    super.initState();
    // Сохраняем Future, чтобы перерисовка не запускала повторное чтение данных.
    _servicesFuture = widget.data.getServices(contentLocale);
  }

  @override
  Widget build(BuildContext context) => PageBody(
    onRefresh: () async {
      setState(() {
        _servicesFuture = widget.data.getServices(contentLocale);
      });
      try {
        await _servicesFuture;
      } catch (_) {
        /* Ошибку покажет виджет AsyncContent. */
      }
    },
    children: [
      const PageHeading(
        number: '01',
        title: 'Услуги\nи возможности.',
        subtitle: 'Выберите направление — вместе найдём подход к вашей задаче.',
      ),
      if (widget.data.isDemo)
        const Padding(
          padding: EdgeInsets.only(bottom: 20),
          child: Text(
            'Услуги и цены приведены для примера.',
            style: TextStyle(fontSize: 12, color: PipColors.muted, height: 1.5),
          ),
        ),
      AsyncContent(
        future: _servicesFuture,
        onRetry: () => setState(() {
          _servicesFuture = widget.data.getServices(contentLocale);
        }),
        builder: (page) => Column(
          children: [
            if (page.items.isEmpty)
              const EmptyContent(
                'Пока нет услуг',
                'Добавленные направления будут доступны здесь.',
              ),
            for (final (index, service) in page.items.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: ServiceCard(
                  service: service,
                  index: index,
                  data: widget.data,
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      BriefCallout(data: widget.data),
    ],
  );
}
