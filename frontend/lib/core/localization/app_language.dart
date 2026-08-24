import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const languageStorageKey = 'selected_language';
const agreementStorageKey = 'terms_agreed';

class AppLanguage {
  const AppLanguage(this.code, this.label);

  final String code;
  final String label;
}

const supportedLanguages = [
  AppLanguage('en', 'English'),
  AppLanguage('ne', '\u{0928}\u{0947}\u{092A}\u{093E}\u{0932}\u{0940}'),
  AppLanguage('hi', 'Hindi'),
  AppLanguage('bn', 'Bengali'),
  AppLanguage('ur', 'Urdu'),
  AppLanguage('zh', 'Chinese'),
  AppLanguage('ja', 'Japanese'),
  AppLanguage('ko', 'Korean'),
  AppLanguage('es', 'Spanish'),
  AppLanguage('fr', 'French'),
  AppLanguage('ar', 'Arabic'),
  AppLanguage('de', 'German'),
];

final localSettingsProvider = StateNotifierProvider<LocalSettingsNotifier, AsyncValue<String?>>((ref) {
  return LocalSettingsNotifier()..load();
});

class LocalSettingsNotifier extends StateNotifier<AsyncValue<String?>> {
  LocalSettingsNotifier() : super(const AsyncValue.loading());

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> load() async {
    state = AsyncValue.data(await _storage.read(key: languageStorageKey));
  }

  Future<void> saveLanguage(String code) async {
    await _storage.write(key: languageStorageKey, value: code);
    state = AsyncValue.data(code);
  }

  Future<bool> hasLanguage() async => (await _storage.read(key: languageStorageKey)) != null;

  Future<bool> hasAgreement() async => (await _storage.read(key: agreementStorageKey)) == 'true';

  Future<void> saveAgreement() async {
    await _storage.write(key: agreementStorageKey, value: 'true');
  }

  Future<String> nextRouteAfterAuth(Map<String, dynamic>? user) async {
    if (!await hasLanguage()) return '/language';
    if (!await hasAgreement()) return '/terms';
    if (user != null && user['role'] == 'admin') return '/admin/dashboard';
    return '/dashboard';
  }
}

final appStringsProvider = Provider<AppStrings>((ref) {
  final code = ref.watch(localSettingsProvider).valueOrNull ?? 'en';
  return AppStrings(code);
});

class AppStrings {
  AppStrings(this.code);

  final String code;

  static const _values = {
    'en': {
      'dashboard': 'Dashboard',
      'scanLeaf': 'Scan Leaf',
      'history': 'History',
      'profile': 'Profile',
      'welcome': 'Welcome',
      'instruction': 'Scan a crop leaf to see disease analysis.',
      'latestScan': 'Latest Scan',
      'noScansTitle': 'No scans yet',
      'noScansBody': 'Your latest leaf diagnosis will appear here after your first scan.',
      'language': 'Language',
      'terms': 'Terms & Conditions',
      'agree': 'I Agree',
      'disagree': 'I Do Not Agree',
      'selectLanguage': 'Select Language',
      'save': 'Save',
      'changePassword': 'Change Password',
      'noHistory': 'No scan history found',
      'historyHint': 'Your scanned leaf results will appear here.',
      'diseaseLibrary': 'Disease Library',
      'searchHint': 'Search diseases, crops, or symptoms...',
      'retake': 'Retake',
      'scanNow': 'Scan Crop Now',
      'healthy': 'Healthy',
      'diseased': 'Diseased',
      'totalScans': 'Total Scans',
      'logout': 'Logout',
      'login': 'Login',
      'signup': 'Sign Up',
      'forgotPassword': 'Forgot Password?',
      'resetPassword': 'Reset Password',
      'sendOtp': 'Send OTP Code',
      'otpSent': 'OTP Code Sent!',
      'verifyOtp': 'Verify OTP',
      'enterOtp': 'Enter 6-digit OTP code sent to your email',
      'newPassword': 'New Password',
      'confirmPassword': 'Confirm New Password',
      'passwordResetSuccess': 'Password reset successful! Please log in.',
      'loginSubtitle': 'Log in to protect your crops with AI diagnosis',
      'signupSubtitle': 'Create an account to start scanning crops',
      'emailLabel': 'Email Address',
      'passwordLabel': 'Password',
      'nameLabel': 'Full Name',
      'usernameLabel': 'Username',
      'districtLabel': 'District / Location',
      'adminMode': 'Admin Control Panel',
      'offlineWarning': 'You are offline. Scans will be analyzed when connected.',
    },
    'ne': {
      'dashboard': 'ड्यासबोर्ड',
      'scanLeaf': 'पात स्क्यान',
      'history': 'इतिहास',
      'profile': 'प्रोफाइल',
      'welcome': 'स्वागत छ',
      'instruction': 'रोग विश्लेषण हेर्न बालीको पात स्क्यान गर्नुहोस्।',
      'latestScan': 'पछिल्लो स्क्यान',
      'noScansTitle': 'अहिलेसम्म स्क्यान छैन',
      'noScansBody': 'पहिलो स्क्यानपछि तपाईंको पात निदान यहाँ देखिनेछ।',
      'language': 'भाषा',
      'terms': 'नियम र शर्तहरू',
      'agree': 'म सहमत छु',
      'disagree': 'म सहमत छैन',
      'selectLanguage': 'भाषा छान्नुहोस्',
      'save': 'सुरक्षित गर्नुहोस्',
      'changePassword': 'पासवर्ड परिवर्तन',
      'noHistory': 'स्क्यान इतिहास भेटिएन',
      'historyHint': 'तपाईंका स्क्यान गरिएका पातका नतिजा यहाँ देखिनेछन्।',
      'diseaseLibrary': 'रोग पुस्तकालय',
      'searchHint': 'रोग, बाली वा लक्षण खोज्नुहोस्...',
      'retake': 'पुन: खिच्नुहोस्',
      'scanNow': 'अहिले स्क्यान गर्नुहोस्',
      'healthy': 'स्वस्थ',
      'diseased': 'रोगग्रस्त',
      'totalScans': 'कुल स्क्यानहरू',
      'logout': 'लगआउट',
      'login': 'लगइन',
      'signup': 'साइन अप',
      'forgotPassword': 'पासवर्ड बिर्सनुभयो?',
      'resetPassword': 'पासवर्ड रिसेट गर्नुहोस्',
      'sendOtp': 'OTP कोड पठाउनुहोस्',
      'otpSent': 'OTP कोड पठाइयो!',
      'verifyOtp': 'OTP प्रमाणिकरण गर्नुहोस्',
      'enterOtp': 'इमेलमा पठाइएको ६ अंकको OTP कोड राख्नुहोस्',
      'newPassword': 'नयाँ पासवर्ड',
      'confirmPassword': 'पासवर्ड पुष्टि गर्नुहोस्',
      'passwordResetSuccess': 'पासवर्ड रिसेट सफल भयो! कृपया लगइन गर्नुहोस्।',
      'loginSubtitle': 'AI निदानको साथ बाली सुरक्षा गर्न लगइन गर्नुहोस्',
      'signupSubtitle': 'बाली स्क्यान सुरु गर्न खाता बनाउनुहोस्',
      'emailLabel': 'इमेल ठेगाना',
      'passwordLabel': 'पासवर्ड',
      'nameLabel': 'पुरा नाम',
      'usernameLabel': 'प्रयोगकर्ता नाम',
      'districtLabel': 'जिल्ला / स्थान',
      'adminMode': 'एडमिन नियन्त्रण प्यानल',
      'offlineWarning': 'तपाईं अफलाइन हुनुहुन्छ। अनलाइन भएपछि स्क्यान हुनेछ।',
    },
  };

  String t(String key) => _values[code]?[key] ?? _values['en']![key] ?? key;
}

