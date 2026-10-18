import 'package:dartz/dartz.dart';
import 'package:customer_app/core/errors/failures.dart';
import 'package:customer_app/src/domain/entities/job_requests/job_request_entity.dart';
import 'package:customer_app/src/domain/entities/job_requests/quotation_entity.dart';

abstract class JobRequestRepository {
  Future<Either<Failure, List<JobRequestEntity>>> getJobRequests();
  Future<Either<Failure, JobRequestEntity>> getJobRequest(int id);
  Future<Either<Failure, JobRequestEntity>> createJobRequest({
    required int propertyId,
    required int serviceCategoryId,
    required String description,
    required DateTime preferredDate,
  });
  Future<Either<Failure, void>> cancelJobRequest(int id);
  Future<Either<Failure, List<QuotationEntity>>> getJobRequestQuotations(int id);
  Future<Either<Failure, void>> acceptQuotation(int quotationId);
}
