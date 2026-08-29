import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import '../core/token_storage.dart';
import 'api_exception.dart';

/// Thin HTTP client used by every feature service (AuthService,
/// PredictService, DiseaseService, HistoryService, AdminService).
/// Centralizes: JSON encode/decode, Bearer token header, and turning
/// Flask's `{'error': '...'}` responses into ApiException.
class ApiService {
  static const _timeout = Duration(seconds: 30);

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await TokenStorage.getAccessToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  dynamic _handle(http.Response res) {
    final isJson =
        res.headers['content-type']?.contains('application/json') ?? false;
    final decoded = isJson && res.body.isNotEmpty ? jsonDecode(res.body) : {};

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return decoded;
    }

    final message = (decoded is Map && decoded['error'] != null)
        ? decoded['error'].toString()
        : 'Something went wrong (${res.statusCode})';
    throw ApiException(message, res.statusCode,
        body: decoded is Map<String, dynamic> ? decoded : null);
  }

  /// Turns low-level network failures (unreachable host, DNS failure,
  /// timeout) into a clear ApiException instead of letting a generic
  /// SocketException/TimeoutException bubble up. This is what shows up
  /// in the UI when the server address in Server Settings is wrong or
  /// the phone can't reach it (e.g. different Wi-Fi than the PC).
  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on TimeoutException {
      throw ApiException(
          'Could not reach the server at ${ApiConfig.baseUrl} (timed out). '
          'Check Server settings and make sure the backend is running and '
          'reachable on your current network.',
          0);
    } on SocketException catch (e) {
      throw ApiException(
          'Could not reach the server at ${ApiConfig.baseUrl}. '
          '${e.message}. Check Server settings.',
          0);
    } on HandshakeException {
      throw ApiException(
          'Secure connection to ${ApiConfig.baseUrl} failed. Check Server settings.',
          0);
    } on FormatException {
      throw ApiException(
          'The server returned something unexpected. Check the address in '
          'Server settings (it should not include a trailing /api).',
          0);
    }
  }

  Future<dynamic> get(String url, {bool auth = true}) => _guard(() async {
        final res = await http
            .get(Uri.parse(url), headers: await _headers(auth: auth))
            .timeout(_timeout);
        return _handle(res);
      });

  Future<dynamic> post(String url,
          {Map<String, dynamic>? body, bool auth = true}) =>
      _guard(() async {
        final res = await http
            .post(Uri.parse(url),
                headers: await _headers(auth: auth),
                body: body != null ? jsonEncode(body) : null)
            .timeout(_timeout);
        return _handle(res);
      });

  Future<dynamic> put(String url,
          {Map<String, dynamic>? body, bool auth = true}) =>
      _guard(() async {
        final res = await http
            .put(Uri.parse(url),
                headers: await _headers(auth: auth),
                body: body != null ? jsonEncode(body) : null)
            .timeout(_timeout);
        return _handle(res);
      });

  Future<dynamic> delete(String url, {bool auth = true}) => _guard(() async {
        final res = await http
            .delete(Uri.parse(url), headers: await _headers(auth: auth))
            .timeout(_timeout);
        return _handle(res);
      });

  /// Multipart upload used for /api/predict and profile-pic upload.
  /// [fieldName] must match what Flask reads via request.files['...'].
  Future<dynamic> uploadFile(
    String url,
    File file, {
    required String fieldName,
    bool auth = true,
  }) =>
      _guard(() async {
        final request = http.MultipartRequest('POST', Uri.parse(url));
        if (auth) {
          final token = await TokenStorage.getAccessToken();
          if (token != null) request.headers['Authorization'] = 'Bearer $token';
        }
        request.files
            .add(await http.MultipartFile.fromPath(fieldName, file.path));

        final streamed = await request.send().timeout(_timeout);
        final res = await http.Response.fromStream(streamed);
        return _handle(res);
      });
}
