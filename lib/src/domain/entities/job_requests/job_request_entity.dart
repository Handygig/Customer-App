import 'package:equatable/equatable.dart';
import 'package:customer_app/src/domain/entities/properties/property_entity.dart';
import 'package:customer_app/src/domain/entities/services/service_category_entity.dart';
import 'package:customer_app/src/domain/entities/job_requests/quotation_entity.dart';
import 'package:customer_app/src/domain/entities/job_requests/job_assignment_entity.dart';
import 'package:customer_app/src/domain/entities/payments/card_entity.dart';

class JobRequestEntity extends Equatable {
  final int id;
  final String description;
  final DateTime? preferredDate;
  final String status;
  final String paymentMethod;
  final int? cardId;
  final CardEntity? card;
  final PropertyEntity? property;
  final ServiceCategoryEntity? serviceCategory;
  final List<QuotationEntity> quotations;
  final JobAssignmentEntity? assignment;
  final DateTime? createdAt;

  const JobRequestEntity({
    required this.id,
    required this.description,
    this.preferredDate,
    required this.status,
    this.paymentMethod = 'card',
    this.cardId,
    this.card,
    this.property,
    this.serviceCategory,
    this.quotations = const [],
    this.assignment,
    this.createdAt,
  });

  bool get isCancelled => status.toLowerCase() == 'cancelled';
  bool get isAssigned =>
      assignment != null || status.toLowerCase() == 'assigned';
  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isPending => status.toLowerCase() == 'pending';
  bool get canCancel => !isCancelled && !isAssigned && !isCompleted;
  bool get hasQuotations => quotations.isNotEmpty;
  bool get isCash => paymentMethod.toLowerCase() == 'cash';
  bool get isCard => paymentMethod.toLowerCase() == 'card';

  JobRequestEntity copyWith({
    int? id,
    String? description,
    DateTime? preferredDate,
    String? status,
    String? paymentMethod,
    int? cardId,
    CardEntity? card,
    PropertyEntity? property,
    ServiceCategoryEntity? serviceCategory,
    List<QuotationEntity>? quotations,
    JobAssignmentEntity? assignment,
    DateTime? createdAt,
  }) {
    return JobRequestEntity(
      id: id ?? this.id,
      description: description ?? this.description,
      preferredDate: preferredDate ?? this.preferredDate,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      cardId: cardId ?? this.cardId,
      card: card ?? this.card,
      property: property ?? this.property,
      serviceCategory: serviceCategory ?? this.serviceCategory,
      quotations: quotations ?? this.quotations,
      assignment: assignment ?? this.assignment,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        description,
        preferredDate,
        status,
        paymentMethod,
        cardId,
        card,
        property,
        serviceCategory,
        quotations,
        assignment,
        createdAt,
      ];
}
