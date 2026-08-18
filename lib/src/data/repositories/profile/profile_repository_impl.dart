import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:customer_app/config/theme/app_theme.dart';
import 'package:customer_app/core/constants/app_assets.dart';
import 'package:customer_app/core/errors/failures.dart';
import 'package:customer_app/src/domain/entities/profile/user_profile.dart';
import 'package:customer_app/src/domain/entities/profile/payment_card.dart';
import 'package:customer_app/src/domain/entities/profile/property.dart';
import 'package:customer_app/src/domain/repositories/profile/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  // Singleton pattern for seamless global state sharing across presentation screens
  static final ProfileRepositoryImpl _instance =
      ProfileRepositoryImpl._internal();
  factory ProfileRepositoryImpl() => _instance;

  ProfileRepositoryImpl._internal() {
    _profileController = StreamController<UserProfile>.broadcast();
    _cardsController = StreamController<List<PaymentCard>>.broadcast();
    _propertiesController = StreamController<List<Property>>.broadcast();
  }

  late final StreamController<UserProfile> _profileController;
  late final StreamController<List<PaymentCard>> _cardsController;
  late final StreamController<List<Property>> _propertiesController;

  // In-memory reactive state
  UserProfile _profile = const UserProfile(
    id: 'user_001',
    firstName: 'Alex',
    lastName: 'Johnson',
    email: 'alex.johnson@example.com',
    phone: '+1 (555) 382-9102',
    gender: GenderType.male,
    membershipTier: 'Gold Member',
    rewardPoints: 1250,
    walletBalance: 45.00,
    referralCode: 'ALEX2026',
    isTwoFactorEnabled: false,
    languageCode: 'en',
    pushNotificationsEnabled: true,
    biometricsEnabled: true,
    memberSinceYear: '2026',
  );

  List<PaymentCard> _cards = [
    const PaymentCard(
      id: 'card_1',
      cardholderName: 'Alex Johnson',
      lastFourDigits: '4920',
      expiryDate: '12/28',
      brand: CardBrand.mastercard,
      isDefault: true,
      cardLimit: 43093.00,
      gradientColors: [0xFF3D4127, 0xFF636B2F],
    ),
    const PaymentCard(
      id: 'card_2',
      cardholderName: 'Alex Johnson',
      lastFourDigits: '8812',
      expiryDate: '09/27',
      brand: CardBrand.visa,
      isDefault: false,
      cardLimit: 15500.00,
      gradientColors: [0xFF636B2F, 0xFFBAC095],
    ),
    const PaymentCard(
      id: 'card_3',
      cardholderName: 'Alex Johnson',
      lastFourDigits: '3049',
      expiryDate: '05/29',
      brand: CardBrand.amex,
      isDefault: false,
      cardLimit: 25000.00,
      gradientColors: [0xFF1F2414, 0xFF3D4127],
    ),
  ];

  List<Property> _properties = [
    const Property(
      id: 'prop_1',
      title: 'Primary Residence',
      address: '742 Evergreen Terrace, Springfield',
      type: PropertyType.villa,
      bedrooms: 4,
      areaSqft: 2800,
      isPrimary: true,
      imagePath: AppAssets.propertyVilla,
    ),
    const Property(
      id: 'prop_2',
      title: 'Downtown Apartment',
      address: '101 Skyline Towers, Apt 4B',
      type: PropertyType.apartment,
      bedrooms: 2,
      areaSqft: 1100,
      isPrimary: false,
      imagePath: AppAssets.propertyApartment,
    ),
    const Property(
      id: 'prop_3',
      title: 'Beach House',
      address: '12 Ocean Drive, Malibu',
      type: PropertyType.house,
      bedrooms: 3,
      areaSqft: 2100,
      isPrimary: false,
      imagePath: AppAssets.propertyCottage,
    ),
  ];

  @override
  Stream<UserProfile> watchUserProfile() async* {
    yield _profile;
    yield* _profileController.stream;
  }

  @override
  Future<Either<Failure, UserProfile>> getUserProfile() async {
    return Right(_profile);
  }

  @override
  Future<Either<Failure, void>> updateUserProfile(UserProfile profile) async {
    _profile = profile;
    _profileController.add(_profile);
    return const Right(null);
  }

  @override
  Stream<List<PaymentCard>> watchPaymentCards() async* {
    yield _cards;
    yield* _cardsController.stream;
  }

  @override
  Future<Either<Failure, List<PaymentCard>>> getPaymentCards() async {
    return Right(List.unmodifiable(_cards));
  }

  @override
  Future<Either<Failure, void>> addPaymentCard(PaymentCard card) async {
    if (card.isDefault) {
      _cards = _cards.map((c) => c.copyWith(isDefault: false)).toList();
    }
    _cards = [..._cards, card];
    _cardsController.add(_cards);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> deletePaymentCard(String cardId) async {
    _cards = _cards.where((c) => c.id != cardId).toList();
    if (_cards.isNotEmpty && !_cards.any((c) => c.isDefault)) {
      _cards[0] = _cards[0].copyWith(isDefault: true);
    }
    _cardsController.add(_cards);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> updatePaymentCard(PaymentCard card) async {
    if (card.isDefault) {
      _cards = _cards.map((c) => c.copyWith(isDefault: false)).toList();
    }
    final index = _cards.indexWhere((c) => c.id == card.id);
    if (index != -1) {
      _cards[index] = card;
    }
    _cardsController.add(_cards);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> setDefaultPaymentCard(String cardId) async {
    _cards = _cards.map((c) {
      return c.copyWith(isDefault: c.id == cardId);
    }).toList();
    _cardsController.add(_cards);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> toggleFreezePaymentCard(String cardId) async {
    _cards = _cards.map((c) {
      if (c.id == cardId) {
        return c.copyWith(isFrozen: !c.isFrozen);
      }
      return c;
    }).toList();
    _cardsController.add(_cards);
    return const Right(null);
  }

  @override
  Stream<List<Property>> watchProperties() async* {
    yield _properties;
    yield* _propertiesController.stream;
  }

  @override
  Future<Either<Failure, List<Property>>> getProperties() async {
    return Right(List.unmodifiable(_properties));
  }

  @override
  Future<Either<Failure, void>> addProperty(Property property) async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (property.isPrimary) {
      _properties = _properties
          .map((p) => p.copyWith(isPrimary: false))
          .toList();
    }
    _properties = [..._properties, property];
    _propertiesController.add(_properties);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> updateProperty(Property property) async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (property.isPrimary) {
      _properties = _properties
          .map((p) => p.copyWith(isPrimary: false))
          .toList();
    }
    final index = _properties.indexWhere((p) => p.id == property.id);
    if (index != -1) {
      _properties[index] = property;
      _propertiesController.add(_properties);
    }
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> deleteProperty(String propertyId) async {
    _properties = _properties.where((p) => p.id != propertyId).toList();
    if (_properties.isNotEmpty && !_properties.any((p) => p.isPrimary)) {
      _properties[0] = _properties[0].copyWith(isPrimary: true);
    }
    _propertiesController.add(_properties);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> setPrimaryProperty(String propertyId) async {
    _properties = _properties.map((p) {
      return p.copyWith(isPrimary: p.id == propertyId);
    }).toList();
    _propertiesController.add(_properties);
    return const Right(null);
  }

  @override
  Future<Either<Failure, bool>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return const Right(true);
  }

  @override
  Future<Either<Failure, void>> toggleTwoFactorAuth(bool enabled) async {
    _profile = _profile.copyWith(isTwoFactorEnabled: enabled);
    _profileController.add(_profile);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> updateLanguage(String languageCode) async {
    _profile = _profile.copyWith(languageCode: languageCode);
    _profileController.add(_profile);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> toggleNotifications(bool enabled) async {
    _profile = _profile.copyWith(pushNotificationsEnabled: enabled);
    _profileController.add(_profile);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> toggleBiometrics(bool enabled) async {
    _profile = _profile.copyWith(biometricsEnabled: enabled);
    _profileController.add(_profile);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> toggleDarkMode(bool enabled) async {
    _profile = _profile.copyWith(isDarkMode: enabled);
    _profileController.add(_profile);
    themeModeNotifier.value = enabled ? ThemeMode.dark : ThemeMode.light;
    return const Right(null);
  }
}
