import 'package:flutter/material.dart';

import '../data/demo_data.dart';
import '../models.dart';
import '../widgets/brief_callout.dart';
import '../widgets/common_widgets.dart';

class ArticleScreen extends StatefulWidget {
  const ArticleScreen({super.key, required this.article, required this.data});
  final StudioArticle article;
  final DemoData data;
  @override
  State<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<ArticleScreen> {
  late Future<StudioArticle> _articleFuture;
  @override
  void initState() {
    super.initState();
    // Читаем полный текст примера через источник данных. API подключим позже.
    _articleFuture = _loadArticle();
  }

  Future<StudioArticle> _loadArticle() {
    return widget.data.getArticle(widget.article.slug, contentLocale);
  }

  Future<void> _refreshArticle() async {
    setState(() {
      _articleFuture = _loadArticle();
    });
    try {
      await _articleFuture;
    } catch (_) {
      /* Ошибку покажет виджет AsyncContent. */
    }
  }

  @override
  Widget build(BuildContext context) => DetailScaffold(
    data: widget.data,
    title: 'Блог',
    body: PageBody(
      onRefresh: _refreshArticle,
      children: [
        AsyncContent(
          future: _articleFuture,
          onRetry: _refreshArticle,
          builder: (article) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Eyebrow(article.category.toUpperCase()),
              const SizedBox(height: 18),
              Text(
                article.title.resolve(contentLocale),
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
              if (widget.data.isDemo)
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
              BriefCallout(data: widget.data),
            ],
          ),
        ),
      ],
    ),
  );
}
