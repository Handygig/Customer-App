import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:customer_app/config/theme/app_theme.dart';
import 'package:customer_app/core/constants/app_assets.dart';
import 'package:customer_app/core/constants/app_endpoints.dart';
import 'package:customer_app/core/di/service_locator.dart';
import 'package:customer_app/core/errors/failures.dart';
import 'package:customer_app/core/services/dio_client.dart';
import 'package:customer_app/core/services/network_service.dart';
import 'package:customer_app/core/services/language_manager.dart';
import 'package:customer_app/src/domain/entities/profile/user_profile.dart';
import 'package:customer_app/src/domain/entities/profile/payment_card.dart';
import 'package:customer_app/src/domain/entities/profile/property.dart';
import 'package:customer_app/src/domain/repositories/profile/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final Dio _dio;
  final NetworkService? _networkService;

  static ProfileRepositoryImpl? _instance;

  factory ProfileRepositoryImpl([Dio? dio, NetworkService? networkService]) {
    _instance ??= ProfileRepositoryImpl._internal(
      dio ?? (sl.isRegistered<Dio>() ? sl<Dio>() : DioClient.create()),
      networkService ??
          (sl.isRegistered<NetworkService>() ? sl<NetworkService>() : null),
    );
    return _instance!;
  }

  ProfileRepositoryImpl._internal(this._dio, this._networkService) {
    _profileController = StreamController<UserProfile>.broadcast();
    _cardsController = StreamController<List<PaymentCard>>.broadcast();
    _propertiesController = StreamController<List<Property>>.broadcast();
  }

  late final StreamController<UserProfile> _profileController;
  late final StreamController<List<PaymentCard>> _cardsController;
  late final StreamController<List<Property>> _propertiesController;

  // In-memory reactive state
  UserProfile _profile = const UserProfile(
    id: '',
    firstName: '',
    lastName: '',
    email: '',
    phone: '',
    gender: GenderType.male,
    membershipTier: 'Member',
    rewardPoints: 0,
    walletBalance: 0.0,
    referralCode: '',
    isTwoFactorEnabled: false,
    languageCode: 'en',
    pushNotificationsEnabled: true,
    biometricsEnabled: true,
    memberSinceYear: '2026',
  );

  List<PaymentCard> _cards = [];
  List<Property> _properties = [];

  @override
  Stream<UserProfile> watchUserProfile() async* {
    if (_profile.id.isNotEmpty) {
      yield _profile;
    }
    unawaited(getUserProfile());
    yield* _profileController.stream;
  }

  @override
  Future<Either<Failure, UserProfile>> getUserProfile() async {
    if (_networkService != null && !await _networkService.isConnected()) {
      if (_profile.id.isNotEmpty) return Right(_profile);
      return const Left(NetworkFailure(errorMessage: 'No internet connection'));
    }
    try {
      final response = await _dio.get(AppEndpoints.userProfile);
      final data = response.data;
      final json = (data is Map && data['user'] is Map)
          ? Map<String, dynamic>.from(data['user'] as Map)
          : (data is Map
              ? Map<String, dynamic>.from(data)
              : <String, dynamic>{});

      if (json.isNotEmpty) {
        _profile = UserProfile.fromJson(json);
        _profileController.add(_profile);
      }
      return Right(_profile);
    } on DioException catch (e) {
      debugPrint('⚠️ [ProfileRepositoryImpl.getUserProfile] DioException: ${e.message}');
      if (_profile.id.isNotEmpty) {
        return Right(_profile);
      }
      return Left(APIFailure(errorMessage: e.message ?? 'Failed to load profile'));
    } catch (e, stackTrace) {
      debugPrint('⚠️ [ProfileRepositoryImpl.getUserProfile] Error: $e');
      if (_profile.id.isNotEmpty) {
        return Right(_profile);
      }
      return Left(APIFailure(errorMessage: e.toString(), stackTrace: stackTrace));
    }
  }

  @override
  Future<Either<Failure, void>> updateUserProfile(UserProfile profile) async {
    try {
      final response = await _dio.put(
        AppEndpoints.userProfile,
        data: {
          'full_name': profile.fullName,
          'email': profile.email,
          'phone': profile.phone,
          'gender': profile.gender.name,
        },
      );

      final data = response.data;
      final json = (data is Map && data['user'] is Map)
          ? Map<String, dynamic>.from(data['user'] as Map)
          : (data is Map
              ? Map<String, dynamic>.from(data)
              : <String, dynamic>{});

      if (json.isNotEmpty) {
        _profile = UserProfile.fromJson(json);
      } else {
        _profile = profile;
      }
      _profileController.add(_profile);
      return const Right(null);
    } on DioException catch (e) {
      debugPrint('⚠️ [ProfileRepositoryImpl.updateUserProfile] DioException: ${e.message}');
      final String msg = (e.response?.data is Map && e.response?.data['message'] != null)
          ? e.response!.data['message'].toString()
          : (e.message ?? 'Failed to update profile');
      return Left(APIFailure(errorMessage: msg));
    } catch (e, stackTrace) {
      debugPrint('⚠️ [ProfileRepositoryImpl.updateUserProfile] Error: $e');
      return Left(APIFailure(errorMessage: e.toString(), stackTrace: stackTrace));
    }
  }

  @override
  Stream<List<PaymentCard>> watchPaymentCards() async* {
    if (_cards.isNotEmpty) {
      yield _cards;
    }
    unawaited(getPaymentCards());
    yield* _cardsController.stream;
  }

  @override
  Future<Either<Failure, List<PaymentCard>>> getPaymentCards() async {
    try {
      final response = await _dio.get(AppEndpoints.customerCards);
      final rawData = response.data;
      List<dynamic> items = [];
      if (rawData is Map && rawData['data'] is List) {
        items = rawData['data'] as List<dynamic>;
      } else if (rawData is List) {
        items = rawData;
      }
      _cards = items.map((e) {
        final map = Map<String, dynamic>.from(e as Map);
        final cardTypeStr = (map['card_type'] ?? 'visa').toString().toLowerCase();
        CardBrand brand = CardBrand.visa;
        if (cardTypeStr.contains('master')) {
          brand = CardBrand.mastercard;
        } else if (cardTypeStr.contains('amex')) {
          brand = CardBrand.amex;
        } else if (cardTypeStr.contains('discover')) {
          brand = CardBrand.discover;
        }

        final masked = (map['masked_card_number'] ?? '').toString();
        final lastFour = masked.length >= 4 ? masked.substring(masked.length - 4) : '0000';
        return PaymentCard(
          id: map['id']?.toString() ?? '',
          cardholderName: map['card_holder_name']?.toString() ?? '',
          lastFourDigits: lastFour,
          expiryDate: map['expiry_date']?.toString() ?? '',
          brand: brand,
          isDefault: map['is_default'] == true || map['is_default'] == 1,
          isFrozen: map['is_frozen'] == true || map['is_frozen'] == 1,
          cardLimit: 5000.0,
          gradientColors: brand == CardBrand.mastercard
              ? const [0xFF3D4127, 0xFF636B2F]
              : brand == CardBrand.visa
                  ? const [0xFF636B2F, 0xFFBAC095]
                  : const [0xFF1F2414, 0xFF3D4127],
        );
      }).toList();
      _cardsController.add(_cards);
      return Right(List.unmodifiable(_cards));
    } catch (_) {
      return Right(List.unmodifiable(_cards));
    }
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
    if (_properties.isNotEmpty) {
      yield _properties;
    }
    unawaited(getProperties());
    yield* _propertiesController.stream;
  }

  @override
  Future<Either<Failure, List<Property>>> getProperties() async {
    try {
      final response = await _dio.get(AppEndpoints.customerProperties);
      final rawData = response.data;
      List<dynamic> items = [];
      if (rawData is Map && rawData['data'] is List) {
        items = rawData['data'] as List<dynamic>;
      } else if (rawData is List) {
        items = rawData;
      }
      _properties = items.map((e) {
        final map = Map<String, dynamic>.from(e as Map);
        final label = map['label']?.toString() ?? 'Property';
        final addressLine = map['address_line']?.toString() ?? '';
        final city = map['city']?.toString() ?? '';
        final fullAddr = addressLine.isNotEmpty && city.isNotEmpty
            ? '$addressLine, $city'
            : (addressLine.isNotEmpty ? addressLine : city);
        return Property(
          id: map['id']?.toString() ?? '',
          title: label,
          address: fullAddr,
          type: PropertyType.house,
          bedrooms: 3,
          areaSqft: 2000,
          isPrimary: map['is_default'] == true || map['is_default'] == 1,
          imagePath: AppAssets.propertyVilla,
        );
      }).toList();
      _propertiesController.add(_properties);
      return Right(List.unmodifiable(_properties));
    } catch (_) {
      return Right(List.unmodifiable(_properties));
    }
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
    await LanguageManager.setLanguage(languageCode);
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

  @override
  Future<Either<Failure, Map<String, dynamic>>> getRewardsSummary() async {
    try {
      final response = await _dio.get(AppEndpoints.customerRewards);
      final data = response.data;
      if (data is Map && data['data'] is Map) {
        final summary = Map<String, dynamic>.from(data['data'] as Map);
        // Sync profile state
        _profile = _profile.copyWith(
          rewardPoints: (summary['reward_points'] as num?)?.toInt() ?? _profile.rewardPoints,
          walletBalance: (summary['wallet_balance'] as num?)?.toDouble() ?? _profile.walletBalance,
          membershipTier: summary['membership_tier']?.toString() ?? _profile.membershipTier,
          referralCode: summary['referral_code']?.toString() ?? _profile.referralCode,
        );
        _profileController.add(_profile);
        return Right(summary);
      }
      return const Left(APIFailure(errorMessage: 'Invalid response from server'));
    } on DioException catch (e) {
      debugPrint('⚠️ [ProfileRepositoryImpl.getRewardsSummary] DioException: ${e.message}');
      final msg = (e.response?.data is Map && e.response?.data['message'] != null)
          ? e.response!.data['message'].toString()
          : (e.message ?? 'Failed to load rewards summary');
      return Left(APIFailure(errorMessage: msg));
    } catch (e, stackTrace) {
      debugPrint('⚠️ [ProfileRepositoryImpl.getRewardsSummary] Error: $e');
      return Left(APIFailure(errorMessage: e.toString(), stackTrace: stackTrace));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> redeemPoints(int points) async {
    try {
      final response = await _dio.post(
        AppEndpoints.customerRedeemPoints,
        data: {'points': points},
      );
      final data = response.data;
      if (data is Map && data['data'] is Map) {
        final resData = Map<String, dynamic>.from(data['data'] as Map);
        _profile = _profile.copyWith(
          rewardPoints: (resData['reward_points'] as num?)?.toInt() ?? (_profile.rewardPoints - points),
          walletBalance: (resData['wallet_balance'] as num?)?.toDouble() ?? _profile.walletBalance,
        );
        _profileController.add(_profile);
        return Right(resData);
      }
      return const Left(APIFailure(errorMessage: 'Invalid response from server'));
    } on DioException catch (e) {
      final msg = (e.response?.data is Map && e.response?.data['message'] != null)
          ? e.response!.data['message'].toString()
          : (e.message ?? 'Failed to redeem points');
      return Left(APIFailure(errorMessage: msg));
    } catch (e, stackTrace) {
      return Left(APIFailure(errorMessage: e.toString(), stackTrace: stackTrace));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> applyReferralCode(String code) async {
    try {
      final response = await _dio.post(
        AppEndpoints.customerApplyReferral,
        data: {'referral_code': code},
      );
      final data = response.data;
      if (data is Map && data['data'] is Map) {
        final resData = Map<String, dynamic>.from(data['data'] as Map);
        if (resData['wallet_balance'] != null) {
          _profile = _profile.copyWith(
            walletBalance: (resData['wallet_balance'] as num).toDouble(),
          );
          _profileController.add(_profile);
        }
        return Right(resData);
      }
      return const Left(APIFailure(errorMessage: 'Invalid response from server'));
    } on DioException catch (e) {
      final msg = (e.response?.data is Map && e.response?.data['message'] != null)
          ? e.response!.data['message'].toString()
          : (e.message ?? 'Failed to apply referral code');
      return Left(APIFailure(errorMessage: msg));
    } catch (e, stackTrace) {
      return Left(APIFailure(errorMessage: e.toString(), stackTrace: stackTrace));
    }
  }
}
