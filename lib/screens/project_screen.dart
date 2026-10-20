import 'package:flutter/material.dart';

import '../data/demo_data.dart';
import '../models.dart';
import '../widgets/brief_callout.dart';
import '../widgets/common_widgets.dart';

class ProjectScreen extends StatefulWidget {
  const ProjectScreen({super.key, required this.project, required this.data});
  final StudioProject project;
  final DemoData data;
  @override
  State<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen> {
  late Future<StudioProject> _projectFuture;
  @override
  void initState() {
    super.initState();
    // Читаем подробный локальный пример по slug. Источник можно заменить на API.
    _projectFuture = _loadProject();
  }

  Future<StudioProject> _loadProject() {
    return widget.data.getProject(widget.project.slug, contentLocale);
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
    data: widget.data,
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
                    demo: widget.data.isDemo,
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
              if (project.gallery.isEmpty && widget.data.isDemo)
                for (int index = 0; index < 2; index++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Panel(
                      padding: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 220,
                            width: double.infinity,
                            child: ProjectArtwork(
                              variant: project.visual + index,
                              demo: true,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'Пример экрана ${index + 1}',
                              style: const TextStyle(
                                color: PipColors.muted,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
              else if (project.gallery.isEmpty)
                const EmptyContent(
                  'Нет изображений',
                  'Галерея этого проекта пока не опубликована.',
                ),
              for (final image in project.gallery) GalleryImage(image: image),
              const SizedBox(height: 18),
              if (widget.data.isDemo)
                const OutlinedButton(
                  onPressed: null,
                  child: Text('Ссылка на сайт · пример'),
                )
              else if (project.websiteUrl != null)
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
              BriefCallout(data: widget.data),
            ],
          ),
        ),
      ],
    ),
  );
}
