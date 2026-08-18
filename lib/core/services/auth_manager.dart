import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:customer_app/core/constants/app_local_keys.dart';

class AuthManager {
  AuthManager._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static final ValueNotifier<bool> authStateNotifier = ValueNotifier(false);

  static Future<void> init() async {
    final token = await getAccessToken();
    authStateNotifier.value = token != null && token.isNotEmpty;
  }

  static Future<void> saveSession({required String accessToken}) async {
    await _storage.write(key: AppLocalKeys.accessToken, value: accessToken);
    authStateNotifier.value = true;
  }

  static Future<String?> getAccessToken() =>
      _storage.read(key: AppLocalKeys.accessToken);

  static Future<void> logout() async {
    try {
      await _storage.delete(key: AppLocalKeys.accessToken);
      authStateNotifier.value = false;
    } catch (e) {
      debugPrint('Logout failed: $e');
    }
  }

  static bool get isLoggedIn => authStateNotifier.value;
}
