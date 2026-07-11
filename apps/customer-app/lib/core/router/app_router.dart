import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/login_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/salon/salon_details_screen.dart';
import '../../features/booking/booking_screen.dart';

import '../../features/navigation/main_navigation.dart';

import '../../features/booking/payment_gateway_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const MainNavigation(),
      ),
      GoRoute(
        path: '/salon-details',
        builder: (context, state) {
          final salon = state.extra as Map<String, dynamic>;
          return SalonDetailsScreen(salon: salon);
        },
      ),
      GoRoute(
        path: '/booking',
        builder: (context, state) {
          final bookingData = state.extra as Map<String, dynamic>;
          return BookingScreen(bookingData: bookingData);
        },
      ),
      GoRoute(
        path: '/payment-gateway',
        builder: (context, state) {
          final checkoutData = state.extra as Map<String, dynamic>;
          return PaymentGatewayScreen(checkoutData: checkoutData);
        },
      ),
    ],
  );
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        context.go('/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}


