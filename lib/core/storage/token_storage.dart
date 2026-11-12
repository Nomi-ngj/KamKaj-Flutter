import 'secure_storage.dart';
import 'storage_keys.dart';

/// Holds the auth token pair in secure storage.
final class TokenStorage {
  const TokenStorage(this._secureStorage);

  final SecureStorage _secureStorage;

  Future<String?> get accessToken => _secureStorage.read(StorageKeys.accessToken);

  Future<String?> get refreshToken => _secureStorage.read(StorageKeys.refreshToken);

  Future<void> save({required String accessToken, required String refreshToken}) async {
    await _secureStorage.write(StorageKeys.accessToken, accessToken);
    await _secureStorage.write(StorageKeys.refreshToken, refreshToken);
  }

  Future<void> clear() async {
    await _secureStorage.delete(StorageKeys.accessToken);
    await _secureStorage.delete(StorageKeys.refreshToken);
  }
}
