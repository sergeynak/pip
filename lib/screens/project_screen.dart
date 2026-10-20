import 'package:flutter/material.dart';

import '../api/api_service.dart';
import '../models.dart';
import '../widgets/brief_callout.dart';
import '../widgets/common_widgets.dart';

class ProjectScreen extends StatefulWidget {
  const ProjectScreen({super.key, required this.project, required this.api});
  final StudioProject project;
  final ApiService api;
  @override
  State<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen> {
  late Future<StudioProject> _projectFuture;
  @override
  void initState() {
    super.initState();
    // Полное описание и галерея приходят отдельным запросом по slug проекта.
    _projectFuture = _loadProject();
  }

  Future<StudioProject> _loadProject() {
    return widget.api.getProject(widget.project.slug, contentLocale);
  }

  Future<void> _refreshProject() async {
    // Заменяем Future: AsyncContent покажет загрузку, результат или ошибку.
    setState(() {
      _projectFuture = _loadProject();
    });
    try {
      await _projectFuture;
    } catch (_) {
      /* Ошибку покажет виджет AsyncContent. */
    }
  }

  @override
  Widget build(BuildContext context) => DetailScaffold(
    api: widget.api,
    title: 'Проект',
    body: PageBody(
      onRefresh: _refreshProject,
      children: [
        AsyncContent(
          future: _projectFuture,
          onRetry: _refreshProject,
          builder: (project) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Eyebrow(project.category.toUpperCase()),
              const SizedBox(height: 16),
              Text(
                project.title.resolve(contentLocale),
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
                    demo: widget.api.isDemo,
                  ),
                ),
              ),
              const SectionHeading('О проекте'),
              SelectableText(
                project.description.resolve(contentLocale),
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
              BriefCallout(api: widget.api),
            ],
          ),
        ),
      ],
    ),
  );
}
