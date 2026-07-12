import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/booking.dart';
import '../models/wallet.dart';
import '../models/staff_member.dart';
import '../models/salon_customer.dart';
import '../models/inventory.dart';
import '../models/chat.dart';
import 'api_providers.dart';

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
