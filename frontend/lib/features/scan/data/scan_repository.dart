import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/services/api_client.dart';

final scanRepositoryProvider = Provider<ScanRepository>((ref) => ScanRepository());

final scanHistoryProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.read(scanRepositoryProvider).history();
});

class ScanRepository {
  ScanRepository() : _apiClient = ApiClient(AppConfig.apiBaseUrl);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> predict(XFile image) async {
    final bytes = await image.readAsBytes();
    final formData = FormData.fromMap({
      'image': MultipartFile.fromBytes(bytes, filename: image.name),
    });
    final response = await _apiClient.dio.post('scans/predict/', data: formData);
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<List<Map<String, dynamic>>> history() async {
    final response = await _apiClient.dio.get('scans/history/');
    final data = response.data;
    if (data is List) {
      return data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    }
    if (data is Map && data['results'] is List) {
      return (data['results'] as List).map((item) => Map<String, dynamic>.from(item as Map)).toList();
    }
    return [];
  }

  Future<void> deleteScan(int id) async {
    await _apiClient.dio.delete('scans/history/$id/');
  }
}
