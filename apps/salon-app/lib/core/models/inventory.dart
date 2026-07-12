class ProductCategory {
  final String id;
  final String name;

  const ProductCategory({required this.id, required this.name});

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(id: json['id'] as String, name: json['name'] as String);
  }
}

class Product {
  final String id;
  final String categoryId;
  final String? categoryName;
  final String name;
  final String? description;
  final double price;
  final String? sku;
  final int stockQty;

  const Product({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.price,
    required this.stockQty,
    this.categoryName,
    this.description,
    this.sku,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final category = json['category'] as Map<String, dynamic>?;
    return Product(
      id: json['id'] as String,
      categoryId: json['categoryId'] as String,
      categoryName: category?['name'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: double.parse(json['price'].toString()),
      sku: json['sku'] as String?,
      stockQty: json['stockQty'] as int,
    );
  }
}
