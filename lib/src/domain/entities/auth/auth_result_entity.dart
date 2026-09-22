import 'package:customer_app/src/domain/entities/auth/user_entity.dart';

class AuthResultEntity {
  final String token;
  final UserEntity user;
  final bool isNewUser;
  final bool isProfileComplete;

  const AuthResultEntity({
    required this.token,
    required this.user,
    required this.isNewUser,
    required this.isProfileComplete,
  });
}
