import 'package:dartz/dartz.dart';
import 'package:customer_app/core/errors/failures.dart';
import 'package:customer_app/src/domain/entities/auth/auth_result_entity.dart';
import 'package:customer_app/src/domain/entities/auth/otp_session_entity.dart';
import 'package:customer_app/src/domain/entities/auth/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, OtpSessionEntity>> sendOtp({required String phoneNumber});

  Future<Either<Failure, OtpSessionEntity>> resendOtp({
    required String phoneNumber,
    required int? forceResendingToken,
  });

  Future<Either<Failure, AuthResultEntity>> verifyOtpAndRegister({
    required String verificationId,
    required String smsCode,
  });

  Future<Either<Failure, AuthResultEntity>> loginWithCurrentFirebaseUser();

  Future<Either<Failure, UserEntity>> completeProfile({
    required String firstName,
    required String lastName,
    required String email,
    required String gender,
    String? profileImagePath,
  });

  Future<Either<Failure, void>> logout();
}
