import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:customer_app/src/domain/usecases/auth/complete_profile_usecase.dart';
import 'package:customer_app/src/domain/usecases/auth/login_with_firebase_usecase.dart';
import 'package:customer_app/src/domain/usecases/auth/logout_usecase.dart';
import 'package:customer_app/src/domain/usecases/auth/resend_otp_usecase.dart';
import 'package:customer_app/src/domain/usecases/auth/send_otp_usecase.dart';
import 'package:customer_app/src/domain/usecases/auth/verify_otp_and_register_usecase.dart';
import 'package:customer_app/src/presentation/blocs/auth/auth_event.dart';
import 'package:customer_app/src/presentation/blocs/auth/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SendOtpUsecase _sendOtp;
  final ResendOtpUsecase _resendOtp;
  final VerifyOtpAndRegisterUsecase _verifyOtpAndRegister;
  final LoginWithFirebaseUsecase _loginWithFirebase;
  final CompleteProfileUsecase _completeProfile;
  final LogoutUsecase _logout;

  AuthBloc({
    required this._sendOtp,
    required this._resendOtp,
    required this._verifyOtpAndRegister,
    required this._loginWithFirebase,
    required this._completeProfile,
    required this._logout,
  }) : super(const AuthInitial()) {
    on<SendOtpRequested>(_onSendOtp);
    on<ResendOtpRequested>(_onResendOtp);
    on<VerifyOtpRequested>(_onVerifyOtp);
    on<LoginWithFirebaseRequested>(_onLogin);
    on<CompleteProfileRequested>(_onCompleteProfile);
    on<LogoutRequested>(_onLogout);
  }

  Future<void> _onSendOtp(
    SendOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(AuthOperation.sendOtp));
    final res = await _sendOtp(event.phoneNumber);
    res.fold(
      (failure) => emit(
        AuthFailure(
          operation: AuthOperation.sendOtp,
          message: failure.errorMessage,
        ),
      ),
      (session) =>
          emit(AuthOtpSent(phoneNumber: event.phoneNumber, session: session)),
    );
  }

  Future<void> _onResendOtp(
    ResendOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(AuthOperation.resendOtp));
    final res = await _resendOtp(
      phoneNumber: event.phoneNumber,
      forceResendingToken: event.forceResendingToken,
    );
    res.fold(
      (failure) => emit(
        AuthFailure(
          operation: AuthOperation.resendOtp,
          message: failure.errorMessage,
        ),
      ),
      (session) =>
          emit(AuthOtpResent(phoneNumber: event.phoneNumber, session: session)),
    );
  }

  Future<void> _onVerifyOtp(
    VerifyOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(AuthOperation.verifyOtp));
    final res = await _verifyOtpAndRegister(
      verificationId: event.verificationId,
      smsCode: event.smsCode,
    );
    res.fold(
      (failure) => emit(
        AuthFailure(
          operation: AuthOperation.verifyOtp,
          message: failure.errorMessage,
        ),
      ),
      (result) => emit(AuthAuthenticated(result)),
    );
  }

  Future<void> _onLogin(
    LoginWithFirebaseRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(AuthOperation.login));
    final res = await _loginWithFirebase();
    res.fold(
      (failure) => emit(
        AuthFailure(
          operation: AuthOperation.login,
          message: failure.errorMessage,
        ),
      ),
      (result) => emit(AuthAuthenticated(result)),
    );
  }

  Future<void> _onCompleteProfile(
    CompleteProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(AuthOperation.completeProfile));
    final res = await _completeProfile(
      firstName: event.firstName,
      lastName: event.lastName,
      email: event.email,
      gender: event.gender,
      profileImagePath: event.profileImagePath,
    );
    res.fold(
      (failure) => emit(
        AuthFailure(
          operation: AuthOperation.completeProfile,
          message: failure.errorMessage,
        ),
      ),
      (user) => emit(AuthProfileCompleted(user)),
    );
  }

  Future<void> _onLogout(LogoutRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading(AuthOperation.logout));
    final res = await _logout();
    res.fold(
      (failure) => emit(
        AuthFailure(
          operation: AuthOperation.logout,
          message: failure.errorMessage,
        ),
      ),
      (_) => emit(const AuthLoggedOut()),
    );
  }
}
