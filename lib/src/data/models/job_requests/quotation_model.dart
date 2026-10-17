import 'package:customer_app/src/domain/entities/job_requests/quotation_entity.dart';

class QuotationProviderModel extends QuotationProviderEntity {
  const QuotationProviderModel({
    super.id,
    super.name,
    super.rating,
    super.profileImage,
  });

  factory QuotationProviderModel.fromJson(Map<String, dynamic> json) {
    return QuotationProviderModel(
      id: _asNullableInt(json['id']),
      name: json['name']?.toString().trim(),
      rating: _asNullableDouble(json['rating']),
      profileImage: json['profile_image']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'rating': rating,
      'profile_image': profileImage,
    };
  }

  static int? _asNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static double? _asNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}

class QuotationModel extends QuotationEntity {
  const QuotationModel({
    required super.id,
    required super.quotedPrice,
    super.estimatedDuration,
    super.message,
    required super.status,
    super.provider,
    super.createdAt,
  });

  factory QuotationModel.fromJson(Map<String, dynamic> json) {
    return QuotationModel(
      id: _asInt(json['id']),
      quotedPrice: _asDouble(json['quoted_price']),
      estimatedDuration: json['estimated_duration']?.toString(),
      message: json['message']?.toString(),
      status: (json['status'] ?? 'pending').toString(),
      provider: json['provider'] is Map<String, dynamic>
          ? QuotationProviderModel.fromJson(
              Map<String, dynamic>.from(json['provider'] as Map))
          : null,
      createdAt: _asDateTime(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quoted_price': quotedPrice,
      'estimated_duration': estimatedDuration,
      'message': message,
      'status': status,
      'provider': provider != null
          ? (provider is QuotationProviderModel
              ? (provider as QuotationProviderModel).toJson()
              : {
                  'id': provider!.id,
                  'name': provider!.name,
                  'rating': provider!.rating,
                  'profile_image': provider!.profileImage,
                })
          : null,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _asDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  static DateTime? _asDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
