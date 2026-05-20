class AppConfig {
  static const String appName = 'ساحة التحدي التعليمي';

  static const String environment =
      String.fromEnvironment('APP_ENV', defaultValue: 'dev');

  static String get apiBaseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) return override;

    return switch (environment) {
      'prod' => 'https://api.challenge-edu.example.com/api',
      'staging' => 'https://staging-api.challenge-edu.example.com/api',
      _ => 'http://10.0.2.2:8000/api',
    };
  }

  /// Demo mode: uses mock data when true (no backend needed)
  static const bool demoMode = false;

  static const int defaultTimerSeconds = 60;
  static const int diceMin = 1;
  static const int diceMax = 3;
}
