import 'package:customer_app/src/data/models/payments/card_model.dart';
import 'package:customer_app/src/data/models/payments/payment_model.dart';

abstract class PaymentRemoteDataSource {
  Future<List<CardModel>> getCards();

  Future<CardModel> addCard({
    required String cardType,
    required String maskedCardNumber,
    required String expiryDate,
    required String cardHolderName,
    String? billingAddress,
  });

  Future<void> deleteCard(int cardId);

  Future<void> setDefaultCard(int cardId);

  Future<void> toggleFreezeCard(int cardId, bool freeze);

  Future<PaymentModel> payJobAssignment({
    required int jobAssignmentId,
    required int cardId,
  });
}