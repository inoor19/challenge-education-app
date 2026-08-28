import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/models/api_models.dart';
import '../../../core/providers/api_provider.dart';

// ─── Auth State ───────────────────────────────────────────────────────────────

class AuthState {
  final AuthUser? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});

  bool get isAuthenticated => user != null;

  AuthState copyWith({AuthUser? user, bool? isLoading, String? error}) =>
      AuthState(
        user: user ?? this.user,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

// ─── Auth Notifier ────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _api;

  AuthNotifier(this._api) : super(const AuthState());

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _api.login(email, password);
      await _api.saveToken(data['token']);
      final user = AuthUser.fromJson(data['user']);
      state = AuthState(user: user);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractError(e),
      );
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _api.register(name, email, password);
      await _api.saveToken(data['token']);
      final user = AuthUser.fromJson(data['user']);
      state = AuthState(user: user);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractError(e),
      );
      return false;
    }
  }

  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }

  Future<void> logout() async {
    try {
      await _api.logout();
    } catch (_) {
      await _api.clearToken();
    }
    state = const AuthState();
  }

  Future<bool> tryAutoLogin() async {
    final hasToken = await _api.hasToken();
    if (!hasToken) return false;

    try {
      final userData = await _api.me();
      final user = AuthUser.fromJson(userData);
      state = AuthState(user: user);
      return true;
    } catch (_) {
      await _api.clearToken();
      return false;
    }
  }

  String _extractError(dynamic e) {
    return AppError.message(
      e,
      fallback: 'تعذر تسجيل الدخول. تحقق من البيانات وحاول مجدداً.',
    );
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.watch(apiClientProvider)),
);
