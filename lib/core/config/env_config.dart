enum Environment {
  dev,
  test,
  prod,
}

class EnvConfig {
  final String apiBaseUrl;
  final String appName;
  final bool enableLogging;
  final Environment environment;

  static EnvConfig? _instance;

  factory EnvConfig({
    required String apiBaseUrl,
    required String appName,
    required bool enableLogging,
    required Environment environment,
  }) {
    _instance ??= EnvConfig._internal(
      apiBaseUrl: apiBaseUrl,
      appName: appName,
      enableLogging: enableLogging,
      environment: environment,
    );
    return _instance!;
  }

  EnvConfig._internal({
    required this.apiBaseUrl,
    required this.appName,
    required this.enableLogging,
    required this.environment,
  });

  static EnvConfig get instance {
    return _instance!;
  }

  static bool isDevelopment() => _instance?.environment == Environment.dev;
  static bool isTest() => _instance?.environment == Environment.test;
  static bool isProduction() => _instance?.environment == Environment.prod;

} 