import 'package:customer_app/src/data/models/job_requests/job_assignment_model.dart';
import 'package:customer_app/src/data/models/job_assignments/review_model.dart';
import 'package:customer_app/src/data/models/job_assignments/dispute_model.dart';

abstract class JobAssignmentRemoteDataSource {
  Future<List<JobAssignmentModel>> getJobAssignments();
  Future<JobAssignmentModel> getJobAssignment(int id);
  Future<ReviewModel> submitReview(
    int assignmentId, {
    required int rating,
    String? comment,
  });
  Future<DisputeModel> submitDispute(
    int assignmentId, {
    required String reason,
  });
  Future<JobAssignmentModel> approveExtraCharge(int assignmentId);
  Future<JobAssignmentModel> rejectExtraCharge(int assignmentId);
  Future<JobAssignmentModel> simulateExtraQuote(
    int assignmentId, {
    double? extraAmount,
    String? extraReason,
  });
  Future<JobAssignmentModel> simulateStartJob(int assignmentId);
  Future<JobAssignmentModel> simulateCompleteJob(int assignmentId);
}
