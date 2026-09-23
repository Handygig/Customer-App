import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:customer_app/core/errors/failures.dart';
import 'package:customer_app/core/errors/auth_exception.dart';
import 'package:customer_app/core/services/network_service.dart';
import 'package:customer_app/src/data/data_sources/remote/services/service_category_remote_data_source.dart';
import 'package:customer_app/src/domain/entities/services/service_category_entity.dart';
import 'package:customer_app/src/domain/repositories/services/service_category_repository.dart';

class ServiceCategoryRepositoryImpl implements ServiceCategoryRepository {
  final ServiceCategoryRemoteDataSource _remoteDataSource;
  final NetworkService _networkService;

  ServiceCategoryRepositoryImpl(
    this._remoteDataSource,
    this._networkService,
  );

  @override
  Future<Either<Failure, List<ServiceCategoryEntity>>> getServiceCategories() async {
    try {
      if (!await _networkService.isConnected()) {
        return const Left(
          NetworkFailure(errorMessage: 'No internet connection detected.'),
        );
      }

      final categories = await _remoteDataSource.getServiceCategories();
      return Right(categories);
    } on AuthException catch (e) {
      return Left(APIFailure(errorMessage: e.message));
    } catch (e, stackTrace) {
      debugPrint('⚠️ [ServiceCategoryRepositoryImpl.getServiceCategories] Error: $e');
      return Left(
        APIFailure(errorMessage: e.toString(), stackTrace: stackTrace),
      );
    }
  }
}
