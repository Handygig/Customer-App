import 'package:flutter/material.dart';
import 'package:customer_app/core/constants/app_colors.dart';

class NotificationEntity {
  final int id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final int? relatedId;
  final String? relatedType;
  final DateTime? createdAt;

  const NotificationEntity({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    this.relatedId,
    this.relatedType,
    this.createdAt,
  });

  NotificationEntity copyWith({
    int? id,
    String? title,
    String? message,
    String? type,
    bool? isRead,
    int? relatedId,
    String? relatedType,
    DateTime? createdAt,
  }) {
    return NotificationEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      relatedId: relatedId ?? this.relatedId,
      relatedType: relatedType ?? this.relatedType,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static int _parseInt(dynamic val, [int fallback = 0]) {
    if (val == null) return fallback;
    if (val is num) return val.toInt();
    return int.tryParse(val.toString()) ?? fallback;
  }

  factory NotificationEntity.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    if (json['created_at'] != null) {
      try {
        parsedDate = DateTime.parse(json['created_at'].toString());
      } catch (_) {}
    }

    return NotificationEntity(
      id: _parseInt(json['id']),
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString().toLowerCase() ?? 'system',
      isRead: json['is_read'] == true || json['is_read'] == 1 || json['is_read'] == '1',
      relatedId: json['related_id'] != null ? _parseInt(json['related_id']) : null,
      relatedType: json['related_type']?.toString(),
      createdAt: parsedDate,
    );
  }

  String get timeAgo {
    if (createdAt == null) return 'Recently';
    final diff = DateTime.now().difference(createdAt!);
    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${(diff.inDays / 7).floor()}w ago';
    }
  }

  IconData get icon {
    switch (type) {
      case 'job':
      case 'booking':
        return Icons.event_available_rounded;
      case 'pro':
      case 'tracking':
        return Icons.near_me_rounded;
      case 'offer':
      case 'promo':
        return Icons.local_offer_rounded;
      case 'payment':
      case 'invoice':
        return Icons.receipt_long_rounded;
      case 'reward':
        return Icons.stars_rounded;
      case 'account':
        return Icons.home_work_rounded;
      case 'dispute':
        return Icons.gavel_rounded;
      case 'system':
      default:
        return Icons.notifications_active_rounded;
    }
  }

  Color get color {
    switch (type) {
      case 'job':
      case 'booking':
        return AppColors.primaryLight;
      case 'pro':
      case 'tracking':
        return AppColors.primary;
      case 'offer':
      case 'promo':
        return AppColors.accentOliveLight;
      case 'payment':
      case 'invoice':
        return AppColors.primaryDark;
      case 'reward':
        return AppColors.accentLime;
      case 'account':
        return AppColors.primary;
      case 'dispute':
        return const Color(0xFFD32F2F);
      case 'system':
      default:
        return AppColors.primary;
    }
  }
}
