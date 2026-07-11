import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';
import '../storage/local_storage.dart';

class ApiClient {
  final Dio dio;
  final LocalStorage localStorage;

  ApiClient({
    required this.localStorage,
    String? baseUrl,
  }) : dio = Dio(
          BaseOptions(
            baseUrl: baseUrl ?? (kIsWeb ? 'http://localhost:4000/api/v1' : (Platform.isAndroid ? 'http://10.0.2.2:4000/api/v1' : 'http://localhost:4000/api/v1')),
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            contentType: Headers.jsonContentType,
          ),
        ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = localStorage.accessToken;
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          final tenantId = localStorage.tenantId;
          if (tenantId != null) {
            options.headers['x-tenant-id'] = tenantId;
          }
          return handler.next(options);
        },
        onError: (e, handler) async {
          // Handle token refresh logic here when 401 is received
          return handler.next(e);
        },
      ),
    );
  }
}
