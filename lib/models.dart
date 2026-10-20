/// Язык содержимого может отличаться от языка интерфейса.
enum ContentLocale { ru, en, kk }

class LocalizedText {
  const LocalizedText(this.values);
  final Map<ContentLocale, String> values;

  String resolve(ContentLocale locale) =>
      values[locale] ??
      values[ContentLocale.ru] ??
      values.values.firstOrNull ??
      '';
}

class StudioService {
  const StudioService({
    required this.id,
    required this.title,
    required this.description,
    required this.deliverables,
    required this.faq,
    this.startingPrice,
    this.sections = const [],
    this.projects = const [],
    this.contentLanguage,
  });
  final String id;
  final LocalizedText title;
  final LocalizedText description;
  final List<String> deliverables;
  final List<({String question, String answer})> faq;
  final String? startingPrice;
  final List<({String heading, String text})> sections;
  final List<StudioProject> projects;
  final String? contentLanguage;
}

class StudioProject {
  const StudioProject({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.serviceIds,
    required this.visual,
    this.imageUrls = const [],
    this.websiteUrl,
    String? slug,
    this.coverUrl,
    this.gallery = const [],
    this.fieldLanguages = const {},
  }) : slug = slug ?? id;
  final String id;
  final String slug;
  final LocalizedText title;
  final String category;
  final LocalizedText description;
  final List<String> serviceIds;
  final int visual;
  final List<Uri> imageUrls;
  final Uri? websiteUrl;
  final Uri? coverUrl;
  final List<ProjectImage> gallery;
  final Map<String, String> fieldLanguages;
}

class ProjectImage {
  const ProjectImage({
    required this.url,
    this.thumbnailUrl,
    this.caption = '',
    this.kind = 'current',
    this.width,
    this.height,
  });
  final Uri url;
  final Uri? thumbnailUrl;
  final String caption;
  final String kind;
  final num? width;
  final num? height;
}

class StudioArticle {
  const StudioArticle({
    required this.id,
    required this.title,
    required this.category,
    required this.paragraphs,
    String? slug,
    this.coverUrl,
    this.publishedAt,
    this.author,
    this.websiteUrl,
    this.fieldLanguages = const {},
  }) : slug = slug ?? id;
  final String id;
  final String slug;
  final LocalizedText title;
  final String category;
  final List<String> paragraphs;
  final Uri? coverUrl;
  final DateTime? publishedAt;
  final String? author;
  final Uri? websiteUrl;
  final Map<String, String> fieldLanguages;
}

class StudioContact {
  const StudioContact({this.telegram, this.email, this.about, this.websiteUrl});
  final Uri? telegram;
  final String? email;
  final LocalizedText? about;
  final Uri? websiteUrl;
}

class BriefOptions {
  const BriefOptions({
    required this.serviceOptions,
    this.nameMin = 2,
    this.nameMax = 100,
    this.contactMin = 3,
    this.contactMax = 200,
    this.messageMax = 5000,
    this.servicesMax = 6,
  });
  final List<String> serviceOptions;
  final int nameMin;
  final int nameMax;
  final int contactMin;
  final int contactMax;
  final int messageMax;
  final int servicesMax;
}

class ContentPage<T> {
  const ContentPage(this.items, {this.nextPage});
  final List<T> items;

  /// Номер следующей страницы; null означает, что список закончился.
  final int? nextPage;
}

class AppException implements Exception {
  const AppException(this.message);
  final String message;
  @override
  String toString() => message;
}
