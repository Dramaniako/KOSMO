import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/shared_preferences_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/user_entity.dart';

class AuthState {
  final UserEntity? user;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    UserEntity? user,
    bool? isLoading,
    String? errorMessage,
    bool clearUser = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final id = prefs.getInt('auth_id');
    final email = prefs.getString('auth_email');
    final name = prefs.getString('auth_name');
    final isVerified = prefs.getBool('auth_is_verified') ?? false;

    if (email != null && name != null) {
      return AuthState(
        user: UserEntity(
          id: id,
          name: name,
          email: email,
          isVerified: isVerified,
        ),
      );
    }
    return const AuthState();
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final repository = ref.read(authRepositoryProvider);
      final user = await repository.login(email, password);

      if (user != null) {
        final prefs = ref.read(sharedPreferencesProvider);
        await prefs.setInt('auth_id', user.id ?? 0);
        await prefs.setString('auth_email', user.email);
        await prefs.setString('auth_name', user.name);
        await prefs.setBool('auth_is_verified', user.isVerified);

        state = AuthState(user: user);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Email atau Kata Sandi salah.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal melakukan login: $e',
      );
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final repository = ref.read(authRepositoryProvider);
      final user = await repository.register(name, email, password);

      if (user != null) {
        final prefs = ref.read(sharedPreferencesProvider);
        await prefs.setInt('auth_id', user.id ?? 0);
        await prefs.setString('auth_email', user.email);
        await prefs.setString('auth_name', user.name);
        await prefs.setBool('auth_is_verified', user.isVerified);

        state = AuthState(user: user);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Gagal mendaftarkan akun.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove('auth_id');
    await prefs.remove('auth_email');
    await prefs.remove('auth_name');
    await prefs.remove('auth_is_verified');

    state = const AuthState();
  }

  Future<void> verifyUser() async {
    if (state.user != null) {
      try {
        final repository = ref.read(authRepositoryProvider);
        final success = await repository.verifyUser(state.user!.email);

        if (success) {
          final updatedUser = state.user!.copyWith(isVerified: true);

          final prefs = ref.read(sharedPreferencesProvider);
          await prefs.setBool('auth_is_verified', true);

          state = AuthState(user: updatedUser);
        }
      } catch (e) {
        debugPrint('Error verifying user: $e');
      }
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
