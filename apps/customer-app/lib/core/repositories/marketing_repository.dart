import 'package:dio/dio.dart';
import '../models/marketing.dart';
import '../network/api_client.dart';
import '../network/api_exception.dart';

class MarketingRepository {
  final ApiClient apiClient;

  MarketingRepository({required this.apiClient});

  Options _tenantHeader(String tenantId) => Options(headers: {'x-tenant-id': tenantId});

  Future<CouponValidation> validateCoupon({
    required String tenantId,
    required String code,
    required double amount,
  }) async {
    try {
      final response = await apiClient.dio.get(
        '/marketing/coupons/validate',
        queryParameters: {'code': code, 'amount': amount},
        options: _tenantHeader(tenantId),
      );
      return CouponValidation.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<SalonReview>> getSalonReviews(String salonId) async {
    try {
      final response = await apiClient.dio.get('/marketing/reviews/salon/$salonId');
      final list = response.data['data'] as List;
      return list.map((json) => SalonReview.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> createReview({
    required String tenantId,
    required int rating,
    String? comment,
  }) async {
    try {
      await apiClient.dio.post(
        '/marketing/reviews',
        data: {'rating': rating, 'comment': comment, 'tenantId': tenantId},
        options: _tenantHeader(tenantId),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
