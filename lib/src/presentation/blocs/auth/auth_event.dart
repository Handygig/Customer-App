import 'package:equatable/equatable.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => const [];
}

class SendOtpRequested extends AuthEvent {
  final String phoneNumber;

  const SendOtpRequested(this.phoneNumber);

  @override
  List<Object?> get props => [phoneNumber];
}

class ResendOtpRequested extends AuthEvent {
  final String phoneNumber;
  final int? forceResendingToken;

  const ResendOtpRequested({
    required this.phoneNumber,
    required this.forceResendingToken,
  });

  @override
  List<Object?> get props => [phoneNumber, forceResendingToken];
}

class VerifyOtpRequested extends AuthEvent {
  final String verificationId;
  final String smsCode;

  const VerifyOtpRequested({
    required this.verificationId,
    required this.smsCode,
  });

  @override
  List<Object?> get props => [verificationId, smsCode];
}

class LoginWithFirebaseRequested extends AuthEvent {
  const LoginWithFirebaseRequested();
}

class CompleteProfileRequested extends AuthEvent {
  final String firstName;
  final String lastName;
  final String email;
  final String gender;
  final String? profileImagePath;

  const CompleteProfileRequested({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.gender,
    this.profileImagePath,
  });

  @override
  List<Object?> get props => [
    firstName,
    lastName,
    email,
    gender,
    profileImagePath,
  ];
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}
