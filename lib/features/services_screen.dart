part of 'studio_screens.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key, required this.repository});
  final StudioRepository repository;
  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  late Future<ContentPage<StudioService>> _future;
  @override
  void initState() {
    super.initState();
    _future = widget.repository.services(_locale);
  }

  @override
  Widget build(BuildContext context) => PageBody(
    onRefresh: () async {
      setState(() {
        _future = widget.repository.services(_locale);
      });
      try {
        await _future;
      } catch (_) {
        /* Rendered by AsyncContent. */
      }
    },
    children: [
      const PageHeading(
        number: '01',
        title: 'Услуги\nи возможности.',
        subtitle: 'Выберите направление — вместе найдём подход к вашей задаче.',
      ),
      if (widget.repository.isDemo)
        const Padding(
          padding: EdgeInsets.only(bottom: 20),
          child: Text(
            'Демонстрационные направления. Цены появятся после подключения CMS.',
            style: TextStyle(fontSize: 12, color: PipColors.muted, height: 1.5),
          ),
        ),
      AsyncContent(
        future: _future,
        onRetry: () => setState(() {
          _future = widget.repository.services(_locale);
        }),
        builder: (page) => Column(
          children: [
            if (page.items.isEmpty)
              const EmptyContent(
                'Пока нет услуг',
                'Каталог появится после публикации в CMS.',
              ),
            for (final (index, service) in page.items.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _ServiceCard(
                  service: service,
                  index: index,
                  repository: widget.repository,
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      _BriefCallout(repository: widget.repository),
    ],
  );
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.service,
    required this.index,
    required this.repository,
    this.compact = false,
  });
  final StudioService service;
  final int index;
  final StudioRepository repository;
  final bool compact;
  @override
  Widget build(BuildContext context) => Panel(
    onTap: () => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ServiceScreen(service: service, repository: repository),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${index + 1}'.padLeft(2, '0'),
              style: const TextStyle(
                color: PipColors.accent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                service.title.resolve(_locale),
                style: TextStyle(
                  fontSize: compact ? 17 : 21,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Icon(
              Icons.north_east_rounded,
              size: 20,
              color: PipColors.muted,
            ),
          ],
        ),
        if (!compact) ...[
          const SizedBox(height: 18),
          Text(
            service.description.resolve(_locale),
            style: const TextStyle(
              color: PipColors.muted,
              fontSize: 13,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            service.startingPrice ?? 'Стоимость появится позже',
            style: TextStyle(
              color: service.startingPrice == null
                  ? PipColors.muted
                  : PipColors.text,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    ),
  );
}

class ServiceScreen extends StatefulWidget {
  const ServiceScreen({
    super.key,
    required this.service,
    required this.repository,
  });
  final StudioService service;
  final StudioRepository repository;
  @override
  State<ServiceScreen> createState() => _ServiceScreenState();
}

class _ServiceScreenState extends State<ServiceScreen> {
  late Future<StudioService> _future;
  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<StudioService> _load() =>
      widget.repository.service(widget.service.id, _locale);
  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    try {
      await _future;
    } catch (_) {
      /* Rendered by AsyncContent. */
    }
  }

  @override
  Widget build(BuildContext context) => DetailScaffold(
    repository: widget.repository,
    title: 'Направление',
    body: PageBody(
      onRefresh: _refresh,
      children: [
        AsyncContent(
          future: _future,
          onRetry: _refresh,
          builder: (service) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Eyebrow(widget.repository.isDemo ? 'ПРИМЕР УСЛУГИ' : 'УСЛУГА'),
              const SizedBox(height: 16),
              Text(
                service.title.resolve(_locale),
                style: const TextStyle(
                  fontSize: 34,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                service.description.resolve(_locale),
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
                  widget.repository,
                  serviceTitle: service.title.resolve(_locale),
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
                    child: _ProjectCard(
                      project: project,
                      repository: widget.repository,
                    ),
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
