part of 'studio_screens.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key, required this.repository});
  final StudioRepository repository;
  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  final _search = TextEditingController();
  late Future<ContentPage<StudioProject>> _future;
  final List<StudioProject> _additional = [];
  final Set<String> _knownIds = {};
  bool _loadingMore = false;
  String? _paginationError;
  String? _nextCursor;
  int _generation = 0;
  Timer? _debounce;
  bool _waitingSearch = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<ContentPage<StudioProject>> _load() async {
    final generation = ++_generation;
    final page = await widget.repository.projects(_locale, query: _search.text);
    if (generation == _generation) {
      _nextCursor = page.nextCursor;
      _knownIds
        ..clear()
        ..addAll(page.items.map((item) => item.id));
    }
    return page;
  }

  void _searchChanged(String query) {
    _debounce?.cancel();
    _generation++;
    setState(() {
      _waitingSearch = true;
      _loadingMore = false;
      _nextCursor = null;
    });
    _debounce = Timer(const Duration(milliseconds: 300), _refresh);
  }

  Future<void> _refresh() async {
    _debounce?.cancel();
    setState(() {
      _additional.clear();
      _nextCursor = null;
      _paginationError = null;
      _loadingMore = false;
      _waitingSearch = false;
      _future = _load();
    });
    try {
      await _future;
    } catch (_) {
      /* Rendered by AsyncContent. */
    }
  }

  Future<void> _loadMore() async {
    final generation = _generation;
    setState(() {
      _loadingMore = true;
      _paginationError = null;
    });
    try {
      final page = await widget.repository.projects(
        _locale,
        query: _search.text,
        cursor: _nextCursor,
      );
      if (!mounted || generation != _generation) return;
      setState(() {
        _additional.addAll(page.items.where((item) => _knownIds.add(item.id)));
        _nextCursor = page.nextCursor;
      });
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(
          () => _paginationError = 'Не удалось загрузить следующую страницу.',
        );
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loadingMore = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => PageBody(
    onRefresh: _refresh,
    children: [
      const PageHeading(
        number: '02',
        title: 'Работы\nс характером.',
        subtitle: 'Идеи, воплощённые в интерфейсах и визуальных системах.',
      ),
      TextField(
        controller: _search,
        maxLength: 100,
        onChanged: _searchChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Поиск проектов',
          prefixIcon: const Icon(Icons.search_rounded, color: PipColors.muted),
          suffixIcon: _search.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Очистить поиск',
                  onPressed: () {
                    _search.clear();
                    _searchChanged('');
                  },
                  icon: const Icon(Icons.close_rounded),
                ),
        ),
      ),
      const SizedBox(height: 22),
      if (widget.repository.isDemo)
        const Padding(
          padding: EdgeInsets.only(bottom: 14),
          child: Text(
            'Ниже — демонстрационные проекты.',
            style: TextStyle(color: PipColors.muted, fontSize: 12),
          ),
        ),
      if (_waitingSearch)
        const Padding(
          padding: EdgeInsets.all(36),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        )
      else
        AsyncContent(
          future: _future,
          onRetry: _refresh,
          builder: (page) => Column(
            children: [
              if (page.items.isEmpty)
                EmptyContent(
                  'Ничего не найдено',
                  _search.text.trim().isEmpty
                      ? 'Опубликованные проекты появятся здесь.'
                      : 'Попробуйте другое название или направление.',
                ),
              for (final project in [...page.items, ..._additional])
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _ProjectCard(
                    project: project,
                    repository: widget.repository,
                  ),
                ),
              if (_paginationError != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _paginationError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              if (_nextCursor != null)
                OutlinedButton(
                  onPressed: _loadingMore ? null : _loadMore,
                  child: Text(_loadingMore ? 'Загружаем…' : 'Загрузить ещё'),
                ),
            ],
          ),
        ),
    ],
  );
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.project, required this.repository});
  final StudioProject project;
  final StudioRepository repository;
  @override
  Widget build(BuildContext context) => Panel(
    padding: EdgeInsets.zero,
    onTap: () => _openProject(context, repository, project),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 205,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ProjectArtwork(
                variant: project.visual,
                imageUrl: project.coverUrl,
                demo: repository.isDemo,
              ),
              if (repository.isDemo)
                const Positioned(left: 14, top: 14, child: ExampleTag()),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(19),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.category,
                      style: const TextStyle(
                        color: PipColors.muted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      project.title.resolve(_locale),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.north_east_rounded,
                color: PipColors.muted,
                size: 21,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class ProjectScreen extends StatefulWidget {
  const ProjectScreen({
    super.key,
    required this.project,
    required this.repository,
  });
  final StudioProject project;
  final StudioRepository repository;
  @override
  State<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen> {
  late Future<StudioProject> _future;
  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<StudioProject> _load() =>
      widget.repository.project(widget.project.slug, _locale);
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
    title: 'Проект',
    body: PageBody(
      onRefresh: _refresh,
      children: [
        AsyncContent(
          future: _future,
          onRetry: _refresh,
          builder: (project) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Eyebrow(project.category.toUpperCase()),
              const SizedBox(height: 16),
              Text(
                project.title.resolve(_locale),
                style: const TextStyle(
                  fontSize: 36,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 24),
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: SizedBox(
                  height: 260,
                  width: double.infinity,
                  child: ProjectArtwork(
                    variant: project.visual,
                    imageUrl: project.coverUrl,
                    demo: widget.repository.isDemo,
                  ),
                ),
              ),
              const SectionHeading('О проекте'),
              SelectableText(
                project.description.resolve(_locale),
                style: const TextStyle(
                  color: PipColors.muted,
                  height: 1.8,
                  fontSize: 15,
                ),
              ),
              const SectionHeading('Галерея'),
              if (project.gallery.isEmpty)
                const EmptyContent(
                  'Нет изображений',
                  'Галерея этого проекта пока не опубликована.',
                ),
              for (final image in project.gallery) GalleryImage(image: image),
              const SizedBox(height: 18),
              if (project.websiteUrl != null)
                OutlinedButton.icon(
                  onPressed: () => openExternal(context, project.websiteUrl!),
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('Открыть сайт'),
                )
              else
                const Text(
                  'Ссылка на сайт пока не опубликована.',
                  style: TextStyle(color: PipColors.muted, fontSize: 12),
                ),
              const SizedBox(height: 30),
              _BriefCallout(repository: widget.repository),
            ],
          ),
        ),
      ],
    ),
  );
}
