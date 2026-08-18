enum PropertyType { apartment, house, villa, office }

class Property {
  final String id;
  final String title;
  final String address;
  final PropertyType type;
  final int bedrooms;
  final int areaSqft;
  final bool isPrimary;
  final String? imagePath;

  const Property({
    required this.id,
    required this.title,
    required this.address,
    required this.type,
    required this.bedrooms,
    required this.areaSqft,
    this.isPrimary = false,
    this.imagePath,
  });

  Property copyWith({
    String? id,
    String? title,
    String? address,
    PropertyType? type,
    int? bedrooms,
    int? areaSqft,
    bool? isPrimary,
    String? imagePath,
  }) {
    return Property(
      id: id ?? this.id,
      title: title ?? this.title,
      address: address ?? this.address,
      type: type ?? this.type,
      bedrooms: bedrooms ?? this.bedrooms,
      areaSqft: areaSqft ?? this.areaSqft,
      isPrimary: isPrimary ?? this.isPrimary,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}
