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
    final role = prefs.getString('auth_role') ?? 'tenant';
    final age = prefs.getInt('auth_age');
    final phoneNumber = prefs.getString('auth_phone_number');
    final gender = prefs.getString('auth_gender');
    final address = prefs.getString('auth_address');

    if (email != null && name != null) {
      return AuthState(
        user: UserEntity(
          id: id,
          name: name,
          email: email,
          isVerified: isVerified,
          role: role,
          age: age == 0 ? null : age,
          phoneNumber: phoneNumber,
          gender: gender,
          address: address,
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
        await prefs.setString('auth_role', user.role);
        await prefs.setInt('auth_age', user.age ?? 0);
        await prefs.setString('auth_phone_number', user.phoneNumber ?? '');
        await prefs.setString('auth_gender', user.gender ?? '');
        await prefs.setString('auth_address', user.address ?? '');

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
        await prefs.setString('auth_role', user.role);
        await prefs.setInt('auth_age', 0);
        await prefs.setString('auth_phone_number', '');
        await prefs.setString('auth_gender', '');
        await prefs.setString('auth_address', '');

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
    await prefs.remove('auth_role');
    await prefs.remove('auth_age');
    await prefs.remove('auth_phone_number');
    await prefs.remove('auth_gender');
    await prefs.remove('auth_address');

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

  Future<bool> updateProfile({
    required String name,
    required int age,
    required String phoneNumber,
    required String gender,
    required String address,
  }) async {
    final user = state.user;
    if (user == null) return false;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repository = ref.read(authRepositoryProvider);
      final success = await repository.updateProfile(
        id: user.id!,
        name: name,
        age: age,
        phoneNumber: phoneNumber,
        gender: gender,
        address: address,
      );

      if (success) {
        final updatedUser = user.copyWith(
          name: name,
          age: age,
          phoneNumber: phoneNumber,
          gender: gender,
          address: address,
        );

        final prefs = ref.read(sharedPreferencesProvider);
        await prefs.setString('auth_name', name);
        await prefs.setInt('auth_age', age);
        await prefs.setString('auth_phone_number', phoneNumber);
        await prefs.setString('auth_gender', gender);
        await prefs.setString('auth_address', address);

        state = AuthState(user: updatedUser);
        return true;
      }
      state = state.copyWith(isLoading: false, errorMessage: 'Gagal memperbarui profil di database.');
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Error: $e');
      return false;
    }
  }

  Future<bool> upgradeRole(String newRole) async {
    final user = state.user;
    if (user == null) return false;

    try {
      final repository = ref.read(authRepositoryProvider);
      final success = await repository.upgradeRole(user.id!, newRole);

      if (success) {
        final updatedUser = user.copyWith(role: newRole);

        final prefs = ref.read(sharedPreferencesProvider);
        await prefs.setString('auth_role', newRole);

        state = AuthState(user: updatedUser);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error upgrading role: $e');
      return false;
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
