import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/services/api_client.dart';

final adminRepositoryProvider = Provider((ref) => AdminRepository());

class AdminRepository {
  AdminRepository() : _apiClient = ApiClient(AppConfig.apiBaseUrl);

  final ApiClient _apiClient;
  Dio get _dio => _apiClient.dio;

  Future<Map<String, dynamic>> fetchDashboardStats() async {
    try {
      final response = await _dio.get('accounts/admin/stats/');
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Failed to fetch admin stats'));
    }
  }

  Future<List<Map<String, dynamic>>> fetchUsers({String? search, String? role}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (role != null && role.isNotEmpty) queryParams['role'] = role;

      final response = await _dio.get('accounts/admin/users/', queryParameters: queryParams);
      final list = response.data as List? ?? [];
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Failed to fetch users'));
    }
  }

  Future<void> updateUserAction(int userId, String action) async {
    try {
      await _dio.post('accounts/admin/users/$userId/$action/');
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'User action failed'));
    }
  }

  Future<void> deleteUser(int userId) async {
    try {
      await _dio.delete('accounts/admin/users/$userId/');
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Delete user failed'));
    }
  }

  Future<List<Map<String, dynamic>>> fetchAdminScans({String? status, String? search}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _dio.get('scans/admin/scans/', queryParameters: queryParams);
      final list = response.data as List? ?? [];
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Failed to fetch admin scans'));
    }
  }

  Future<void> deleteAdminScan(int scanId) async {
    try {
      await _dio.delete('scans/admin/scans/$scanId/');
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Delete scan failed'));
    }
  }

  Future<List<Map<String, dynamic>>> fetchAdminDiseases() async {
    try {
      final response = await _dio.get('scans/admin/diseases/');
      final list = response.data as List? ?? [];
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Failed to fetch admin diseases'));
    }
  }

  Future<void> createDisease(Map<String, dynamic> data) async {
    try {
      await _dio.post('scans/admin/diseases/', data: data);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Create disease failed'));
    }
  }

  Future<void> deleteDisease(int diseaseId) async {
    try {
      await _dio.delete('scans/admin/diseases/$diseaseId/');
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Delete disease failed'));
    }
  }

  Future<Map<String, dynamic>> fetchSettings() async {
    try {
      final response = await _dio.get('common/admin/settings/');
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Failed to fetch settings'));
    }
  }

  Future<void> updateSettings(Map<String, dynamic> data) async {
    try {
      await _dio.patch('common/admin/settings/', data: data);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Update settings failed'));
    }
  }

  Future<List<Map<String, dynamic>>> fetchLogs() async {
    try {
      final response = await _dio.get('common/admin/logs/');
      final list = response.data as List? ?? [];
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Failed to fetch logs'));
    }
  }

  String _messageFromDio(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map && data.isNotEmpty) return data.values.first.toString();
    if (data != null) return data.toString();
    return fallback;
  }
}
