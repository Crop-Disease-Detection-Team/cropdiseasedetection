import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/token_storage.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/api_exception.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// Holds the logged-in user + session status app-wide.
/// Wrap MaterialApp with ChangeNotifierProvider(create: (_) => AuthProvider())
/// and read it anywhere with context.watch<AuthProvider>() / context.read<...>().
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus status = AuthStatus.unknown;
  AppUser? currentUser;
  String? lastError;

  bool get isAdmin => currentUser?.isAdmin ?? false;

  /// Called once from splash screen to see if a saved session exists.
  Future<void> tryAutoLogin() async {
    final token = await TokenStorage.getAccessToken();
    final userJson = await TokenStorage.getUserJson();
    if (token == null || userJson == null) {
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    try {
      // Validate token is still accepted by the backend.
      final result = await _authService.me();
      currentUser = AppUser.fromJson(result['user'] as Map<String, dynamic>);
      await TokenStorage.updateUserJson(jsonEncode(currentUser!.toJson()));
      status = AuthStatus.authenticated;
    } catch (_) {
      await TokenStorage.clear();
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    lastError = null;
    try {
      final result = await _authService.login(email: email, password: password);
      final user = AppUser.fromJson(result['user'] as Map<String, dynamic>);
      await TokenStorage.saveSession(
        accessToken: result['access_token'],
        refreshToken: result['refresh_token'],
        userJson: jsonEncode(user.toJson()),
      );
      currentUser = user;
      status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      lastError = e.message;
      // Surface the "requires_verification" flag so the login screen can
      // route the user to the OTP screen instead of just showing an error.
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
    } catch (_) {
      // ignore network errors on logout — clear local session regardless
    }
    await TokenStorage.clear();
    currentUser = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void updateUser(AppUser user) {
    currentUser = user;
    TokenStorage.updateUserJson(jsonEncode(user.toJson()));
    notifyListeners();
  }
}
