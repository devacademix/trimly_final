import 'package:dio/dio.dart';
import '../models/auth_user.dart';
import '../network/api_client.dart';
import '../network/api_exception.dart';
import '../storage/secure_storage.dart';

class AuthRepository {
  final ApiClient apiClient;
  final SecureStorage secureStorage;

  AuthRepository({required this.apiClient, required this.secureStorage});

  Future<AuthUser> loginWithOtp({required String phone, required String otp, required String role}) async {
    try {
      final response = await apiClient.dio.post('/auth/otp/verify', data: {
        'phone': phone,
        'otp': otp,
        'role': role,
      });
      final data = response.data['data'] as Map<String, dynamic>;
      final user = AuthUser.fromJson(data['user'] as Map<String, dynamic>);

      await secureStorage.saveSession(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      );
      if (user.tenantId != null) {
        await secureStorage.saveTenantId(user.tenantId!);
      }

      return user;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Returns null if there's no session or it's no longer valid — the
  /// caller (AuthController) treats that as "not logged in", not an error.
  Future<AuthUser?> fetchCurrentUser() async {
    final token = await secureStorage.accessToken;
    if (token == null) return null;

    try {
      final response = await apiClient.dio.get('/auth/me');
      return AuthUser.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) return null;
      rethrow;
    }
  }

  Future<void> logout() async {
    final refreshToken = await secureStorage.refreshToken;
    if (refreshToken != null) {
      try {
        await apiClient.dio.post('/auth/logout', data: {'refreshToken': refreshToken});
      } catch (_) {
        // Best-effort — always clear the local session regardless.
      }
    }
    await secureStorage.clear();
  }
}
