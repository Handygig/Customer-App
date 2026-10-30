import 'package:flutter/material.dart';
import 'package:customer_app/core/constants/app_colors.dart';

class ExclusiveOffer {
  final int id;
  final String title;
  final String description;
  final String badge;
  final String code;
  final String discountText;
  final String discountType;
  final double discountValue;
  final double? minSpend;
  final List<Color> gradientColors;
  final Color accentColor;
  final IconData icon;
  final String? terms;

  const ExclusiveOffer({
    required this.id,
    required this.title,
    required this.description,
    required this.badge,
    required this.code,
    required this.discountText,
    required this.discountType,
    required this.discountValue,
    this.minSpend,
    required this.gradientColors,
    required this.accentColor,
    required this.icon,
    this.terms,
  });

  static double _parseDouble(dynamic val, [double fallback = 0.0]) {
    if (val == null) return fallback;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? fallback;
  }

  static double? _parseNullableDouble(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString());
  }

  static int _parseInt(dynamic val, [int fallback = 0]) {
    if (val == null) return fallback;
    if (val is num) return val.toInt();
    return int.tryParse(val.toString()) ?? fallback;
  }

  static Color _parseColor(String? hexString, Color fallback) {
    if (hexString == null || hexString.isEmpty) return fallback;
    try {
      final hex = hexString.replaceAll('#', '').trim();
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    } catch (_) {}
    return fallback;
  }

  static IconData _parseIcon(String? iconName) {
    switch (iconName?.toLowerCase().trim()) {
      case 'yard_rounded':
      case 'yard':
        return Icons.yard_rounded;
      case 'shield_rounded':
      case 'shield':
        return Icons.shield_rounded;
      case 'build':
      case 'wrench':
        return Icons.build_rounded;
      case 'cleaning_services':
      case 'clean':
        return Icons.cleaning_services_rounded;
      case 'auto_awesome_rounded':
      case 'sparkles':
      default:
        return Icons.auto_awesome_rounded;
    }
  }

  factory ExclusiveOffer.fromJson(Map<String, dynamic> json) {
    final startColor = _parseColor(
      json['gradient_start']?.toString(),
      AppColors.primaryDark,
    );
    final endColor = _parseColor(
      json['gradient_end']?.toString(),
      AppColors.primary,
    );
    final accent = _parseColor(
      json['accent_color']?.toString(),
      AppColors.accentLime,
    );

    final discountVal = _parseDouble(json['discount_value']);
    final discountType = json['discount_type']?.toString() ?? 'percentage';
    String discountTxt = json['discount_text']?.toString() ?? '';
    if (discountTxt.isEmpty) {
      if (discountType == 'percentage') {
        discountTxt = '${discountVal.toInt()}% OFF';
      } else {
        discountTxt = 'LKR ${discountVal.toStringAsFixed(0)} OFF';
      }
    }

    return ExclusiveOffer(
      id: _parseInt(json['id']),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      badge: json['badge']?.toString() ?? 'EXCLUSIVE OFFER',
      code: json['code']?.toString() ?? '',
      discountText: discountTxt,
      discountType: discountType,
      discountValue: discountVal,
      minSpend: _parseNullableDouble(json['min_spend']),
      gradientColors: [startColor, endColor],
      accentColor: accent,
      icon: _parseIcon(json['icon_name']?.toString()),
      terms: json['terms']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'badge': badge,
      'code': code,
      'discount': discountText,
      'discount_type': discountType,
      'discount_value': discountValue,
      'min_spend': minSpend,
      'gradient': gradientColors,
      'accent': accentColor,
      'icon': icon,
      'terms': terms,
    };
  }
}
