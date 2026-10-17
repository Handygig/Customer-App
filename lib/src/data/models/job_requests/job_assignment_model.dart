import 'package:customer_app/src/domain/entities/job_requests/job_assignment_entity.dart';

class JobAssignmentModel extends JobAssignmentEntity {
  const JobAssignmentModel({
    required super.id,
    required super.status,
    super.assignedAt,
    super.startDate,
    super.endDate,
    super.providerId,
    super.providerName,
    super.providerPhone,
    super.providerImage,
    super.companyName,
  });

  factory JobAssignmentModel.fromJson(Map<String, dynamic> json) {
    final provider = json['provider'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(json['provider'] as Map)
        : null;
    final company = json['company'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(json['company'] as Map)
        : null;

    return JobAssignmentModel(
      id: _asInt(json['id']),
      status: (json['status'] ?? '').toString(),
      assignedAt: _asDateTime(json['assigned_at']),
      startDate: _asDateTime(json['start_date']),
      endDate: _asDateTime(json['end_date']),
      providerId: _asNullableInt(provider?['id']),
      providerName: provider?['name']?.toString(),
      providerPhone: provider?['phone']?.toString(),
      providerImage: provider?['profile_image']?.toString(),
      companyName: company?['name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'assigned_at': assignedAt?.toIso8601String(),
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'provider': providerId != null
          ? {
              'id': providerId,
              'name': providerName,
              'phone': providerPhone,
              'profile_image': providerImage,
            }
          : null,
      'company': companyName != null ? {'name': companyName} : null,
    };
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? _asNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static DateTime? _asDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
