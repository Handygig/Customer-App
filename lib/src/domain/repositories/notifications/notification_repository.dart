import 'package:dartz/dartz.dart';
import 'package:customer_app/core/errors/failures.dart';
import 'package:customer_app/src/domain/entities/notifications/notification_entity.dart';

abstract class NotificationRepository {
  Future<Either<Failure, List<NotificationEntity>>> getNotifications({
    String? type,
    bool? unreadOnly,
  });

  Future<Either<Failure, void>> markAsRead(int id);

  Future<Either<Failure, void>> markAllAsRead();

  Future<Either<Failure, void>> deleteNotification(int id);
}
