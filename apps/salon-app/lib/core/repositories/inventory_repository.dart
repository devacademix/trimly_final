import 'package:dio/dio.dart';
import '../models/inventory.dart';
import '../network/api_client.dart';
import '../network/api_exception.dart';

class InventoryRepository {
  final ApiClient apiClient;

  InventoryRepository({required this.apiClient});

  Future<List<ProductCategory>> getCategories() async {
    try {
      final response = await apiClient.dio.get('/inventory/categories');
      final list = response.data['data'] as List;
      return list.map((json) => ProductCategory.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ProductCategory> createCategory(String name) async {
    try {
      final response = await apiClient.dio.post('/inventory/categories', data: {'name': name});
      return ProductCategory.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<Product>> getProducts() async {
    try {
      final response = await apiClient.dio.get('/inventory/products');
      final list = response.data['data'] as List;
      return list.map((json) => Product.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Product> createProduct({
    required String categoryId,
    required String name,
    required double price,
    String? description,
    String? sku,
    int stockQty = 0,
  }) async {
    try {
      final response = await apiClient.dio.post('/inventory/products', data: {
        'categoryId': categoryId,
        'name': name,
        'price': price,
        'stockQty': stockQty,
        if (description != null) 'description': description,
        if (sku != null) 'sku': sku,
      });
      return Product.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> addStockMovement({
    required String productId,
    required String movementType,
    required int quantity,
    String? reason,
  }) async {
    try {
      await apiClient.dio.post('/inventory/movements', data: {
        'productId': productId,
        'movementType': movementType,
        'quantity': quantity,
        if (reason != null) 'reason': reason,
      });
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
