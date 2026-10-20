/// The API response envelope, kept separate from future feature DTOs.
class ApiResponse {
  const ApiResponse({
    required this.data,
    required this.meta,
    required this.statusCode,
    this.isEmpty = false,
  });

  final Object? data;
  final ApiMeta meta;
  final int statusCode;

  /// True for a successful response with no body, including HTTP 204.
  final bool isEmpty;
}

class ApiMeta {
  const ApiMeta({this.requestId, this.lang, this.pagination});

  factory ApiMeta.fromJson(Map<String, dynamic> json) {
    final requestId = json['requestId'];
    final lang = json['lang'];
    final pagination = json['pagination'];
    if ((requestId != null && requestId is! String) ||
        (lang != null && lang is! String) ||
        (pagination != null && pagination is! Map<String, dynamic>)) {
      throw const FormatException('Invalid API metadata.');
    }
    return ApiMeta(
      requestId: requestId as String?,
      lang: lang as String?,
      pagination: pagination == null
          ? null
          : PageInfo.fromJson(pagination as Map<String, dynamic>),
    );
  }

  final String? requestId;
  final String? lang;
  final PageInfo? pagination;
}

class PageInfo {
  const PageInfo({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrevious,
  });

  factory PageInfo.fromJson(Map<String, dynamic> json) {
    int integer(String key, int minimum) {
      final value = json[key];
      if (value is! int || value < minimum) {
        throw FormatException('Invalid pagination field: $key.');
      }
      return value;
    }

    bool boolean(String key) {
      final value = json[key];
      if (value is! bool) {
        throw FormatException('Invalid pagination field: $key.');
      }
      return value;
    }

    return PageInfo(
      page: integer('page', 1),
      limit: integer('limit', 1),
      total: integer('total', 0),
      totalPages: integer('totalPages', 0),
      hasNext: boolean('hasNext'),
      hasPrevious: boolean('hasPrevious'),
    );
  }

  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNext;
  final bool hasPrevious;
}

/// Actual language of each content field; a requested language may fall back.
class FieldLanguages {
  FieldLanguages(Map<String, String> values)
    : values = Map.unmodifiable(values);

  factory FieldLanguages.fromJson(Map<String, dynamic> json) {
    final values = <String, String>{};
    for (final entry in json.entries) {
      if (entry.value is! String) {
        throw FormatException('Invalid language for field: ${entry.key}.');
      }
      values[entry.key] = entry.value as String;
    }
    return FieldLanguages(values);
  }

  final Map<String, String> values;

  String? operator [](String field) => values[field];
}
