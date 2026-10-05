/// Base URL injected at build/run time; it is never stored in source secrets.
///
/// Android Emulator: http://10.0.2.2:800
/// Chrome/Windows:      http://127.0.0.1:800
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:800',
  );

  static Uri endpoint(String path) {
    final base = Uri.parse(baseUrl);
    if (!base.hasScheme ||
        !base.hasAuthority ||
        (base.scheme != 'http' && base.scheme != 'https')) {
      throw const FormatException(
        'API_BASE_URL debe ser una URL HTTP(S) válida.',
      );
    }
    return base.replace(path: path, query: null, fragment: null);
  }
}
