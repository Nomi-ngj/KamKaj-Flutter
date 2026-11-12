import '../entities/app_language.dart';

abstract interface class SettingsRepository {
  bool get isOnboardingCompleted;
  Future<void> completeOnboarding();

  /// `null` until the user has chosen a language.
  AppLanguage? get language;
  Future<void> saveLanguage(AppLanguage language);
}
