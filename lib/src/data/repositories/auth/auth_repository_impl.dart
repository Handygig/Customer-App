import 'package:dartz/dartz.dart';
import 'package:customer_app/core/errors/failures.dart';
import 'package:customer_app/core/errors/auth_exception.dart';
import 'package:customer_app/core/services/auth_manager.dart';
import 'package:customer_app/core/services/network_service.dart';
import 'package:customer_app/src/data/data_sources/remote/auth/auth_remote_data_source.dart';
import 'package:customer_app/src/domain/entities/auth/auth_result_entity.dart';
import 'package:customer_app/src/domain/entities/auth/otp_session_entity.dart';
import 'package:customer_app/src/domain/entities/auth/user_entity.dart';
import 'package:customer_app/src/domain/repositories/auth/auth_repository.dart';
import 'package:flutter/foundation.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final NetworkService _networkService;

  AuthRepositoryImpl(this._remoteDataSource, this._networkService);

  @override
  Future<Either<Failure, OtpSessionEntity>> sendOtp({
    required String phoneNumber,
  }) async {
    try {
      if (!await _networkService.isConnected()) {
        return const Left(
          NetworkFailure(errorMessage: 'No internet connection detected.'),
        );
      }
      final result = await _remoteDataSource.sendOtp(phoneNumber: phoneNumber);
      return Right(result);
    } on AuthException catch (e) {
      return Left(APIFailure(errorMessage: e.message));
    } catch (e, stackTrace) {
      debugPrint('⚠️ [AuthRepositoryImpl.sendOtp] Error: $e');
      return Left(
        APIFailure(errorMessage: e.toString(), stackTrace: stackTrace),
      );
    }
  }

  @override
  Future<Either<Failure, OtpSessionEntity>> resendOtp({
    required String phoneNumber,
    required int? forceResendingToken,
  }) async {
    try {
      if (!await _networkService.isConnected()) {
        return const Left(
          NetworkFailure(errorMessage: 'No internet connection detected.'),
        );
      }
      final result = await _remoteDataSource.sendOtp(
        phoneNumber: phoneNumber,
        forceResendingToken: forceResendingToken,
      );
      return Right(result);
    } on AuthException catch (e) {
      return Left(APIFailure(errorMessage: e.message));
    } catch (e, stackTrace) {
      debugPrint('⚠️ [AuthRepositoryImpl.resendOtp] Error: $e');
      return Left(
        APIFailure(errorMessage: e.toString(), stackTrace: stackTrace),
      );
    }
  }

  @override
  Future<Either<Failure, AuthResultEntity>> verifyOtpAndRegister({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      if (!await _networkService.isConnected()) {
        return const Left(
          NetworkFailure(errorMessage: 'No internet connection detected.'),
        );
      }
      final idToken = await _remoteDataSource.verifyOtpAndGetFirebaseIdToken(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      final result = await _remoteDataSource.registerWithFirebase(
        firebaseIdToken: idToken,
      );

      if (result.token.trim().isEmpty) {
        return const Left(
          APIFailure(
            errorMessage: 'The server did not return an authentication token.',
          ),
        );
      }

      await AuthManager.saveSession(accessToken: result.token);
      return Right(result);
    } on AuthException catch (e) {
      return Left(APIFailure(errorMessage: e.message));
    } catch (e, stackTrace) {
      debugPrint('⚠️ [AuthRepositoryImpl.verifyOtpAndRegister] Error: $e');
      return Left(
        APIFailure(errorMessage: e.toString(), stackTrace: stackTrace),
      );
    }
  }

  @override
  Future<Either<Failure, AuthResultEntity>>
  loginWithCurrentFirebaseUser() async {
    try {
      if (!await _networkService.isConnected()) {
        return const Left(
          NetworkFailure(errorMessage: 'No internet connection detected.'),
        );
      }
      final idToken = await _remoteDataSource.getCurrentFirebaseIdToken();
      final result = await _remoteDataSource.loginWithFirebase(
        firebaseIdToken: idToken,
      );

      if (result.token.trim().isEmpty) {
        return const Left(
          APIFailure(
            errorMessage: 'The server did not return an authentication token.',
          ),
        );
      }

      await AuthManager.saveSession(accessToken: result.token);
      return Right(result);
    } on AuthException catch (e) {
      return Left(APIFailure(errorMessage: e.message));
    } catch (e, stackTrace) {
      debugPrint(
        '⚠️ [AuthRepositoryImpl.loginWithCurrentFirebaseUser] Error: $e',
      );
      return Left(
        APIFailure(errorMessage: e.toString(), stackTrace: stackTrace),
      );
    }
  }

  @override
  Future<Either<Failure, UserEntity>> completeProfile({
    required String firstName,
    required String lastName,
    required String email,
    required String gender,
    String? profileImagePath,
  }) async {
    try {
      if (!await _networkService.isConnected()) {
        return const Left(
          NetworkFailure(errorMessage: 'No internet connection detected.'),
        );
      }
      final token = await AuthManager.getAccessToken();
      if (token == null || token.trim().isEmpty) {
        return const Left(
          APIFailure(
            errorMessage:
                'Your session has expired. Please verify your number again.',
          ),
        );
      }

      final result = await _remoteDataSource.completeProfile(
        bearerToken: token,
        firstName: firstName,
        lastName: lastName,
        email: email,
        gender: gender,
        profileImagePath: profileImagePath,
      );
      return Right(result);
    } on AuthException catch (e) {
      return Left(APIFailure(errorMessage: e.message));
    } catch (e, stackTrace) {
      debugPrint('⚠️ [AuthRepositoryImpl.completeProfile] Error: $e');
      return Left(
        APIFailure(errorMessage: e.toString(), stackTrace: stackTrace),
      );
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _remoteDataSource.logout();
      await AuthManager.logout();
      await _remoteDataSource.signOutFirebase();
      return const Right(null);
    } catch (e, stackTrace) {
      debugPrint('⚠️ [AuthRepositoryImpl.logout] Error: $e');
      return Left(
        APIFailure(errorMessage: e.toString(), stackTrace: stackTrace),
      );
    }
  }
}
