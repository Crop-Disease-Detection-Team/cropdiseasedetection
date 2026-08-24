import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/services/api_client.dart';

final diseaseRepositoryProvider = Provider((ref) => DiseaseRepository());

class DiseaseRepository {
  DiseaseRepository() : _apiClient = ApiClient(AppConfig.apiBaseUrl);

  final ApiClient _apiClient;
  Dio get _dio => _apiClient.dio;

  Future<List<Map<String, dynamic>>> fetchCrops() async {
    try {
      final response = await _dio.get('scans/crops/');
      final list = response.data as List? ?? [];
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Failed to fetch crops'));
    }
  }

  Future<List<Map<String, dynamic>>> fetchDiseases({int? cropId, String? search}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (cropId != null) queryParams['crop'] = cropId;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _dio.get('scans/diseases/', queryParameters: queryParams);
      final list = response.data as List? ?? [];
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Failed to fetch diseases'));
    }
  }

  Future<Map<String, dynamic>> fetchDiseaseDetail(int id) async {
    try {
      final response = await _dio.get('scans/diseases/$id/');
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Failed to fetch disease details'));
    }
  }

  String _messageFromDio(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map && data.isNotEmpty) return data.values.first.toString();
    if (data != null) return data.toString();
    return fallback;
  }
}
