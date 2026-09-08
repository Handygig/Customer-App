import 'package:equatable/equatable.dart';
import 'package:customer_app/src/domain/entities/services/service_category_entity.dart';

abstract class ServiceCategoryState extends Equatable {
  const ServiceCategoryState();

  @override
  List<Object?> get props => [];
}

class ServiceCategoryInitial extends ServiceCategoryState {
  const ServiceCategoryInitial();
}

class ServiceCategoryLoading extends ServiceCategoryState {
  const ServiceCategoryLoading();
}

class ServiceCategoryLoaded extends ServiceCategoryState {
  final List<ServiceCategoryEntity> categories;

  const ServiceCategoryLoaded(this.categories);

  @override
  List<Object?> get props => [categories];
}

class ServiceCategoryError extends ServiceCategoryState {
  final String message;

  const ServiceCategoryError(this.message);

  @override
  List<Object?> get props => [message];
}
