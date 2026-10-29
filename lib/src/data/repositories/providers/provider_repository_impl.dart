import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:customer_app/core/errors/failures.dart';
import 'package:customer_app/core/errors/auth_exception.dart';
import 'package:customer_app/core/services/network_service.dart';
import 'package:customer_app/src/data/data_sources/remote/providers/provider_remote_data_source.dart';
import 'package:customer_app/src/domain/entities/providers/service_provider_entity.dart';
import 'package:customer_app/src/domain/repositories/providers/provider_repository.dart';

class ProviderRepositoryImpl implements ProviderRepository {
  final ProviderRemoteDataSource _remoteDataSource;
  final NetworkService _networkService;

  ProviderRepositoryImpl(
    this._remoteDataSource,
    this._networkService,
  );

  @override
  Future<Either<Failure, List<ServiceProviderEntity>>> searchProviders({
    double? latitude,
    double? longitude,
    double? radius,
    String? service,
    int? categoryId,
    String? location,
  }) async {
    try {
      if (!await _networkService.isConnected()) {
        return const Left(
          NetworkFailure(errorMessage: 'No internet connection detected.'),
        );
      }

      final providers = await _remoteDataSource.searchProviders(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
        service: service,
        categoryId: categoryId,
        location: location,
      );
      return Right(providers);
    } on AuthException catch (e) {
      return Left(APIFailure(errorMessage: e.message));
    } catch (e, stackTrace) {
      debugPrint('⚠️ [ProviderRepositoryImpl.searchProviders] Error: $e');
      return Left(
        APIFailure(errorMessage: e.toString(), stackTrace: stackTrace),
      );
    }
  }
}
