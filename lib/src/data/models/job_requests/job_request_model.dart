import 'package:customer_app/src/data/models/properties/property_model.dart';
import 'package:customer_app/src/data/models/services/service_category_model.dart';
import 'package:customer_app/src/data/models/job_requests/quotation_model.dart';
import 'package:customer_app/src/data/models/job_requests/job_assignment_model.dart';
import 'package:customer_app/src/domain/entities/job_requests/job_request_entity.dart';

class JobRequestModel extends JobRequestEntity {
  const JobRequestModel({
    required super.id,
    required super.description,
    super.preferredDate,
    required super.status,
    super.property,
    super.serviceCategory,
    super.quotations = const [],
    super.assignment,
    super.createdAt,
  });

  factory JobRequestModel.fromJson(Map<String, dynamic> json) {
    final propertyJson = json['property'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(json['property'] as Map)
        : null;
    final categoryJson = json['service_category'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(json['service_category'] as Map)
        : null;
    final assignmentJson = json['assignment'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(json['assignment'] as Map)
        : null;

    final List<QuotationModel> quotes;
    if (json['quotations'] is List) {
      quotes = (json['quotations'] as List)
          .whereType<Map<String, dynamic>>()
          .map((q) => QuotationModel.fromJson(q))
          .toList();
    } else {
      quotes = const [];
    }

    return JobRequestModel(
      id: _asInt(json['id']),
      description: (json['description'] ?? '').toString().trim(),
      preferredDate: _asDateTime(json['preferred_date']),
      status: (json['status'] ?? 'pending').toString(),
      property:
          propertyJson != null ? PropertyModel.fromJson(propertyJson) : null,
      serviceCategory: categoryJson != null
          ? ServiceCategoryModel.fromJson(categoryJson)
          : null,
      quotations: quotes,
      assignment: assignmentJson != null
          ? JobAssignmentModel.fromJson(assignmentJson)
          : null,
      createdAt: _asDateTime(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'preferred_date': preferredDate?.toIso8601String(),
      'status': status,
      'property': property is PropertyModel
          ? (property as PropertyModel).toJson()
          : null,
      'service_category': serviceCategory is ServiceCategoryModel
          ? (serviceCategory as ServiceCategoryModel).toJson()
          : null,
      'quotations': quotations
          .whereType<QuotationModel>()
          .map((q) => q.toJson())
          .toList(),
      'assignment': assignment is JobAssignmentModel
          ? (assignment as JobAssignmentModel).toJson()
          : null,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  static Map<String, dynamic> toStoreJson({
    required int propertyId,
    required int serviceCategoryId,
    required String description,
    required DateTime preferredDate,
  }) {
    // Format preferred_date as YYYY-MM-DD HH:mm:ss or ISO
    final year = preferredDate.year.toString().padLeft(4, '0');
    final month = preferredDate.month.toString().padLeft(2, '0');
    final day = preferredDate.day.toString().padLeft(2, '0');
    final hour = preferredDate.hour.toString().padLeft(2, '0');
    final minute = preferredDate.minute.toString().padLeft(2, '0');
    final second = preferredDate.second.toString().padLeft(2, '0');
    final formattedDate = '$year-$month-$day $hour:$minute:$second';

    return {
      'property_id': propertyId,
      'service_category_id': serviceCategoryId,
      'description': description.trim(),
      'preferred_date': formattedDate,
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
