import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:customer_app/core/services/dio_client.dart';
import 'package:customer_app/core/services/network_service.dart';
import 'package:customer_app/core/services/device_name_service.dart';
import 'package:customer_app/src/data/data_sources/remote/auth/auth_remote_data_source.dart';
import 'package:customer_app/src/data/data_sources/remote/auth/auth_remote_data_source_impl.dart';
import 'package:customer_app/src/data/repositories/auth/auth_repository_impl.dart';
import 'package:customer_app/src/domain/repositories/auth/auth_repository.dart';
import 'package:customer_app/src/data/repositories/profile/profile_repository_impl.dart';
import 'package:customer_app/src/domain/repositories/profile/profile_repository.dart';
import 'package:customer_app/src/domain/usecases/auth/complete_profile_usecase.dart';
import 'package:customer_app/src/domain/usecases/auth/login_with_firebase_usecase.dart';
import 'package:customer_app/src/domain/usecases/auth/logout_usecase.dart';
import 'package:customer_app/src/domain/usecases/auth/resend_otp_usecase.dart';
import 'package:customer_app/src/domain/usecases/auth/send_otp_usecase.dart';
import 'package:customer_app/src/domain/usecases/auth/verify_otp_and_register_usecase.dart';
import 'package:customer_app/src/domain/usecases/profile/profile_usecases.dart';
import 'package:customer_app/src/data/data_sources/remote/services/service_category_remote_data_source.dart';
import 'package:customer_app/src/data/data_sources/remote/services/service_category_remote_data_source_impl.dart';
import 'package:customer_app/src/domain/repositories/services/service_category_repository.dart';
import 'package:customer_app/src/data/repositories/services/service_category_repository_impl.dart';
import 'package:customer_app/src/domain/usecases/services/get_service_categories_usecase.dart';
import 'package:customer_app/src/presentation/cubits/services/service_category_cubit.dart';
import 'package:customer_app/src/data/data_sources/remote/services/service_remote_data_source.dart';
import 'package:customer_app/src/data/data_sources/remote/services/service_remote_data_source_impl.dart';
import 'package:customer_app/src/domain/repositories/services/service_repository.dart';
import 'package:customer_app/src/data/repositories/services/service_repository_impl.dart';
import 'package:customer_app/src/domain/usecases/services/get_services_usecase.dart';
import 'package:customer_app/src/presentation/cubits/services/service_cubit.dart';
import 'package:customer_app/src/data/data_sources/remote/properties/property_remote_data_source.dart';
import 'package:customer_app/src/data/data_sources/remote/properties/property_remote_data_source_impl.dart';
import 'package:customer_app/src/domain/repositories/properties/property_repository.dart';
import 'package:customer_app/src/data/repositories/properties/property_repository_impl.dart';
import 'package:customer_app/src/domain/usecases/properties/property_usecases.dart';
import 'package:customer_app/src/presentation/cubits/properties/property_cubit.dart';
import 'package:customer_app/src/data/data_sources/remote/payments/payment_remote_data_source.dart';
import 'package:customer_app/src/data/data_sources/remote/payments/payment_remote_data_source_impl.dart';
import 'package:customer_app/src/domain/repositories/payments/payment_repository.dart';
import 'package:customer_app/src/data/repositories/payments/payment_repository_impl.dart';
import 'package:customer_app/src/domain/usecases/payments/card_usecases.dart';
import 'package:customer_app/src/presentation/cubits/payments/card_cubit.dart';
import 'package:customer_app/src/presentation/blocs/auth/auth_bloc.dart';
import 'package:customer_app/src/data/data_sources/remote/job_requests/job_request_remote_data_source.dart';
import 'package:customer_app/src/data/data_sources/remote/job_requests/job_request_remote_data_source_impl.dart';
import 'package:customer_app/src/domain/repositories/job_requests/job_request_repository.dart';
import 'package:customer_app/src/data/repositories/job_requests/job_request_repository_impl.dart';
import 'package:customer_app/src/domain/usecases/job_requests/job_request_usecases.dart';
import 'package:customer_app/src/presentation/cubits/job_requests/job_request_cubit.dart';
import 'package:customer_app/src/data/data_sources/remote/job_assignments/job_assignment_remote_data_source.dart';
import 'package:customer_app/src/data/data_sources/remote/job_assignments/job_assignment_remote_data_source_impl.dart';
import 'package:customer_app/src/domain/repositories/job_assignments/job_assignment_repository.dart';
import 'package:customer_app/src/data/repositories/job_assignments/job_assignment_repository_impl.dart';
import 'package:customer_app/src/domain/usecases/job_assignments/job_assignment_usecases.dart';
import 'package:customer_app/src/presentation/cubits/job_assignments/job_assignment_cubit.dart';
import 'package:customer_app/src/domain/repositories/notifications/notification_repository.dart';
import 'package:customer_app/src/data/repositories/notifications/notification_repository_impl.dart';
import 'package:customer_app/src/presentation/cubits/notifications/notification_cubit.dart';
import 'package:customer_app/src/domain/repositories/faq/faq_repository.dart';
import 'package:customer_app/src/data/repositories/faq/faq_repository_impl.dart';
import 'package:customer_app/src/data/data_sources/remote/providers/provider_remote_data_source.dart';
import 'package:customer_app/src/data/data_sources/remote/providers/provider_remote_data_source_impl.dart';
import 'package:customer_app/src/domain/repositories/providers/provider_repository.dart';
import 'package:customer_app/src/data/repositories/providers/provider_repository_impl.dart';
import 'package:customer_app/src/domain/usecases/providers/search_providers_usecase.dart';
import 'package:customer_app/src/presentation/cubits/providers/provider_search_cubit.dart';

final sl = GetIt.instance;

Future<void> initServiceLocator() async {
  // External / Third-party
  sl.registerLazySingleton<Dio>(() => DioClient.create());
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );
  sl.registerLazySingleton<Connectivity>(() => Connectivity());

  // Services
  sl.registerLazySingleton<DeviceNameService>(() => DeviceNameService());
  sl.registerLazySingleton<NetworkService>(
    () => NetworkService(connectivity: sl<Connectivity>()),
  );

  // Data Sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(
      firebaseAuth: sl<FirebaseAuth>(),
      dio: sl<Dio>(),
      deviceNameService: sl<DeviceNameService>(),
    ),
  );
  sl.registerLazySingleton<ServiceCategoryRemoteDataSource>(
    () => ServiceCategoryRemoteDataSourceImpl(sl<Dio>()),
  );
  sl.registerLazySingleton<ServiceRemoteDataSource>(
    () => ServiceRemoteDataSourceImpl(sl<Dio>()),
  );
  sl.registerLazySingleton<PropertyRemoteDataSource>(
    () => PropertyRemoteDataSourceImpl(sl<Dio>()),
  );
  sl.registerLazySingleton<PaymentRemoteDataSource>(
    () => PaymentRemoteDataSourceImpl(sl<Dio>()),
  );
  sl.registerLazySingleton<JobRequestRemoteDataSource>(
    () => JobRequestRemoteDataSourceImpl(sl<Dio>()),
  );
  sl.registerLazySingleton<JobAssignmentRemoteDataSource>(
    () => JobAssignmentRemoteDataSourceImpl(sl<Dio>()),
  );
  sl.registerLazySingleton<ProviderRemoteDataSource>(
    () => ProviderRemoteDataSourceImpl(sl<Dio>()),
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl<AuthRemoteDataSource>(), sl<NetworkService>()),
  );
  sl.registerLazySingleton<ProviderRepository>(
    () => ProviderRepositoryImpl(
      sl<ProviderRemoteDataSource>(),
      sl<NetworkService>(),
    ),
  );
  sl.registerLazySingleton<ServiceCategoryRepository>(
    () => ServiceCategoryRepositoryImpl(
      sl<ServiceCategoryRemoteDataSource>(),
      sl<NetworkService>(),
    ),
  );
  sl.registerLazySingleton<ServiceRepository>(
    () => ServiceRepositoryImpl(
      sl<ServiceRemoteDataSource>(),
      sl<NetworkService>(),
    ),
  );
  sl.registerLazySingleton<PropertyRepository>(
    () => PropertyRepositoryImpl(
      sl<PropertyRemoteDataSource>(),
      sl<NetworkService>(),
    ),
  );
  sl.registerLazySingleton<PaymentRepository>(
    () => PaymentRepositoryImpl(
      sl<PaymentRemoteDataSource>(),
      sl<NetworkService>(),
    ),
  );
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(sl<Dio>(), sl<NetworkService>()),
  );
  sl.registerLazySingleton<JobRequestRepository>(
    () => JobRequestRepositoryImpl(
      sl<JobRequestRemoteDataSource>(),
      sl<NetworkService>(),
    ),
  );
  sl.registerLazySingleton<JobAssignmentRepository>(
    () => JobAssignmentRepositoryImpl(
      sl<JobAssignmentRemoteDataSource>(),
      sl<NetworkService>(),
    ),
  );
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(sl<Dio>(), sl<NetworkService>()),
  );
  sl.registerLazySingleton<FaqRepository>(
    () => FaqRepositoryImpl(sl<Dio>(), sl<NetworkService>()),
  );

  // Use Cases
  // Auth Usecases
  sl.registerLazySingleton<SendOtpUsecase>(
    () => SendOtpUsecase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<ResendOtpUsecase>(
    () => ResendOtpUsecase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<VerifyOtpAndRegisterUsecase>(
    () => VerifyOtpAndRegisterUsecase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<LoginWithFirebaseUsecase>(
    () => LoginWithFirebaseUsecase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<CompleteProfileUsecase>(
    () => CompleteProfileUsecase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<LogoutUsecase>(
    () => LogoutUsecase(sl<AuthRepository>()),
  );

  // Services Usecases
  sl.registerLazySingleton<GetServiceCategoriesUseCase>(
    () => GetServiceCategoriesUseCase(sl<ServiceCategoryRepository>()),
  );
  sl.registerLazySingleton<GetServicesUseCase>(
    () => GetServicesUseCase(sl<ServiceRepository>()),
  );
  sl.registerLazySingleton<SearchProvidersUseCase>(
    () => SearchProvidersUseCase(sl<ProviderRepository>()),
  );

  // Properties Usecases
  sl.registerLazySingleton<GetPropertiesUseCase>(
    () => GetPropertiesUseCase(sl<PropertyRepository>()),
  );
  sl.registerLazySingleton<GetPropertyUseCase>(
    () => GetPropertyUseCase(sl<PropertyRepository>()),
  );
  sl.registerLazySingleton<AddPropertyUseCase>(
    () => AddPropertyUseCase(sl<PropertyRepository>()),
  );
  sl.registerLazySingleton<UpdatePropertyUseCase>(
    () => UpdatePropertyUseCase(sl<PropertyRepository>()),
  );
  sl.registerLazySingleton<DeletePropertyUseCase>(
    () => DeletePropertyUseCase(sl<PropertyRepository>()),
  );

  // Payment Usecases
  sl.registerLazySingleton<GetCardsUseCase>(
    () => GetCardsUseCase(sl<PaymentRepository>()),
  );
  sl.registerLazySingleton<AddCardUseCase>(
    () => AddCardUseCase(sl<PaymentRepository>()),
  );
  sl.registerLazySingleton<DeleteCardUseCase>(
    () => DeleteCardUseCase(sl<PaymentRepository>()),
  );
  sl.registerLazySingleton<SetDefaultCardUseCase>(
    () => SetDefaultCardUseCase(sl<PaymentRepository>()),
  );
  sl.registerLazySingleton<ToggleFreezeCardUseCase>(
    () => ToggleFreezeCardUseCase(sl<PaymentRepository>()),
  );
  sl.registerLazySingleton<PayJobAssignmentUseCase>(
    () => PayJobAssignmentUseCase(sl<PaymentRepository>()),
  );

  // Job Request Usecases
  sl.registerLazySingleton<GetJobRequestsUseCase>(
    () => GetJobRequestsUseCase(sl<JobRequestRepository>()),
  );
  sl.registerLazySingleton<GetJobRequestDetailsUseCase>(
    () => GetJobRequestDetailsUseCase(sl<JobRequestRepository>()),
  );
  sl.registerLazySingleton<CreateJobRequestUseCase>(
    () => CreateJobRequestUseCase(sl<JobRequestRepository>()),
  );
  sl.registerLazySingleton<CancelJobRequestUseCase>(
    () => CancelJobRequestUseCase(sl<JobRequestRepository>()),
  );
  sl.registerLazySingleton<GetJobRequestQuotationsUseCase>(
    () => GetJobRequestQuotationsUseCase(sl<JobRequestRepository>()),
  );
  sl.registerLazySingleton<AcceptQuotationUseCase>(
    () => AcceptQuotationUseCase(sl<JobRequestRepository>()),
  );

  // Job Assignment Usecases
  sl.registerLazySingleton<GetJobAssignmentsUseCase>(
    () => GetJobAssignmentsUseCase(sl<JobAssignmentRepository>()),
  );
  sl.registerLazySingleton<GetJobAssignmentDetailsUseCase>(
    () => GetJobAssignmentDetailsUseCase(sl<JobAssignmentRepository>()),
  );
  sl.registerLazySingleton<SubmitReviewUseCase>(
    () => SubmitReviewUseCase(sl<JobAssignmentRepository>()),
  );
  sl.registerLazySingleton<SubmitDisputeUseCase>(
    () => SubmitDisputeUseCase(sl<JobAssignmentRepository>()),
  );

  // Profile Usecases
  sl.registerLazySingleton<GetUserProfileUseCase>(
    () => GetUserProfileUseCase(sl<ProfileRepository>()),
  );
  sl.registerLazySingleton<UpdateUserProfileUseCase>(
    () => UpdateUserProfileUseCase(sl<ProfileRepository>()),
  );
  sl.registerLazySingleton<ManagePaymentCardsUseCase>(
    () => ManagePaymentCardsUseCase(sl<ProfileRepository>()),
  );
  sl.registerLazySingleton<ManagePropertiesUseCase>(
    () => ManagePropertiesUseCase(sl<ProfileRepository>()),
  );
  sl.registerLazySingleton<ManageSettingsUseCase>(
    () => ManageSettingsUseCase(sl<ProfileRepository>()),
  );

  // Blocs & Cubits
  sl.registerFactory<AuthBloc>(
    () => AuthBloc(
      sendOtp: sl<SendOtpUsecase>(),
      resendOtp: sl<ResendOtpUsecase>(),
      verifyOtpAndRegister: sl<VerifyOtpAndRegisterUsecase>(),
      loginWithFirebase: sl<LoginWithFirebaseUsecase>(),
      completeProfile: sl<CompleteProfileUsecase>(),
      logout: sl<LogoutUsecase>(),
    ),
  );
  sl.registerFactory<ServiceCategoryCubit>(
    () => ServiceCategoryCubit(sl<GetServiceCategoriesUseCase>()),
  );
  sl.registerFactory<ServiceCubit>(
    () => ServiceCubit(sl<GetServicesUseCase>()),
  );
  sl.registerFactory<PropertyCubit>(
    () => PropertyCubit(
      sl<GetPropertiesUseCase>(),
      sl<AddPropertyUseCase>(),
      sl<UpdatePropertyUseCase>(),
      sl<DeletePropertyUseCase>(),
    ),
  );
  sl.registerFactory<CardCubit>(
    () => CardCubit(
      sl<GetCardsUseCase>(),
      sl<AddCardUseCase>(),
      sl<DeleteCardUseCase>(),
      sl<SetDefaultCardUseCase>(),
      sl<ToggleFreezeCardUseCase>(),
      sl<PayJobAssignmentUseCase>(),
    ),
  );
  sl.registerFactory<JobRequestCubit>(
    () => JobRequestCubit(
      sl<GetJobRequestsUseCase>(),
      sl<GetJobRequestDetailsUseCase>(),
      sl<CreateJobRequestUseCase>(),
      sl<CancelJobRequestUseCase>(),
      sl<GetJobRequestQuotationsUseCase>(),
      sl<AcceptQuotationUseCase>(),
    ),
  );
  sl.registerFactory<JobAssignmentCubit>(
    () => JobAssignmentCubit(
      sl<GetJobAssignmentsUseCase>(),
      sl<GetJobAssignmentDetailsUseCase>(),
      sl<SubmitReviewUseCase>(),
      sl<SubmitDisputeUseCase>(),
    ),
  );
  sl.registerFactory<NotificationCubit>(
    () => NotificationCubit(sl<NotificationRepository>()),
  );
  sl.registerFactory<ProviderSearchCubit>(
    () => ProviderSearchCubit(sl<SearchProvidersUseCase>()),
  );
}
