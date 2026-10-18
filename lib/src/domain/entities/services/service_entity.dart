import 'package:equatable/equatable.dart';

class ServiceEntity extends Equatable {
  final int id;
  final String title;
  final String name;
  final int? categoryId;
  final String? category;
  final String? description;
  final double? basePrice;
  final String? price;
  final String? imageUrl;
  final bool isActive;

  const ServiceEntity({
    required this.id,
    required this.title,
    required this.name,
    this.categoryId,
    this.category,
    this.description,
    this.basePrice,
    this.price,
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
        basePrice,
        price,
        imageUrl,
        isActive,
      ];
}
