import 'package:customer_app/src/domain/entities/properties/property_entity.dart';

class PropertyModel extends PropertyEntity {
  const PropertyModel({
    required super.id,
    required super.label,
    required super.addressLine,
    required super.city,
    super.latitude,
    super.longitude,
    required super.isDefault,
  });

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    return PropertyModel(
      id: _asInt(json['id']),
      label: (json['label'] ?? json['name'] ?? json['title'] ?? '').toString().trim(),
      addressLine: (json['address_line'] ?? json['address'] ?? '').toString().trim(),
      city: (json['city'] ?? '').toString().trim(),
      latitude: _asDouble(json['latitude']),
      longitude: _asDouble(json['longitude']),
      isDefault: _asBool(json['is_default'] ?? json['is_primary']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'address_line': addressLine,
      'city': city,
      'latitude': latitude?.toString(),
      'longitude': longitude?.toString(),
      'is_default': isDefault,
    };
  }

  static Map<String, dynamic> toStoreJson({
    required String label,
    required String addressLine,
    required String city,
    double? latitude,
    double? longitude,
    bool? isDefault,
  }) {
    final map = <String, dynamic>{
      'label': label.trim(),
      'address_line': addressLine.trim(),
      'city': city.trim(),
    };
    if (latitude != null) map['latitude'] = latitude;
    if (longitude != null) map['longitude'] = longitude;
    if (isDefault != null) map['is_default'] = isDefault;
    return map;
  }

  static Map<String, dynamic> toUpdateJson({
    String? label,
    String? addressLine,
    String? city,
    double? latitude,
    double? longitude,
    bool? isDefault,
  }) {
    final map = <String, dynamic>{};
    if (label != null) map['label'] = label.trim();
    if (addressLine != null) map['address_line'] = addressLine.trim();
    if (city != null) map['city'] = city.trim();
    if (latitude != null) map['latitude'] = latitude;
    if (longitude != null) map['longitude'] = longitude;
    if (isDefault != null) map['is_default'] = isDefault;
    return map;
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase().trim();
      return lower == 'true' || lower == '1';
    }
    return false;
  }
}
