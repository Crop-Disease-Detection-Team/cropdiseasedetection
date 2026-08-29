import 'dart:io';
import '../core/api_config.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _api = ApiService();

  /// POST /api/auth/register
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? address,
  }) async {
    final result = await _api.post(ApiConfig.register, auth: false, body: {
      'name': name,
      'email': email,
      'password': password,
      'phone': phone ?? '',
      'address': address ?? '',
    });
    return result as Map<String, dynamic>;
  }

  /// POST /api/auth/verify-email
  Future<Map<String, dynamic>> verifyEmail(
      {required String email, required String otp}) async {
    final result = await _api.post(ApiConfig.verifyEmail,
        auth: false, body: {'email': email, 'otp': otp});
    return result as Map<String, dynamic>;
  }

  /// POST /api/auth/resend-verification
  Future<Map<String, dynamic>> resendVerification(String email) async {
    final result = await _api.post(ApiConfig.resendVerification,
        auth: false, body: {'email': email});
    return result as Map<String, dynamic>;
  }

  /// POST /api/auth/login -> { access_token, refresh_token, user }
  Future<Map<String, dynamic>> login(
      {required String email, required String password}) async {
    final result = await _api.post(ApiConfig.login,
        auth: false, body: {'email': email, 'password': password});
    return result as Map<String, dynamic>;
  }

  /// POST /api/auth/logout (requires bearer token)
  Future<void> logout() => _api.post(ApiConfig.logout);

  /// POST /api/auth/forgot-password
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final result = await _api.post(ApiConfig.forgotPassword,
        auth: false, body: {'email': email});
    return result as Map<String, dynamic>;
  }

  /// POST /api/auth/verify-reset-otp
  Future<Map<String, dynamic>> verifyResetOtp(
      {required String email, required String otp}) async {
    final result = await _api.post(ApiConfig.verifyResetOtp,
        auth: false, body: {'email': email, 'otp': otp});
    return result as Map<String, dynamic>;
  }

  /// POST /api/auth/reset-password
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final result = await _api.post(ApiConfig.resetPassword, auth: false, body: {
      'email': email,
      'otp': otp,
      'new_password': newPassword,
    });
    return result as Map<String, dynamic>;
  }

  /// GET /api/auth/me
  Future<Map<String, dynamic>> me() async {
    final result = await _api.get(ApiConfig.me);
    return result as Map<String, dynamic>;
  }

  /// POST /api/auth/change-password
  /// NOTE: backend expects 'old_password' (not 'current_password').
  Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final result = await _api.post(ApiConfig.changePassword, body: {
      'old_password': oldPassword,
      'new_password': newPassword,
    });
    return result as Map<String, dynamic>;
  }

  /// PUT /api/auth/update-profile
  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? phone,
    String? address,
  }) async {
    final result = await _api.put(ApiConfig.updateProfile, body: {
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
    });
    return result as Map<String, dynamic>;
  }

  /// POST /api/auth/upload-profile-pic (multipart, field name 'profile_pic')
  Future<Map<String, dynamic>> uploadProfilePic(File image) async {
    final result = await _api.uploadFile(ApiConfig.uploadProfilePic, image,
        fieldName: 'profile_pic');
    return result as Map<String, dynamic>;
  }
}