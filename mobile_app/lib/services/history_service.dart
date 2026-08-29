import '../core/api_config.dart';
import '../models/scan_model.dart';
import 'api_service.dart';

class HistoryResult {
  final List<ScanRecord> scans;
  final int total;
  final int page;
  final int pages;
  HistoryResult(this.scans, this.total, this.page, this.pages);
}

class HistoryService {
  final ApiService _api = ApiService();

  /// GET /api/history?page=&per_page=
  Future<HistoryResult> getHistory({int page = 1, int perPage = 10}) async {
    final json = await _api
        .get('${ApiConfig.predictHistory}?page=$page&per_page=$perPage');
    final scans = (json['scans'] as List<dynamic>)
        .map((e) => ScanRecord.fromJson(e as Map<String, dynamic>))
        .toList();
    return HistoryResult(
        scans, json['total'] ?? 0, json['page'] ?? 1, json['pages'] ?? 1);
  }

  /// GET /api/history/<scan_id>
  Future<ScanRecord> getScanDetail(int scanId) async {
    final json = await _api.get('${ApiConfig.predictHistory}/$scanId');
    return ScanRecord.fromJson(json as Map<String, dynamic>);
  }

  /// DELETE /api/history (clears ALL scans for the user)
  Future<void> clearHistory() => _api.delete(ApiConfig.predictHistory);
}
