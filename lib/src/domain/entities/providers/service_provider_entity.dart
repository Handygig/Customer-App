import 'package:equatable/equatable.dart';

class ServiceProviderEntity extends Equatable {
  final String id;
  final int? userId;
  final String name;
  final String providerType;
  final String serviceType;
  final List<String> services;
  final String rating;
  final double ratingNum;
  final int reviewsCount;
  final String price;
  final double hourlyRate;
  final String distance;
  final double? distanceKm;
  final String address;
  final String locationArea;
  final double latitude;
  final double longitude;
  final bool isAvailable;
  final String? profileImage;
  final String? bio;
  final String? phone;

  const ServiceProviderEntity({
    required this.id,
    this.userId,
    required this.name,
    this.providerType = 'individual',
    required this.serviceType,
    this.services = const [],
    required this.rating,
    this.ratingNum = 5.0,
    required this.reviewsCount,
    required this.price,
    this.hourlyRate = 45.0,
    required this.distance,
    this.distanceKm,
    required this.address,
    required this.locationArea,
    required this.latitude,
    required this.longitude,
    required this.isAvailable,
    this.profileImage,
    this.bio,
    this.phone,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        providerType,
        serviceType,
        services,
        rating,
        ratingNum,
        reviewsCount,
        price,
        hourlyRate,
        distance,
        distanceKm,
        address,
        locationArea,
        latitude,
        longitude,
        isAvailable,
        profileImage,
        bio,
        phone,
      ];
}
