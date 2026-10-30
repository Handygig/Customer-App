import 'package:equatable/equatable.dart';
import 'package:customer_app/src/domain/entities/job_requests/job_request_entity.dart';
import 'package:customer_app/src/domain/entities/payments/payment_entity.dart';
import 'package:customer_app/src/domain/entities/job_requests/quotation_entity.dart';

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
  final JobRequestEntity? jobRequest;
  final PaymentEntity? payment;
  final QuotationEntity? quotation;
  final double? extraAmount;
  final String? extraReason;
  final String extraStatus;
  final bool hasReviewed;
  final bool hasDispute;

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
    this.jobRequest,
    this.payment,
    this.quotation,
    this.extraAmount,
    this.extraReason,
    this.extraStatus = 'none',
    this.hasReviewed = false,
    this.hasDispute = false,
  });

  bool get isScheduled => status.toLowerCase() == 'scheduled';
  bool get isInProgress =>
      status.toLowerCase() == 'in_progress' || status.toLowerCase() == 'ongoing';
  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isCancelled => status.toLowerCase() == 'cancelled';
  bool get isOngoing => isScheduled || isInProgress;
  bool get hasPendingExtraQuote =>
      extraStatus.toLowerCase() == 'pending' && (extraAmount ?? 0) > 0;
  bool get hasApprovedExtraQuote =>
      extraStatus.toLowerCase() == 'approved' && (extraAmount ?? 0) > 0;
  bool get hasRejectedExtraQuote => extraStatus.toLowerCase() == 'rejected';
  double get totalEffectivePrice =>
      (quotation?.quotedPrice ?? (payment?.amount ?? 0.0)) +
      (hasApprovedExtraQuote ? (extraAmount ?? 0.0) : 0.0);

  JobAssignmentEntity copyWith({
    int? id,
    String? status,
    DateTime? assignedAt,
    DateTime? startDate,
    DateTime? endDate,
    int? providerId,
    String? providerName,
    String? providerPhone,
    String? providerImage,
    String? companyName,
    JobRequestEntity? jobRequest,
    PaymentEntity? payment,
    QuotationEntity? quotation,
    double? extraAmount,
    String? extraReason,
    String? extraStatus,
    bool? hasReviewed,
    bool? hasDispute,
  }) {
    return JobAssignmentEntity(
      id: id ?? this.id,
      status: status ?? this.status,
      assignedAt: assignedAt ?? this.assignedAt,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      providerId: providerId ?? this.providerId,
      providerName: providerName ?? this.providerName,
      providerPhone: providerPhone ?? this.providerPhone,
      providerImage: providerImage ?? this.providerImage,
      companyName: companyName ?? this.companyName,
      jobRequest: jobRequest ?? this.jobRequest,
      payment: payment ?? this.payment,
      quotation: quotation ?? this.quotation,
      extraAmount: extraAmount ?? this.extraAmount,
      extraReason: extraReason ?? this.extraReason,
      extraStatus: extraStatus ?? this.extraStatus,
      hasReviewed: hasReviewed ?? this.hasReviewed,
      hasDispute: hasDispute ?? this.hasDispute,
    );
  }

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
        jobRequest,
        payment,
        quotation,
        extraAmount,
        extraReason,
        extraStatus,
        hasReviewed,
        hasDispute,
      ];
}

