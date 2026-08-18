import 'package:customer_app/src/domain/entities/auth/otp_session_entity.dart';
import 'package:customer_app/src/domain/repositories/auth/auth_repository.dart';

class ResendOtpUsecase {
  final AuthRepository _repository;

  const ResendOtpUsecase(this._repository);

  Future<OtpSessionEntity> call({
    required String phoneNumber,
    required int? forceResendingToken,
  }) {
    return _repository.resendOtp(
      phoneNumber: phoneNumber,
      forceResendingToken: forceResendingToken,
    );
  }
}
