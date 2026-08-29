import 'dart:io';
import '../core/api_config.dart';
import '../models/disease_model.dart';
import 'api_service.dart';

class PredictService {
  final ApiService _api = ApiService();

  /// POST /api/predict (multipart, field name 'image')
  /// Returns the disease result including confidence + treatment info,
  /// and saves a ScanHistory row server-side automatically.
  Future<Disease> predict(File image) async {
    final json = await _api.uploadFile(ApiConfig.predict, image,
        fieldName: 'image');
    return Disease.fromJson(json as Map<String, dynamic>);
  }
}
