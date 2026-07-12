import 'package:dio/dio.dart';

/// Normalizes backend error responses (`{ success: false, error: { code, message } }`,
/// see `AllExceptionsFilter` on the NestJS side) and network failures into one
/// exception type screens can catch and show a message for.
class ApiException implements Exception {
  final String code;
  final String message;
  final int? statusCode;

  const ApiException({required this.code, required this.message, this.statusCode});

  factory ApiException.fromDioException(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] is Map) {
      final error = data['error'] as Map;
      return ApiException(
        code: error['code'] as String? ?? 'UNKNOWN',
        message: error['message'] as String? ?? 'Something went wrong',
        statusCode: e.response?.statusCode,
      );
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(code: 'TIMEOUT', message: 'The request timed out. Please try again.');
      case DioExceptionType.connectionError:
        return const ApiException(
          code: 'CONNECTION_ERROR',
          message: 'Unable to reach the Trimly server. Check your connection.',
        );
      default:
        return ApiException(
          code: 'UNKNOWN',
          message: e.message ?? 'Something went wrong',
          statusCode: e.response?.statusCode,
        );
    }
  }

  @override
  String toString() => message;
}
