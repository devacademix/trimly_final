import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/salon_login_screen.dart';
import '../../features/dashboard/salon_dashboard_screen.dart';
import '../../features/bookings/bookings_list_screen.dart';
import '../../features/navigation/salon_navigation.dart';
import '../../features/ai/ai_assistant_screen.dart';

class SalonRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SalonLoginScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const SalonNavigation(),
      ),
      GoRoute(
        path: '/bookings-list',
        builder: (context, state) => const BookingsListScreen(),
      ),
      GoRoute(
        path: '/ai-assistant',
        builder: (context, state) => const AiAssistantScreen(),
      ),
    ],
  );
}
