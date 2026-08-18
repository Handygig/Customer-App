enum CardBrand { visa, mastercard, amex, discover }

class PaymentCard {
  final String id;
  final String cardholderName;
  final String lastFourDigits;
  final String expiryDate; // MM/YY
  final CardBrand brand;
  final bool isDefault;
  final bool isFrozen;
  final double cardLimit;
  final List<int> gradientColors; // Hex values or Color values

  const PaymentCard({
    required this.id,
    required this.cardholderName,
    required this.lastFourDigits,
    required this.expiryDate,
    required this.brand,
    this.isDefault = false,
    this.isFrozen = false,
    this.cardLimit = 5000.0,
    this.gradientColors = const [0xFF3D4127, 0xFF636B2F],
  });

  PaymentCard copyWith({
    String? id,
    String? cardholderName,
    String? lastFourDigits,
    String? expiryDate,
    CardBrand? brand,
    bool? isDefault,
    bool? isFrozen,
    double? cardLimit,
    List<int>? gradientColors,
  }) {
    return PaymentCard(
      id: id ?? this.id,
      cardholderName: cardholderName ?? this.cardholderName,
      lastFourDigits: lastFourDigits ?? this.lastFourDigits,
      expiryDate: expiryDate ?? this.expiryDate,
      brand: brand ?? this.brand,
      isDefault: isDefault ?? this.isDefault,
      isFrozen: isFrozen ?? this.isFrozen,
      cardLimit: cardLimit ?? this.cardLimit,
      gradientColors: gradientColors ?? this.gradientColors,
    );
  }
}
