import 'dart:io';

import 'package:pip/core/api/api_client.dart';
import 'package:pip/core/api/api_config.dart';
import 'package:pip/data/api_studio_repository.dart';
import 'package:pip/data/studio_repository.dart';

/// Manual smoke check of the public API. All operations below are GET requests.
/// Never send a sample brief to the production CMS from automated checks.
Future<void> main() async {
  final client = ApiClient(config: ApiConfig.fromEnvironment());
  final repository = ApiStudioRepository(client);
  const locale = ContentLocale.ru;
  try {
    final contacts = await repository.contacts(locale);
    final options = await repository.briefOptions(locale);
    stdout.writeln(
      'GET config: ${contacts.email != null ? 'contacts OK' : 'no email'}, '
      '${options.serviceOptions.length} brief options',
    );

    final services = await repository.services(locale);
    stdout.writeln('GET services: ${services.items.length} items');
    if (services.items.isNotEmpty) {
      final detail = await repository.service(services.items.first.id, locale);
      stdout.writeln(
        'GET service detail: ${detail.sections.length} sections, '
        '${detail.projects.length} related projects',
      );
    }

    final projects = await repository.projects(locale);
    stdout.writeln('GET projects: ${projects.items.length} items');
    if (projects.nextCursor != null) {
      final next = await repository.projects(
        locale,
        cursor: projects.nextCursor,
      );
      stdout.writeln('GET projects page 2: ${next.items.length} items');
    }
    if (projects.items.isNotEmpty) {
      final detail = await repository.project(
        projects.items.first.slug,
        locale,
      );
      stdout.writeln(
        'GET project detail: ${detail.gallery.length} gallery images',
      );
    }

    final featured = await repository.projects(locale, featured: true);
    stdout.writeln('GET featured projects: ${featured.items.length} items');
    final posts = await repository.articles(locale);
    stdout.writeln('GET posts: ${posts.items.length} items');
    if (posts.items.isNotEmpty) {
      final detail = await repository.article(posts.items.first.slug, locale);
      stdout.writeln(
        'GET post detail: ${detail.paragraphs.length} text paragraphs',
      );
    }
    stdout.writeln('Public API read check passed. No brief was submitted.');
  } on RepositoryException catch (error) {
    stderr.writeln('API check failed: ${error.message}');
    exitCode = 1;
  } catch (error) {
    stderr.writeln('API check failed: ${error.runtimeType}');
    exitCode = 1;
  } finally {
    client.close();
  }
}
