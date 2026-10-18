import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:customer_app/core/errors/failures.dart';
import 'package:customer_app/core/errors/auth_exception.dart';
import 'package:customer_app/core/services/network_service.dart';
import 'package:customer_app/src/data/data_sources/remote/job_assignments/job_assignment_remote_data_source.dart';
import 'package:customer_app/src/domain/entities/job_requests/job_assignment_entity.dart';
import 'package:customer_app/src/domain/entities/job_assignments/review_entity.dart';
import 'package:customer_app/src/domain/entities/job_assignments/dispute_entity.dart';
import 'package:customer_app/src/domain/repositories/job_assignments/job_assignment_repository.dart';

class JobAssignmentRepositoryImpl implements JobAssignmentRepository {
  final JobAssignmentRemoteDataSource _remoteDataSource;
  final NetworkService _networkService;

  JobAssignmentRepositoryImpl(
    this._remoteDataSource,
    this._networkService,
  );

  @override
  Future<Either<Failure, List<JobAssignmentEntity>>> getJobAssignments() async {
    try {
      if (!await _networkService.isConnected()) {
        return const Left(
            NetworkFailure(errorMessage: 'No internet connection detected.'));
      }
      final assignments = await _remoteDataSource.getJobAssignments();
      return Right(assignments);
    } on AuthException catch (e) {
      return Left(APIFailure(errorMessage: e.message));
    } catch (e, stackTrace) {
      debugPrint('⚠️ [JobAssignmentRepositoryImpl.getJobAssignments] Error: $e');
      return Left(
          APIFailure(errorMessage: e.toString(), stackTrace: stackTrace));
    }
  }

  @override
  Future<Either<Failure, JobAssignmentEntity>> getJobAssignment(int id) async {
    try {
      if (!await _networkService.isConnected()) {
        return const Left(
            NetworkFailure(errorMessage: 'No internet connection detected.'));
      }
      final assignment = await _remoteDataSource.getJobAssignment(id);
      return Right(assignment);
    } on AuthException catch (e) {
      return Left(APIFailure(errorMessage: e.message));
    } catch (e, stackTrace) {
      debugPrint('⚠️ [JobAssignmentRepositoryImpl.getJobAssignment] Error: $e');
      return Left(
          APIFailure(errorMessage: e.toString(), stackTrace: stackTrace));
    }
  }

  @override
  Future<Either<Failure, ReviewEntity>> submitReview(
    int assignmentId, {
    required int rating,
    String? comment,
  }) async {
    try {
      if (!await _networkService.isConnected()) {
        return const Left(
            NetworkFailure(errorMessage: 'No internet connection detected.'));
      }
      final review = await _remoteDataSource.submitReview(
        assignmentId,
        rating: rating,
        comment: comment,
      );
      return Right(review);
    } on AuthException catch (e) {
      return Left(APIFailure(errorMessage: e.message));
    } catch (e, stackTrace) {
      debugPrint('⚠️ [JobAssignmentRepositoryImpl.submitReview] Error: $e');
      return Left(
          APIFailure(errorMessage: e.toString(), stackTrace: stackTrace));
    }
  }

  @override
  Future<Either<Failure, DisputeEntity>> submitDispute(
    int assignmentId, {
    required String reason,
  }) async {
    try {
      if (!await _networkService.isConnected()) {
        return const Left(
            NetworkFailure(errorMessage: 'No internet connection detected.'));
      }
      final dispute = await _remoteDataSource.submitDispute(
        assignmentId,
        reason: reason,
      );
      return Right(dispute);
    } on AuthException catch (e) {
      return Left(APIFailure(errorMessage: e.message));
    } catch (e, stackTrace) {
      debugPrint('⚠️ [JobAssignmentRepositoryImpl.submitDispute] Error: $e');
      return Left(
          APIFailure(errorMessage: e.toString(), stackTrace: stackTrace));
    }
  }
}
