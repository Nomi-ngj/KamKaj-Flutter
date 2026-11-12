/// Keys for persisted values. Kept in one place to avoid collisions.
abstract final class StorageKeys {
  // Secure storage
  static const accessToken = 'auth.access_token';
  static const refreshToken = 'auth.refresh_token';

  // Preferences
  static const onboardingCompleted = 'app.onboarding_completed';
  static const languageCode = 'app.language_code';
}
