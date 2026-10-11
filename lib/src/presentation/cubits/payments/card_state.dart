import 'package:equatable/equatable.dart';
import 'package:customer_app/src/domain/entities/payments/card_entity.dart';
import 'package:customer_app/src/domain/entities/payments/payment_entity.dart';

abstract class CardState extends Equatable {
  const CardState();

  @override
  List<Object?> get props => [];
}

class CardInitial extends CardState {
  const CardInitial();
}

class CardLoading extends CardState {
  const CardLoading();
}

class CardLoaded extends CardState {
  final List<CardEntity> cards;
  final CardEntity? selectedCard;

  const CardLoaded(this.cards, {this.selectedCard});

  CardEntity? get defaultCard {
    if (cards.isEmpty) return null;
    return cards.firstWhere(
      (c) => c.isDefault,
      orElse: () => cards.first,
    );
  }

  @override
  List<Object?> get props => [cards, selectedCard];
}

class CardActionSuccess extends CardState {
  final String message;

  const CardActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class CardPaymentSuccess extends CardState {
  final PaymentEntity payment;

  const CardPaymentSuccess(this.payment);

  @override
  List<Object?> get props => [payment];
}

class CardError extends CardState {
  final String message;

  const CardError(this.message);

  @override
  List<Object?> get props => [message];
}
