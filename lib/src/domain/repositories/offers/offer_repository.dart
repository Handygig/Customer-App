import 'package:dartz/dartz.dart';
import 'package:customer_app/core/errors/failures.dart';
import 'package:customer_app/src/domain/entities/offers/exclusive_offer.dart';

abstract class OfferRepository {
  Future<Either<Failure, List<ExclusiveOffer>>> getExclusiveOffers();
  Future<Either<Failure, void>> claimOffer(String code);
}
