import 'user_role.dart';

/// Mirrors `AuthUser` in `packages/types/src/index.ts`.
class AuthUser {
  final String id;
  final UserRole role;
  final String status;
  final String? email;
  final String? phone;
  final String? fullName;
  final String? tenantId;
  final String? profileImageUrl;
  final String? referralCode;
  final bool onboardingComplete;

  const AuthUser({
    required this.id,
    required this.role,
    required this.status,
    this.email,
    this.phone,
    this.fullName,
    this.tenantId,
    this.profileImageUrl,
    this.referralCode,
    this.onboardingComplete = false,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      role: UserRole.fromJson(json['role'] as String),
      status: json['status'] as String? ?? 'ACTIVE',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      fullName: json['fullName'] as String?,
      tenantId: json['tenantId'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      referralCode: json['referralCode'] as String?,
      onboardingComplete: json['onboardingComplete'] as bool? ?? false,
    );
  }

  String get displayName => fullName?.isNotEmpty == true ? fullName! : (email ?? phone ?? 'Trimly user');
}
