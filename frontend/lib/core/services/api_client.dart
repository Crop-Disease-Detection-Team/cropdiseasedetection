import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  ApiClient(this.baseUrl)
      : dio = Dio(BaseOptions(
          baseUrl: baseUrl.endsWith('/') ? baseUrl : '$baseUrl/',
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 30),
        )) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await const FlutterSecureStorage().read(key: 'access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            // Attempt to refresh the token
            final refreshed = await _refreshToken();
            if (refreshed) {
              // Retry the original request
              final token = await const FlutterSecureStorage().read(key: 'access_token');
              e.requestOptions.headers['Authorization'] = 'Bearer $token';
              try {
                final retryResponse = await dio.fetch(e.requestOptions);
                return handler.resolve(retryResponse);
              } catch (retryError) {
                return handler.next(retryError is DioException ? retryError : e);
              }
            } else {
              // Refresh failed, clear tokens
              await const FlutterSecureStorage().delete(key: 'access_token');
              await const FlutterSecureStorage().delete(key: 'refresh_token');
            }
          }
          return handler.next(e);
        },
      ),
    );
  }

  final Dio dio;
  final String baseUrl;

  Future<bool> _refreshToken() async {
    try {
      final storage = const FlutterSecureStorage();
      final refresh = await storage.read(key: 'refresh_token');
      if (refresh == null) return false;

      // Use a new Dio instance to avoid interceptor loop
      final tokenDio = Dio(BaseOptions(baseUrl: baseUrl.endsWith('/') ? baseUrl : '$baseUrl/'));
      final response = await tokenDio.post('accounts/token/refresh/', data: {'refresh': refresh});
      
      if (response.statusCode == 200) {
        final newAccess = response.data['access'];
        if (newAccess != null) {
          await storage.write(key: 'access_token', value: newAccess);
          // If rotate refresh tokens is enabled on backend, it might send a new refresh token too
          final newRefresh = response.data['refresh'];
          if (newRefresh != null) {
            await storage.write(key: 'refresh_token', value: newRefresh);
          }
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

