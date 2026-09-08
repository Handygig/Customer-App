import 'package:equatable/equatable.dart';

class ServiceCategoryEntity extends Equatable {
  final int id;
  final String name;
  final String? description;
  final bool isActive;

  const ServiceCategoryEntity({
    required this.id,
    required this.name,
    this.description,
    required this.isActive,
  });

  @override
  List<Object?> get props => [id, name, description, isActive];
}
