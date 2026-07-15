/// Summary shape returned by `GET /discovery/salons`.
class Salon {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? logoUrl;
  final String? coverImageUrl;
  final String? primaryCity;
  final int branchCount;
  final double? rating;
  final int reviewCount;

  const Salon({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.logoUrl,
    this.coverImageUrl,
    this.primaryCity,
    this.branchCount = 0,
    this.rating,
    this.reviewCount = 0,
  });

  factory Salon.fromJson(Map<String, dynamic> json) {
    return Salon(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      logoUrl: json['logoUrl'] as String?,
      coverImageUrl: json['coverImageUrl'] as String?,
      primaryCity: json['primaryCity'] as String?,
      branchCount: (json['_count'] as Map<String, dynamic>?)?['branches'] as int? ?? 0,
      rating: (json['rating'] as num?)?.toDouble(),
      reviewCount: json['reviewCount'] as int? ?? 0,
    );
  }
}

class SalonBranch {
  final String id;
  final String name;
  final String address;
  final double? latitude;
  final double? longitude;
  final String? phone;

  const SalonBranch({
    required this.id,
    required this.name,
    required this.address,
    this.latitude,
    this.longitude,
    this.phone,
  });

  factory SalonBranch.fromJson(Map<String, dynamic> json) {
    return SalonBranch(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      phone: json['phone'] as String?,
    );
  }
}

class SalonService {
  final String id;
  final String name;
  final String? description;
  final double price;
  final int duration;
  final String? imageUrl;
  final String categoryName;

  const SalonService({
    required this.id,
    required this.name,
    required this.price,
    required this.duration,
    required this.categoryName,
    this.description,
    this.imageUrl,
  });

  factory SalonService.fromJson(Map<String, dynamic> json, {required String categoryName}) {
    return SalonService(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: double.parse(json['price'].toString()),
      duration: json['duration'] as int,
      imageUrl: json['imageUrl'] as String?,
      categoryName: categoryName,
    );
  }
}

class SalonStaff {
  final String id;
  final String fullName;
  final String? profileImageUrl;
  final String? bio;
  final List<String> specialities;
  final double rating;

  const SalonStaff({
    required this.id,
    required this.fullName,
    this.profileImageUrl,
    this.bio,
    this.specialities = const [],
    this.rating = 0,
  });

  factory SalonStaff.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return SalonStaff(
      id: json['id'] as String,
      fullName: user?['fullName'] as String? ?? 'Staff member',
      profileImageUrl: user?['profileImageUrl'] as String?,
      bio: json['bio'] as String?,
      specialities: (json['specialities'] as List?)?.cast<String>() ?? const [],
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
    );
  }
}

class SalonDetail {
  final Salon summary;
  final List<SalonBranch> branches;
  final List<SalonService> services;
  final List<SalonStaff> staff;
  final String? ownerId;

  const SalonDetail({
    required this.summary,
    required this.branches,
    required this.services,
    required this.staff,
    this.ownerId,
  });

  factory SalonDetail.fromJson(Map<String, dynamic> json) {
    final categories = (json['serviceCategories'] as List? ?? []);
    final services = <SalonService>[];
    for (final cat in categories) {
      final catMap = cat as Map<String, dynamic>;
      final categoryName = catMap['name'] as String? ?? 'Services';
      for (final srv in (catMap['services'] as List? ?? [])) {
        services.add(SalonService.fromJson(srv as Map<String, dynamic>, categoryName: categoryName));
      }
    }

    return SalonDetail(
      summary: Salon.fromJson(json),
      branches: (json['branches'] as List? ?? []).map((b) => SalonBranch.fromJson(b as Map<String, dynamic>)).toList(),
      services: services,
      staff: (json['staff'] as List? ?? []).map((s) => SalonStaff.fromJson(s as Map<String, dynamic>)).toList(),
      ownerId: json['ownerId'] as String?,
    );
  }
}
