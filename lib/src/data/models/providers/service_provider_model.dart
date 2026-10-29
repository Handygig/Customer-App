import 'package:customer_app/src/domain/entities/providers/service_provider_entity.dart';

class ServiceProviderModel extends ServiceProviderEntity {
  const ServiceProviderModel({
    required super.id,
    super.userId,
    required super.name,
    super.providerType,
    required super.serviceType,
    super.services,
    required super.rating,
    super.ratingNum,
    required super.reviewsCount,
    required super.price,
    super.hourlyRate,
    required super.distance,
    super.distanceKm,
    required super.address,
    required super.locationArea,
    required super.latitude,
    required super.longitude,
    required super.isAvailable,
    super.profileImage,
    super.bio,
    super.phone,
  });

  factory ServiceProviderModel.fromJson(Map<String, dynamic> json) {
    final servicesRaw = json['services'];
    List<String> servicesList = const [];
    if (servicesRaw is List) {
      servicesList = servicesRaw.map((e) => e.toString()).toList();
    }

    final idStr = (json['id'] ?? '').toString();
    final nameStr = (json['name'] ?? json['full_name'] ?? 'Service Provider').toString();
    final serviceTypeStr = (json['service_type'] ?? json['category'] ?? 'General Handyman').toString();
    final ratingStr = (json['rating'] ?? '5.0').toString();
    final ratingVal = _asDouble(json['rating_num'] ?? json['rating']) ?? 5.0;
    final reviewsCountVal = _asInt(json['reviews_count'] ?? json['reviewsCount']);
    final priceStr = (json['price'] ?? '\$45/hr').toString();
    final hourlyRateVal = _asDouble(json['hourly_rate'] ?? json['hourlyRate']) ?? 45.0;
    final distanceStr = (json['distance'] ?? 'Nearby').toString();
    final distanceKmVal = _asDouble(json['distance_km'] ?? json['distanceKm']);
    final addressStr = (json['address'] ?? json['address_line1'] ?? json['city'] ?? 'Nearby').toString();
    final locationAreaStr = (json['location_area'] ?? json['city'] ?? 'Downtown').toString();
    final latVal = _asDouble(json['latitude'] ?? json['lat']) ?? 0.0;
    final lngVal = _asDouble(json['longitude'] ?? json['lng']) ?? 0.0;
    final isAvailableVal = _asBool(json['is_available'] ?? json['availability'] == 'available');

    return ServiceProviderModel(
      id: idStr,
      userId: _asNullableInt(json['user_id']),
      name: nameStr,
      providerType: (json['provider_type'] ?? 'individual').toString(),
      serviceType: serviceTypeStr,
      services: servicesList,
      rating: ratingStr,
      ratingNum: ratingVal,
      reviewsCount: reviewsCountVal,
      price: priceStr,
      hourlyRate: hourlyRateVal,
      distance: distanceStr,
      distanceKm: distanceKmVal,
      address: addressStr,
      locationArea: locationAreaStr,
      latitude: latVal,
      longitude: lngVal,
      isAvailable: isAvailableVal,
      profileImage: json['profile_image']?.toString(),
      bio: json['bio']?.toString(),
      phone: json['phone']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'provider_type': providerType,
      'service_type': serviceType,
      'services': services,
      'rating': rating,
      'rating_num': ratingNum,
      'reviews_count': reviewsCount,
      'price': price,
      'hourly_rate': hourlyRate,
      'distance': distance,
      'distance_km': distanceKm,
      'address': address,
      'location_area': locationArea,
      'latitude': latitude,
      'longitude': longitude,
      'is_available': isAvailable,
      'profile_image': profileImage,
      'bio': bio,
      'phone': phone,
    };
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? _asNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase().trim();
      return lower == 'true' || lower == '1' || lower == 'available';
    }
    return false;
  }
}
