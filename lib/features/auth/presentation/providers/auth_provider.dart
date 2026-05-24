import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/shared_preferences_provider.dart';
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
    final email = prefs.getString('auth_email');
    final name = prefs.getString('auth_name');
    final isVerified = prefs.getBool('auth_is_verified') ?? false;

    if (email != null && name != null) {
      return AuthState(
        user: UserEntity(
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

    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 800));

    if (email.isNotEmpty && password.length >= 6) {
      final name = email.split('@')[0];
      final userName = name.isNotEmpty
          ? '${name[0].toUpperCase()}${name.substring(1)}'
          : 'Budi';

      final user = UserEntity(
        name: userName,
        email: email,
        isVerified: false,
      );

      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString('auth_email', email);
      await prefs.setString('auth_name', userName);
      await prefs.setBool('auth_is_verified', false);

      state = AuthState(user: user);
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Email atau Kata Sandi salah.',
      );
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 800));

    if (name.isNotEmpty && email.isNotEmpty && password.length >= 6) {
      final user = UserEntity(
        name: name,
        email: email,
        isVerified: false,
      );

      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString('auth_email', email);
      await prefs.setString('auth_name', name);
      await prefs.setBool('auth_is_verified', false);

      state = AuthState(user: user);
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal membuat akun. Periksa data Anda.',
      );
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove('auth_email');
    await prefs.remove('auth_name');
    await prefs.remove('auth_is_verified');

    state = const AuthState();
  }

  Future<void> verifyUser() async {
    if (state.user != null) {
      final updatedUser = state.user!.copyWith(isVerified: true);

      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setBool('auth_is_verified', true);

      state = AuthState(user: updatedUser);
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
