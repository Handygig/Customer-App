import 'package:customer_app/core/errors/auth_exception.dart';
import 'package:customer_app/core/storage/auth_token_storage.dart';
import 'package:customer_app/src/data/data_sources/remote/auth/auth_remote_data_source.dart';
import 'package:customer_app/src/domain/entities/auth/auth_result_entity.dart';
import 'package:customer_app/src/domain/entities/auth/otp_session_entity.dart';
import 'package:customer_app/src/domain/entities/auth/user_entity.dart';
import 'package:customer_app/src/domain/repositories/auth/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthTokenStorage _tokenStorage;

  const AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required AuthTokenStorage tokenStorage,
  })  : _remoteDataSource = remoteDataSource,
        _tokenStorage = tokenStorage;

  @override
  Future<OtpSessionEntity> sendOtp({required String phoneNumber}) {
    return _remoteDataSource.sendOtp(phoneNumber: phoneNumber);
  }

  @override
  Future<OtpSessionEntity> resendOtp({
    required String phoneNumber,
    required int? forceResendingToken,
  }) {
    return _remoteDataSource.sendOtp(
      phoneNumber: phoneNumber,
      forceResendingToken: forceResendingToken,
    );
  }

  @override
  Future<AuthResultEntity> verifyOtpAndRegister({
    required String verificationId,
    required String smsCode,
  }) async {
    final idToken = await _remoteDataSource.verifyOtpAndGetFirebaseIdToken(
      verificationId: verificationId,
      smsCode: smsCode,
    );

    final result = await _remoteDataSource.registerWithFirebase(
      firebaseIdToken: idToken,
    );

    if (result.token.trim().isEmpty) {
      throw const AuthException('The server did not return an authentication token.');
    }

    await _tokenStorage.saveToken(result.token);
    return result;
  }

  @override
  Future<AuthResultEntity> loginWithCurrentFirebaseUser() async {
    final idToken = await _remoteDataSource.getCurrentFirebaseIdToken();
    final result = await _remoteDataSource.loginWithFirebase(
      firebaseIdToken: idToken,
    );

    if (result.token.trim().isEmpty) {
      throw const AuthException('The server did not return an authentication token.');
    }

    await _tokenStorage.saveToken(result.token);
    return result;
  }

  @override
  Future<UserEntity> completeProfile({
    required String firstName,
    required String lastName,
    required String email,
    required String gender,
    String? profileImagePath,
  }) async {
    final token = await _tokenStorage.readToken();
    if (token == null || token.trim().isEmpty) {
      throw const AuthException('Your session has expired. Please verify your number again.');
    }

    return _remoteDataSource.completeProfile(
      bearerToken: token,
      firstName: firstName,
      lastName: lastName,
      email: email,
      gender: gender,
      profileImagePath: profileImagePath,
    );
  }

  @override
  Future<void> logout() async {
    await _tokenStorage.clearToken();
    await _remoteDataSource.signOutFirebase();
  }
}
