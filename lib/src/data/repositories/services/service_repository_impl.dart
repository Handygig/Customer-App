import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:customer_app/core/errors/failures.dart';
import 'package:customer_app/core/errors/auth_exception.dart';
import 'package:customer_app/core/services/network_service.dart';
import 'package:customer_app/src/data/data_sources/remote/services/service_remote_data_source.dart';
import 'package:customer_app/src/domain/entities/services/service_entity.dart';
import 'package:customer_app/src/domain/repositories/services/service_repository.dart';

class ServiceRepositoryImpl implements ServiceRepository {
  final ServiceRemoteDataSource _remoteDataSource;
  final NetworkService _networkService;

  ServiceRepositoryImpl(
    this._remoteDataSource,
    this._networkService,
  );

  @override
  Future<Either<Failure, List<ServiceEntity>>> getServices({
    int? categoryId,
    String? search,
  }) async {
    try {
      if (!await _networkService.isConnected()) {
        return const Left(
          NetworkFailure(errorMessage: 'No internet connection detected.'),
        );
      }

      final services = await _remoteDataSource.getServices(
        categoryId: categoryId,
        search: search,
      );
      return Right(services);
    } on AuthException catch (e) {
      return Left(APIFailure(errorMessage: e.message));
    } catch (e, stackTrace) {
      debugPrint('⚠️ [ServiceRepositoryImpl.getServices] Error: $e');
      return Left(
        APIFailure(errorMessage: e.toString(), stackTrace: stackTrace),
      );
    }
  }
}
