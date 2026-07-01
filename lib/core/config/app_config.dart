class AppConfig {
  // Use 10.0.2.2 for Android emulator (maps to host localhost),
  // localhost for iOS simulator and web
  static String get baseUrl {
    return 'https://smartclean.smkn1cianjur.sch.id';
  }

  static const String apiVersion = '/api';

  /// Builds a full API URL from an endpoint path.
  /// Example: buildUrl('/login') => 'http://10.0.2.2:8000/api/login'
  static String buildUrl(String endpoint) {
    final path = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return '$baseUrl$apiVersion$path';
  }

  // App metadata
  static const String appName = 'VibeCo';
  static const String appVersion = '0.1.0';
  static const String appTagline = 'Smart School Cleanliness';

  // Timeouts
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration uploadTimeout = Duration(seconds: 60);
}
