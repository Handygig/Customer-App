import 'package:equatable/equatable.dart';
import 'package:customer_app/src/domain/entities/notifications/notification_entity.dart';

abstract class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {
  const NotificationInitial();
}

class NotificationLoading extends NotificationState {
  const NotificationLoading();
}

class NotificationLoaded extends NotificationState {
  final List<NotificationEntity> notifications;
  final String activeFilter; // 'all', 'unread', 'job', 'offer', 'reward', 'system'
  final int unreadCount;

  const NotificationLoaded({
    required this.notifications,
    this.activeFilter = 'all',
    required this.unreadCount,
  });

  NotificationLoaded copyWith({
    List<NotificationEntity>? notifications,
    String? activeFilter,
    int? unreadCount,
  }) {
    return NotificationLoaded(
      notifications: notifications ?? this.notifications,
      activeFilter: activeFilter ?? this.activeFilter,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  @override
  List<Object?> get props => [notifications, activeFilter, unreadCount];
}

class NotificationError extends NotificationState {
  final String message;

  const NotificationError(this.message);

  @override
  List<Object?> get props => [message];
}
