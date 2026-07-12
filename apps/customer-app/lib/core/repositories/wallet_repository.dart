import 'package:dio/dio.dart';
import '../models/wallet.dart';
import '../network/api_client.dart';
import '../network/api_exception.dart';

class WalletRepository {
  final ApiClient apiClient;

  WalletRepository({required this.apiClient});

  Future<WalletDetails> getWalletDetails() async {
    try {
      final response = await apiClient.dio.get('/wallet/balance');
      return WalletDetails.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> requestWithdrawal(double amount) async {
    try {
      await apiClient.dio.post('/wallet/withdraw', data: {'amount': amount});
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
