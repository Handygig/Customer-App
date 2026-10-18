import 'package:equatable/equatable.dart';

class ReviewEntity extends Equatable {
  final int id;
  final int rating;
  final String? comment;
  final int? assignmentId;
  final int? providerId;
  final String? providerName;
  final DateTime? createdAt;

  const ReviewEntity({
    required this.id,
    required this.rating,
    this.comment,
    this.assignmentId,
    this.providerId,
    this.providerName,
    this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        rating,
        comment,
        assignmentId,
        providerId,
        providerName,
        createdAt,
      ];
}
