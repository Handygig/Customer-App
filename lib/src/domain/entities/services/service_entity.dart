import 'package:equatable/equatable.dart';

class ServiceEntity extends Equatable {
  final int id;
  final String title;
  final String name;
  final int? categoryId;
  final String? category;
  final String? description;
  final String? imageUrl;
  final bool isActive;

  const ServiceEntity({
    required this.id,
    required this.title,
    required this.name,
    this.categoryId,
    this.category,
    this.description,
    this.imageUrl,
    required this.isActive,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        name,
        categoryId,
        category,
        description,
        imageUrl,
        isActive,
      ];
}
