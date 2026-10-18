import 'package:customer_app/src/domain/entities/job_assignments/dispute_entity.dart';

class DisputeModel extends DisputeEntity {
  const DisputeModel({
    required super.id,
    required super.reason,
    required super.status,
    super.resolutionNotes,
    super.resolvedAt,
    super.createdAt,
  });

  factory DisputeModel.fromJson(Map<String, dynamic> json) {
    return DisputeModel(
      id: _asInt(json['id']),
      reason: json['reason']?.toString() ?? '',
      status: json['status']?.toString() ?? 'open',
      resolutionNotes: json['resolution_notes']?.toString(),
      resolvedAt: _asDateTime(json['resolved_at']),
      createdAt: _asDateTime(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reason': reason,
      'status': status,
      'resolution_notes': resolutionNotes,
      'resolved_at': resolvedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
    };
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _asDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
