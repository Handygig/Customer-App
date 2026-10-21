import 'package:dartz/dartz.dart';
import 'package:customer_app/core/errors/failures.dart';
import 'package:customer_app/src/domain/entities/job_requests/job_request_entity.dart';
import 'package:customer_app/src/domain/entities/job_requests/quotation_entity.dart';
import 'package:customer_app/src/domain/repositories/job_requests/job_request_repository.dart';

class GetJobRequestsUseCase {
  final JobRequestRepository _repository;

  GetJobRequestsUseCase(this._repository);

  Future<Either<Failure, List<JobRequestEntity>>> call() {
    return _repository.getJobRequests();
  }
}

class GetJobRequestDetailsUseCase {
  final JobRequestRepository _repository;

  GetJobRequestDetailsUseCase(this._repository);

  Future<Either<Failure, JobRequestEntity>> call(int id) {
    return _repository.getJobRequest(id);
  }
}

class CreateJobRequestUseCase {
  final JobRequestRepository _repository;

  CreateJobRequestUseCase(this._repository);

  Future<Either<Failure, JobRequestEntity>> call({
    required int propertyId,
    required int serviceCategoryId,
    required String description,
    required DateTime preferredDate,
    String paymentMethod = 'card',
    int? cardId,
  }) {
    return _repository.createJobRequest(
      propertyId: propertyId,
      serviceCategoryId: serviceCategoryId,
      description: description,
      preferredDate: preferredDate,
      paymentMethod: paymentMethod,
      cardId: cardId,
    );
  }
}

class CancelJobRequestUseCase {
  final JobRequestRepository _repository;

  CancelJobRequestUseCase(this._repository);

  Future<Either<Failure, void>> call(int id) {
    return _repository.cancelJobRequest(id);
  }
}

class GetJobRequestQuotationsUseCase {
  final JobRequestRepository _repository;

  GetJobRequestQuotationsUseCase(this._repository);

  Future<Either<Failure, List<QuotationEntity>>> call(int id) {
    return _repository.getJobRequestQuotations(id);
  }
}

class AcceptQuotationUseCase {
  final JobRequestRepository _repository;

  AcceptQuotationUseCase(this._repository);

  Future<Either<Failure, void>> call(int quotationId) {
    return _repository.acceptQuotation(quotationId);
  }
}
