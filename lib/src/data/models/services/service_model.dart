import 'package:customer_app/src/domain/entities/services/service_entity.dart';

class ServiceModel extends ServiceEntity {
  const ServiceModel({
    required super.id,
    required super.title,
    required super.name,
    super.categoryId,
    super.category,
    super.description,
    super.imageUrl,
    required super.isActive,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    final rawName = (json['title'] ?? json['name'] ?? '').toString().trim();

    return ServiceModel(
      id: _asInt(json['id']),
      title: rawName,
      name: (json['name'] ?? rawName).toString().trim(),
      categoryId: json['category_id'] != null ? _asInt(json['category_id']) : null,
      category: json['category']?.toString().trim() ??
          json['category_name']?.toString().trim(),
      description: json['description']?.toString().trim(),
      imageUrl: json['image_url']?.toString().trim(),
      isActive: _asBool(json['is_active']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'name': name,
      'category_id': categoryId,
      'category': category,
      'description': description,
      'image_url': imageUrl,
      'is_active': isActive,
    };
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.toLowerCase();
      if (normalized == 'true' || normalized == '1') return true;
      if (normalized == 'false' || normalized == '0') return false;
    }
    return true;
  }
}
