import 'package:equatable/equatable.dart';

class ServiceCategoryEntity extends Equatable {
  final int id;
  final String name;
  final String? description;
  final String? imageUrl;
  final bool isActive;

  const ServiceCategoryEntity({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.isActive,
  });

  @override
  List<Object?> get props => [id, name, description, imageUrl, isActive];
}
