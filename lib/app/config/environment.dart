/// Deployment environments. Selected at build time with
/// `--dart-define=ENV=development|staging|production`.
enum Environment {
  development,
  staging,
  production;

  static Environment fromName(String value) {
    return Environment.values.firstWhere(
      (env) => env.name == value,
      orElse: () => Environment.development,
    );
  }

  bool get isProduction => this == Environment.production;
}
