import 'package:customer_app/src/domain/entities/user_profile.dart';
import 'package:customer_app/src/domain/entities/payment_card.dart';
import 'package:customer_app/src/domain/entities/property.dart';

abstract class ProfileRepository {
  Stream<UserProfile> watchUserProfile();
  Future<UserProfile> getUserProfile();
  Future<void> updateUserProfile(UserProfile profile);

  Stream<List<PaymentCard>> watchPaymentCards();
  Future<List<PaymentCard>> getPaymentCards();
  Future<void> addPaymentCard(PaymentCard card);
  Future<void> updatePaymentCard(PaymentCard card);
  Future<void> deletePaymentCard(String cardId);
  Future<void> setDefaultPaymentCard(String cardId);
  Future<void> toggleFreezePaymentCard(String cardId);

  Stream<List<Property>> watchProperties();
  Future<List<Property>> getProperties();
  Future<void> addProperty(Property property);
  Future<void> updateProperty(Property property);
  Future<void> deleteProperty(String propertyId);
  Future<void> setPrimaryProperty(String propertyId);

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<void> toggleTwoFactorAuth(bool enabled);
  Future<void> updateLanguage(String languageCode);
  Future<void> toggleNotifications(bool enabled);
  Future<void> toggleBiometrics(bool enabled);
  Future<void> toggleDarkMode(bool enabled);
}
