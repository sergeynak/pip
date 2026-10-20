/// Build configuration for the public Pip API.
class ApiConfig {
  static const productionBaseUrl = 'https://pip.kz/api/v1';

  ApiConfig({String? baseUrl, this.timeout = const Duration(seconds: 15)})
    : baseUri = _parseBaseUrl(baseUrl) {
    if (timeout <= Duration.zero) {
      throw ArgumentError.value(timeout, 'timeout', 'Must be positive.');
    }
  }

  factory ApiConfig.fromEnvironment() => ApiConfig(
    baseUrl: const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: productionBaseUrl,
    ),
  );

  final Uri? baseUri;
  final Duration timeout;

  bool get isConfigured => baseUri != null;

  static Uri? _parseBaseUrl(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw ArgumentError(
        'API_BASE_URL must be a server URL without '
        'credentials, query parameters, or a fragment.',
      );
    }
    const developmentHosts = {'localhost', '127.0.0.1', '::1', '10.0.2.2'};
    final localHttp =
        uri.scheme == 'http' &&
        developmentHosts.contains(uri.host.toLowerCase());
    if (uri.scheme != 'https' && !localHttp) {
      throw ArgumentError(
        'API_BASE_URL requires HTTPS. HTTP is allowed only '
        'for localhost or the Android emulator host.',
      );
    }
    return uri;
  }
}
