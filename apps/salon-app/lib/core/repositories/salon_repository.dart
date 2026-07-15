import 'package:dio/dio.dart';
import '../models/staff_member.dart';
import '../models/salon_customer.dart';
import '../models/salon_profile.dart';
import '../models/dashboard_stats.dart';
import '../models/salon_service.dart';
import '../models/analytics.dart';
import '../models/marketing.dart';
import '../models/ai_insight.dart';
import '../network/api_client.dart';
import '../network/api_exception.dart';

class SalonRepository {
  final ApiClient apiClient;

  SalonRepository({required this.apiClient});

  // ─── Dashboard ──────────────────────────────────────────────────────────────

  Future<DashboardStats> getDashboardStats() async {
    try {
      final response = await apiClient.dio.get('/analytics/dashboard');
      final data = response.data['data'] as Map<String, dynamic>;
      return DashboardStats.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<AiInsights> getAiInsights() async {
    try {
      final response = await apiClient.dio.get('/analytics/ai-insights');
      final data = response.data['data'] as Map<String, dynamic>;
      return AiInsights.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // ─── Profile ─────────────────────────────────────────────────────────────────

  Future<SalonProfile> getProfile() async {
    try {
      final response = await apiClient.dio.get('/salon/profile');
      final data = response.data['data'] as Map<String, dynamic>;
      return SalonProfile.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<SalonProfile> updateProfile(Map<String, dynamic> updates) async {
    try {
      final response = await apiClient.dio.put('/salon/profile', data: updates);
      final data = response.data['data'] as Map<String, dynamic>;
      return SalonProfile.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<String> updateShopStatus(bool isOpen) async {
    try {
      final response = await apiClient.dio.put('/salon/status', data: {'isOpen': isOpen});
      return response.data['data']['status'] as String;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // ─── Staff ──────────────────────────────────────────────────────────────────

  Future<List<StaffMember>> getStaff() async {
    try {
      final response = await apiClient.dio.get('/salon/staff');
      final list = response.data['data'] as List;
      return list.map((json) => StaffMember.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<StaffMember> recruitStaff({
    required String email,
    required String fullName,
    String? bio,
    List<String>? specialities,
  }) async {
    try {
      final response = await apiClient.dio.post('/salon/staff', data: {
        'email': email,
        'fullName': fullName,
        if (bio != null) 'bio': bio,
        if (specialities != null) 'specialities': specialities,
      });
      final data = response.data['data'] as Map<String, dynamic>;
      return StaffMember.fromJson(data['staff'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // ─── Customers ──────────────────────────────────────────────────────────────

  Future<List<SalonCustomer>> getCustomers() async {
    try {
      final response = await apiClient.dio.get('/salon/customers');
      final list = response.data['data'] as List;
      return list.map((json) => SalonCustomer.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // ─── Service Categories ──────────────────────────────────────────────────────

  Future<List<ServiceCategory>> getCategories() async {
    try {
      final response = await apiClient.dio.get('/salon/categories');
      final list = response.data['data'] as List;
      return list.map((json) => ServiceCategory.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ServiceCategory> createCategory(String name, {String? description}) async {
    try {
      final response = await apiClient.dio.post('/salon/categories', data: {
        'name': name,
        if (description != null) 'description': description,
      });
      return ServiceCategory.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // ─── Services ────────────────────────────────────────────────────────────────

  Future<List<SalonService>> getServices() async {
    try {
      final response = await apiClient.dio.get('/salon/services');
      final list = response.data['data'] as List;
      return list.map((json) => SalonService.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<SalonService> createService(Map<String, dynamic> data) async {
    try {
      final response = await apiClient.dio.post('/salon/services', data: data);
      return SalonService.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<SalonService> updateService(String id, Map<String, dynamic> data) async {
    try {
      final response = await apiClient.dio.put('/salon/services/$id', data: data);
      return SalonService.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> deleteService(String id) async {
    try {
      await apiClient.dio.delete('/salon/services/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // ─── Staff Extended ──────────────────────────────────────────────────────────

  Future<void> updateStaffStatus(String staffId, bool isActive) async {
    try {
      await apiClient.dio.patch('/salon/staff/$staffId/status', data: {'isActive': isActive});
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // ─── Schedules ───────────────────────────────────────────────────────────────

  Future<void> saveSchedules(List<Map<String, dynamic>> schedules) async {
    try {
      await apiClient.dio.post('/salon/schedules', data: {
        'schedules': schedules,
      });
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // ─── Analytics ───────────────────────────────────────────────────────────────

  Future<List<PeakHour>> getPeakHours() async {
    try {
      final response = await apiClient.dio.get('/analytics/peak-hours');
      final list = response.data['data'] as List;
      return list.map((json) => PeakHour.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<TopService>> getTopServices() async {
    try {
      final response = await apiClient.dio.get('/analytics/services');
      final list = response.data['data'] as List;
      return list.map((json) => TopService.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // ─── Coupons & Marketing ─────────────────────────────────────────────────────

  Future<List<Coupon>> getCoupons() async {
    try {
      final response = await apiClient.dio.get('/marketing/coupons/salon');
      final list = response.data['data'] as List;
      return list.map((json) => Coupon.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Coupon> createCoupon(Map<String, dynamic> data) async {
    try {
      final response = await apiClient.dio.post('/marketing/coupons', data: data);
      return Coupon.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // ─── Reviews ─────────────────────────────────────────────────────────────────

  Future<List<SalonReview>> getReviews(String salonId) async {
    try {
      final response = await apiClient.dio.get('/marketing/reviews/salon/$salonId');
      final list = response.data['data'] as List;
      return list.map((json) => SalonReview.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ReviewReplyModel> replyToReview(String reviewId, String replyText) async {
    try {
      final response = await apiClient.dio.post('/marketing/reviews/$reviewId/reply', data: {
        'replyText': replyText,
      });
      return ReviewReplyModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

