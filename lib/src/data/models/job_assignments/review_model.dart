import 'package:customer_app/src/domain/entities/job_assignments/review_entity.dart';

class ReviewModel extends ReviewEntity {
  const ReviewModel({
    required super.id,
    required super.rating,
    super.comment,
    super.assignmentId,
    super.providerId,
    super.providerName,
    super.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    final provider = json['provider'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(json['provider'] as Map)
        : null;

    return ReviewModel(
      id: _asInt(json['id']),
      rating: _asInt(json['rating'], defaultValue: 5),
      comment: json['comment']?.toString(),
      assignmentId: _asNullableInt(json['assignment_id']),
      providerId: _asNullableInt(provider?['id'] ?? json['provider_id']),
      providerName: provider?['name']?.toString(),
      createdAt: _asDateTime(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rating': rating,
      'comment': comment,
      'assignment_id': assignmentId,
      'provider_id': providerId,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  static int _asInt(dynamic value, {int defaultValue = 0}) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? defaultValue;
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
