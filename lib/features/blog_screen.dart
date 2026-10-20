part of 'studio_screens.dart';

class BlogScreen extends StatefulWidget {
  const BlogScreen({super.key, required this.repository});
  final StudioRepository repository;
  @override
  State<BlogScreen> createState() => _BlogScreenState();
}

class _BlogScreenState extends State<BlogScreen> {
  late Future<ContentPage<StudioArticle>> _future;
  final List<StudioArticle> _additional = [];
  final Set<String> _knownIds = {};
  String? _nextCursor;
  bool _loadingMore = false;
  String? _paginationError;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<ContentPage<StudioArticle>> _load() async {
    final generation = ++_generation;
    final page = await widget.repository.articles(_locale);
    if (generation != _generation) return page;
    _nextCursor = page.nextCursor;
    _knownIds
      ..clear()
      ..addAll(page.items.map((item) => item.id));
    return page;
  }

  Future<void> _loadMore() async {
    final generation = _generation;
    setState(() {
      _loadingMore = true;
      _paginationError = null;
    });
    try {
      final page = await widget.repository.articles(
        _locale,
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

  Future<void> _refresh() async {
    setState(() {
      _additional.clear();
      _nextCursor = null;
      _paginationError = null;
      _loadingMore = false;
      _future = _load();
    });
    try {
      await _future;
    } catch (_) {
      /* Rendered by AsyncContent. */
    }
  }

  @override
  Widget build(BuildContext context) => PageBody(
    onRefresh: _refresh,
    children: [
      const PageHeading(
        number: '03',
        title: 'Мысли\nи наблюдения.',
        subtitle: 'О дизайне, процессе и том, как создаются цифровые продукты.',
      ),
      AsyncContent(
        future: _future,
        onRetry: _refresh,
        builder: (page) => Column(
          children: [
            if (page.items.isEmpty)
              const EmptyContent(
                'Публикаций пока нет',
                'Новые статьи студии появятся здесь.',
              ),
            for (final (index, article) in [
              ...page.items,
              ..._additional,
            ].indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Panel(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ArticleScreen(
                        article: article,
                        repository: widget.repository,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (article.coverUrl != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: SizedBox(
                              height: 150,
                              width: double.infinity,
                              child: ProjectArtwork(
                                variant: 0,
                                imageUrl: article.coverUrl,
                              ),
                            ),
                          ),
                        ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: PipColors.accent.withValues(alpha: .12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              index.isEven
                                  ? Icons.lightbulb_outline_rounded
                                  : Icons.gesture_rounded,
                              color: const Color(0xFFB49DEB),
                              size: 28,
                            ),
                          ),
                          const Spacer(),
                          if (widget.repository.isDemo) const ExampleTag(),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Eyebrow(article.category.toUpperCase()),
                      const SizedBox(height: 12),
                      Text(
                        article.title.resolve(_locale),
                        style: const TextStyle(
                          fontSize: 24,
                          height: 1.25,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -.5,
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Row(
                        children: [
                          Text(
                            'Читать статью',
                            style: TextStyle(
                              color: PipColors.muted,
                              fontSize: 13,
                            ),
                          ),
                          Spacer(),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                            color: PipColors.muted,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            if (_paginationError != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _paginationError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
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

class ArticleScreen extends StatefulWidget {
  const ArticleScreen({
    super.key,
    required this.article,
    required this.repository,
  });
  final StudioArticle article;
  final StudioRepository repository;
  @override
  State<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<ArticleScreen> {
  late Future<StudioArticle> _future;
  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<StudioArticle> _load() =>
      widget.repository.article(widget.article.slug, _locale);
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
    title: 'Блог',
    body: PageBody(
      onRefresh: _refresh,
      children: [
        AsyncContent(
          future: _future,
          onRetry: _refresh,
          builder: (article) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Eyebrow(article.category.toUpperCase()),
              const SizedBox(height: 18),
              Text(
                article.title.resolve(_locale),
                style: const TextStyle(
                  fontSize: 34,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.8,
                ),
              ),
              const SizedBox(height: 18),
              if (article.author != null || article.publishedAt != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    [
                      if (article.author != null) article.author!,
                      if (article.publishedAt != null)
                        MaterialLocalizations.of(
                          context,
                        ).formatMediumDate(article.publishedAt!.toLocal()),
                    ].join(' · '),
                    style: const TextStyle(
                      color: PipColors.muted,
                      fontSize: 13,
                    ),
                  ),
                ),
              if (article.coverUrl != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 22),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: SizedBox(
                      height: 220,
                      width: double.infinity,
                      child: ProjectArtwork(
                        variant: 0,
                        imageUrl: article.coverUrl,
                      ),
                    ),
                  ),
                ),
              if (widget.repository.isDemo)
                const Padding(
                  padding: EdgeInsets.only(bottom: 22),
                  child: Text(
                    'Демонстрационный материал',
                    style: TextStyle(color: PipColors.amber, fontSize: 12),
                  ),
                ),
              const Divider(),
              const SizedBox(height: 23),
              for (final paragraph in article.paragraphs)
                Padding(
                  padding: const EdgeInsets.only(bottom: 23),
                  child: SelectableText(
                    paragraph,
                    style: const TextStyle(
                      fontSize: 17,
                      height: 1.8,
                      color: PipColors.text,
                    ),
                  ),
                ),
              if (article.websiteUrl != null)
                OutlinedButton.icon(
                  onPressed: () => openExternal(context, article.websiteUrl!),
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: const Text('Читать на сайте'),
                ),
              const SizedBox(height: 24),
              _BriefCallout(repository: widget.repository),
            ],
          ),
        ),
      ],
    ),
  );
}
