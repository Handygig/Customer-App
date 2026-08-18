import 'package:equatable/equatable.dart';
import 'package:customer_app/src/domain/entities/auth/auth_result_entity.dart';
import 'package:customer_app/src/domain/entities/auth/otp_session_entity.dart';
import 'package:customer_app/src/domain/entities/auth/user_entity.dart';

enum AuthOperation {
  sendOtp,
  resendOtp,
  verifyOtp,
  login,
  completeProfile,
  logout,
}

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => const [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  final AuthOperation operation;

  const AuthLoading(this.operation);

  @override
  List<Object?> get props => [operation];
}

class AuthOtpSent extends AuthState {
  final String phoneNumber;
  final OtpSessionEntity session;

  const AuthOtpSent({
    required this.phoneNumber,
    required this.session,
  });

  @override
  List<Object?> get props => [phoneNumber, session.verificationId, session.forceResendingToken];
}

class AuthOtpResent extends AuthState {
  final String phoneNumber;
  final OtpSessionEntity session;

  const AuthOtpResent({
    required this.phoneNumber,
    required this.session,
  });

  @override
  List<Object?> get props => [phoneNumber, session.verificationId, session.forceResendingToken];
}

class AuthAuthenticated extends AuthState {
  final AuthResultEntity result;

  const AuthAuthenticated(this.result);

  @override
  List<Object?> get props => [
        result.token,
        result.isNewUser,
        result.isProfileComplete,
        result.user.id,
      ];
}

class AuthProfileCompleted extends AuthState {
  final UserEntity user;

  const AuthProfileCompleted(this.user);

  @override
  List<Object?> get props => [user.id, user.email, user.isProfileComplete];
}

class AuthLoggedOut extends AuthState {
  const AuthLoggedOut();
}

class AuthFailure extends AuthState {
  final AuthOperation operation;
  final String message;

  const AuthFailure({
    required this.operation,
    required this.message,
  });

  @override
  List<Object?> get props => [operation, message];
}
