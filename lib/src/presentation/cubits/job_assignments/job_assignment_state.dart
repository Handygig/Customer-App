import 'package:equatable/equatable.dart';
import 'package:customer_app/src/domain/entities/job_requests/job_assignment_entity.dart';

abstract class JobAssignmentState extends Equatable {
  const JobAssignmentState();

  @override
  List<Object?> get props => [];
}

class JobAssignmentInitial extends JobAssignmentState {
  const JobAssignmentInitial();
}

class JobAssignmentLoading extends JobAssignmentState {
  const JobAssignmentLoading();
}

class JobAssignmentLoaded extends JobAssignmentState {
  final List<JobAssignmentEntity> assignments;
  final JobAssignmentEntity? selectedAssignment;
  final bool isSubmittingAction;

  const JobAssignmentLoaded(
    this.assignments, {
    this.selectedAssignment,
    this.isSubmittingAction = false,
  });

  JobAssignmentLoaded copyWith({
    List<JobAssignmentEntity>? assignments,
    JobAssignmentEntity? selectedAssignment,
    bool? isSubmittingAction,
  }) {
    return JobAssignmentLoaded(
      assignments ?? this.assignments,
      selectedAssignment: selectedAssignment ?? this.selectedAssignment,
      isSubmittingAction: isSubmittingAction ?? this.isSubmittingAction,
    );
  }

  @override
  List<Object?> get props => [assignments, selectedAssignment, isSubmittingAction];
}

class JobAssignmentActionInProgress extends JobAssignmentState {
  final List<JobAssignmentEntity> currentAssignments;
  final JobAssignmentEntity? selectedAssignment;

  const JobAssignmentActionInProgress(
    this.currentAssignments, {
    this.selectedAssignment,
  });

  @override
  List<Object?> get props => [currentAssignments, selectedAssignment];
}

class JobAssignmentActionSuccess extends JobAssignmentState {
  final String message;
  final List<JobAssignmentEntity> assignments;
  final JobAssignmentEntity? selectedAssignment;

  const JobAssignmentActionSuccess({
    required this.message,
    required this.assignments,
    this.selectedAssignment,
  });

  @override
  List<Object?> get props => [message, assignments, selectedAssignment];
}

class JobAssignmentError extends JobAssignmentState {
  final String message;
  final List<JobAssignmentEntity>? currentAssignments;
  final JobAssignmentEntity? selectedAssignment;

  const JobAssignmentError(
    this.message, {
    this.currentAssignments,
    this.selectedAssignment,
  });

  @override
  List<Object?> get props => [message, currentAssignments, selectedAssignment];
}
