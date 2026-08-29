/// Thrown by ApiService whenever the backend returns a non-2xx response.
/// Carries the human-readable message from Flask's `{'error': '...'}` body
/// (or a fallback) plus the HTTP status code and any extra flags like
/// `requires_verification`, which screens use to redirect appropriately.
class ApiException implements Exception {
  final String message;
  final int statusCode;
  final Map<String, dynamic>? body;

  ApiException(this.message, this.statusCode, {this.body});

  bool get requiresVerification => body?['requires_verification'] == true;

  @override
  String toString() => message;
}
