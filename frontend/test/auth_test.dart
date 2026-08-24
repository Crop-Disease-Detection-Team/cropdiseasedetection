import 'package:flutter_test/flutter_test.dart';
import 'package:agrivision_ai/core/localization/app_language.dart';

void main() {
  group('Localization and AppStrings Tests', () {
    test('English app strings return correct values', () {
      final strings = AppStrings('en');
      expect(strings.t('dashboard'), 'Dashboard');
      expect(strings.t('scanLeaf'), 'Scan Leaf');
      expect(strings.t('welcome'), 'Welcome');
    });

    test('Nepali app strings return correct values', () {
      final strings = AppStrings('ne');
      expect(strings.t('dashboard'), 'ड्यासबोर्ड');
      expect(strings.t('scanLeaf'), 'पात स्क्यान');
      expect(strings.t('welcome'), 'स्वागत छ');
    });

    test('Fallback to English when key is missing in locale', () {
      final strings = AppStrings('ne');
      expect(strings.t('non_existent_key'), 'non_existent_key');
    });
  });

  group('Supported Languages Tests', () {
    test('Verify supported languages list contains English and Nepali', () {
      final codes = supportedLanguages.map((l) => l.code).toList();
      expect(codes, contains('en'));
      expect(codes, contains('ne'));
    });
  });
}
