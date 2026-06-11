/// Environment configuration
/// Run with:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
///   flutter run --dart-define=API_BASE_URL=http://localhost:8000/api --dart-define=API_KEY=secret
class Env {
  /// Base URL of the soil_web REST API (no trailing slash).
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api',
  );

  /// Optional API key sent as X-Api-Key header. Leave empty to disable.
  static const apiKey = String.fromEnvironment('API_KEY', defaultValue: '');
}
