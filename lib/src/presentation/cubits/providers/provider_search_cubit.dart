import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:customer_app/src/domain/entities/providers/service_provider_entity.dart';
import 'package:customer_app/src/domain/usecases/providers/search_providers_usecase.dart';
import 'package:customer_app/src/presentation/cubits/providers/provider_search_state.dart';

class ProviderSearchCubit extends Cubit<ProviderSearchState> {
  final SearchProvidersUseCase _searchProvidersUseCase;

  // Default initial location: Colombo, Sri Lanka
  static const LatLng defaultLocation = LatLng(6.9271, 79.8612);
  static const String defaultLocationName = 'Colombo, Sri Lanka';

  LatLng _currentLocation = defaultLocation;
  String _currentLocationName = defaultLocationName;
  String _selectedCategory = 'All';
  int? _selectedCategoryId;
  String _serviceQuery = '';
  double _searchRadius = 30.0;
  ServiceProviderEntity? _selectedProvider;

  ProviderSearchCubit(this._searchProvidersUseCase)
      : super(const ProviderSearchInitial());

  List<ServiceProviderEntity> get currentProviders {
    final s = state;
    if (s is ProviderSearchLoaded) return s.providers;
    if (s is ProviderSearchLoading) return s.previousProviders;
    if (s is ProviderSearchError) return s.currentProviders;
    return const [];
  }

  LatLng get currentLocation => _currentLocation;
  String get currentLocationName => _currentLocationName;
  String get selectedCategory => _selectedCategory;
  int? get selectedCategoryId => _selectedCategoryId;
  String get serviceQuery => _serviceQuery;
  ServiceProviderEntity? get selectedProvider => _selectedProvider;

  Future<void> searchProviders({
    LatLng? location,
    String? locationName,
    String? service,
    String? category,
    int? categoryId,
    double? radius,
  }) async {
    if (location != null) _currentLocation = location;
    if (locationName != null) _currentLocationName = locationName;
    if (service != null) _serviceQuery = service;
    if (category != null) _selectedCategory = category;
    if (categoryId != null) _selectedCategoryId = categoryId;
    if (radius != null) _searchRadius = radius;

    final prev = currentProviders;
    emit(ProviderSearchLoading(
      previousProviders: prev,
      centerLocation: _currentLocation,
      locationName: _currentLocationName,
    ));

    final effectiveService = _serviceQuery.isNotEmpty
        ? _serviceQuery
        : (_selectedCategory != 'All' ? _selectedCategory : null);

    final result = await _searchProvidersUseCase(
      latitude: _currentLocation.latitude,
      longitude: _currentLocation.longitude,
      radius: _searchRadius,
      service: effectiveService,
      categoryId: _selectedCategoryId,
      location: _currentLocationName,
    );

    result.fold(
      (failure) {
        emit(ProviderSearchError(
          message: failure.errorMessage,
          currentProviders: prev,
        ));
      },
      (providers) {
        // If previous selected provider exists in new list, maintain it
        if (_selectedProvider != null) {
          final stillExists = providers.any((p) => p.id == _selectedProvider!.id);
          if (!stillExists) {
            _selectedProvider = null;
          } else {
            _selectedProvider = providers.firstWhere((p) => p.id == _selectedProvider!.id);
          }
        }

        emit(ProviderSearchLoaded(
          providers: providers,
          centerLocation: _currentLocation,
          locationName: _currentLocationName,
          selectedCategory: _selectedCategory,
          selectedCategoryId: _selectedCategoryId,
          serviceQuery: _serviceQuery,
          searchRadius: _searchRadius,
          selectedProvider: _selectedProvider,
        ));
      },
    );
  }

  void selectProvider(ServiceProviderEntity? provider) {
    _selectedProvider = provider;
    final s = state;
    if (s is ProviderSearchLoaded) {
      emit(s.copyWith(selectedProvider: () => provider));
    }
  }

  void updateLocation(LatLng location, String locationName) {
    _currentLocation = location;
    _currentLocationName = locationName;
    searchProviders(location: location, locationName: locationName);
  }

  void updateCategory(String category, {int? categoryId}) {
    _selectedCategory = category;
    _selectedCategoryId = categoryId;
    searchProviders(category: category, categoryId: categoryId);
  }

  void updateServiceQuery(String query) {
    _serviceQuery = query;
    searchProviders(service: query);
  }
}
