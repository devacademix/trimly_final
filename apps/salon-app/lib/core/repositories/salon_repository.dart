import 'package:dio/dio.dart';
import '../models/staff_member.dart';
import '../models/salon_customer.dart';
import '../network/api_client.dart';
import '../network/api_exception.dart';

class SalonRepository {
  final ApiClient apiClient;

  SalonRepository({required this.apiClient});

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

  Future<List<SalonCustomer>> getCustomers() async {
    try {
      final response = await apiClient.dio.get('/salon/customers');
      final list = response.data['data'] as List;
      return list.map((json) => SalonCustomer.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
