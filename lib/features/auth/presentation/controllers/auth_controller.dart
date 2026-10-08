import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/user_profile_model.dart';
import '../../../../core/models/user_role.dart';
import '../../../../core/services/supabase_service.dart';

final supabaseServiceProvider = Provider<SupabaseService>((ref) => SupabaseService());

class AuthState {
  final bool isLoading;
  final UserProfile? userProfile;
  final String? errorMessage;

  const AuthState({
    this.isLoading = false,
    this.userProfile,
    this.errorMessage,
  });

  bool get isAuthenticated => userProfile != null;
  UserRole? get role => userProfile?.role;

  AuthState copyWith({
    bool? isLoading,
    UserProfile? userProfile,
    String? errorMessage,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      userProfile: userProfile ?? this.userProfile,
      errorMessage: errorMessage,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  final SupabaseService _service;

  AuthController(this._service) : super(const AuthState()) {
    checkInitialSession();
  }

  Future<void> checkInitialSession() async {
    state = state.copyWith(isLoading: true);
    try {
      final user = _service.currentUser;
      if (user != null) {
        final profile = await _service.fetchUserProfile(user.id);
        state = state.copyWith(isLoading: false, userProfile: profile);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _service.signInWithPassword(email: email, password: password);
      final userId = response.user?.id;
      if (userId != null) {
        final profile = await _service.fetchUserProfile(userId);
        state = state.copyWith(isLoading: false, userProfile: profile);
        return true;
      }
      state = state.copyWith(isLoading: false, errorMessage: 'User tidak ditemukan');
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await _service.signOut();
    state = const AuthState();
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  final service = ref.watch(supabaseServiceProvider);
  return AuthController(service);
});
