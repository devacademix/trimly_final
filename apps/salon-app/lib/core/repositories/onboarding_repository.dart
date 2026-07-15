import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../network/api_exception.dart';
import '../storage/secure_storage.dart';

class OnboardingRepository {
  final ApiClient apiClient;
  final SecureStorage secureStorage;

  OnboardingRepository({required this.apiClient, required this.secureStorage});

  Future<Map<String, dynamic>> getStatus() async {
    try {
      final response = await apiClient.dio.get('/onboarding/status');
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> basicInfo({
    required String ownerName,
    required String salonName,
    required String email,
    required String businessCategory,
  }) async {
    try {
      final response = await apiClient.dio.post('/onboarding/basic-info', data: {
        'ownerName': ownerName,
        'salonName': salonName,
        'email': email,
        'businessCategory': businessCategory,
      });
      final data = response.data['data'] as Map<String, dynamic>;
      await secureStorage.saveTenantId(data['tenantId'] as String);
      return data;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> saveLocation({
    required String country,
    required String state,
    required String city,
    required String area,
    required String fullAddress,
    double? latitude,
    double? longitude,
  }) async {
    try {
      await apiClient.dio.put('/onboarding/location', data: {
        'country': country, 'state': state, 'city': city,
        'area': area, 'fullAddress': fullAddress,
        'latitude': latitude, 'longitude': longitude,
      });
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> saveDetails({
    String? gstNumber, String? panNumber,
    String? businessRegNumber, String? description,
  }) async {
    try {
      await apiClient.dio.put('/onboarding/details', data: {
        'gstNumber': gstNumber, 'panNumber': panNumber,
        'businessRegNumber': businessRegNumber, 'description': description,
      });
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> saveTiming({
    required List<Map<String, dynamic>> schedules,
    List<Map<String, dynamic>>? breaks,
    List<Map<String, dynamic>>? holidays,
  }) async {
    try {
      await apiClient.dio.post('/onboarding/timing', data: {
        'schedules': schedules,
        'breaks': breaks ?? [],
        'holidays': holidays ?? [],
      });
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> savePhotos({
    String? logoUrl, String? coverImageUrl,
    List<Map<String, String>>? gallery,
  }) async {
    try {
      await apiClient.dio.post('/onboarding/photos', data: {
        'logoUrl': logoUrl, 'coverImageUrl': coverImageUrl,
        'gallery': gallery ?? [],
      });
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> addServices(List<Map<String, dynamic>> services) async {
    try {
      final response = await apiClient.dio.post('/onboarding/services', data: {'services': services});
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> addStaff(List<Map<String, dynamic>> staffList) async {
    try {
      await apiClient.dio.post('/onboarding/staff', data: {'staff': staffList});
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> saveBankDetails({
    required String accountHolder,
    required String bankName,
    required String accountNumber,
    required String ifsc,
    String? upiId,
  }) async {
    try {
      await apiClient.dio.put('/onboarding/bank', data: {
        'accountHolder': accountHolder, 'bankName': bankName,
        'accountNumber': accountNumber, 'ifsc': ifsc, 'upiId': upiId,
      });
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> uploadKyc(String documentType, String fileUrl) async {
    try {
      await apiClient.dio.post('/onboarding/kyc/$documentType', data: {'fileUrl': fileUrl});
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<dynamic>> getPlans() async {
    try {
      final response = await apiClient.dio.get('/onboarding/plans');
      return response.data['data'] as List<dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> subscribe(String planId) async {
    try {
      final response = await apiClient.dio.post('/onboarding/subscribe', data: {'planId': planId});
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> completeOnboarding() async {
    try {
      await apiClient.dio.post('/onboarding/complete');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> uploadFile(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });
      final response = await apiClient.dio.post('/upload', data: formData);
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
