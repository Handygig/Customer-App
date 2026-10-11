import 'package:customer_app/src/domain/entities/payments/card_entity.dart';

class CardModel extends CardEntity {
  const CardModel({
    required super.id,
    required super.cardType,
    required super.maskedCardNumber,
    required super.expiryDate,
    required super.cardHolderName,
    super.billingAddress,
    super.isDefault,
    super.isFrozen,
    super.cardLimit,
  });

  factory CardModel.fromJson(Map<String, dynamic> json) {
    return CardModel(
      id: _asInt(json['id']),
      cardType: json['card_type']?.toString() ?? 'visa',
      maskedCardNumber: json['masked_card_number']?.toString() ?? '',
      expiryDate: json['expiry_date']?.toString() ?? '',
      cardHolderName: json['card_holder_name']?.toString() ?? '',
      billingAddress: json['billing_address']?.toString(),
      isDefault: _asBool(json['is_default']),
      isFrozen: _asBool(json['is_frozen']),
      cardLimit: _asDouble(json['card_limit']) ?? 5000.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'card_type': cardType,
      'masked_card_number': maskedCardNumber,
      'expiry_date': expiryDate,
      'card_holder_name': cardHolderName,
      if (billingAddress != null && billingAddress!.isNotEmpty)
        'billing_address': billingAddress,
    };
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return false;
  }

  static double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
