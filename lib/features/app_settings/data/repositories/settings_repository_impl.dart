import '../../../../core/storage/preferences_storage.dart';
import '../../../../core/storage/storage_keys.dart';
import '../../domain/entities/app_language.dart';
import '../../domain/repositories/settings_repository.dart';

final class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl(this._prefs);

  final PreferencesStorage _prefs;

  @override
  bool get isOnboardingCompleted => _prefs.getBool(StorageKeys.onboardingCompleted) ?? false;

  @override
  Future<void> completeOnboarding() =>
      _prefs.setBool(StorageKeys.onboardingCompleted, value: true);

  @override
  AppLanguage? get language {
    final code = _prefs.getString(StorageKeys.languageCode);
    return code == null ? null : AppLanguage.fromCode(code);
  }

  @override
  Future<void> saveLanguage(AppLanguage language) =>
      _prefs.setString(StorageKeys.languageCode, language.code);
}
