import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../network/api_client.dart';

/// Registers this device for Firebase Cloud Messaging and hands the token to
/// the backend (`POST /notifications/device-token`) so booking/payment
/// status changes can push straight to the customer's phone.
class PushNotificationService {
  final ApiClient apiClient;

  PushNotificationService({required this.apiClient});

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return;
      }

      final token = await messaging.getToken();
      if (token != null) {
        await _registerToken(token);
      }
      messaging.onTokenRefresh.listen(_registerToken);

      // Foreground messages don't show a system tray notification by
      // default on Android/iOS — surfacing them is left to a future
      // in-app banner; for now they're just logged so nothing is lost.
      FirebaseMessaging.onMessage.listen((message) {
        debugPrint('[PUSH] Foreground message: ${message.notification?.title} — ${message.notification?.body}');
      });
    } catch (e) {
      // Push is a nice-to-have — never let setup failures affect the rest
      // of the app (e.g. no Firebase project configured for this flavor).
      debugPrint('[PUSH] Initialization failed: $e');
    }
  }

  Future<void> _registerToken(String token) async {
    try {
      await apiClient.dio.post('/notifications/device-token', data: {'token': token});
    } catch (e) {
      debugPrint('[PUSH] Failed to register device token: $e');
    }
  }
}
