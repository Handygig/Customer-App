import 'package:customer_app/src/domain/entities/auth/otp_session_entity.dart';
import 'package:customer_app/src/domain/repositories/auth/auth_repository.dart';

class SendOtpUsecase {
  final AuthRepository _repository;

  const SendOtpUsecase(this._repository);

  Future<OtpSessionEntity> call(String phoneNumber) {
    return _repository.sendOtp(phoneNumber: phoneNumber);
  }
}
