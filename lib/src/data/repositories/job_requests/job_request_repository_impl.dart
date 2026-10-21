import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:customer_app/core/errors/failures.dart';
import 'package:customer_app/core/errors/auth_exception.dart';
import 'package:customer_app/core/services/network_service.dart';
import 'package:customer_app/src/data/data_sources/remote/job_requests/job_request_remote_data_source.dart';
import 'package:customer_app/src/domain/entities/job_requests/job_request_entity.dart';
import 'package:customer_app/src/domain/entities/job_requests/quotation_entity.dart';
import 'package:customer_app/src/domain/repositories/job_requests/job_request_repository.dart';

class JobRequestRepositoryImpl implements JobRequestRepository {
  final JobRequestRemoteDataSource _remoteDataSource;
  final NetworkService _networkService;

  JobRequestRepositoryImpl(
    this._remoteDataSource,
    this._networkService,
  );

  @override
  Future<Either<Failure, List<JobRequestEntity>>> getJobRequests() async {
    try {
      if (!await _networkService.isConnected()) {
        return const Left(
            NetworkFailure(errorMessage: 'No internet connection detected.'));
      }
      final jobRequests = await _remoteDataSource.getJobRequests();
      return Right(jobRequests);
    } on AuthException catch (e) {
      return Left(APIFailure(errorMessage: e.message));
    } catch (e, stackTrace) {
      debugPrint('⚠️ [JobRequestRepositoryImpl.getJobRequests] Error: $e');
      return Left(
          APIFailure(errorMessage: e.toString(), stackTrace: stackTrace));
    }
  }

  @override
  Future<Either<Failure, JobRequestEntity>> getJobRequest(int id) async {
    try {
      if (!await _networkService.isConnected()) {
        return const Left(
            NetworkFailure(errorMessage: 'No internet connection detected.'));
      }
      final jobRequest = await _remoteDataSource.getJobRequest(id);
      return Right(jobRequest);
    } on AuthException catch (e) {
      return Left(APIFailure(errorMessage: e.message));
    } catch (e, stackTrace) {
      debugPrint('⚠️ [JobRequestRepositoryImpl.getJobRequest] Error: $e');
      return Left(
          APIFailure(errorMessage: e.toString(), stackTrace: stackTrace));
    }
  }

  @override
  Future<Either<Failure, JobRequestEntity>> createJobRequest({
    required int propertyId,
    required int serviceCategoryId,
    required String description,
    required DateTime preferredDate,
    String paymentMethod = 'card',
    int? cardId,
  }) async {
    try {
      if (!await _networkService.isConnected()) {
        return const Left(
            NetworkFailure(errorMessage: 'No internet connection detected.'));
      }
      final jobRequest = await _remoteDataSource.createJobRequest(
        propertyId: propertyId,
        serviceCategoryId: serviceCategoryId,
        description: description,
        preferredDate: preferredDate,
        paymentMethod: paymentMethod,
        cardId: cardId,
      );
      return Right(jobRequest);
    } on AuthException catch (e) {
      return Left(APIFailure(errorMessage: e.message));
    } catch (e, stackTrace) {
      debugPrint('⚠️ [JobRequestRepositoryImpl.createJobRequest] Error: $e');
      return Left(
          APIFailure(errorMessage: e.toString(), stackTrace: stackTrace));
    }
  }

  @override
  Future<Either<Failure, void>> cancelJobRequest(int id) async {
    try {
      if (!await _networkService.isConnected()) {
        return const Left(
            NetworkFailure(errorMessage: 'No internet connection detected.'));
      }
      await _remoteDataSource.cancelJobRequest(id);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(APIFailure(errorMessage: e.message));
    } catch (e, stackTrace) {
      debugPrint('⚠️ [JobRequestRepositoryImpl.cancelJobRequest] Error: $e');
      return Left(
          APIFailure(errorMessage: e.toString(), stackTrace: stackTrace));
    }
  }

  @override
  Future<Either<Failure, List<QuotationEntity>>> getJobRequestQuotations(
      int id) async {
    try {
      if (!await _networkService.isConnected()) {
        return const Left(
            NetworkFailure(errorMessage: 'No internet connection detected.'));
      }
      final quotations = await _remoteDataSource.getJobRequestQuotations(id);
      return Right(quotations);
    } on AuthException catch (e) {
      return Left(APIFailure(errorMessage: e.message));
    } catch (e, stackTrace) {
      debugPrint(
          '⚠️ [JobRequestRepositoryImpl.getJobRequestQuotations] Error: $e');
      return Left(
          APIFailure(errorMessage: e.toString(), stackTrace: stackTrace));
    }
  }

  @override
  Future<Either<Failure, void>> acceptQuotation(int quotationId) async {
    try {
      if (!await _networkService.isConnected()) {
        return const Left(
            NetworkFailure(errorMessage: 'No internet connection detected.'));
      }
      await _remoteDataSource.acceptQuotation(quotationId);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(APIFailure(errorMessage: e.message));
    } catch (e, stackTrace) {
      debugPrint('⚠️ [JobRequestRepositoryImpl.acceptQuotation] Error: $e');
      return Left(
          APIFailure(errorMessage: e.toString(), stackTrace: stackTrace));
    }
  }
}
