import 'package:flutter/material.dart';

import '../api/api_service.dart';
import '../models.dart';
import '../widgets/brief_callout.dart';
import '../widgets/common_widgets.dart';
import '../widgets/project_card.dart';
import '../widgets/service_card.dart';
import 'navigation.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.api, required this.onTab});
  final ApiService api;
  final ValueChanged<int> onTab;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<ContentPage<StudioService>> _services;
  late Future<ContentPage<StudioProject>> _projects;

  @override
  void initState() {
    super.initState();
    // Главной нужны услуги и только избранные проекты; запросы независимы.
    _services = widget.api.getServices(contentLocale);
    _projects = widget.api.getProjects(contentLocale, featured: true);
  }

  @override
  Widget build(BuildContext context) => PageBody(
    onRefresh: () async {
      setState(() {
        _services = widget.api.getServices(contentLocale);
        _projects = widget.api.getProjects(contentLocale, featured: true);
      });
      try {
        await Future.wait([_services, _projects]);
      } catch (_) {
        /* Ошибку покажет виджет AsyncContent. */
      }
    },
    children: [
      const Eyebrow('ИДЕИ СТАНОВЯТСЯ ЦИФРОВЫМИ'),
      const SizedBox(height: 17),
      const Text(
        'Создаём\nто, что\nзапоминают.',
        style: TextStyle(
          fontSize: 43,
          height: 1.06,
          letterSpacing: -1.7,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 19),
      const Text(
        'Дизайн, технологии и внимание\nк вашему проекту.',
        style: TextStyle(color: PipColors.muted, fontSize: 15, height: 1.6),
      ),
      const SizedBox(height: 25),
      FilledButton(
        onPressed: () => openBrief(context, widget.api),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(child: Text('Обсудить проект')),
            SizedBox(width: 12),
            Icon(Icons.north_east_rounded, size: 19),
          ],
        ),
      ),
      const SizedBox(height: 22),
      const _StudioVisual(),
      SectionHeading(
        'Что мы делаем',
        action: 'Услуги',
        onAll: () => widget.onTab(1),
      ),
      AsyncContent(
        future: _services,
        onRetry: () => setState(() {
          _services = widget.api.getServices(contentLocale);
        }),
        builder: (page) {
          if (page.items.isEmpty) {
            return const EmptyContent(
              'Услуги скоро появятся',
              'Студия ещё не опубликовала направления работы.',
            );
          }
          return Column(
            children: [
              for (final (index, service) in page.items.take(3).indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ServiceCard(
                    service: service,
                    index: index,
                    api: widget.api,
                    compact: true,
                  ),
                ),
            ],
          );
        },
      ),
      SectionHeading(
        'Избранные проекты',
        action: 'Все',
        onAll: () => widget.onTab(2),
      ),
      if (widget.api.isDemo)
        const Padding(
          padding: EdgeInsets.only(bottom: 14),
          child: Text(
            'Примеры наполнения будущего портфолио.',
            style: TextStyle(color: PipColors.muted, fontSize: 12),
          ),
        ),
      AsyncContent(
        future: _projects,
        onRetry: () => setState(() {
          _projects = widget.api.getProjects(contentLocale, featured: true);
        }),
        builder: (page) => Column(
          children: [
            if (page.items.isEmpty)
              const EmptyContent(
                'Проекты скоро появятся',
                'Опубликованные кейсы будут доступны здесь.',
              ),
            for (final project in page.items.take(2))
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ProjectCard(project: project, api: widget.api),
              ),
          ],
        ),
      ),
      const SizedBox(height: 15),
      BriefCallout(api: widget.api),
    ],
  );
}

class _StudioVisual extends StatelessWidget {
  const _StudioVisual();
  @override
  Widget build(BuildContext context) => MediaQuery.withNoTextScaling(
    child: ExcludeSemantics(
      child: Container(
        height: 170,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: const Color(0xFF211A32),
          border: Border.all(color: const Color(0xFF382A50)),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -24,
              top: -64,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: PipColors.accent.withValues(alpha: .3),
                    width: 1,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 14,
              top: -25,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: PipColors.accent.withValues(alpha: .5),
                    width: 1,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 26,
              top: 31,
              child: Transform.rotate(
                angle: -.38,
                child: Container(
                  width: 135,
                  height: 90,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(48),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFC9AFFF),
                        Color(0xFF8D5BE4),
                        Color(0xFF492F85),
                      ],
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x557853D9),
                        blurRadius: 32,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 82,
                      height: 37,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40),
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF34234D), Color(0xFF8050C2)],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const Positioned(
              left: 20,
              top: 19,
              child: Eyebrow('DESIGN × DEVELOPMENT', color: Color(0xFFBFA4EF)),
            ),
            const Positioned(
              left: 20,
              bottom: 20,
              child: Text(
                'От идеи\nк впечатлению.',
                style: TextStyle(
                  fontSize: 21,
                  height: 1.15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -.5,
                ),
              ),
            ),
            const Positioned(
              right: 19,
              bottom: 18,
              child: Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFFC3A5FF),
                size: 20,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
