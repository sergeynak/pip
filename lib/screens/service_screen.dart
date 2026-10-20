import 'package:flutter/material.dart';

import '../data/demo_data.dart';
import '../models.dart';
import '../widgets/common_widgets.dart';
import '../widgets/project_card.dart';
import 'navigation.dart';

class ServiceScreen extends StatefulWidget {
  const ServiceScreen({super.key, required this.service, required this.data});
  final StudioService service;
  final DemoData data;
  @override
  State<ServiceScreen> createState() => _ServiceScreenState();
}

class _ServiceScreenState extends State<ServiceScreen> {
  late Future<StudioService> _serviceFuture;
  @override
  void initState() {
    super.initState();
    // В каталоге краткая карточка. Здесь читаем полный локальный пример и FAQ.
    _serviceFuture = _loadService();
  }

  Future<StudioService> _loadService() {
    return widget.data.getService(widget.service.id, contentLocale);
  }

  Future<void> _refreshService() async {
    // Этот же метод используется для свайпа вниз и кнопки «Повторить».
    setState(() {
      _serviceFuture = _loadService();
    });
    try {
      await _serviceFuture;
    } catch (_) {
      /* Ошибку покажет виджет AsyncContent. */
    }
  }

  @override
  Widget build(BuildContext context) => DetailScaffold(
    data: widget.data,
    title: 'Направление',
    body: PageBody(
      onRefresh: _refreshService,
      children: [
        AsyncContent(
          future: _serviceFuture,
          onRetry: _refreshService,
          builder: (service) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Eyebrow(widget.data.isDemo ? 'ПРИМЕР УСЛУГИ' : 'УСЛУГА'),
              const SizedBox(height: 16),
              Text(
                service.title.resolve(contentLocale),
                style: const TextStyle(
                  fontSize: 34,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                service.description.resolve(contentLocale),
                style: const TextStyle(
                  color: PipColors.muted,
                  height: 1.7,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 23),
              Text(
                service.startingPrice ?? 'Стоимость пока не опубликована',
                style: const TextStyle(color: PipColors.muted, fontSize: 13),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () => openBrief(
                  context,
                  widget.data,
                  serviceTitle: service.title.resolve(contentLocale),
                ),
                icon: const Icon(Icons.north_east_rounded, size: 18),
                label: const Text('Обсудить эту услугу'),
              ),
              if (service.deliverables.isNotEmpty) ...[
                const SectionHeading('Что входит'),
                Panel(
                  child: Column(
                    children: [
                      for (final (index, item) in service.deliverables.indexed)
                        Padding(
                          padding: EdgeInsets.only(top: index == 0 ? 0 : 20),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.check_rounded,
                                color: PipColors.accent,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item,
                                  style: const TextStyle(height: 1.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              for (final section in service.sections) ...[
                SectionHeading(section.heading),
                Text(
                  section.text,
                  style: const TextStyle(
                    color: PipColors.muted,
                    fontSize: 15,
                    height: 1.7,
                  ),
                ),
              ],
              if (service.projects.isNotEmpty) ...[
                const SectionHeading('Примеры работ'),
                for (final project in service.projects)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: ProjectCard(project: project, data: widget.data),
                  ),
              ],
              if (service.faq.isNotEmpty)
                const SectionHeading('Частые вопросы'),
              for (final faq in service.faq)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Panel(
                    padding: EdgeInsets.zero,
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 5,
                      ),
                      childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      shape: const Border(),
                      collapsedShape: const Border(),
                      title: Text(
                        faq.question,
                        style: const TextStyle(fontSize: 15),
                      ),
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            faq.answer,
                            style: const TextStyle(
                              color: PipColors.muted,
                              height: 1.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}
