import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:customer_app/src/domain/entities/job_requests/job_request_entity.dart';
import 'package:customer_app/src/domain/entities/job_requests/quotation_entity.dart';
import 'package:customer_app/src/domain/usecases/job_requests/job_request_usecases.dart';
import 'package:customer_app/src/presentation/cubits/job_requests/job_request_state.dart';

class JobRequestCubit extends Cubit<JobRequestState> {
  final GetJobRequestsUseCase _getJobRequestsUseCase;
  final GetJobRequestDetailsUseCase _getJobRequestDetailsUseCase;
  final CreateJobRequestUseCase _createJobRequestUseCase;
  final CancelJobRequestUseCase _cancelJobRequestUseCase;
  final GetJobRequestQuotationsUseCase _getJobRequestQuotationsUseCase;
  final AcceptQuotationUseCase _acceptQuotationUseCase;

  List<JobRequestEntity> _cachedRequests = const [];
  JobRequestEntity? _selectedJobRequest;
  final Map<int, List<QuotationEntity>> _quotationsByJobId = {};

  JobRequestCubit(
    this._getJobRequestsUseCase,
    this._getJobRequestDetailsUseCase,
    this._createJobRequestUseCase,
    this._cancelJobRequestUseCase,
    this._getJobRequestQuotationsUseCase,
    this._acceptQuotationUseCase,
  ) : super(const JobRequestInitial());

  List<JobRequestEntity> get currentRequests => _cachedRequests;
  JobRequestEntity? get selectedJobRequest => _selectedJobRequest;
  List<QuotationEntity> quotationsFor(int jobId) =>
      _quotationsByJobId[jobId] ?? const [];

  Future<void> loadJobRequests({
    bool forceRefresh = false,
    bool silent = false,
  }) async {
    if (!forceRefresh && state is JobRequestLoaded && _cachedRequests.isNotEmpty) {
      return;
    }

    if (!silent) {
      emit(const JobRequestLoading());
    }

    final result = await _getJobRequestsUseCase();
    await result.fold(
      (failure) async {
        emit(JobRequestError(
          failure.errorMessage,
          currentJobRequests: _cachedRequests,
          selectedJobRequest: _selectedJobRequest,
        ));
      },
      (requests) async {
        _cachedRequests = requests;
        emit(JobRequestLoaded(
          List.unmodifiable(_cachedRequests),
          selectedJobRequest: _selectedJobRequest,
          quotationsByJobId: Map.unmodifiable(_quotationsByJobId),
        ));

        // Fetch quotations for pending requests
        final pending = requests.where((r) => r.isPending).toList();
        if (pending.isNotEmpty) {
          final updated = await Future.wait(requests.map((r) async {
            if (!r.isPending) return r;
            final quoteRes = await _getJobRequestQuotationsUseCase(r.id);
            return quoteRes.fold(
              (_) => r,
              (quotes) {
                _quotationsByJobId[r.id] = quotes;
                return r.copyWith(quotations: quotes);
              },
            );
          }));

          _cachedRequests = updated;
          emit(JobRequestLoaded(
            List.unmodifiable(_cachedRequests),
            selectedJobRequest: _selectedJobRequest,
            quotationsByJobId: Map.unmodifiable(_quotationsByJobId),
          ));
        }
      },
    );
  }

  Future<JobRequestEntity?> loadJobRequestDetails(int id) async {
    final result = await _getJobRequestDetailsUseCase(id);
    return result.fold(
      (failure) {
        emit(JobRequestError(
          failure.errorMessage,
          currentJobRequests: _cachedRequests,
          selectedJobRequest: _selectedJobRequest,
        ));
        return null;
      },
      (jobRequest) {
        _selectedJobRequest = jobRequest;
        if (jobRequest.quotations.isNotEmpty) {
          _quotationsByJobId[id] = jobRequest.quotations;
        }

        // Update in cached list if exists
        _cachedRequests = _cachedRequests.map((r) {
          return r.id == id ? jobRequest : r;
        }).toList();

        emit(JobRequestLoaded(
          List.unmodifiable(_cachedRequests),
          selectedJobRequest: _selectedJobRequest,
          quotationsByJobId: Map.unmodifiable(_quotationsByJobId),
        ));
        return jobRequest;
      },
    );
  }

  Future<JobRequestEntity?> createJobRequest({
    required int propertyId,
    required int serviceCategoryId,
    required String description,
    required DateTime preferredDate,
  }) async {
    emit(JobRequestActionInProgress(
      _cachedRequests,
      selectedJobRequest: _selectedJobRequest,
    ));

    final result = await _createJobRequestUseCase(
      propertyId: propertyId,
      serviceCategoryId: serviceCategoryId,
      description: description,
      preferredDate: preferredDate,
    );

    return result.fold(
      (failure) {
        emit(JobRequestError(
          failure.errorMessage,
          currentJobRequests: _cachedRequests,
          selectedJobRequest: _selectedJobRequest,
        ));
        return null;
      },
      (newRequest) {
        _cachedRequests = [newRequest, ..._cachedRequests];
        _selectedJobRequest = newRequest;

        emit(JobRequestActionSuccess(
          message: 'Job request submitted successfully!',
          jobRequests: List.unmodifiable(_cachedRequests),
          selectedJobRequest: _selectedJobRequest,
          quotationsByJobId: Map.unmodifiable(_quotationsByJobId),
        ));

        emit(JobRequestLoaded(
          List.unmodifiable(_cachedRequests),
          selectedJobRequest: _selectedJobRequest,
          quotationsByJobId: Map.unmodifiable(_quotationsByJobId),
        ));
        return newRequest;
      },
    );
  }

  Future<bool> cancelJobRequest(int id) async {
    emit(JobRequestActionInProgress(
      _cachedRequests,
      selectedJobRequest: _selectedJobRequest,
    ));

    final result = await _cancelJobRequestUseCase(id);

    return result.fold(
      (failure) {
        emit(JobRequestError(
          failure.errorMessage,
          currentJobRequests: _cachedRequests,
          selectedJobRequest: _selectedJobRequest,
        ));
        return false;
      },
      (_) {
        _cachedRequests = _cachedRequests.map((r) {
          if (r.id == id) {
            return r.copyWith(status: 'cancelled');
          }
          return r;
        }).toList();

        if (_selectedJobRequest?.id == id) {
          _selectedJobRequest =
              _selectedJobRequest!.copyWith(status: 'cancelled');
        }

        emit(JobRequestActionSuccess(
          message: 'Job request cancelled successfully',
          jobRequests: List.unmodifiable(_cachedRequests),
          selectedJobRequest: _selectedJobRequest,
          quotationsByJobId: Map.unmodifiable(_quotationsByJobId),
        ));

        emit(JobRequestLoaded(
          List.unmodifiable(_cachedRequests),
          selectedJobRequest: _selectedJobRequest,
          quotationsByJobId: Map.unmodifiable(_quotationsByJobId),
        ));
        return true;
      },
    );
  }

  Future<List<QuotationEntity>> loadJobRequestQuotations(int id) async {
    final result = await _getJobRequestQuotationsUseCase(id);
    return result.fold(
      (failure) {
        emit(JobRequestError(
          failure.errorMessage,
          currentJobRequests: _cachedRequests,
          selectedJobRequest: _selectedJobRequest,
        ));
        return const [];
      },
      (quotes) {
        _quotationsByJobId[id] = quotes;

        // If selected job request is this one, update its quotations
        if (_selectedJobRequest?.id == id) {
          _selectedJobRequest =
              _selectedJobRequest!.copyWith(quotations: quotes);
        }

        _cachedRequests = _cachedRequests.map((r) {
          if (r.id == id) {
            return r.copyWith(quotations: quotes);
          }
          return r;
        }).toList();

        emit(JobRequestLoaded(
          List.unmodifiable(_cachedRequests),
          selectedJobRequest: _selectedJobRequest,
          quotationsByJobId: Map.unmodifiable(_quotationsByJobId),
        ));
        return quotes;
      },
    );
  }

  Future<bool> acceptQuotation(int quotationId, int jobRequestId) async {
    emit(JobRequestActionInProgress(
      _cachedRequests,
      selectedJobRequest: _selectedJobRequest,
    ));

    final result = await _acceptQuotationUseCase(quotationId);

    return result.fold(
      (failure) {
        emit(JobRequestError(
          failure.errorMessage,
          currentJobRequests: _cachedRequests,
          selectedJobRequest: _selectedJobRequest,
        ));
        return false;
      },
      (_) {
        // Mark quotation as accepted and request as assigned
        final currentQuotes = _quotationsByJobId[jobRequestId] ?? [];
        final updatedQuotes = currentQuotes.map((q) {
          if (q.id == quotationId) {
            return QuotationEntity(
              id: q.id,
              quotedPrice: q.quotedPrice,
              estimatedDuration: q.estimatedDuration,
              message: q.message,
              status: 'accepted',
              provider: q.provider,
              createdAt: q.createdAt,
            );
          }
          return QuotationEntity(
            id: q.id,
            quotedPrice: q.quotedPrice,
            estimatedDuration: q.estimatedDuration,
            message: q.message,
            status: 'rejected',
            provider: q.provider,
            createdAt: q.createdAt,
          );
        }).toList();

        _quotationsByJobId[jobRequestId] = updatedQuotes;

        _cachedRequests = _cachedRequests.map((r) {
          if (r.id == jobRequestId) {
            return r.copyWith(
              status: 'assigned',
              quotations: updatedQuotes,
            );
          }
          return r;
        }).toList();

        if (_selectedJobRequest?.id == jobRequestId) {
          _selectedJobRequest = _selectedJobRequest!.copyWith(
            status: 'assigned',
            quotations: updatedQuotes,
          );
        }

        emit(JobRequestActionSuccess(
          message: 'Quotation accepted and job assigned successfully!',
          jobRequests: List.unmodifiable(_cachedRequests),
          selectedJobRequest: _selectedJobRequest,
          quotationsByJobId: Map.unmodifiable(_quotationsByJobId),
        ));

        emit(JobRequestLoaded(
          List.unmodifiable(_cachedRequests),
          selectedJobRequest: _selectedJobRequest,
          quotationsByJobId: Map.unmodifiable(_quotationsByJobId),
        ));
        return true;
      },
    );
  }
}
