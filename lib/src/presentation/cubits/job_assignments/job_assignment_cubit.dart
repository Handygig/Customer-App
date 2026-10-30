import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:customer_app/src/domain/entities/job_requests/job_assignment_entity.dart';
import 'package:customer_app/src/domain/usecases/job_assignments/job_assignment_usecases.dart';
import 'package:customer_app/src/presentation/cubits/job_assignments/job_assignment_state.dart';

class JobAssignmentCubit extends Cubit<JobAssignmentState> {
  final GetJobAssignmentsUseCase _getJobAssignmentsUseCase;
  final GetJobAssignmentDetailsUseCase _getJobAssignmentDetailsUseCase;
  final SubmitReviewUseCase _submitReviewUseCase;
  final SubmitDisputeUseCase _submitDisputeUseCase;
  final ApproveExtraChargeUseCase _approveExtraChargeUseCase;
  final RejectExtraChargeUseCase _rejectExtraChargeUseCase;
  final SimulateExtraQuoteUseCase _simulateExtraQuoteUseCase;
  final SimulateCompleteJobUseCase _simulateCompleteJobUseCase;

  List<JobAssignmentEntity> _cachedAssignments = const [];
  JobAssignmentEntity? _selectedAssignment;

  JobAssignmentCubit(
    this._getJobAssignmentsUseCase,
    this._getJobAssignmentDetailsUseCase,
    this._submitReviewUseCase,
    this._submitDisputeUseCase,
    this._approveExtraChargeUseCase,
    this._rejectExtraChargeUseCase,
    this._simulateExtraQuoteUseCase,
    this._simulateCompleteJobUseCase,
  ) : super(const JobAssignmentInitial());

  List<JobAssignmentEntity> get currentAssignments => _cachedAssignments;
  JobAssignmentEntity? get selectedAssignment => _selectedAssignment;

  Future<void> loadAssignments({
    bool forceRefresh = false,
    bool silent = false,
  }) async {
    if (!forceRefresh &&
        state is JobAssignmentLoaded &&
        _cachedAssignments.isNotEmpty) {
      return;
    }

    if (!silent) {
      emit(const JobAssignmentLoading());
    }

    final result = await _getJobAssignmentsUseCase();
    result.fold(
      (failure) {
        emit(JobAssignmentError(
          failure.errorMessage,
          currentAssignments: _cachedAssignments,
          selectedAssignment: _selectedAssignment,
        ));
      },
      (assignments) {
        _cachedAssignments = assignments;
        emit(JobAssignmentLoaded(
          List.unmodifiable(_cachedAssignments),
          selectedAssignment: _selectedAssignment,
        ));
      },
    );
  }

  Future<JobAssignmentEntity?> loadAssignmentDetails(int id) async {
    final result = await _getJobAssignmentDetailsUseCase(id);
    return result.fold(
      (failure) {
        emit(JobAssignmentError(
          failure.errorMessage,
          currentAssignments: _cachedAssignments,
          selectedAssignment: _selectedAssignment,
        ));
        return null;
      },
      (assignment) {
        _selectedAssignment = assignment;

        _cachedAssignments = _cachedAssignments.map((a) {
          return a.id == id ? assignment : a;
        }).toList();

        emit(JobAssignmentLoaded(
          List.unmodifiable(_cachedAssignments),
          selectedAssignment: _selectedAssignment,
        ));
        return assignment;
      },
    );
  }

  Future<bool> submitReview(
    int assignmentId, {
    required int rating,
    String? comment,
  }) async {
    emit(JobAssignmentActionInProgress(
      _cachedAssignments,
      selectedAssignment: _selectedAssignment,
    ));

    final result = await _submitReviewUseCase(
      assignmentId,
      rating: rating,
      comment: comment,
    );

    return result.fold(
      (failure) {
        emit(JobAssignmentError(
          failure.errorMessage,
          currentAssignments: _cachedAssignments,
          selectedAssignment: _selectedAssignment,
        ));
        return false;
      },
      (review) {
        // Mark hasReviewed as true
        _cachedAssignments = _cachedAssignments.map((a) {
          if (a.id == assignmentId) {
            return a.copyWith(hasReviewed: true);
          }
          return a;
        }).toList();

        if (_selectedAssignment?.id == assignmentId) {
          _selectedAssignment = _selectedAssignment!.copyWith(hasReviewed: true);
        }

        emit(JobAssignmentActionSuccess(
          message: 'Review submitted successfully!',
          assignments: List.unmodifiable(_cachedAssignments),
          selectedAssignment: _selectedAssignment,
        ));

        emit(JobAssignmentLoaded(
          List.unmodifiable(_cachedAssignments),
          selectedAssignment: _selectedAssignment,
        ));
        return true;
      },
    );
  }

  Future<bool> submitDispute(
    int assignmentId, {
    required String reason,
  }) async {
    emit(JobAssignmentActionInProgress(
      _cachedAssignments,
      selectedAssignment: _selectedAssignment,
    ));

    final result = await _submitDisputeUseCase(
      assignmentId,
      reason: reason,
    );

    return result.fold(
      (failure) {
        emit(JobAssignmentError(
          failure.errorMessage,
          currentAssignments: _cachedAssignments,
          selectedAssignment: _selectedAssignment,
        ));
        return false;
      },
      (dispute) {
        // Mark hasDispute as true
        _cachedAssignments = _cachedAssignments.map((a) {
          if (a.id == assignmentId) {
            return a.copyWith(hasDispute: true);
          }
          return a;
        }).toList();

        if (_selectedAssignment?.id == assignmentId) {
          _selectedAssignment = _selectedAssignment!.copyWith(hasDispute: true);
        }

        emit(JobAssignmentActionSuccess(
          message: 'Dispute submitted successfully!',
          assignments: List.unmodifiable(_cachedAssignments),
          selectedAssignment: _selectedAssignment,
        ));

        emit(JobAssignmentLoaded(
          List.unmodifiable(_cachedAssignments),
          selectedAssignment: _selectedAssignment,
        ));
        return true;
      },
    );
  }

  Future<bool> approveExtraCharge(int assignmentId) async {
    emit(JobAssignmentActionInProgress(
      _cachedAssignments,
      selectedAssignment: _selectedAssignment,
    ));

    final result = await _approveExtraChargeUseCase(assignmentId);

    return result.fold(
      (failure) {
        emit(JobAssignmentError(
          failure.errorMessage,
          currentAssignments: _cachedAssignments,
          selectedAssignment: _selectedAssignment,
        ));
        return false;
      },
      (assignment) {
        _selectedAssignment = assignment;
        _cachedAssignments = _cachedAssignments.map((a) {
          return a.id == assignmentId ? assignment : a;
        }).toList();

        emit(JobAssignmentActionSuccess(
          message: 'Updated quotation approved successfully!',
          assignments: List.unmodifiable(_cachedAssignments),
          selectedAssignment: _selectedAssignment,
        ));

        emit(JobAssignmentLoaded(
          List.unmodifiable(_cachedAssignments),
          selectedAssignment: _selectedAssignment,
        ));
        return true;
      },
    );
  }

  Future<bool> rejectExtraCharge(int assignmentId) async {
    emit(JobAssignmentActionInProgress(
      _cachedAssignments,
      selectedAssignment: _selectedAssignment,
    ));

    final result = await _rejectExtraChargeUseCase(assignmentId);

    return result.fold(
      (failure) {
        emit(JobAssignmentError(
          failure.errorMessage,
          currentAssignments: _cachedAssignments,
          selectedAssignment: _selectedAssignment,
        ));
        return false;
      },
      (assignment) {
        _selectedAssignment = assignment;
        _cachedAssignments = _cachedAssignments.map((a) {
          return a.id == assignmentId ? assignment : a;
        }).toList();

        emit(JobAssignmentActionSuccess(
          message: 'Updated quotation declined.',
          assignments: List.unmodifiable(_cachedAssignments),
          selectedAssignment: _selectedAssignment,
        ));

        emit(JobAssignmentLoaded(
          List.unmodifiable(_cachedAssignments),
          selectedAssignment: _selectedAssignment,
        ));
        return true;
      },
    );
  }

  Future<JobAssignmentEntity?> simulateExtraQuote(
    int assignmentId, {
    double? extraAmount,
    String? extraReason,
  }) async {
    emit(JobAssignmentActionInProgress(
      _cachedAssignments,
      selectedAssignment: _selectedAssignment,
    ));

    final result = await _simulateExtraQuoteUseCase(
      assignmentId,
      extraAmount: extraAmount,
      extraReason: extraReason,
    );

    return result.fold(
      (failure) {
        emit(JobAssignmentError(
          failure.errorMessage,
          currentAssignments: _cachedAssignments,
          selectedAssignment: _selectedAssignment,
        ));
        return null;
      },
      (assignment) {
        _selectedAssignment = assignment;
        _cachedAssignments = _cachedAssignments.map((a) {
          return a.id == assignmentId ? assignment : a;
        }).toList();

        emit(JobAssignmentActionSuccess(
          message: 'Updated quotation simulated from provider!',
          assignments: List.unmodifiable(_cachedAssignments),
          selectedAssignment: _selectedAssignment,
        ));

        emit(JobAssignmentLoaded(
          List.unmodifiable(_cachedAssignments),
          selectedAssignment: _selectedAssignment,
        ));
        return assignment;
      },
    );
  }

  Future<JobAssignmentEntity?> simulateCompleteJob(int assignmentId) async {
    emit(JobAssignmentActionInProgress(
      _cachedAssignments,
      selectedAssignment: _selectedAssignment,
    ));

    final result = await _simulateCompleteJobUseCase(assignmentId);

    return result.fold(
      (failure) {
        emit(JobAssignmentError(
          failure.errorMessage,
          currentAssignments: _cachedAssignments,
          selectedAssignment: _selectedAssignment,
        ));
        return null;
      },
      (assignment) {
        _selectedAssignment = assignment;
        _cachedAssignments = _cachedAssignments.map((a) {
          return a.id == assignmentId ? assignment : a;
        }).toList();

        emit(JobAssignmentActionSuccess(
          message: 'Job completed simulated successfully!',
          assignments: List.unmodifiable(_cachedAssignments),
          selectedAssignment: _selectedAssignment,
        ));

        emit(JobAssignmentLoaded(
          List.unmodifiable(_cachedAssignments),
          selectedAssignment: _selectedAssignment,
        ));
        return assignment;
      },
    );
  }
}
