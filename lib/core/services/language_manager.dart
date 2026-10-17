import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:customer_app/core/constants/app_local_keys.dart';

class LanguageManager {
  LanguageManager._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String defaultLanguageCode = 'en';

  static final ValueNotifier<Locale> localeNotifier = ValueNotifier(
    const Locale(defaultLanguageCode),
  );

  static final ValueNotifier<bool> hasSelectedLanguageNotifier = ValueNotifier(
    false,
  );

  static Future<void> init() async {
    try {
      final code =
          await _storage.read(key: AppLocalKeys.languageCode) ??
          defaultLanguageCode;
      localeNotifier.value = Locale(code);

      final hasSelected = await _storage.read(
        key: AppLocalKeys.hasSelectedLanguage,
      );
      hasSelectedLanguageNotifier.value = hasSelected == 'true';
    } catch (e) {
      debugPrint('LanguageManager init failed: $e');
    }
  }

  static bool get hasSelectedLanguage => hasSelectedLanguageNotifier.value;

  static String get currentLanguageCode => localeNotifier.value.languageCode;

  static Future<void> setLanguage(String code) async {
    try {
      await _storage.write(key: AppLocalKeys.languageCode, value: code);
      await _storage.write(
        key: AppLocalKeys.hasSelectedLanguage,
        value: 'true',
      );
      localeNotifier.value = Locale(code);
      hasSelectedLanguageNotifier.value = true;
    } catch (e) {
      debugPrint('LanguageManager setLanguage failed: $e');
    }
  }

  static Future<String> getLanguageCode() async {
    try {
      return await _storage.read(key: AppLocalKeys.languageCode) ??
          defaultLanguageCode;
    } catch (e) {
      return defaultLanguageCode;
    }
  }

  static Future<bool> checkHasSelectedLanguage() async {
    try {
      final val = await _storage.read(key: AppLocalKeys.hasSelectedLanguage);
      final selected = val == 'true';
      hasSelectedLanguageNotifier.value = selected;
      return selected;
    } catch (e) {
      return false;
    }
  }
}
