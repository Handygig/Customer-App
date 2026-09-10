import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:customer_app/src/domain/entities/properties/property_entity.dart';
import 'package:customer_app/src/domain/usecases/properties/property_usecases.dart';
import 'package:customer_app/src/presentation/cubits/properties/property_state.dart';

class PropertyCubit extends Cubit<PropertyState> {
  final GetPropertiesUseCase _getPropertiesUseCase;
  final AddPropertyUseCase _addPropertyUseCase;
  final UpdatePropertyUseCase _updatePropertyUseCase;
  final DeletePropertyUseCase _deletePropertyUseCase;

  PropertyCubit(
    this._getPropertiesUseCase,
    this._addPropertyUseCase,
    this._updatePropertyUseCase,
    this._deletePropertyUseCase,
  ) : super(const PropertyInitial());

  List<PropertyEntity> get currentProperties {
    final s = state;
    if (s is PropertyLoaded) return s.properties;
    if (s is PropertyActionInProgress) return s.properties;
    if (s is PropertyActionSuccess) return s.properties;
    if (s is PropertyError && s.currentProperties != null) {
      return s.currentProperties!;
    }
    return const [];
  }

  Future<void> loadProperties({bool forceRefresh = false}) async {
    if (!forceRefresh && state is PropertyLoaded) return;

    emit(const PropertyLoading());
    final result = await _getPropertiesUseCase();
    result.fold(
      (failure) => emit(PropertyError(failure.errorMessage)),
      (properties) => emit(PropertyLoaded(properties)),
    );
  }

  Future<bool> addProperty({
    required String label,
    required String addressLine,
    required String city,
    double? latitude,
    double? longitude,
    bool? isDefault,
  }) async {
    final prev = currentProperties;
    emit(PropertyActionInProgress(prev));

    final result = await _addPropertyUseCase(
      label: label,
      addressLine: addressLine,
      city: city,
      latitude: latitude,
      longitude: longitude,
      isDefault: isDefault,
    );

    return result.fold(
      (failure) {
        emit(PropertyError(failure.errorMessage, currentProperties: prev));
        return false;
      },
      (newProperty) {
        // If it was marked default, unmark other properties locally
        List<PropertyEntity> updated;
        if (newProperty.isDefault) {
          updated = [
            ...prev.map((p) => p.copyWith(isDefault: false)),
            newProperty,
          ];
        } else {
          updated = [...prev, newProperty];
        }
        emit(PropertyActionSuccess(
          message: 'Property added successfully.',
          properties: updated,
        ));
        emit(PropertyLoaded(updated));
        return true;
      },
    );
  }

  Future<bool> updateProperty({
    required int id,
    String? label,
    String? addressLine,
    String? city,
    double? latitude,
    double? longitude,
    bool? isDefault,
  }) async {
    final prev = currentProperties;
    emit(PropertyActionInProgress(prev));

    final result = await _updatePropertyUseCase(
      id: id,
      label: label,
      addressLine: addressLine,
      city: city,
      latitude: latitude,
      longitude: longitude,
      isDefault: isDefault,
    );

    return result.fold(
      (failure) {
        emit(PropertyError(failure.errorMessage, currentProperties: prev));
        return false;
      },
      (updatedProperty) {
        final updated = prev.map((p) {
          if (p.id == id) return updatedProperty;
          if (updatedProperty.isDefault) return p.copyWith(isDefault: false);
          return p;
        }).toList();

        emit(PropertyActionSuccess(
          message: 'Property updated successfully.',
          properties: updated,
        ));
        emit(PropertyLoaded(updated));
        return true;
      },
    );
  }

  Future<bool> setDefaultProperty(int id) async {
    return updateProperty(id: id, isDefault: true);
  }

  Future<bool> deleteProperty(int id) async {
    final prev = currentProperties;
    emit(PropertyActionInProgress(prev));

    final result = await _deletePropertyUseCase(id);
    return result.fold(
      (failure) {
        emit(PropertyError(failure.errorMessage, currentProperties: prev));
        return false;
      },
      (_) {
        final updated = prev.where((p) => p.id != id).toList();
        emit(PropertyActionSuccess(
          message: 'Property deleted successfully.',
          properties: updated,
        ));
        emit(PropertyLoaded(updated));
        return true;
      },
    );
  }
}
