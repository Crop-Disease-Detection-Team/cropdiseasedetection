import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/services/api_client.dart';

final favouritesRepositoryProvider = Provider<FavouritesRepository>((ref) => FavouritesRepository());

final favouritesListProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.read(favouritesRepositoryProvider).fetchFavourites();
});

class FavouritesRepository {
  FavouritesRepository() : _apiClient = ApiClient(AppConfig.apiBaseUrl);

  final ApiClient _apiClient;
  Dio get _dio => _apiClient.dio;

  Future<List<Map<String, dynamic>>> fetchFavourites() async {
    try {
      final response = await _dio.get('favourites/');
      final list = response.data as List? ?? [];
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Failed to fetch favourites'));
    }
  }

  Future<Map<String, dynamic>> addFavourite(int diseaseId, {String? notes}) async {
    try {
      final response = await _dio.post('favourites/', data: {
        'disease_id': diseaseId,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      });
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Failed to save favourite'));
    }
  }

  Future<void> removeFavourite(int favouriteId) async {
    try {
      await _dio.delete('favourites/$favouriteId/');
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Failed to remove favourite'));
    }
  }

  String _messageFromDio(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map && data.isNotEmpty) return data.values.first.toString();
    if (data != null) return data.toString();
    return fallback;
  }
}
