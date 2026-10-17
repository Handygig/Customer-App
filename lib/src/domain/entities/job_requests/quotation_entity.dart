import 'package:equatable/equatable.dart';

class QuotationProviderEntity extends Equatable {
  final int? id;
  final String? name;
  final double? rating;
  final String? profileImage;

  const QuotationProviderEntity({
    this.id,
    this.name,
    this.rating,
    this.profileImage,
  });

  @override
  List<Object?> get props => [id, name, rating, profileImage];
}

class QuotationEntity extends Equatable {
  final int id;
  final double quotedPrice;
  final String? estimatedDuration;
  final String? message;
  final String status;
  final QuotationProviderEntity? provider;
  final DateTime? createdAt;

  const QuotationEntity({
    required this.id,
    required this.quotedPrice,
    this.estimatedDuration,
    this.message,
    required this.status,
    this.provider,
    this.createdAt,
  });

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isAccepted => status.toLowerCase() == 'accepted';
  bool get isRejected => status.toLowerCase() == 'rejected';

  @override
  List<Object?> get props => [
        id,
        quotedPrice,
        estimatedDuration,
        message,
        status,
        provider,
        createdAt,
      ];
}
