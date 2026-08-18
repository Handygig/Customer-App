import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:customer_app/core/network/api_config.dart';
import 'package:customer_app/core/services/device_name_service.dart';
import 'package:customer_app/core/storage/auth_token_storage.dart';
import 'package:customer_app/src/data/data_sources/remote/auth/auth_remote_data_source_impl.dart';
import 'package:customer_app/src/data/repositories/auth/auth_repository_impl.dart';
import 'package:customer_app/src/domain/repositories/auth/auth_repository.dart';
import 'package:customer_app/src/domain/usecases/auth/complete_profile_usecase.dart';
import 'package:customer_app/src/domain/usecases/auth/login_with_firebase_usecase.dart';
import 'package:customer_app/src/domain/usecases/auth/logout_usecase.dart';
import 'package:customer_app/src/domain/usecases/auth/resend_otp_usecase.dart';
import 'package:customer_app/src/domain/usecases/auth/send_otp_usecase.dart';
import 'package:customer_app/src/domain/usecases/auth/verify_otp_and_register_usecase.dart';
import 'package:customer_app/src/presentation/blocs/auth/auth_bloc.dart';

class AuthModule {
  AuthModule._();

  static AuthRepository createRepository() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
        headers: const {'Accept': 'application/json'},
      ),
    );

    final remote = AuthRemoteDataSourceImpl(
      firebaseAuth: FirebaseAuth.instance,
      dio: dio,
      deviceNameService: DeviceNameService(),
    );

    return AuthRepositoryImpl(
      remoteDataSource: remote,
      tokenStorage: const AuthTokenStorage(),
    );
  }

  static AuthBloc createBloc() {
    final repository = createRepository();

    return AuthBloc(
      sendOtp: SendOtpUsecase(repository),
      resendOtp: ResendOtpUsecase(repository),
      verifyOtpAndRegister: VerifyOtpAndRegisterUsecase(repository),
      loginWithFirebase: LoginWithFirebaseUsecase(repository),
      completeProfile: CompleteProfileUsecase(repository),
      logout: LogoutUsecase(repository),
    );
  }
}
