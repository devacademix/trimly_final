/// Mirrors `SalonService.getStaff` — a StaffProfile joined with its User.
class StaffMember {
  final String id;
  final String fullName;
  final String? email;
  final String? phone;
  final String status;
  final String? bio;
  final List<String> specialities;
  final double rating;
  final bool isAvailable;

  const StaffMember({
    required this.id,
    required this.fullName,
    required this.status,
    this.email,
    this.phone,
    this.bio,
    this.specialities = const [],
    this.rating = 0,
    this.isAvailable = true,
  });

  factory StaffMember.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return StaffMember(
      id: json['id'] as String,
      fullName: user?['fullName'] as String? ?? 'Staff member',
      email: user?['email'] as String?,
      phone: user?['phone'] as String?,
      status: user?['status'] as String? ?? 'ACTIVE',
      bio: json['bio'] as String?,
      specialities: (json['specialities'] as List?)?.cast<String>() ?? const [],
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      isAvailable: json['isAvailable'] as bool? ?? true,
    );
  }
}
