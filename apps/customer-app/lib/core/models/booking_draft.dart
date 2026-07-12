import 'salon.dart';

/// In-memory state passed between the booking flow's screens via go_router's
/// `extra` — never serialized, so it can hold typed model instances directly.
class BookingDraft {
  final String tenantId;
  final String branchId;
  final String salonName;
  final SalonService service;
  final SalonStaff? staff;

  const BookingDraft({
    required this.tenantId,
    required this.branchId,
    required this.salonName,
    required this.service,
    this.staff,
  });
}

class CheckoutDraft {
  final String tenantId;
  final String bookingId;
  final String orderId;
  final String keyId;
  final double price;
  final String salonName;
  final String serviceName;
  final String paymentMethod;

  const CheckoutDraft({
    required this.tenantId,
    required this.bookingId,
    required this.orderId,
    required this.keyId,
    required this.price,
    required this.salonName,
    required this.serviceName,
    required this.paymentMethod,
  });
}
