import 'package:equatable/equatable.dart';
import 'package:customer_app/src/domain/entities/properties/property_entity.dart';

abstract class PropertyState extends Equatable {
  const PropertyState();

  @override
  List<Object?> get props => [];
}

class PropertyInitial extends PropertyState {
  const PropertyInitial();
}

class PropertyLoading extends PropertyState {
  const PropertyLoading();
}

class PropertyLoaded extends PropertyState {
  final List<PropertyEntity> properties;

  const PropertyLoaded(this.properties);

  @override
  List<Object?> get props => [properties];
}

class PropertyActionInProgress extends PropertyState {
  final List<PropertyEntity> properties;

  const PropertyActionInProgress(this.properties);

  @override
  List<Object?> get props => [properties];
}

class PropertyActionSuccess extends PropertyState {
  final String message;
  final List<PropertyEntity> properties;

  const PropertyActionSuccess({
    required this.message,
    required this.properties,
  });

  @override
  List<Object?> get props => [message, properties];
}

class PropertyError extends PropertyState {
  final String message;
  final List<PropertyEntity>? currentProperties;

  const PropertyError(this.message, {this.currentProperties});

  @override
  List<Object?> get props => [message, currentProperties];
}
