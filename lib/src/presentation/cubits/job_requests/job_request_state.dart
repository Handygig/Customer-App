import 'package:equatable/equatable.dart';
import 'package:customer_app/src/domain/entities/job_requests/job_request_entity.dart';
import 'package:customer_app/src/domain/entities/job_requests/quotation_entity.dart';

abstract class JobRequestState extends Equatable {
  const JobRequestState();

  @override
  List<Object?> get props => [];
}

class JobRequestInitial extends JobRequestState {
  const JobRequestInitial();
}

class JobRequestLoading extends JobRequestState {
  const JobRequestLoading();
}

class JobRequestLoaded extends JobRequestState {
  final List<JobRequestEntity> jobRequests;
  final JobRequestEntity? selectedJobRequest;
  final Map<int, List<QuotationEntity>> quotationsByJobId;

  const JobRequestLoaded(
    this.jobRequests, {
    this.selectedJobRequest,
    this.quotationsByJobId = const {},
  });

  JobRequestLoaded copyWith({
    List<JobRequestEntity>? jobRequests,
    JobRequestEntity? selectedJobRequest,
    Map<int, List<QuotationEntity>>? quotationsByJobId,
  }) {
    return JobRequestLoaded(
      jobRequests ?? this.jobRequests,
      selectedJobRequest: selectedJobRequest ?? this.selectedJobRequest,
      quotationsByJobId: quotationsByJobId ?? this.quotationsByJobId,
    );
  }

  @override
  List<Object?> get props => [jobRequests, selectedJobRequest, quotationsByJobId];
}

class JobRequestActionInProgress extends JobRequestState {
  final List<JobRequestEntity> currentJobRequests;
  final JobRequestEntity? selectedJobRequest;

  const JobRequestActionInProgress(
    this.currentJobRequests, {
    this.selectedJobRequest,
  });

  @override
  List<Object?> get props => [currentJobRequests, selectedJobRequest];
}

class JobRequestActionSuccess extends JobRequestState {
  final String message;
  final List<JobRequestEntity> jobRequests;
  final JobRequestEntity? selectedJobRequest;
  final Map<int, List<QuotationEntity>> quotationsByJobId;

  const JobRequestActionSuccess({
    required this.message,
    required this.jobRequests,
    this.selectedJobRequest,
    this.quotationsByJobId = const {},
  });

  @override
  List<Object?> get props => [
        message,
        jobRequests,
        selectedJobRequest,
        quotationsByJobId,
      ];
}

class JobRequestError extends JobRequestState {
  final String message;
  final List<JobRequestEntity>? currentJobRequests;
  final JobRequestEntity? selectedJobRequest;

  const JobRequestError(
    this.message, {
    this.currentJobRequests,
    this.selectedJobRequest,
  });

  @override
  List<Object?> get props => [message, currentJobRequests, selectedJobRequest];
}
