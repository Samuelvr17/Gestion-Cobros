import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/user_profile.dart';
import '../../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

class AuthState {
  final UserProfile? user;
  final bool isLoading;
  final String? errorMessage;

  AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  AuthState copyWith({
    Object? user = _sentinel,
    bool? isLoading,
    Object? errorMessage = _sentinel,
  }) {
    return AuthState(
      user: user == _sentinel ? this.user : (user as UserProfile?),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage == _sentinel ? this.errorMessage : (errorMessage as String?),
    );
  }

  static const _sentinel = Object();
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(AuthState());

  Future<void> checkSession() async {
    try {
      state = state.copyWith(isLoading: true);
      final user = await _authService.getCurrentUser();
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      // Handle error gracefully on startup (e.g. network issues)
      state = state.copyWith(
        user: null, 
        isLoading: false,
        errorMessage: 'Error al conectar: ${e.toString()}',
      );
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await _authService.login(email, password);
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await _authService.logout();
    state = AuthState();
  }

  Future<void> updatePassword(String newPassword) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _authService.changePassword(newPassword);
      // After changing password, we need to refresh the profile state
      await checkSession();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});
