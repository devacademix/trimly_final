import 'package:dio/dio.dart';
import '../config/env.dart';
import '../storage/secure_storage.dart';

/// Endpoints that must never carry a stale Authorization header or trigger
/// a refresh-and-retry loop on 401 (refreshing here would recurse).
const _authExemptPaths = ['/auth/login', '/auth/register', '/auth/refresh', '/auth/otp/send', '/auth/otp/verify'];

class ApiClient {
  final Dio dio;
  final SecureStorage secureStorage;

  /// Called once when the refresh token itself is rejected — the session is
  /// truly gone. Wired by the auth provider to flip app state to
  /// unauthenticated so the router redirects to /login.
  void Function()? onSessionExpired;

  Future<String?>? _refreshing;

  ApiClient({required this.secureStorage, String? baseUrl})
      : dio = Dio(
          BaseOptions(
            baseUrl: baseUrl ?? Env.apiBaseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            contentType: Headers.jsonContentType,
          ),
        ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (!_authExemptPaths.any((p) => options.path.contains(p))) {
            final token = await secureStorage.accessToken;
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          final tenantId = await secureStorage.tenantId;
          if (tenantId != null) {
            options.headers['x-tenant-id'] = tenantId;
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          final isAuthExempt = _authExemptPaths.any((p) => error.requestOptions.path.contains(p));
          final alreadyRetried = error.requestOptions.extra['retried'] == true;

          if (error.response?.statusCode != 401 || isAuthExempt || alreadyRetried) {
            return handler.next(error);
          }

          final newToken = await _refreshSession();
          if (newToken == null) {
            onSessionExpired?.call();
            return handler.next(error);
          }

          try {
            final retryOptions = error.requestOptions;
            retryOptions.extra['retried'] = true;
            retryOptions.headers['Authorization'] = 'Bearer $newToken';
            final response = await dio.fetch(retryOptions);
            return handler.resolve(response);
          } on DioException catch (retryError) {
            return handler.next(retryError);
          }
        },
      ),
    );
  }

  /// Coalesces concurrent 401s onto a single in-flight refresh call.
  Future<String?> _refreshSession() {
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  Future<String?> _doRefresh() async {
    final refreshToken = await secureStorage.refreshToken;
    if (refreshToken == null) return null;

    try {
      // Bare request (bypasses interceptors) so this never recurses.
      final response = await Dio(BaseOptions(baseUrl: dio.options.baseUrl)).post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final data = response.data['data'];
      final newAccessToken = data['accessToken'] as String;
      final newRefreshToken = data['refreshToken'] as String;
      await secureStorage.saveSession(accessToken: newAccessToken, refreshToken: newRefreshToken);
      return newAccessToken;
    } catch (_) {
      await secureStorage.clear();
      return null;
    }
  }
}
