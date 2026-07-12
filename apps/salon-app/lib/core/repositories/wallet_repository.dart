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

  /// Settles the salon's full pending wallet balance to their registered
  /// bank account (`POST /wallet/settle` — the salon-owner equivalent of a
  /// withdrawal; `/wallet/withdraw` is customer-only on the backend).
  Future<void> settleBalance() async {
    try {
      await apiClient.dio.post('/wallet/settle');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
