import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_user.dart';
import '../models/user_role.dart';
import '../network/api_exception.dart';
import 'api_providers.dart';
import 'onboarding_provider.dart';

enum AuthStatus {
  /// Still checking for a persisted session (splash screen).
  unknown,
  authenticated,
  unauthenticated,
}

class AuthState {
  final AuthStatus status;
  final AuthUser? user;
  final String? errorMessage;

  const AuthState({this.status = AuthStatus.unknown, this.user, this.errorMessage});

  AuthState copyWith({AuthStatus? status, AuthUser? user, String? errorMessage}) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

/// Roles allowed to sign into the salon (business) app.
const _allowedRoles = [UserRole.salonOwner, UserRole.staff];

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    final apiClient = ref.watch(apiClientProvider);
    apiClient.onSessionExpired = () {
      state = const AuthState(status: AuthStatus.unauthenticated, errorMessage: 'Your session expired. Please sign in again.');
    };

    _restoreSession();
    return const AuthState();
  }

  Future<void> _restoreSession() async {
    try {
      final user = await ref.read(authRepositoryProvider).fetchCurrentUser();
      if (user != null) {
        await ref.read(onboardingControllerProvider.notifier).fetchStatus();
      }
      state = user != null
          ? AuthState(status: AuthStatus.authenticated, user: user)
          : const AuthState(status: AuthStatus.unauthenticated);
      if (user != null) _registerPushToken();
    } catch (_) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  // Fire-and-forget — push registration should never block or fail the auth flow.
  void _registerPushToken() {
    ref.read(pushNotificationServiceProvider).initialize();
  }

  /// Returns true on success. On failure, [state.errorMessage] is set.
  Future<bool> loginWithOtp({required String phone, required String otp, required String role}) async {
    try {
      final user = await ref.read(authRepositoryProvider).loginWithOtp(phone: phone, otp: otp, role: role);

      if (!_allowedRoles.contains(user.role)) {
        await ref.read(authRepositoryProvider).logout();
        state = const AuthState(
          status: AuthStatus.unauthenticated,
          errorMessage: 'This app is for salon owners and staff only.',
        );
        return false;
      }

      state = AuthState(status: AuthStatus.authenticated, user: user);
      await ref.read(onboardingControllerProvider.notifier).fetchStatus();
      _registerPushToken();
      return true;
    } on ApiException catch (e) {
      state = AuthState(status: AuthStatus.unauthenticated, errorMessage: e.message);
      return false;
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Called after OTP verification completes externally (e.g. from onboarding).
  /// Re-fetches the current user to restore the authenticated state.
  Future<void> restoreAfterOtp() async {
    try {
      final user = await ref.read(authRepositoryProvider).fetchCurrentUser();
      if (user != null) {
        await ref.read(onboardingControllerProvider.notifier).fetchStatus();
        state = AuthState(status: AuthStatus.authenticated, user: user);
        _registerPushToken();
      }
    } catch (_) {
      // Will be redirected by router to login
    }
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);
