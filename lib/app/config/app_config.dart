import 'environment.dart';

/// Immutable build-time configuration.
///
/// Values come from `--dart-define` so no URL or secret lives in source code.
/// ```sh
/// flutter run --dart-define=ENV=staging --dart-define=API_BASE_URL=https://...
/// ```
class AppConfig {
  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.useMockApi,
    required this.connectTimeout,
    required this.receiveTimeout,
  });

  factory AppConfig.fromEnvironment() {
    const envName = String.fromEnvironment('ENV', defaultValue: 'development');
    const baseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://api.dev.kamkaj.example/v1',
    );
    // Mock data is on by default until the backend exists.
    const mock = bool.fromEnvironment('USE_MOCK_API', defaultValue: true);

    return AppConfig(
      environment: Environment.fromName(envName),
      apiBaseUrl: baseUrl,
      useMockApi: mock,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
    );
  }

  final Environment environment;
  final String apiBaseUrl;
  final bool useMockApi;
  final Duration connectTimeout;
  final Duration receiveTimeout;

  bool get enableNetworkLogs => !environment.isProduction;
}
