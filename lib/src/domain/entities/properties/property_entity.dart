import 'package:equatable/equatable.dart';

class PropertyEntity extends Equatable {
  final int id;
  final String label;
  final String addressLine;
  final String city;
  final double? latitude;
  final double? longitude;
  final bool isDefault;

  const PropertyEntity({
    required this.id,
    required this.label,
    required this.addressLine,
    required this.city,
    this.latitude,
    this.longitude,
    required this.isDefault,
  });

  String get fullAddress {
    if (addressLine.trim().isEmpty) return city.trim();
    if (city.trim().isEmpty) return addressLine.trim();
    return '${addressLine.trim()}, ${city.trim()}';
  }

  // Compatibility helpers for existing UI components
  String get title => label;
  String get address => fullAddress;
  bool get isPrimary => isDefault;

  PropertyEntity copyWith({
    int? id,
    String? label,
    String? addressLine,
    String? city,
    double? latitude,
    double? longitude,
    bool? isDefault,
  }) {
    return PropertyEntity(
      id: id ?? this.id,
      label: label ?? this.label,
      addressLine: addressLine ?? this.addressLine,
      city: city ?? this.city,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  List<Object?> get props => [
    id,
    label,
    addressLine,
    city,
    latitude,
    longitude,
    isDefault,
  ];
}
