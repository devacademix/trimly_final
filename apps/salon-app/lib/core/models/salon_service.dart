import '../config/env.dart';

class ServiceCategory {
  final String id;
  final String name;
  final String? description;

  const ServiceCategory({required this.id, required this.name, this.description});

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    return ServiceCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
    );
  }
}

class SalonService {
  final String id;
  final String name;
  final String? description;
  final double price;
  final double? discountPrice;
  final int duration; // minutes
  final String? categoryId;
  final String? categoryName;
  final String? imageUrl;
  final String gender;
  final bool isActive;
  final bool? homeServiceAvailable;

  const SalonService({
    required this.id,
    required this.name,
    required this.price,
    required this.duration,
    required this.gender,
    required this.isActive,
    this.description,
    this.discountPrice,
    this.categoryId,
    this.categoryName,
    this.imageUrl,
    this.homeServiceAvailable,
  });

  factory SalonService.fromJson(Map<String, dynamic> json) {
    final category = json['category'] as Map<String, dynamic>?;
    return SalonService(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: double.parse(json['price'].toString()),
      discountPrice: json['discountPrice'] != null ? double.parse(json['discountPrice'].toString()) : null,
      duration: (json['duration'] as num).toInt(),
      categoryId: json['categoryId'] as String?,
      categoryName: category?['name'] as String?,
      imageUrl: Env.cleanImageUrl(json['imageUrl'] as String?),
      gender: (json['gender'] as String?) ?? 'OTHER',
      isActive: (json['isActive'] as bool?) ?? true,
      homeServiceAvailable: json['homeServiceAvailable'] as bool?,
    );
  }
}
