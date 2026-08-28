class AppConfig {
  static const String appName = 'ساحة التنافس';

  static const String environment =
      String.fromEnvironment('APP_ENV', defaultValue: 'dev');

  static String get apiBaseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) return override;

    return switch (environment) {
      'prod' => 'https://competitionarena.me/api',
      'staging' => 'https://competitionarena.me/api',
      _ => 'https://competitionarena.me/api',
    };
  }

  /// Demo mode: uses mock data when true (no backend needed)
  static const bool demoMode = false;

  static const int defaultTimerSeconds = 60;
  static const int diceMin = 1;
  static const int diceMax = 3;
}
