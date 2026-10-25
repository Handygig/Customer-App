import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:customer_app/src/domain/entities/providers/service_provider_entity.dart';

abstract class ProviderSearchState extends Equatable {
  const ProviderSearchState();

  @override
  List<Object?> get props => [];
}

class ProviderSearchInitial extends ProviderSearchState {
  const ProviderSearchInitial();
}

class ProviderSearchLoading extends ProviderSearchState {
  final List<ServiceProviderEntity> previousProviders;
  final LatLng? centerLocation;
  final String? locationName;

  const ProviderSearchLoading({
    this.previousProviders = const [],
    this.centerLocation,
    this.locationName,
  });

  @override
  List<Object?> get props => [previousProviders, centerLocation, locationName];
}

class ProviderSearchLoaded extends ProviderSearchState {
  final List<ServiceProviderEntity> providers;
  final LatLng centerLocation;
  final String locationName;
  final String selectedCategory;
  final int? selectedCategoryId;
  final String serviceQuery;
  final double searchRadius;
  final ServiceProviderEntity? selectedProvider;

  const ProviderSearchLoaded({
    required this.providers,
    required this.centerLocation,
    required this.locationName,
    this.selectedCategory = 'All',
    this.selectedCategoryId,
    this.serviceQuery = '',
    this.searchRadius = 30.0,
    this.selectedProvider,
  });

  ProviderSearchLoaded copyWith({
    List<ServiceProviderEntity>? providers,
    LatLng? centerLocation,
    String? locationName,
    String? selectedCategory,
    int? selectedCategoryId,
    String? serviceQuery,
    double? searchRadius,
    ServiceProviderEntity? Function()? selectedProvider,
  }) {
    return ProviderSearchLoaded(
      providers: providers ?? this.providers,
      centerLocation: centerLocation ?? this.centerLocation,
      locationName: locationName ?? this.locationName,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      serviceQuery: serviceQuery ?? this.serviceQuery,
      searchRadius: searchRadius ?? this.searchRadius,
      selectedProvider: selectedProvider != null
          ? selectedProvider()
          : this.selectedProvider,
    );
  }

  @override
  List<Object?> get props => [
        providers,
        centerLocation,
        locationName,
        selectedCategory,
        selectedCategoryId,
        serviceQuery,
        searchRadius,
        selectedProvider,
      ];
}

class ProviderSearchError extends ProviderSearchState {
  final String message;
  final List<ServiceProviderEntity> currentProviders;

  const ProviderSearchError({
    required this.message,
    this.currentProviders = const [],
  });

  @override
  List<Object?> get props => [message, currentProviders];
}
