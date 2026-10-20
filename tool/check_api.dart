import 'dart:io';

import 'package:pip/api/api_service.dart';
import 'package:pip/models.dart';

/// Ручная проверка публичного API. Здесь выполняются только GET-запросы.
/// Тестовые заявки в рабочую CMS этим скриптом не отправляются.
Future<void> main() async {
  final api = ApiService();
  const locale = ContentLocale.ru;
  try {
    final contacts = await api.getContacts(locale);
    final options = await api.getBriefOptions(locale);
    stdout.writeln(
      'GET config: ${contacts.email != null ? 'contacts OK' : 'no email'}, '
      '${options.serviceOptions.length} brief options',
    );

    final services = await api.getServices(locale);
    stdout.writeln('GET services: ${services.items.length} items');
    if (services.items.isNotEmpty) {
      final detail = await api.getService(services.items.first.id, locale);
      stdout.writeln(
        'GET service detail: ${detail.sections.length} sections, '
        '${detail.projects.length} related projects',
      );
    }

    final projects = await api.getProjects(locale);
    stdout.writeln('GET projects: ${projects.items.length} items');
    if (projects.nextPage != null) {
      final next = await api.getProjects(locale, page: projects.nextPage!);
      stdout.writeln('GET projects page 2: ${next.items.length} items');
    }
    if (projects.items.isNotEmpty) {
      final detail = await api.getProject(projects.items.first.slug, locale);
      stdout.writeln(
        'GET project detail: ${detail.gallery.length} gallery images',
      );
    }

    final featured = await api.getProjects(locale, featured: true);
    stdout.writeln('GET featured projects: ${featured.items.length} items');
    final posts = await api.getArticles(locale);
    stdout.writeln('GET posts: ${posts.items.length} items');
    if (posts.items.isNotEmpty) {
      final detail = await api.getArticle(posts.items.first.slug, locale);
      stdout.writeln(
        'GET post detail: ${detail.paragraphs.length} text paragraphs',
      );
    }
    stdout.writeln('Public API read check passed. No brief was submitted.');
  } on AppException catch (error) {
    stderr.writeln('API check failed: ${error.message}');
    exitCode = 1;
  } catch (error) {
    stderr.writeln('API check failed: ${error.runtimeType}');
    exitCode = 1;
  } finally {
    api.close();
  }
}
