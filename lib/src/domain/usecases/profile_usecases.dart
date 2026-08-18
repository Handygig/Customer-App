import 'package:customer_app/src/domain/entities/user_profile.dart';
import 'package:customer_app/src/domain/entities/payment_card.dart';
import 'package:customer_app/src/domain/entities/property.dart';
import 'package:customer_app/src/domain/repositories/profile_repository.dart';

class GetUserProfileUseCase {
  final ProfileRepository repository;
  GetUserProfileUseCase(this.repository);

  Stream<UserProfile> watch() => repository.watchUserProfile();
  Future<UserProfile> call() => repository.getUserProfile();
}

class UpdateUserProfileUseCase {
  final ProfileRepository repository;
  UpdateUserProfileUseCase(this.repository);

  Future<void> call(UserProfile profile) =>
      repository.updateUserProfile(profile);
}

class ManagePaymentCardsUseCase {
  final ProfileRepository repository;
  ManagePaymentCardsUseCase(this.repository);

  Stream<List<PaymentCard>> watch() => repository.watchPaymentCards();
  Future<void> addCard(PaymentCard card) => repository.addPaymentCard(card);
  Future<void> deleteCard(String cardId) =>
      repository.deletePaymentCard(cardId);
  Future<void> setDefaultCard(String cardId) =>
      repository.setDefaultPaymentCard(cardId);
}

class ManagePropertiesUseCase {
  final ProfileRepository repository;
  ManagePropertiesUseCase(this.repository);

  Stream<List<Property>> watch() => repository.watchProperties();
  Future<void> addProperty(Property property) =>
      repository.addProperty(property);
  Future<void> deleteProperty(String propertyId) =>
      repository.deleteProperty(propertyId);
}

class ManageSettingsUseCase {
  final ProfileRepository repository;
  ManageSettingsUseCase(this.repository);

  Future<bool> changePassword(String current, String next) =>
      repository.changePassword(currentPassword: current, newPassword: next);

  Future<void> toggle2FA(bool enabled) =>
      repository.toggleTwoFactorAuth(enabled);
  Future<void> setLanguage(String code) => repository.updateLanguage(code);
  Future<void> toggleNotifications(bool enabled) =>
      repository.toggleNotifications(enabled);
  Future<void> toggleBiometrics(bool enabled) =>
      repository.toggleBiometrics(enabled);
}
