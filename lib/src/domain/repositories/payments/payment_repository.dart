import 'package:dartz/dartz.dart';
import 'package:customer_app/core/errors/failures.dart';
import 'package:customer_app/src/domain/entities/payments/card_entity.dart';
import 'package:customer_app/src/domain/entities/payments/payment_entity.dart';

abstract class PaymentRepository {
  Future<Either<Failure, List<CardEntity>>> getCards();

  Future<Either<Failure, CardEntity>> addCard({
    required String cardType,
    required String maskedCardNumber,
    required String expiryDate,
    required String cardHolderName,
    String? billingAddress,
  });

  Future<Either<Failure, void>> deleteCard(int cardId);

  Future<Either<Failure, void>> setDefaultCard(int cardId);

  Future<Either<Failure, void>> toggleFreezeCard(int cardId, bool freeze);

  Future<Either<Failure, PaymentEntity>> payJobAssignment({
    required int jobAssignmentId,
    required int cardId,
  });
}