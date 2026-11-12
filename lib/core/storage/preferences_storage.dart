import 'package:shared_preferences/shared_preferences.dart';

/// Contract for simple, non-sensitive preferences.
abstract interface class PreferencesStorage {
  bool? getBool(String key);
  Future<void> setBool(String key, {required bool value});
  String? getString(String key);
  Future<void> setString(String key, String value);
  Future<void> remove(String key);
}

final class SharedPreferencesStorage implements PreferencesStorage {
  const SharedPreferencesStorage(this._prefs);

  final SharedPreferences _prefs;

  @override
  bool? getBool(String key) => _prefs.getBool(key);

  @override
  Future<void> setBool(String key, {required bool value}) => _prefs.setBool(key, value);

  @override
  String? getString(String key) => _prefs.getString(key);

  @override
  Future<void> setString(String key, String value) => _prefs.setString(key, value);

  @override
  Future<void> remove(String key) => _prefs.remove(key);
}
