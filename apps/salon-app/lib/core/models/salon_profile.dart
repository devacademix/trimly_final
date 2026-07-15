import '../config/env.dart';

/// Full salon profile returned by GET /salon/profile
class SalonProfile {
  final String id;
  final String name;
  final String? legalName;
  final String? description;
  final String? businessCategory;
  final String? businessRegNumber;
  final String? gstNumber;
  final String? panNumber;
  final String? ownerEmail;
  final String? ownerPhone;
  final String? logoUrl;
  final String? coverImageUrl;
  final String? websiteUrl;
  final String? fullAddress;
  final String? area;
  final String? city;
  final String? state;
  final String? country;
  final double? latitude;
  final double? longitude;
  final String? timezone;
  final String? currency;
  final String status;
  final bool isActive;
  final String onboardingStep;

  final List<WorkingHour> workingHours;

  const SalonProfile({
    required this.id,
    required this.name,
    required this.status,
    required this.isActive,
    required this.onboardingStep,
    this.workingHours = const [],
    this.legalName,
    this.description,
    this.businessCategory,
    this.businessRegNumber,
    this.gstNumber,
    this.panNumber,
    this.ownerEmail,
    this.ownerPhone,
    this.logoUrl,
    this.coverImageUrl,
    this.websiteUrl,
    this.fullAddress,
    this.area,
    this.city,
    this.state,
    this.country,
    this.latitude,
    this.longitude,
    this.timezone,
    this.currency,
  });

  factory SalonProfile.fromJson(Map<String, dynamic> json) {
    final whList = json['workingHours'] as List? ?? [];
    return SalonProfile(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      legalName: json['legalName'] as String?,
      description: json['description'] as String?,
      businessCategory: json['businessCategory'] as String?,
      businessRegNumber: json['businessRegNumber'] as String?,
      gstNumber: json['gstNumber'] as String?,
      panNumber: json['panNumber'] as String?,
      ownerEmail: json['ownerEmail'] as String?,
      ownerPhone: json['ownerPhone'] as String?,
      logoUrl: Env.cleanImageUrl(json['logoUrl'] as String?),
      coverImageUrl: Env.cleanImageUrl(json['coverImageUrl'] as String?),
      websiteUrl: json['websiteUrl'] as String?,
      fullAddress: json['fullAddress'] as String?,
      area: json['area'] as String?,
      city: json['primaryCity'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      timezone: json['timezone'] as String?,
      currency: json['currency'] as String?,
      status: (json['status'] as String?) ?? 'PENDING_APPROVAL',
      isActive: (json['isActive'] as bool?) ?? true,
      onboardingStep: (json['onboardingStep'] as String?) ?? 'COMPLETED',
      workingHours: whList.map((x) => WorkingHour.fromJson(x as Map<String, dynamic>)).toList(),
    );
  }

  SalonProfile copyWith({
    String? name,
    String? legalName,
    String? description,
    String? ownerEmail,
    String? ownerPhone,
    String? logoUrl,
    String? coverImageUrl,
    String? gstNumber,
    String? panNumber,
    String? businessRegNumber,
    String? websiteUrl,
    String? fullAddress,
    String? area,
    String? city,
    String? state,
    List<WorkingHour>? workingHours,
  }) {
    return SalonProfile(
      id: id,
      name: name ?? this.name,
      legalName: legalName ?? this.legalName,
      description: description ?? this.description,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      logoUrl: logoUrl ?? this.logoUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      gstNumber: gstNumber ?? this.gstNumber,
      panNumber: panNumber ?? this.panNumber,
      businessRegNumber: businessRegNumber ?? this.businessRegNumber,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      fullAddress: fullAddress ?? this.fullAddress,
      area: area ?? this.area,
      city: city ?? this.city,
      state: state ?? this.state,
      status: status,
      isActive: isActive,
      onboardingStep: onboardingStep,
      businessCategory: businessCategory,
      country: country,
      latitude: latitude,
      longitude: longitude,
      timezone: timezone,
      currency: currency,
      workingHours: workingHours ?? this.workingHours,
    );
  }
}

class WorkingHour {
  final String id;
  final int dayOfWeek;
  final String openTime;
  final String closeTime;
  final bool isOpen;

  const WorkingHour({
    required this.id,
    required this.dayOfWeek,
    required this.openTime,
    required this.closeTime,
    required this.isOpen,
  });

  factory WorkingHour.fromJson(Map<String, dynamic> json) {
    return WorkingHour(
      id: json['id'] as String,
      dayOfWeek: json['dayOfWeek'] as int,
      openTime: json['openTime'] as String,
      closeTime: json['closeTime'] as String,
      isOpen: json['isOpen'] as bool? ?? true,
    );
  }
}
