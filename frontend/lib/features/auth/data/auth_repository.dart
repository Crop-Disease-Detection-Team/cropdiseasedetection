import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/config/app_config.dart';
import '../../../core/services/api_client.dart';

class AuthRepository {
  AuthRepository() : _apiClient = ApiClient(AppConfig.apiBaseUrl);

  final ApiClient _apiClient;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Dio get _dio => _apiClient.dio;

  Future<Map<String, dynamic>> signup(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('accounts/signup/', data: data);
      final result = Map<String, dynamic>.from(response.data as Map);
      if (result.containsKey('access') || result.containsKey('refresh')) {
        await _saveTokens(result);
      }
      return result;
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Signup failed'));
    }
  }

  Future<Map<String, dynamic>> verifyOtp(String email, String code) async {
    try {
      final response = await _dio.post('accounts/verify-otp/', data: {'email': email, 'code': code});
      final data = Map<String, dynamic>.from(response.data as Map);
      await _saveTokens(data);
      return data;
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'OTP verification failed'));
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post('accounts/login/', data: {'email': email, 'password': password});
      final data = Map<String, dynamic>.from(response.data as Map);
      await _saveTokens(data);
      return data;
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Login failed'));
    }
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await _dio.post('accounts/forgot-password/', data: {'email': email});
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Forgot password request failed'));
    }
  }

  Future<Map<String, dynamic>> resetPassword({required String email, required String code, required String password}) async {
    try {
      final response = await _dio.post('accounts/reset-password/', data: {'email': email, 'code': code, 'password': password});
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Password reset failed'));
    }
  }

  Future<Map<String, dynamic>> me() async {

    final response = await _dio.get('accounts/me/');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> updateProfile({
    required String username,
    required String district,
    required String phone,
  }) async {
    try {
      final response = await _dio.patch('accounts/me/', data: {
        'username': username,
        'district': district,
        'phone': phone,
      });
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Profile update failed'));
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      await _dio.post('accounts/change-password/', data: {
        'current_password': currentPassword,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      });
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Password change failed'));
    }
  }

  Future<void> _saveTokens(Map<String, dynamic> data) async {
    final access = data['access']?.toString();
    final refresh = data['refresh']?.toString();
    if (access != null) await _storage.write(key: 'access_token', value: access);
    if (refresh != null) await _storage.write(key: 'refresh_token', value: refresh);
  }

  Future<void> logout() async {
    final refresh = await _storage.read(key: 'refresh_token');
    if (refresh != null) {
      try {
        await _dio.post('accounts/logout/', data: {'refresh': refresh});
      } catch (_) {
        // Ignore logout endpoint failures; we still clear local state.
      }
    }
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }

  String _messageFromDio(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map && data.isNotEmpty) return data.values.first.toString();
    if (data != null) return data.toString();
    return fallback;
  }
}
