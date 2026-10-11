import 'package:dartz/dartz.dart';
import 'package:customer_app/core/errors/auth_exception.dart';
import 'package:customer_app/core/errors/failures.dart';
import 'package:customer_app/core/services/network_service.dart';
import 'package:customer_app/src/data/data_sources/remote/payments/payment_remote_data_source.dart';
import 'package:customer_app/src/domain/entities/payments/card_entity.dart';
import 'package:customer_app/src/domain/entities/payments/payment_entity.dart';
import 'package:customer_app/src/domain/repositories/payments/payment_repository.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentRemoteDataSource _remoteDataSource;
  final NetworkService _networkService;

  PaymentRepositoryImpl(this._remoteDataSource, this._networkService);

  @override
  Future<Either<Failure, List<CardEntity>>> getCards() async {
    if (!await _networkService.isConnected()) {
      return Left(
        const NetworkFailure(
          errorMessage: 'No internet connection. Please check your network.',
        ),
      );
    }

    try {
      final cards = await _remoteDataSource.getCards();
      return Right(cards);
    } on AuthException catch (e) {
      return Left(APIFailure(errorMessage: e.message));
    } catch (e) {
      return Left(
        APIFailure(errorMessage: 'Failed to retrieve payment cards: '),
      );
    }
  }

  @override
  Future<Either<Failure, CardEntity>> addCard({
    required String cardType,
    required String maskedCardNumber,
    required String expiryDate,
    required String cardHolderName,
    String? billingAddress,
  }) async {
    if (!await _networkService.isConnected()) {
      return Left(
        const NetworkFailure(
          errorMessage: 'No internet connection. Please check your network.',
        ),
      );
    }

    try {
      final card = await _remoteDataSource.addCard(
        cardType: cardType,
        maskedCardNumber: maskedCardNumber,
        expiryDate: expiryDate,
        cardHolderName: cardHolderName,
        billingAddress: billingAddress,
      );
      return Right(card);
    } on AuthException catch (e) {
      return Left(APIFailure(errorMessage: e.message));
    } catch (e) {
      return Left(APIFailure(errorMessage: 'Failed to add card: '));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCard(int cardId) async {
    if (!await _networkService.isConnected()) {
      return Left(
        const NetworkFailure(
          errorMessage: 'No internet connection. Please check your network.',
        ),
      );
    }

    try {
      await _remoteDataSource.deleteCard(cardId);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(APIFailure(errorMessage: e.message));
    } catch (e) {
      return Left(APIFailure(errorMessage: 'Failed to delete card: '));
    }
  }

  @override
  Future<Either<Failure, void>> setDefaultCard(int cardId) async {
    if (!await _networkService.isConnected()) {
      return Left(
        const NetworkFailure(
          errorMessage: 'No internet connection. Please check your network.',
        ),
      );
    }

    try {
      await _remoteDataSource.setDefaultCard(cardId);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(APIFailure(errorMessage: e.message));
    } catch (e) {
      return Left(APIFailure(errorMessage: 'Failed to set default card: '));
    }
  }

  @override
  Future<Either<Failure, void>> toggleFreezeCard(int cardId, bool freeze) async {
    if (!await _networkService.isConnected()) {
      return Left(
        const NetworkFailure(
          errorMessage: 'No internet connection. Please check your network.',
        ),
      );
    }

    try {
      await _remoteDataSource.toggleFreezeCard(cardId, freeze);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(APIFailure(errorMessage: e.message));
    } catch (e) {
      return Left(APIFailure(errorMessage: 'Failed to update card status: '));
    }
  }

  @override
  Future<Either<Failure, PaymentEntity>> payJobAssignment({
    required int jobAssignmentId,
    required int cardId,
  }) async {
    if (!await _networkService.isConnected()) {
      return Left(
        const NetworkFailure(
          errorMessage: 'No internet connection. Please check your network.',
        ),
      );
    }

    try {
      final payment = await _remoteDataSource.payJobAssignment(
        jobAssignmentId: jobAssignmentId,
        cardId: cardId,
      );
      return Right(payment);
    } on AuthException catch (e) {
      return Left(APIFailure(errorMessage: e.message));
    } catch (e) {
      return Left(APIFailure(errorMessage: 'Failed to process payment: '));
    }
  }
}