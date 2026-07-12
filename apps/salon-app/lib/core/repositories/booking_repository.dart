import 'package:dio/dio.dart';
import '../models/booking.dart';
import '../network/api_client.dart';
import '../network/api_exception.dart';

class BookingRepository {
  final ApiClient apiClient;

  BookingRepository({required this.apiClient});

  Future<List<Booking>> listBookings({BookingStatus? status}) async {
    try {
      final response = await apiClient.dio.get('/booking', queryParameters: {
        if (status != null) 'status': status.value,
      });
      final list = response.data['data'] as List;
      return list.map((json) => Booking.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Booking> updateStatus(String id, BookingStatus status) async {
    try {
      final response = await apiClient.dio.patch('/booking/$id/status', data: {'status': status.value});
      return Booking.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
