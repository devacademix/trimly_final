/// Mirrors `UserRole` in `packages/types/src/index.ts`.
enum UserRole {
  superAdmin('SUPER_ADMIN'),
  salonOwner('SALON_OWNER'),
  manager('MANAGER'),
  receptionist('RECEPTIONIST'),
  staff('STAFF'),
  customer('CUSTOMER');

  final String value;
  const UserRole(this.value);

  static UserRole fromJson(String value) {
    return UserRole.values.firstWhere(
      (r) => r.value == value,
      orElse: () => UserRole.customer,
    );
  }
}
