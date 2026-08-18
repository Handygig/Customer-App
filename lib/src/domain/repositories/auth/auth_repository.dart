import 'package:customer_app/src/domain/entities/auth/auth_result_entity.dart';
import 'package:customer_app/src/domain/entities/auth/otp_session_entity.dart';
import 'package:customer_app/src/domain/entities/auth/user_entity.dart';

abstract class AuthRepository {
  Future<OtpSessionEntity> sendOtp({required String phoneNumber});

  Future<OtpSessionEntity> resendOtp({
    required String phoneNumber,
    required int? forceResendingToken,
  });

  Future<AuthResultEntity> verifyOtpAndRegister({
    required String verificationId,
    required String smsCode,
  });

  Future<AuthResultEntity> loginWithCurrentFirebaseUser();

  Future<UserEntity> completeProfile({
    required String firstName,
    required String lastName,
    required String email,
    required String gender,
    String? profileImagePath,
  });

  Future<void> logout();
}
