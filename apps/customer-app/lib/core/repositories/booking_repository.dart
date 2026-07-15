import 'package:dio/dio.dart';
import '../models/booking.dart';
import '../network/api_client.dart';
import '../network/api_exception.dart';

class AvailabilityResult {
  final bool isOpen;
  final String? reason;
  final List<String> slots;

  const AvailabilityResult({required this.isOpen, this.reason, this.slots = const []});

  factory AvailabilityResult.fromJson(Map<String, dynamic> json) {
    return AvailabilityResult(
      isOpen: json['isOpen'] as bool? ?? false,
      reason: json['reason'] as String?,
      slots: (json['slots'] as List?)?.cast<String>() ?? const [],
    );
  }
}

class CheckoutSession {
  final String gateway;
  final String orderId;
  final double amount;
  final String keyId;

  const CheckoutSession({required this.gateway, required this.orderId, required this.amount, required this.keyId});

  factory CheckoutSession.fromJson(Map<String, dynamic> json) {
    return CheckoutSession(
      gateway: json['gateway'] as String,
      orderId: json['orderId'] as String,
      amount: (json['amount'] as num).toDouble(),
      keyId: json['keyId'] as String,
    );
  }
}

class BookingRepository {
  final ApiClient apiClient;

  BookingRepository({required this.apiClient});

  Options _tenantHeader(String tenantId) => Options(headers: {'x-tenant-id': tenantId});

  Future<AvailabilityResult> getAvailability({
    required String tenantId,
    required String branchId,
    required DateTime date,
    String? staffId,
  }) async {
    try {
      final response = await apiClient.dio.get(
        '/booking/availability',
        queryParameters: {
          'branchId': branchId,
          'date': date.toIso8601String(),
          'staffId': staffId,
        }..removeWhere((_, v) => v == null),
        options: _tenantHeader(tenantId),
      );
      return AvailabilityResult.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Booking> createBooking({
    required String tenantId,
    required String branchId,
    required String serviceId,
    required DateTime startTime,
    String? staffId,
    String? couponCode,
  }) async {
    try {
      final response = await apiClient.dio.post(
        '/booking/create',
        data: {
          'branchId': branchId,
          'serviceId': serviceId,
          'startTime': startTime.toIso8601String(),
          'staffId': staffId,
          'couponCode': couponCode,
        }..removeWhere((_, v) => v == null),
        options: _tenantHeader(tenantId),
      );
      return Booking.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<CheckoutSession> checkout({required String tenantId, required String bookingId}) async {
    try {
      final response = await apiClient.dio.post(
        '/payments/checkout',
        data: {'bookingId': bookingId},
        options: _tenantHeader(tenantId),
      );
      return CheckoutSession.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<Booking>> listMyBookings({BookingStatus? status}) async {
    try {
      final response = await apiClient.dio.get('/booking',
          queryParameters: status != null ? {'status': status.value} : null);
      final list = response.data['data'] as List;
      return list.map((json) => Booking.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Booking> cancelBooking(String id, {String? notes}) async {
    try {
      final response = await apiClient.dio.patch(
        '/booking/$id/cancel',
        data: notes != null ? {'notes': notes} : null,
      );
      return Booking.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Booking> rescheduleBooking(String id, DateTime startTime) async {
    try {
      final response = await apiClient.dio.patch('/booking/$id/reschedule', data: {
        'startTime': startTime.toIso8601String(),
      });
      return Booking.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
