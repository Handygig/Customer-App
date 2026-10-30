import 'package:dartz/dartz.dart';
import 'package:customer_app/core/errors/failures.dart';
import 'package:customer_app/src/domain/entities/job_requests/job_assignment_entity.dart';
import 'package:customer_app/src/domain/entities/job_assignments/review_entity.dart';
import 'package:customer_app/src/domain/entities/job_assignments/dispute_entity.dart';
import 'package:customer_app/src/domain/repositories/job_assignments/job_assignment_repository.dart';

class GetJobAssignmentsUseCase {
  final JobAssignmentRepository _repository;

  GetJobAssignmentsUseCase(this._repository);

  Future<Either<Failure, List<JobAssignmentEntity>>> call() {
    return _repository.getJobAssignments();
  }
}

class GetJobAssignmentDetailsUseCase {
  final JobAssignmentRepository _repository;

  GetJobAssignmentDetailsUseCase(this._repository);

  Future<Either<Failure, JobAssignmentEntity>> call(int id) {
    return _repository.getJobAssignment(id);
  }
}

class SubmitReviewUseCase {
  final JobAssignmentRepository _repository;

  SubmitReviewUseCase(this._repository);

  Future<Either<Failure, ReviewEntity>> call(
    int assignmentId, {
    required int rating,
    String? comment,
  }) {
    return _repository.submitReview(
      assignmentId,
      rating: rating,
      comment: comment,
    );
  }
}

class SubmitDisputeUseCase {
  final JobAssignmentRepository _repository;

  SubmitDisputeUseCase(this._repository);

  Future<Either<Failure, DisputeEntity>> call(
    int assignmentId, {
    required String reason,
  }) {
    return _repository.submitDispute(
      assignmentId,
      reason: reason,
    );
  }
}

class ApproveExtraChargeUseCase {
  final JobAssignmentRepository _repository;

  ApproveExtraChargeUseCase(this._repository);

  Future<Either<Failure, JobAssignmentEntity>> call(int assignmentId) {
    return _repository.approveExtraCharge(assignmentId);
  }
}

class RejectExtraChargeUseCase {
  final JobAssignmentRepository _repository;

  RejectExtraChargeUseCase(this._repository);

  Future<Either<Failure, JobAssignmentEntity>> call(int assignmentId) {
    return _repository.rejectExtraCharge(assignmentId);
  }
}

class SimulateExtraQuoteUseCase {
  final JobAssignmentRepository _repository;

  SimulateExtraQuoteUseCase(this._repository);

  Future<Either<Failure, JobAssignmentEntity>> call(
    int assignmentId, {
    double? extraAmount,
    String? extraReason,
  }) {
    return _repository.simulateExtraQuote(
      assignmentId,
      extraAmount: extraAmount,
      extraReason: extraReason,
    );
  }
}

class SimulateStartJobUseCase {
  final JobAssignmentRepository _repository;

  SimulateStartJobUseCase(this._repository);

  Future<Either<Failure, JobAssignmentEntity>> call(int assignmentId) {
    return _repository.simulateStartJob(assignmentId);
  }
}

class SimulateCompleteJobUseCase {
  final JobAssignmentRepository _repository;

  SimulateCompleteJobUseCase(this._repository);

  Future<Either<Failure, JobAssignmentEntity>> call(int assignmentId) {
    return _repository.simulateCompleteJob(assignmentId);
  }
}
