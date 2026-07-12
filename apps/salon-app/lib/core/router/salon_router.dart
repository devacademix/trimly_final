import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../features/auth/salon_login_screen.dart';
import '../../features/bookings/bookings_list_screen.dart';
import '../../features/navigation/salon_navigation.dart';
import '../../features/ai/ai_assistant_screen.dart';
import '../../features/staff/staff_roster_screen.dart';
import '../../features/inventory/inventory_screen.dart';
import '../../features/chat/chat_list_screen.dart';
import '../../features/chat/chat_conversation_screen.dart';

/// Bridges Riverpod state changes into go_router's `refreshListenable`, so
/// the router re-evaluates `redirect` whenever auth state changes (e.g.
/// after login, logout, or a session expiring mid-session).
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen(authControllerProvider, (previous, next) {
      if (previous?.status != next.status) notifyListeners();
    });
  }
}

final salonRouterProvider = Provider<GoRouter>((ref) {
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
        return path == '/login' ? null : '/login';
      }
      // authenticated
      if (path == '/login' || path == '/') return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SalonSplashScreen(),
      ),
      GoRoute(
        path: '/login',
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
      GoRoute(
        path: '/staff',
        builder: (context, state) => const StaffRosterScreen(),
      ),
      GoRoute(
        path: '/inventory',
        builder: (context, state) => const InventoryScreen(),
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

class SalonSplashScreen extends StatelessWidget {
  const SalonSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0F172A),
      body: Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
    );
  }
}
