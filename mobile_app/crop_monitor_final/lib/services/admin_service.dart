import '../core/api_config.dart';
import 'api_service.dart';

class AdminService {
  final ApiService _api = ApiService();

  /// GET /api/admin/dashboard/stats
  Future<Map<String, dynamic>> getDashboardStats() async {
    final json = await _api.get(ApiConfig.adminDashboardStats);
    return json as Map<String, dynamic>;
  }

  /// GET /api/admin/users?search=&page=&per_page=
  Future<Map<String, dynamic>> getUsers(
      {String search = '', int page = 1, int perPage = 20}) async {
    final uri = Uri.parse(ApiConfig.adminUsers).replace(queryParameters: {
      if (search.isNotEmpty) 'search': search,
      'page': '$page',
      'per_page': '$perPage',
    });
    final json = await _api.get(uri.toString());
    return json as Map<String, dynamic>;
  }

  /// GET /api/admin/users/<id>
  Future<Map<String, dynamic>> getUserDetail(int userId) async {
    final json = await _api.get('${ApiConfig.adminUsers}/$userId');
    return json as Map<String, dynamic>;
  }

  /// PUT /api/admin/users/<id>/status — { is_active: bool }
  Future<void> setUserStatus(int userId, bool isActive) =>
      _api.put('${ApiConfig.adminUsers}/$userId/status',
          body: {'is_active': isActive});

  /// DELETE /api/admin/users/<id>
  Future<void> deleteUser(int userId) =>
      _api.delete('${ApiConfig.adminUsers}/$userId');

  /// GET /api/admin/scans?page=&per_page=
  Future<Map<String, dynamic>> getAllScans(
      {int page = 1, int perPage = 20}) async {
    final uri = Uri.parse(ApiConfig.adminScans).replace(queryParameters: {
      'page': '$page',
      'per_page': '$perPage',
    });
    final json = await _api.get(uri.toString());
    return json as Map<String, dynamic>;
  }

  /// GET /api/admin/feedback?status=&page=&per_page=
  Future<Map<String, dynamic>> getAllFeedback(
      {String? status, int page = 1, int perPage = 20}) async {
    final uri = Uri.parse(ApiConfig.adminFeedback).replace(queryParameters: {
      if (status != null && status.isNotEmpty) 'status': status,
      'page': '$page',
      'per_page': '$perPage',
    });
    final json = await _api.get(uri.toString());
    return json as Map<String, dynamic>;
  }

  /// PUT /api/admin/feedback/<id>/status — { status: 'pending'|'reviewed'|'resolved' }
  Future<void> setFeedbackStatus(int feedbackId, String status) =>
      _api.put('${ApiConfig.adminFeedback}/$feedbackId/status',
          body: {'status': status});
}
