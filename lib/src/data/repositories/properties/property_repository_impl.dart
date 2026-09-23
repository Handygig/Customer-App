import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:customer_app/core/errors/failures.dart';
import 'package:customer_app/core/errors/auth_exception.dart';
import 'package:customer_app/core/services/network_service.dart';
import 'package:customer_app/src/data/data_sources/remote/properties/property_remote_data_source.dart';
import 'package:customer_app/src/domain/entities/properties/property_entity.dart';
import 'package:customer_app/src/domain/repositories/properties/property_repository.dart';

class PropertyRepositoryImpl implements PropertyRepository {
  final PropertyRemoteDataSource _remoteDataSource;
  final NetworkService _networkService;

  PropertyRepositoryImpl(
    this._remoteDataSource,
    this._networkService,
  );

  @override
  Future<Either<Failure, List<PropertyEntity>>> getProperties() async {
    try {
      if (!await _networkService.isConnected()) {
        return const Left(NetworkFailure(errorMessage: 'No internet connection detected.'));
      }
      final properties = await _remoteDataSource.getProperties();
      return Right(properties);
    } on AuthException catch (e) {
      return Left(APIFailure(errorMessage: e.message));
    } catch (e, stackTrace) {
      debugPrint('⚠️ [PropertyRepositoryImpl.getProperties] Error: $e');
      return Left(APIFailure(errorMessage: e.toString(), stackTrace: stackTrace));
    }
  }

  @override
  Future<Either<Failure, PropertyEntity>> getProperty(int id) async {
    try {
      if (!await _networkService.isConnected()) {
        return const Left(NetworkFailure(errorMessage: 'No internet connection detected.'));
      }
      final property = await _remoteDataSource.getProperty(id);
      return Right(property);
    } on AuthException catch (e) {
      return Left(APIFailure(errorMessage: e.message));
    } catch (e, stackTrace) {
      debugPrint('⚠️ [PropertyRepositoryImpl.getProperty] Error: $e');
      return Left(APIFailure(errorMessage: e.toString(), stackTrace: stackTrace));
    }
  }

  @override
  Future<Either<Failure, PropertyEntity>> addProperty({
    required String label,
    required String addressLine,
    required String city,
    double? latitude,
    double? longitude,
    bool? isDefault,
  }) async {
    try {
      if (!await _networkService.isConnected()) {
        return const Left(NetworkFailure(errorMessage: 'No internet connection detected.'));
      }
      final property = await _remoteDataSource.addProperty(
        label: label,
        addressLine: addressLine,
        city: city,
        latitude: latitude,
        longitude: longitude,
        isDefault: isDefault,
      );
      return Right(property);
    } on AuthException catch (e) {
      return Left(APIFailure(errorMessage: e.message));
    } catch (e, stackTrace) {
      debugPrint('⚠️ [PropertyRepositoryImpl.addProperty] Error: $e');
      return Left(APIFailure(errorMessage: e.toString(), stackTrace: stackTrace));
    }
  }

  @override
  Future<Either<Failure, PropertyEntity>> updateProperty({
    required int id,
    String? label,
    String? addressLine,
    String? city,
    double? latitude,
    double? longitude,
    bool? isDefault,
  }) async {
    try {
      if (!await _networkService.isConnected()) {
        return const Left(NetworkFailure(errorMessage: 'No internet connection detected.'));
      }
      final property = await _remoteDataSource.updateProperty(
        id: id,
        label: label,
        addressLine: addressLine,
        city: city,
        latitude: latitude,
        longitude: longitude,
        isDefault: isDefault,
      );
      return Right(property);
    } on AuthException catch (e) {
      return Left(APIFailure(errorMessage: e.message));
    } catch (e, stackTrace) {
      debugPrint('⚠️ [PropertyRepositoryImpl.updateProperty] Error: $e');
      return Left(APIFailure(errorMessage: e.toString(), stackTrace: stackTrace));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProperty(int id) async {
    try {
      if (!await _networkService.isConnected()) {
        return const Left(NetworkFailure(errorMessage: 'No internet connection detected.'));
      }
      await _remoteDataSource.deleteProperty(id);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(APIFailure(errorMessage: e.message));
    } catch (e, stackTrace) {
      debugPrint('⚠️ [PropertyRepositoryImpl.deleteProperty] Error: $e');
      return Left(APIFailure(errorMessage: e.toString(), stackTrace: stackTrace));
    }
  }
}
