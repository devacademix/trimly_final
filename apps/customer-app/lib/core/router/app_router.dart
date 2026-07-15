import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../models/booking_draft.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/signup_screen.dart';
import '../../features/onboarding/customer_onboarding_screen.dart';
import '../../features/salon/salon_details_screen.dart';
import '../../features/booking/booking_screen.dart';
import '../../features/navigation/main_navigation.dart';
import '../../features/booking/payment_gateway_screen.dart';
import '../../features/chat/chat_list_screen.dart';
import '../../features/chat/chat_conversation_screen.dart';

/// Bridges Riverpod state changes into go_router's `refreshListenable`, so
/// the router re-evaluates `redirect` whenever auth state changes (e.g.
/// after login, logout, or a session expiring mid-session).
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen(authControllerProvider, (previous, next) {
      if (previous?.status != next.status || 
          previous?.user?.onboardingComplete != next.user?.onboardingComplete) {
        notifyListeners();
      }
    });
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final path = state.matchedLocation;

      if (authState.status == AuthStatus.unknown) {
        return path == '/' ? null : '/';
      }
      if (authState.status == AuthStatus.unauthenticated) {
        if (path == '/login' || path == '/signup') return null;
        return '/login';
      }
      // authenticated
      final user = authState.user;
      if (user != null && !user.onboardingComplete) {
        if (path == '/onboarding' || path == '/login' || path == '/signup' || path == '/') return '/onboarding';
        return null;
      }
      
      if (path == '/login' || path == '/signup' || path == '/' || path == '/onboarding') return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const CustomerOnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const MainNavigation(),
      ),
      GoRoute(
        path: '/salon-details/:id',
        builder: (context, state) {
          final salonId = state.pathParameters['id']!;
          return SalonDetailsScreen(salonId: salonId);
        },
      ),
      GoRoute(
        path: '/booking',
        builder: (context, state) {
          final draft = state.extra as BookingDraft;
          return BookingScreen(draft: draft);
        },
      ),
      GoRoute(
        path: '/payment-gateway',
        builder: (context, state) {
          final checkoutDraft = state.extra as CheckoutDraft;
          return PaymentGatewayScreen(checkoutDraft: checkoutDraft);
        },
      ),
      GoRoute(
        path: '/chat',
        builder: (context, state) => const ChatListScreen(),
      ),
      GoRoute(
        path: '/chat/:roomId',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          final title = state.extra as String? ?? 'Chat';
          return ChatConversationScreen(roomId: roomId, title: title);
        },
      ),
    ],
  );
});

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
