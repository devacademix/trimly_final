import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyTenantId = 'tenant_id';

  final SharedPreferences _prefs;

  LocalStorage(this._prefs);

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await _prefs.setString(_keyAccessToken, accessToken);
    await _prefs.setString(_keyRefreshToken, refreshToken);
  }

  String? get accessToken => _prefs.getString(_keyAccessToken);
  String? get refreshToken => _prefs.getString(_keyRefreshToken);

  Future<void> saveTenantId(String tenantId) async {
    await _prefs.setString(_keyTenantId, tenantId);
  }

  String? get tenantId => _prefs.getString(_keyTenantId);

  Future<void> clear() async {
    await _prefs.remove(_keyAccessToken);
    await _prefs.remove(_keyRefreshToken);
    await _prefs.remove(_keyTenantId);
  }
}
