import 'package:customer_app/src/domain/entities/payments/payment_entity.dart';
import 'package:customer_app/src/data/models/payments/card_model.dart';

class PaymentModel extends PaymentEntity {
  const PaymentModel({
    required super.id,
    required super.amount,
    super.paymentMethod,
    required super.paymentStatus,
    super.paymentDate,
    super.card,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: _asInt(json['id']),
      amount: _asDouble(json['amount']) ?? 0.0,
      paymentMethod: json['payment_method']?.toString(),
      paymentStatus: json['payment_status']?.toString() ?? 'pending',
      paymentDate: json['payment_date']?.toString(),
      card: json['card'] != null && json['card'] is Map<String, dynamic>
          ? CardModel.fromJson(json['card'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'payment_date': paymentDate,
      if (card != null && card is CardModel) 'card': (card as CardModel).toJson(),
    };
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
