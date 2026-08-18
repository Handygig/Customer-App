import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthTokenStorage {
  static const _tokenKey = 'customer_sanctum_token';

  final FlutterSecureStorage _storage;

  const AuthTokenStorage({
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  }) : _storage = storage;

  Future<void> saveToken(String token) {
    return _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> readToken() {
    return _storage.read(key: _tokenKey);
  }

  Future<void> clearToken() {
    return _storage.delete(key: _tokenKey);
  }
}
