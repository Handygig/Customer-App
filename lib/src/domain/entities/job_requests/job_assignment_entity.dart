import 'package:equatable/equatable.dart';

class JobAssignmentEntity extends Equatable {
  final int id;
  final String status;
  final DateTime? assignedAt;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? providerId;
  final String? providerName;
  final String? providerPhone;
  final String? providerImage;
  final String? companyName;

  const JobAssignmentEntity({
    required this.id,
    required this.status,
    this.assignedAt,
    this.startDate,
    this.endDate,
    this.providerId,
    this.providerName,
    this.providerPhone,
    this.providerImage,
    this.companyName,
  });

  @override
  List<Object?> get props => [
        id,
        status,
        assignedAt,
        startDate,
        endDate,
        providerId,
        providerName,
        providerPhone,
        providerImage,
        companyName,
      ];
}
