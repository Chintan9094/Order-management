import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/repository_providers.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/network/auth_token_store.dart';
import '../../domain/entities/staff_user.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

@immutable
class AuthState {
  const AuthState({
    required this.status,
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  const AuthState.unknown()
      : status = AuthStatus.unknown,
        user = null,
        isLoading = true,
        errorMessage = null;

  final AuthStatus status;
  final StaffUser? user;
  final bool isLoading;
  final String? errorMessage;

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;

  AuthState copyWith({
    AuthStatus? status,
    StaffUser? user,
    bool clearUser = false,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._ref) : super(const AuthState.unknown()) {
    restoreSession();
  }

  final Ref _ref;

  Future<void> restoreSession() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final token =
          await _ref.read(authTokenStoreProvider).readStaffAccessToken();
      if (token == null || token.isEmpty) {
        state = const AuthState(
          status: AuthStatus.unauthenticated,
          isLoading: false,
        );
        return;
      }
      final user = await _ref.read(authRepositoryProvider).currentUser();
      if (user == null) {
        await _ref.read(authTokenStoreProvider).clearStaffTokens();
        state = const AuthState(
          status: AuthStatus.unauthenticated,
          isLoading: false,
        );
        return;
      }
      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
        isLoading: false,
      );
    } catch (_) {
      await _ref.read(authTokenStoreProvider).clearStaffTokens();
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        isLoading: false,
      );
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final session = await _ref.read(authRepositoryProvider).login(
            email: email,
            password: password,
          );
      state = AuthState(
        status: AuthStatus.authenticated,
        user: session.user,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        isLoading: false,
        errorMessage: ErrorMapper.userMessage(e),
      );
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _ref.read(authRepositoryProvider).logout();
    } catch (_) {
      await _ref.read(authTokenStoreProvider).clearStaffTokens();
    }
    state = const AuthState(
      status: AuthStatus.unauthenticated,
      isLoading: false,
    );
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref);
});
