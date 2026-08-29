import 'package:shared_preferences/shared_preferences.dart';

/// Central place for backend connection settings.
///
/// IMPORTANT — how this now works:
/// Instead of a hardcoded IP that breaks every time you switch Wi-Fi
/// networks, the server URL is now stored in the phone's local storage
/// and can be changed from inside the app (Login screen -> the gear/
/// settings icon in the top right -> "Server settings"). No rebuild
/// needed when your PC's IP changes.
///
/// [_fallbackBaseUrl] below is only used the very first time the app
/// runs, before the user has set anything. Update it to whatever your
/// current setup is, but after that you can just change it in-app.
///
/// Quick reference for what to put in that field:
///   - Android EMULATOR reaching Flask on your PC -> http://10.0.2.2:5000
///   - Real phone on the same Wi-Fi as your PC     -> http://<PC LAN IP>:5000
///   - ngrok / deployed backend                    -> https://your-url
class ApiConfig {
  ApiConfig._();

  static const String _fallbackBaseUrl = 'http://192.168.1.254:5000';
  static const String _prefsKey = 'server_base_url';

  static String _baseUrl = _fallbackBaseUrl;

  /// Must be called once before the app starts (see main.dart) so the
  /// last saved server URL is loaded from disk.
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved != null && saved.trim().isNotEmpty) {
      _baseUrl = _normalize(saved);
    }
  }

  static String _normalize(String url) {
    var u = url.trim();
    if (u.endsWith('/')) u = u.substring(0, u.length - 1);
    return u;
  }

  /// Call this from the Server Settings screen when the user saves a
  /// new address. Persists it so it survives app restarts.
  static Future<void> setBaseUrl(String url) async {
    final normalized = _normalize(url);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, normalized);
    _baseUrl = normalized;
  }

  /// ACTIVE BASE URL — now read at runtime instead of compiled in.
  static String get baseUrl => _baseUrl;

  static String get apiBase => '$baseUrl/api';

  // ---- Auth ----
  static String get register => '$apiBase/auth/register';
  static String get verifyEmail => '$apiBase/auth/verify-email';
  static String get resendVerification => '$apiBase/auth/resend-verification';
  static String get login => '$apiBase/auth/login';
  static String get logout => '$apiBase/auth/logout';
  static String get forgotPassword => '$apiBase/auth/forgot-password';
  static String get verifyResetOtp => '$apiBase/auth/verify-reset-otp';
  static String get resetPassword => '$apiBase/auth/reset-password';
  static String get me => '$apiBase/auth/me';
  static String get changePassword => '$apiBase/auth/change-password';
  static String get refresh => '$apiBase/auth/refresh';
  static String get updateProfile => '$apiBase/auth/update-profile';
  static String get uploadProfilePic => '$apiBase/auth/upload-profile-pic';

  // ---- Predict ----
  static String get predict => '$apiBase/predict';
  static String get predictHistory => '$apiBase/history';

  // ---- User / diseases ----
  static String get userDiseases => '$apiBase/user/diseases';
  static String get userStatistics => '$apiBase/user/statistics';
  static String get userFavorites => '$apiBase/user/favorites';
  static String get userScans => '$apiBase/user/scans';
  static String get diseaseSearch => '$apiBase/user/diseases/search';
  static String get userCrops => '$apiBase/user/crops';

  // ---- Admin ----
  static String get adminDashboardStats => '$apiBase/admin/dashboard/stats';
  static String get adminUsers => '$apiBase/admin/users';
  static String get adminScans => '$apiBase/admin/scans';

  // ---- Feedback ----
  static String get feedback => '$apiBase/feedback';

  /// Resolves a relative image path returned by the backend
  /// (e.g. "/uploads/scans/xyz.jpeg") into a fully qualified URL.
  static String resolveImage(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return path.startsWith('/') ? '$baseUrl$path' : '$baseUrl/$path';
  }
}
