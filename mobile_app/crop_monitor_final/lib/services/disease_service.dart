import '../core/api_config.dart';
import '../models/disease_model.dart';
import 'api_service.dart';

class DiseaseListResult {
  final List<Disease> diseases;
  final int total;
  final int totalPages;
  DiseaseListResult(this.diseases, this.total, this.totalPages);
}

class DiseaseService {
  final ApiService _api = ApiService();

  /// GET /api/user/diseases?page=&per_page=&crop_type=&search=
  /// NOTE: this list endpoint returns short-form disease cards
  /// (id, disease_name, crop_type, severity_level, sample_image_url,
  /// truncated description) — fetch full detail via getDiseaseDetail().
  Future<DiseaseListResult> getDiseases({
    int page = 1,
    int perPage = 50,
    String? cropType,
    String? search,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'per_page': '$perPage',
      if (cropType != null && cropType.isNotEmpty) 'crop_type': cropType,
      if (search != null && search.isNotEmpty) 'search': search,
    };
    final uri = Uri.parse(ApiConfig.userDiseases).replace(queryParameters: params);
    final json = await _api.get(uri.toString());
    final diseases = (json['diseases'] as List<dynamic>)
        .map((e) => Disease.fromJson(e as Map<String, dynamic>))
        .toList();
    return DiseaseListResult(
        diseases, json['total'] ?? 0, json['total_pages'] ?? 1);
  }

  /// GET /api/user/diseases/<id> — full detail incl. medicines
  Future<Disease> getDiseaseDetail(int id) async {
    final json = await _api.get('${ApiConfig.userDiseases}/$id');
    return Disease.fromJson(json as Map<String, dynamic>);
  }

  /// GET /api/user/statistics — dashboard cards (total scans, avg confidence...)
  Future<Map<String, dynamic>> getUserStatistics() async {
    final json = await _api.get(ApiConfig.userStatistics);
    return json as Map<String, dynamic>;
  }

  /// GET /api/user/crops — distinct crop types for the filter dropdown
  Future<List<String>> getCrops() async {
    final json = await _api.get(ApiConfig.userCrops);
    final list = (json is Map ? json['crops'] : json) as List<dynamic>? ?? [];
    return list.map((e) => e.toString()).toList();
  }

  /// GET/POST/DELETE favorites
  Future<List<Disease>> getFavorites() async {
    final json = await _api.get(ApiConfig.userFavorites);
    final list = (json['favorites'] ?? json['diseases'] ?? []) as List<dynamic>;
    return list.map((e) => Disease.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> addFavorite(int diseaseId) =>
      _api.post('${ApiConfig.userFavorites}/$diseaseId');

  Future<void> removeFavorite(int diseaseId) =>
      _api.delete('${ApiConfig.userFavorites}/$diseaseId');
}
