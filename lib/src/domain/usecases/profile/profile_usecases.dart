import 'package:dartz/dartz.dart';
import 'package:customer_app/core/errors/failures.dart';
import 'package:customer_app/src/domain/entities/profile/user_profile.dart';
import 'package:customer_app/src/domain/entities/profile/payment_card.dart';
import 'package:customer_app/src/domain/entities/profile/property.dart';
import 'package:customer_app/src/domain/repositories/profile/profile_repository.dart';

class GetUserProfileUseCase {
  final ProfileRepository repository;
  GetUserProfileUseCase(this.repository);

  Stream<UserProfile> watch() => repository.watchUserProfile();
  Future<Either<Failure, UserProfile>> call() => repository.getUserProfile();
}

class UpdateUserProfileUseCase {
  final ProfileRepository repository;
  UpdateUserProfileUseCase(this.repository);

  Future<Either<Failure, void>> call(UserProfile profile) =>
      repository.updateUserProfile(profile);
}

class ManagePaymentCardsUseCase {
  final ProfileRepository repository;
  ManagePaymentCardsUseCase(this.repository);

  Stream<List<PaymentCard>> watch() => repository.watchPaymentCards();
  Future<Either<Failure, void>> addCard(PaymentCard card) =>
      repository.addPaymentCard(card);
  Future<Either<Failure, void>> deleteCard(String cardId) =>
      repository.deletePaymentCard(cardId);
  Future<Either<Failure, void>> setDefaultCard(String cardId) =>
      repository.setDefaultPaymentCard(cardId);
}

class ManagePropertiesUseCase {
  final ProfileRepository repository;
  ManagePropertiesUseCase(this.repository);

  Stream<List<Property>> watch() => repository.watchProperties();
  Future<Either<Failure, void>> addProperty(Property property) =>
      repository.addProperty(property);
  Future<Either<Failure, void>> deleteProperty(String propertyId) =>
      repository.deleteProperty(propertyId);
}

class ManageSettingsUseCase {
  final ProfileRepository repository;
  ManageSettingsUseCase(this.repository);

  Future<Either<Failure, bool>> changePassword(String current, String next) =>
      repository.changePassword(currentPassword: current, newPassword: next);

  Future<Either<Failure, void>> toggle2FA(bool enabled) =>
      repository.toggleTwoFactorAuth(enabled);
  Future<Either<Failure, void>> setLanguage(String code) =>
      repository.updateLanguage(code);
  Future<Either<Failure, void>> toggleNotifications(bool enabled) =>
      repository.toggleNotifications(enabled);
  Future<Either<Failure, void>> toggleBiometrics(bool enabled) =>
      repository.toggleBiometrics(enabled);
}
