import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/booking.dart';
import '../models/wallet.dart';
import '../models/staff_member.dart';
import '../models/salon_customer.dart';
import '../models/inventory.dart';
import '../models/chat.dart';
import '../models/dashboard_stats.dart';
import '../models/salon_profile.dart';
import '../models/salon_service.dart';
import '../models/analytics.dart';
import '../models/marketing.dart';
import '../models/payroll.dart';
import '../models/ai_insight.dart';
import 'api_providers.dart';

final aiInsightsProvider = FutureProvider.autoDispose<AiInsights>((ref) {
  return ref.watch(salonRepositoryProvider).getAiInsights();
});

final monthlyPayrollProvider = FutureProvider.family.autoDispose<List<StaffPayrollResult>, Map<String, int>>((ref, params) {
  final month = params['month']!;
  final year = params['year']!;
  return ref.watch(payrollRepositoryProvider).getMonthlyPayroll(month, year);
});

final bookingsListProvider = FutureProvider.autoDispose<List<Booking>>((ref) {
  return ref.watch(bookingRepositoryProvider).listBookings();
});

final walletDetailsProvider = FutureProvider.autoDispose<WalletDetails>((ref) {
  return ref.watch(walletRepositoryProvider).getWalletDetails();
});

final staffListProvider = FutureProvider.autoDispose<List<StaffMember>>((ref) {
  return ref.watch(salonRepositoryProvider).getStaff();
});

final salonCustomersProvider = FutureProvider.autoDispose<List<SalonCustomer>>((ref) {
  return ref.watch(salonRepositoryProvider).getCustomers();
});

final productCategoriesProvider = FutureProvider.autoDispose<List<ProductCategory>>((ref) {
  return ref.watch(inventoryRepositoryProvider).getCategories();
});

final productsListProvider = FutureProvider.autoDispose<List<Product>>((ref) {
  return ref.watch(inventoryRepositoryProvider).getProducts();
});

final chatRoomsProvider = FutureProvider.autoDispose<List<ChatRoom>>((ref) {
  return ref.watch(chatRepositoryProvider).getRooms();
});

// ─── Dashboard Providers ─────────────────────────────────────────────────────

final dashboardStatsProvider = FutureProvider.autoDispose<DashboardStats>((ref) {
  return ref.watch(salonRepositoryProvider).getDashboardStats();
});

final salonProfileProvider = FutureProvider.autoDispose<SalonProfile>((ref) {
  return ref.watch(salonRepositoryProvider).getProfile();
});

// ─── Service Providers ────────────────────────────────────────────────────────

final serviceCategoriesProvider = FutureProvider.autoDispose<List<ServiceCategory>>((ref) {
  return ref.watch(salonRepositoryProvider).getCategories();
});

final servicesListProvider = FutureProvider.autoDispose<List<SalonService>>((ref) {
  return ref.watch(salonRepositoryProvider).getServices();
});

// ─── Analytics Providers ─────────────────────────────────────────────────────

final peakHoursProvider = FutureProvider.autoDispose<List<PeakHour>>((ref) {
  return ref.watch(salonRepositoryProvider).getPeakHours();
});

final topServicesProvider = FutureProvider.autoDispose<List<TopService>>((ref) {
  return ref.watch(salonRepositoryProvider).getTopServices();
});

// ─── Marketing & Review Providers ────────────────────────────────────────────

final marketingCouponsProvider = FutureProvider.autoDispose<List<Coupon>>((ref) {
  return ref.watch(salonRepositoryProvider).getCoupons();
});

final salonReviewsProvider = FutureProvider.autoDispose.family<List<SalonReview>, String>((ref, salonId) {
  return ref.watch(salonRepositoryProvider).getReviews(salonId);
});
