/// Mirrors `SalonService.getCustomers` — a distinct customer derived from
/// this tenant's booking history.
class SalonCustomer {
  final String id;
  final String? fullName;
  final String? email;
  final String? phone;
  final String? profileImageUrl;
  final int visits;
  final DateTime lastVisit;

  const SalonCustomer({
    required this.id,
    required this.visits,
    required this.lastVisit,
    this.fullName,
    this.email,
    this.phone,
    this.profileImageUrl,
  });

  factory SalonCustomer.fromJson(Map<String, dynamic> json) {
    return SalonCustomer(
      id: json['id'] as String,
      fullName: json['fullName'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      visits: json['visits'] as int,
      lastVisit: DateTime.parse(json['lastVisit'] as String),
    );
  }

  String get displayName => fullName?.isNotEmpty == true ? fullName! : (email ?? phone ?? 'Customer');
}
