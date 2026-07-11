import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_client.dart';
import '../storage/local_storage.dart';

// Provider for SharedPreferences (overridden in main)
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

// Provider for LocalStorage
final localStorageProvider = Provider<LocalStorage>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalStorage(prefs);
});

// Provider for ApiClient
final apiClientProvider = Provider<ApiClient>((ref) {
  final localStorage = ref.watch(localStorageProvider);
  return ApiClient(localStorage: localStorage);
});
