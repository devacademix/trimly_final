import 'package:dio/dio.dart';
import '../models/salon.dart';
import '../network/api_client.dart';
import '../network/api_exception.dart';

class SalonRepository {
  final ApiClient apiClient;

  SalonRepository({required this.apiClient});

  Future<List<Salon>> browseSalons({String? search}) async {
    try {
      final response = await apiClient.dio.get('/discovery/salons', queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
      });
      final list = response.data['data'] as List;
      return list.map((json) => Salon.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<SalonDetail> getSalonDetail(String id) async {
    try {
      final response = await apiClient.dio.get('/discovery/salons/$id');
      return SalonDetail.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
