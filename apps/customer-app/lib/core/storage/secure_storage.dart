import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Encrypted on-device storage (Keystore on Android, Keychain on iOS) for the
/// session — access token, refresh token, and the active tenant scope.
/// Replaces the previous plaintext SharedPreferences storage.
class SecureStorage {
  static const _keyAccessToken = 'trimly_access_token';
  static const _keyRefreshToken = 'trimly_refresh_token';
  static const _keyTenantId = 'trimly_tenant_id';

  final FlutterSecureStorage _storage;

  const SecureStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );

  Future<void> saveSession({required String accessToken, required String refreshToken}) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);
    await _storage.write(key: _keyRefreshToken, value: refreshToken);
  }

  Future<String?> get accessToken => _storage.read(key: _keyAccessToken);
  Future<String?> get refreshToken => _storage.read(key: _keyRefreshToken);

  Future<void> saveTenantId(String? tenantId) async {
    if (tenantId == null) {
      await _storage.delete(key: _keyTenantId);
    } else {
      await _storage.write(key: _keyTenantId, value: tenantId);
    }
  }

  Future<String?> get tenantId => _storage.read(key: _keyTenantId);

  Future<void> clear() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
    await _storage.delete(key: _keyTenantId);
  }
}
