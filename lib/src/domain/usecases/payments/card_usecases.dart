import 'package:dartz/dartz.dart';
import 'package:customer_app/core/errors/failures.dart';
import 'package:customer_app/src/domain/entities/payments/card_entity.dart';
import 'package:customer_app/src/domain/entities/payments/payment_entity.dart';
import 'package:customer_app/src/domain/repositories/payments/payment_repository.dart';

class GetCardsUseCase {
  final PaymentRepository repository;

  GetCardsUseCase(this.repository);

  Future<Either<Failure, List<CardEntity>>> call() {
    return repository.getCards();
  }
}

class AddCardUseCase {
  final PaymentRepository repository;

  AddCardUseCase(this.repository);

  Future<Either<Failure, CardEntity>> call({
    required String cardType,
    required String maskedCardNumber,
    required String expiryDate,
    required String cardHolderName,
    String? billingAddress,
  }) {
    return repository.addCard(
      cardType: cardType,
      maskedCardNumber: maskedCardNumber,
      expiryDate: expiryDate,
      cardHolderName: cardHolderName,
      billingAddress: billingAddress,
    );
  }
}

class DeleteCardUseCase {
  final PaymentRepository repository;

  DeleteCardUseCase(this.repository);

  Future<Either<Failure, void>> call(int cardId) {
    return repository.deleteCard(cardId);
  }
}

class SetDefaultCardUseCase {
  final PaymentRepository repository;

  SetDefaultCardUseCase(this.repository);

  Future<Either<Failure, void>> call(int cardId) {
    return repository.setDefaultCard(cardId);
  }
}

class ToggleFreezeCardUseCase {
  final PaymentRepository repository;

  ToggleFreezeCardUseCase(this.repository);

  Future<Either<Failure, void>> call(int cardId, bool freeze) {
    return repository.toggleFreezeCard(cardId, freeze);
  }
}

class PayJobAssignmentUseCase {
  final PaymentRepository repository;

  PayJobAssignmentUseCase(this.repository);

  Future<Either<Failure, PaymentEntity>> call({
    required int jobAssignmentId,
    required int cardId,
  }) {
    return repository.payJobAssignment(
      jobAssignmentId: jobAssignmentId,
      cardId: cardId,
    );
  }
}