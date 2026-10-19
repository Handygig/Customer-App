import 'package:dartz/dartz.dart';
import 'package:customer_app/core/errors/failures.dart';
import 'package:customer_app/src/domain/entities/profile/user_profile.dart';
import 'package:customer_app/src/domain/entities/profile/payment_card.dart';
import 'package:customer_app/src/domain/entities/profile/property.dart';

abstract class ProfileRepository {
  Stream<UserProfile> watchUserProfile();
  Future<Either<Failure, UserProfile>> getUserProfile();
  Future<Either<Failure, void>> updateUserProfile(UserProfile profile);

  Stream<List<PaymentCard>> watchPaymentCards();
  Future<Either<Failure, List<PaymentCard>>> getPaymentCards();
  Future<Either<Failure, void>> addPaymentCard(PaymentCard card);
  Future<Either<Failure, void>> updatePaymentCard(PaymentCard card);
  Future<Either<Failure, void>> deletePaymentCard(String cardId);
  Future<Either<Failure, void>> setDefaultPaymentCard(String cardId);
  Future<Either<Failure, void>> toggleFreezePaymentCard(String cardId);

  Stream<List<Property>> watchProperties();
  Future<Either<Failure, List<Property>>> getProperties();
  Future<Either<Failure, void>> addProperty(Property property);
  Future<Either<Failure, void>> updateProperty(Property property);
  Future<Either<Failure, void>> deleteProperty(String propertyId);
  Future<Either<Failure, void>> setPrimaryProperty(String propertyId);

  Future<Either<Failure, bool>> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<Either<Failure, void>> toggleTwoFactorAuth(bool enabled);
  Future<Either<Failure, void>> updateLanguage(String languageCode);
  Future<Either<Failure, void>> toggleNotifications(bool enabled);
  Future<Either<Failure, void>> toggleBiometrics(bool enabled);
  Future<Either<Failure, void>> toggleDarkMode(bool enabled);

  // Rewards & Referral
  Future<Either<Failure, Map<String, dynamic>>> getRewardsSummary();
  Future<Either<Failure, Map<String, dynamic>>> redeemPoints(int points);
  Future<Either<Failure, Map<String, dynamic>>> applyReferralCode(String code);
}
