import 'package:customer_app/src/domain/entities/auth/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    super.id,
    super.phoneNumber,
    super.firebaseUid,
    super.firstName,
    super.lastName,
    super.email,
    super.gender,
    super.profileImage,
    required super.isProfileComplete,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] is Map
        ? Map<String, dynamic>.from(json['customer'] as Map)
        : const <String, dynamic>{};

    final rawComplete = json['is_profile_complete'];
    final inferredComplete = _hasText(json['first_name']) &&
        _hasText(json['last_name']) &&
        _hasText(json['email']);

    return UserModel(
      id: _asInt(json['id']),
      phoneNumber: _asString(json['phone_number'] ?? json['phone']),
      firebaseUid: _asString(json['firebase_uid']),
      firstName: _asString(json['first_name']),
      lastName: _asString(json['last_name']),
      email: _asString(json['email']),
      gender: _asString(json['gender'] ?? customer['gender']),
      profileImage: _asString(
        json['profile_image_url'] ?? json['profile_image'],
      ),
      isProfileComplete: rawComplete is bool
          ? rawComplete
          : rawComplete is num
              ? rawComplete != 0
              : inferredComplete,
    );
  }

  static bool _hasText(dynamic value) {
    return value != null && value.toString().trim().isNotEmpty;
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  static String? _asString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}
