import 'package:equatable/equatable.dart';
import 'package:customer_app/src/domain/entities/payments/card_entity.dart';

class PaymentEntity extends Equatable {
  final int id;
  final double amount;
  final String? paymentMethod;
  final String paymentStatus;
  final String? paymentDate;
  final CardEntity? card;

  const PaymentEntity({
    required this.id,
    required this.amount,
    this.paymentMethod,
    required this.paymentStatus,
    this.paymentDate,
    this.card,
  });

  bool get isPaid => paymentStatus.toLowerCase() == 'completed' || paymentStatus.toLowerCase() == 'paid';

  @override
  List<Object?> get props => [
        id,
        amount,
        paymentMethod,
        paymentStatus,
        paymentDate,
        card,
      ];
}
