import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

class AuthState {
  final Map<String, dynamic>? user;
  final String? tempEmail;
  final bool isLoading;
  final String? error;

  AuthState({this.user, this.tempEmail, this.isLoading = false, this.error});

  AuthState copyWith({Map<String, dynamic>? user, String? tempEmail, bool? isLoading, String? error, bool clearError = false}) {
    return AuthState(
      user: user ?? this.user,
      tempEmail: tempEmail ?? this.tempEmail,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(AuthState());

  Future<bool> signup(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _repository.signup(data);
      if (res.containsKey('user')) {
        final user = Map<String, dynamic>.from(res['user'] as Map);
        await _cacheUserLocally(user);
        state = state.copyWith(isLoading: false, user: user, tempEmail: null);
        return true;
      }
      final devOtp = res['dev_otp'];
      if (devOtp != null) {
        // Kept for local backend development where email delivery is disabled.
        // ignore: avoid_print
        print('--- DEV OTP: $devOtp ---');
      }
      state = state.copyWith(isLoading: false, tempEmail: data['email']);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> verifyOtp(String code) async {
    if (state.tempEmail == null) return false;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _repository.verifyOtp(state.tempEmail!, code);
      final user = Map<String, dynamic>.from(res['user'] as Map);
      await _cacheUserLocally(user);
      state = state.copyWith(isLoading: false, user: user);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _repository.login(email, password);
      final user = Map<String, dynamic>.from(res['user'] as Map);
      await _cacheUserLocally(user);
      state = state.copyWith(isLoading: false, user: user);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> forgotPassword(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _repository.forgotPassword(email);
      final devOtp = res['dev_otp'];
      if (devOtp != null) {
        // ignore: avoid_print
        print('--- DEV RESET OTP: $devOtp ---');
      }
      state = state.copyWith(isLoading: false, tempEmail: email);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> resetPassword({required String code, required String password}) async {
    if (state.tempEmail == null) return false;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository.resetPassword(email: state.tempEmail!, code: code, password: password);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> loadCurrentUser({bool isOnline = true}) async {

    final prefs = await SharedPreferences.getInstance();
    final cachedUserString = prefs.getString('cached_user_profile');
    Map<String, dynamic>? cachedUser;

    if (cachedUserString != null) {
      try {
        cachedUser = jsonDecode(cachedUserString) as Map<String, dynamic>;
        state = state.copyWith(user: cachedUser);
      } catch (_) {
        cachedUser = null;
      }
    }

    if (!isOnline) {
      return;
    }

    try {
      final user = await _repository.me();
      await _cacheUserLocally(user);
      state = state.copyWith(user: user);
    } on Exception {
      final hasAccessToken = (await const FlutterSecureStorage().read(key: 'access_token')) != null;
      if (!hasAccessToken) {
        await logout();
        return;
      }
      if (cachedUser == null) {
        await logout();
      }
    }
  }

  Future<bool> updateProfile({required String username, required String district, required String phone}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repository.updateProfile(username: username, district: district, phone: phone);
      await _cacheUserLocally(user);
      state = state.copyWith(isLoading: false, user: user);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cached_user_profile');
    await prefs.remove('is_logged_in');
    await prefs.remove('user_id');
    await prefs.remove('user_role');
    state = AuthState(); // Reset state
  }

  Future<void> _cacheUserLocally(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_user_profile', jsonEncode(user));
    await prefs.setBool('is_logged_in', true);
    await prefs.setInt('user_id', user['id'] as int);
    await prefs.setString('user_role', user['role']?.toString() ?? 'user');
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});
