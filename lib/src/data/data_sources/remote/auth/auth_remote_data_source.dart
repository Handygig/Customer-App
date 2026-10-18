import 'package:customer_app/src/data/models/auth/auth_result_model.dart';
import 'package:customer_app/src/data/models/auth/user_model.dart';
import 'package:customer_app/src/domain/entities/auth/otp_session_entity.dart';

abstract class AuthRemoteDataSource {
  Future<OtpSessionEntity> sendOtp({
    required String phoneNumber,
    int? forceResendingToken,
  });

  Future<String> verifyOtpAndGetFirebaseIdToken({
    required String verificationId,
    required String smsCode,
  });

  Future<String> getCurrentFirebaseIdToken();

  Future<AuthResultModel> registerWithFirebase({
    required String firebaseIdToken,
  });

  Future<AuthResultModel> loginWithFirebase({required String firebaseIdToken});

  Future<UserModel> completeProfile({
    required String bearerToken,
    required String firstName,
    required String lastName,
    required String email,
    required String gender,
    String? profileImagePath,
  });

  Future<void> logout();

  Future<void> signOutFirebase();
}
