import 'package:flutter/material.dart';

import '../data/demo_data.dart';
import '../models.dart';
import '../widgets/common_widgets.dart';
import 'article_screen.dart';

class BlogScreen extends StatefulWidget {
  const BlogScreen({super.key, required this.data});
  final DemoData data;
  @override
  State<BlogScreen> createState() => _BlogScreenState();
}

class _BlogScreenState extends State<BlogScreen> {
  late Future<ContentPage<StudioArticle>> _articlesFuture;
  final List<StudioArticle> _moreArticles = [];
  final Set<String> _loadedArticleIds = {};
  int? _nextPage;
  bool _loadingMore = false;
  String? _paginationError;
  int _requestVersion = 0;

  @override
  void initState() {
    super.initState();
    // Список получает краткие карточки. Полный текст загрузится в статье.
    _articlesFuture = _loadArticles();
  }

  Future<ContentPage<StudioArticle>> _loadArticles() async {
    _requestVersion++;
    final requestVersion = _requestVersion;
    final page = await widget.data.getArticles(contentLocale);
    // Ответ от предыдущего обновления больше не меняет текущую пагинацию.
    if (requestVersion != _requestVersion) return page;
    _nextPage = page.nextPage;
    _loadedArticleIds.clear();
    for (final article in page.items) {
      _loadedArticleIds.add(article.id);
    }
    return page;
  }

  Future<void> _loadMoreArticles() async {
    // Номер следующей страницы берём из результата чтения данных.
    // Локальные примеры помещаются на одну страницу; API подключим позже.
    if (_nextPage == null || _loadingMore) return;
    final requestVersion = _requestVersion;
    setState(() {
      _loadingMore = true;
      _paginationError = null;
    });
    try {
      final page = await widget.data.getArticles(
        contentLocale,
        page: _nextPage!,
      );
      if (!mounted || requestVersion != _requestVersion) return;
      setState(() {
        for (final article in page.items) {
          if (!_loadedArticleIds.contains(article.id)) {
            _loadedArticleIds.add(article.id);
            _moreArticles.add(article);
          }
        }
        _nextPage = page.nextPage;
      });
    } catch (_) {
      if (mounted && requestVersion == _requestVersion) {
        setState(
          () => _paginationError = 'Не удалось загрузить следующую страницу.',
        );
      }
    } finally {
      if (mounted && requestVersion == _requestVersion) {
        setState(() => _loadingMore = false);
      }
    }
  }

  Future<void> _refreshArticles() async {
    // При обновлении очищаем дополнительные страницы и загружаем список заново.
    setState(() {
      _moreArticles.clear();
      _nextPage = null;
      _paginationError = null;
      _loadingMore = false;
      _articlesFuture = _loadArticles();
    });
    try {
      await _articlesFuture;
    } catch (_) {
      /* Ошибку покажет виджет AsyncContent. */
    }
  }

  @override
  Widget build(BuildContext context) => PageBody(
    onRefresh: _refreshArticles,
    children: [
      const PageHeading(
        number: '03',
        title: 'Мысли\nи наблюдения.',
        subtitle: 'О дизайне, процессе и том, как создаются цифровые продукты.',
      ),
      AsyncContent(
        future: _articlesFuture,
        onRetry: _refreshArticles,
        builder: (page) => Column(
          children: [
            if (page.items.isEmpty)
              const EmptyContent(
                'Публикаций пока нет',
                'Новые статьи студии появятся здесь.',
              ),
            for (final (index, article) in [
              ...page.items,
              ..._moreArticles,
            ].indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Panel(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          ArticleScreen(article: article, data: widget.data),
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
                          if (widget.data.isDemo) const ExampleTag(),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Eyebrow(article.category.toUpperCase()),
                      const SizedBox(height: 12),
                      Text(
                        article.title.resolve(contentLocale),
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
            if (_nextPage != null)
              OutlinedButton(
                onPressed: _loadingMore ? null : _loadMoreArticles,
                child: Text(_loadingMore ? 'Загружаем…' : 'Загрузить ещё'),
              ),
          ],
        ),
      ),
    ],
  );
}
