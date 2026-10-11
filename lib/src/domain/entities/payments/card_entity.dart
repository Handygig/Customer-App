import 'package:equatable/equatable.dart';
import 'package:customer_app/src/domain/entities/profile/payment_card.dart';

export 'package:customer_app/src/domain/entities/profile/payment_card.dart' show CardBrand;

class CardEntity extends Equatable {
  final int id;
  final String cardType;
  final String maskedCardNumber;
  final String expiryDate;
  final String cardHolderName;
  final String? billingAddress;
  final bool isDefault;
  final bool isFrozen;
  final double cardLimit;

  const CardEntity({
    required this.id,
    required this.cardType,
    required this.maskedCardNumber,
    required this.expiryDate,
    required this.cardHolderName,
    this.billingAddress,
    this.isDefault = false,
    this.isFrozen = false,
    this.cardLimit = 5000.0,
  });

  // UI convenience getters
  String get cardholderName => cardHolderName;

  String get lastFourDigits {
    final digitsOnly = maskedCardNumber.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length >= 4) {
      return digitsOnly.substring(digitsOnly.length - 4);
    }
    return maskedCardNumber.length >= 4
        ? maskedCardNumber.substring(maskedCardNumber.length - 4)
        : maskedCardNumber;
  }

  CardBrand get brand {
    final lower = cardType.toLowerCase();
    if (lower.contains('visa')) return CardBrand.visa;
    if (lower.contains('master')) return CardBrand.mastercard;
    if (lower.contains('amex') || lower.contains('american')) return CardBrand.amex;
    if (lower.contains('discover')) return CardBrand.discover;
    return CardBrand.visa;
  }

  List<int> get gradientColors {
    switch (brand) {
      case CardBrand.visa:
        return const [0xFF1A1F71, 0xFF0D47A1];
      case CardBrand.mastercard:
        return const [0xFFEB001B, 0xFFF79E1B];
      case CardBrand.amex:
        return const [0xFF002663, 0xFF2E77BC];
      case CardBrand.discover:
        return const [0xFFFF6000, 0xFFFF9A00];
    }
  }

  CardEntity copyWith({
    int? id,
    String? cardType,
    String? maskedCardNumber,
    String? expiryDate,
    String? cardHolderName,
    String? billingAddress,
    bool? isDefault,
    bool? isFrozen,
    double? cardLimit,
  }) {
    return CardEntity(
      id: id ?? this.id,
      cardType: cardType ?? this.cardType,
      maskedCardNumber: maskedCardNumber ?? this.maskedCardNumber,
      expiryDate: expiryDate ?? this.expiryDate,
      cardHolderName: cardHolderName ?? this.cardHolderName,
      billingAddress: billingAddress ?? this.billingAddress,
      isDefault: isDefault ?? this.isDefault,
      isFrozen: isFrozen ?? this.isFrozen,
      cardLimit: cardLimit ?? this.cardLimit,
    );
  }

  PaymentCard toPaymentCard() {
    return PaymentCard(
      id: id.toString(),
      cardholderName: cardHolderName,
      lastFourDigits: lastFourDigits,
      expiryDate: expiryDate,
      brand: brand,
      isDefault: isDefault,
      isFrozen: isFrozen,
      cardLimit: cardLimit,
      gradientColors: gradientColors,
    );
  }

  @override
  List<Object?> get props => [
        id,
        cardType,
        maskedCardNumber,
        expiryDate,
        cardHolderName,
        billingAddress,
        isDefault,
        isFrozen,
        cardLimit,
      ];
}
