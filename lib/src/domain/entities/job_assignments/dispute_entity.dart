import 'package:equatable/equatable.dart';

class DisputeEntity extends Equatable {
  final int id;
  final String reason;
  final String status;
  final String? resolutionNotes;
  final DateTime? resolvedAt;
  final DateTime? createdAt;

  const DisputeEntity({
    required this.id,
    required this.reason,
    required this.status,
    this.resolutionNotes,
    this.resolvedAt,
    this.createdAt,
  });

  bool get isOpen => status.toLowerCase() == 'open';
  bool get isResolved => status.toLowerCase() == 'resolved';

  @override
  List<Object?> get props => [
        id,
        reason,
        status,
        resolutionNotes,
        resolvedAt,
        createdAt,
      ];
}
