import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:customer_app/core/errors/auth_exception.dart';
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
    required SendOtpUsecase sendOtp,
    required ResendOtpUsecase resendOtp,
    required VerifyOtpAndRegisterUsecase verifyOtpAndRegister,
    required LoginWithFirebaseUsecase loginWithFirebase,
    required CompleteProfileUsecase completeProfile,
    required LogoutUsecase logout,
  })  : _sendOtp = sendOtp,
        _resendOtp = resendOtp,
        _verifyOtpAndRegister = verifyOtpAndRegister,
        _loginWithFirebase = loginWithFirebase,
        _completeProfile = completeProfile,
        _logout = logout,
        super(const AuthInitial()) {
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
    try {
      final session = await _sendOtp(event.phoneNumber);
      emit(AuthOtpSent(phoneNumber: event.phoneNumber, session: session));
    } catch (error) {
      emit(AuthFailure(
        operation: AuthOperation.sendOtp,
        message: _message(error),
      ));
    }
  }

  Future<void> _onResendOtp(
    ResendOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(AuthOperation.resendOtp));
    try {
      final session = await _resendOtp(
        phoneNumber: event.phoneNumber,
        forceResendingToken: event.forceResendingToken,
      );
      emit(AuthOtpResent(phoneNumber: event.phoneNumber, session: session));
    } catch (error) {
      emit(AuthFailure(
        operation: AuthOperation.resendOtp,
        message: _message(error),
      ));
    }
  }

  Future<void> _onVerifyOtp(
    VerifyOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(AuthOperation.verifyOtp));
    try {
      final result = await _verifyOtpAndRegister(
        verificationId: event.verificationId,
        smsCode: event.smsCode,
      );
      emit(AuthAuthenticated(result));
    } catch (error) {
      emit(AuthFailure(
        operation: AuthOperation.verifyOtp,
        message: _message(error),
      ));
    }
  }

  Future<void> _onLogin(
    LoginWithFirebaseRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(AuthOperation.login));
    try {
      emit(AuthAuthenticated(await _loginWithFirebase()));
    } catch (error) {
      emit(AuthFailure(
        operation: AuthOperation.login,
        message: _message(error),
      ));
    }
  }

  Future<void> _onCompleteProfile(
    CompleteProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(AuthOperation.completeProfile));
    try {
      final user = await _completeProfile(
        firstName: event.firstName,
        lastName: event.lastName,
        email: event.email,
        gender: event.gender,
        profileImagePath: event.profileImagePath,
      );
      emit(AuthProfileCompleted(user));
    } catch (error) {
      emit(AuthFailure(
        operation: AuthOperation.completeProfile,
        message: _message(error),
      ));
    }
  }

  Future<void> _onLogout(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(AuthOperation.logout));
    try {
      await _logout();
      emit(const AuthLoggedOut());
    } catch (error) {
      emit(AuthFailure(
        operation: AuthOperation.logout,
        message: _message(error),
      ));
    }
  }

  String _message(Object error) {
    if (error is AuthException) return error.message;
    return 'Something went wrong. Please try again.';
  }
}
