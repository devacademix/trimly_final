import 'package:dio/dio.dart';
import '../models/payroll.dart';
import '../network/api_client.dart';
import '../network/api_exception.dart';

class PayrollRepository {
  final ApiClient apiClient;

  PayrollRepository({required this.apiClient});

  Future<List<StaffPayrollResult>> getMonthlyPayroll(int month, int year) async {
    try {
      final response = await apiClient.dio.get('/payroll', queryParameters: {
        'month': month,
        'year': year,
      });
      final list = response.data['data'] as List;
      return list.map((json) => StaffPayrollResult.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> markAsPaid(String staffId, int month, int year) async {
    try {
      await apiClient.dio.post('/payroll/$staffId/pay', data: {
        'month': month,
        'year': year,
      });
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> updateCommission(String staffId, double baseSalary, double commissionRate) async {
    try {
      await apiClient.dio.patch('/payroll/staff/$staffId/commission', data: {
        'baseSalary': baseSalary,
        'commissionRate': commissionRate,
      });
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
