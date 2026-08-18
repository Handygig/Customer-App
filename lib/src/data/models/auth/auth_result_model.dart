import 'package:customer_app/src/data/models/auth/user_model.dart';
import 'package:customer_app/src/domain/entities/auth/auth_result_entity.dart';

class AuthResultModel extends AuthResultEntity {
  const AuthResultModel({
    required super.token,
    required UserModel super.user,
    required super.isNewUser,
    required super.isProfileComplete,
  });

  factory AuthResultModel.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] is Map
        ? Map<String, dynamic>.from(json['user'] as Map)
        : const <String, dynamic>{};
    final user = UserModel.fromJson(userJson);

    final isProfileComplete = _asBool(
      json['is_profile_complete'],
      fallback: user.isProfileComplete,
    );

    return AuthResultModel(
      token: (json['token'] ?? json['access_token'] ?? '').toString(),
      user: user,
      isNewUser: _asBool(json['is_new_user']),
      isProfileComplete: isProfileComplete,
    );
  }

  static bool _asBool(dynamic value, {bool fallback = false}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.toLowerCase();
      if (normalized == 'true' || normalized == '1') return true;
      if (normalized == 'false' || normalized == '0') return false;
    }
    return fallback;
  }
}
