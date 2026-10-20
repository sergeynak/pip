import 'dart:async';

import 'package:flutter/material.dart';

import '../data/demo_data.dart';
import '../models.dart';
import '../widgets/common_widgets.dart';
import '../widgets/project_card.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key, required this.data});
  final DemoData data;
  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  final _search = TextEditingController();
  late Future<ContentPage<StudioProject>> _projectsFuture;
  final List<StudioProject> _moreProjects = [];
  final Set<String> _loadedProjectIds = {};
  bool _loadingMore = false;
  String? _paginationError;
  int? _nextPage;
  int _requestVersion = 0;
  Timer? _debounce;
  bool _waitingSearch = false;

  @override
  void initState() {
    super.initState();
    // При первом открытии загружаем первую страницу портфолио.
    _projectsFuture = _loadProjects();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<ContentPage<StudioProject>> _loadProjects() async {
    // Номер загрузки отличает актуальный поиск от устаревшего результата.
    _requestVersion++;
    final requestVersion = _requestVersion;
    final page = await widget.data.getProjects(
      contentLocale,
      query: _search.text,
    );
    if (requestVersion == _requestVersion) {
      _nextPage = page.nextPage;
      _loadedProjectIds.clear();
      for (final project in page.items) {
        _loadedProjectIds.add(project.id);
      }
    }
    return page;
  }

  void _searchChanged(String query) {
    // Ждём паузу в наборе, чтобы не перечитывать данные после каждой буквы.
    // Такая же задержка пригодится при будущем подключении API.
    _debounce?.cancel();
    _requestVersion++;
    setState(() {
      _waitingSearch = true;
      _loadingMore = false;
      _nextPage = null;
    });
    _debounce = Timer(const Duration(milliseconds: 300), _refreshProjects);
  }

  Future<void> _refreshProjects() async {
    // Новый поиск и обновление свайпом всегда начинаются с первой страницы.
    _debounce?.cancel();
    setState(() {
      _moreProjects.clear();
      _nextPage = null;
      _paginationError = null;
      _loadingMore = false;
      _waitingSearch = false;
      _projectsFuture = _loadProjects();
    });
    try {
      await _projectsFuture;
    } catch (_) {
      /* Ошибку покажет виджет AsyncContent. */
    }
  }

  Future<void> _loadMoreProjects() async {
    // Добавляем следующую страницу, только если поиск не успел измениться.
    if (_nextPage == null || _loadingMore) return;
    final requestVersion = _requestVersion;
    setState(() {
      _loadingMore = true;
      _paginationError = null;
    });
    try {
      final page = await widget.data.getProjects(
        contentLocale,
        query: _search.text,
        page: _nextPage!,
      );
      if (!mounted || requestVersion != _requestVersion) return;
      setState(() {
        for (final project in page.items) {
          if (!_loadedProjectIds.contains(project.id)) {
            _loadedProjectIds.add(project.id);
            _moreProjects.add(project);
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

  @override
  Widget build(BuildContext context) => PageBody(
    onRefresh: _refreshProjects,
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
      if (widget.data.isDemo)
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
          future: _projectsFuture,
          onRetry: _refreshProjects,
          builder: (page) => Column(
            children: [
              if (page.items.isEmpty)
                EmptyContent(
                  'Ничего не найдено',
                  _search.text.trim().isEmpty
                      ? 'Опубликованные проекты появятся здесь.'
                      : 'Попробуйте другое название или направление.',
                ),
              for (final project in [...page.items, ..._moreProjects])
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ProjectCard(project: project, data: widget.data),
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
              if (_nextPage != null)
                OutlinedButton(
                  onPressed: _loadingMore ? null : _loadMoreProjects,
                  child: Text(_loadingMore ? 'Загружаем…' : 'Загрузить ещё'),
                ),
            ],
          ),
        ),
    ],
  );
}
