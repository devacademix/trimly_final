import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
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

class FavoritesNotifier extends StateNotifier<List<Salon>> {
  FavoritesNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('favorite_salons') ?? [];
    state = list.map((item) {
      try {
        return Salon.fromJson(jsonDecode(item) as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    }).whereType<Salon>().toList();
  }

  Future<void> toggle(Salon salon) async {
    final prefs = await SharedPreferences.getInstance();
    final exists = state.any((s) => s.id == salon.id);
    if (exists) {
      state = state.where((s) => s.id != salon.id).toList();
    } else {
      state = [...state, salon];
    }
    final list = state.map((s) => jsonEncode({
      'id': s.id,
      'name': s.name,
      'slug': s.slug,
      'description': s.description,
      'logoUrl': s.logoUrl,
      'coverImageUrl': s.coverImageUrl,
      'primaryCity': s.primaryCity,
      'branchCount': s.branchCount,
      'rating': s.rating,
      'reviewCount': s.reviewCount,
    })).toList();
    await prefs.setStringList('favorite_salons', list);
  }
}

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, List<Salon>>((ref) {
  return FavoritesNotifier();
});
