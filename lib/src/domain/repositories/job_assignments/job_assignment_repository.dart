import 'package:dartz/dartz.dart';
import 'package:customer_app/core/errors/failures.dart';
import 'package:customer_app/src/domain/entities/job_requests/job_assignment_entity.dart';
import 'package:customer_app/src/domain/entities/job_assignments/review_entity.dart';
import 'package:customer_app/src/domain/entities/job_assignments/dispute_entity.dart';

abstract class JobAssignmentRepository {
  Future<Either<Failure, List<JobAssignmentEntity>>> getJobAssignments();
  Future<Either<Failure, JobAssignmentEntity>> getJobAssignment(int id);
  Future<Either<Failure, ReviewEntity>> submitReview(
    int assignmentId, {
    required int rating,
    String? comment,
  });
  Future<Either<Failure, DisputeEntity>> submitDispute(
    int assignmentId, {
    required String reason,
  });
  Future<Either<Failure, JobAssignmentEntity>> approveExtraCharge(int assignmentId);
  Future<Either<Failure, JobAssignmentEntity>> rejectExtraCharge(int assignmentId);
  Future<Either<Failure, JobAssignmentEntity>> simulateExtraQuote(
    int assignmentId, {
    double? extraAmount,
    String? extraReason,
  });
  Future<Either<Failure, JobAssignmentEntity>> simulateStartJob(int assignmentId);
  Future<Either<Failure, JobAssignmentEntity>> simulateCompleteJob(int assignmentId);
}
