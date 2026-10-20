import 'package:flutter_test/flutter_test.dart';
import 'package:pip/api/api_config.dart';

void main() {
  test('environment has no server unless API_BASE_URL is supplied', () {
    const baseUrl = String.fromEnvironment('API_BASE_URL');
    final config = ApiConfig.fromEnvironment();
    if (baseUrl.trim().isEmpty) {
      expect(config.baseUri, isNull);
      expect(config.isConfigured, isFalse);
    } else {
      expect(config.baseUri, Uri.parse(baseUrl.trim()));
      expect(config.isConfigured, isTrue);
    }
  });

  test('an explicitly unconfigured transport never assumes a server', () {
    expect(ApiConfig().baseUri, isNull);
    expect(ApiConfig(baseUrl: '   ').isConfigured, isFalse);
    expect(
      ApiConfig(baseUrl: 'https://example.test/api/v1').isConfigured,
      isTrue,
    );
  });

  test('allows local HTTP development addresses', () {
    for (final host in ['localhost', '127.0.0.1', '[::1]', '10.0.2.2']) {
      expect(ApiConfig(baseUrl: 'http://$host:4000/api').isConfigured, isTrue);
    }
  });

  test('rejects unsafe or ambiguous base URLs', () {
    for (final url in [
      'http://example.test/api',
      '/api',
      'ftp://example.test/api',
      'https://user:password@example.test/api',
      'https://example.test/api?lang=ru',
      'https://example.test/api#fragment',
    ]) {
      expect(() => ApiConfig(baseUrl: url), throwsArgumentError, reason: url);
    }
  });

  test('requires a positive timeout', () {
    expect(() => ApiConfig(timeout: Duration.zero), throwsArgumentError);
  });
}
