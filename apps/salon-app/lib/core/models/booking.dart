enum BookingStatus {
  pending('PENDING'),
  confirmed('CONFIRMED'),
  completed('COMPLETED'),
  cancelled('CANCELLED'),
  noShow('NO_SHOW');

  final String value;
  const BookingStatus(this.value);

  static BookingStatus fromJson(String value) {
    return BookingStatus.values.firstWhere((s) => s.value == value, orElse: () => BookingStatus.pending);
  }

  String get label {
    switch (this) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.noShow:
        return 'No-show';
    }
  }
}

/// Mirrors the shape returned by `GET /booking` (BookingService.listBookings)
/// when called by a salon owner/staff — scoped to their tenant.
class Booking {
  final String id;
  final String tenantId;
  final String branchId;
  final DateTime startTime;
  final DateTime endTime;
  final BookingStatus status;
  final double totalPrice;
  final String? notes;
  final String? branchName;
  final String? customerName;
  final String? customerEmail;
  final String? customerPhone;
  final String? staffName;
  final String serviceName;
  final int serviceDuration;

  const Booking({
    required this.id,
    required this.tenantId,
    required this.branchId,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.totalPrice,
    required this.serviceName,
    required this.serviceDuration,
    this.notes,
    this.branchName,
    this.customerName,
    this.customerEmail,
    this.customerPhone,
    this.staffName,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    final items = json['items'] as List? ?? [];
    final firstItem = items.isNotEmpty ? items.first as Map<String, dynamic> : null;
    final service = firstItem?['service'] as Map<String, dynamic>?;
    final branch = json['branch'] as Map<String, dynamic>?;
    final customer = json['customer'] as Map<String, dynamic>?;
    final staff = json['staff'] as Map<String, dynamic>?;
    final staffUser = staff?['user'] as Map<String, dynamic>?;

    return Booking(
      id: json['id'] as String,
      tenantId: json['tenantId'] as String,
      branchId: json['branchId'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      status: BookingStatus.fromJson(json['status'] as String),
      totalPrice: double.parse(json['totalPrice'].toString()),
      notes: json['notes'] as String?,
      branchName: branch?['name'] as String?,
      customerName: customer?['fullName'] as String?,
      customerEmail: customer?['email'] as String?,
      customerPhone: customer?['phone'] as String?,
      staffName: staffUser?['fullName'] as String?,
      serviceName: service?['name'] as String? ?? 'Service',
      serviceDuration: service?['duration'] as int? ?? 0,
    );
  }
}
