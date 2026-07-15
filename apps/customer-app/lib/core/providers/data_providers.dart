import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/salon.dart';
import '../models/booking.dart';
import '../models/chat.dart';
import '../models/wallet.dart';
import '../models/marketing.dart';
import 'api_providers.dart';

final salonListProvider = FutureProvider.autoDispose.family<List<Salon>, String>((ref, search) {
  return ref.watch(salonRepositoryProvider).browseSalons(search: search);
});

final salonDetailProvider = FutureProvider.autoDispose.family<SalonDetail, String>((ref, salonId) {
  return ref.watch(salonRepositoryProvider).getSalonDetail(salonId);
});

final myBookingsProvider = FutureProvider.autoDispose<List<Booking>>((ref) {
  return ref.watch(bookingRepositoryProvider).listMyBookings();
});

final chatRoomsProvider = FutureProvider.autoDispose<List<ChatRoom>>((ref) {
  return ref.watch(chatRepositoryProvider).getRooms();
});

final walletDetailsProvider = FutureProvider.autoDispose<WalletDetails>((ref) {
  return ref.watch(walletRepositoryProvider).getWalletDetails();
});

final salonReviewsProvider = FutureProvider.autoDispose.family<List<SalonReview>, String>((ref, salonId) {
  return ref.watch(marketingRepositoryProvider).getSalonReviews(salonId);
});
