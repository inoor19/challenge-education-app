import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
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
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final errors = data['errors'];
        if (errors is Map<String, dynamic>) {
          for (final errorList in errors.values.whereType<List>()) {
            if (errorList.isNotEmpty) {
              final message = errorList.first;
              if (message is String) return message;
            }
          }
        }

        final message = data['message'];
        if (message is String && message.isNotEmpty) return message;
      }

      if (e.response?.statusCode == 422 || e.response?.statusCode == 401) {
        return 'البريد الإلكتروني أو كلمة المرور غير صحيحة.';
      }
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        return 'تعذر الاتصال بالخادم. تحقق من الشبكة.';
      }
    }

    if (e is Exception) {
      final msg = e.toString();
      if (msg.contains('422') || msg.contains('401')) {
        return 'البريد الإلكتروني أو كلمة المرور غير صحيحة.';
      }
      if (msg.contains('SocketException') || msg.contains('connection')) {
        return 'تعذر الاتصال بالخادم. تحقق من الشبكة.';
      }
    }
    return 'حدث خطأ. يرجى المحاولة مجدداً.';
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.watch(apiClientProvider)),
);
