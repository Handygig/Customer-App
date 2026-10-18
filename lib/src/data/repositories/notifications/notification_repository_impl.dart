import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:customer_app/core/constants/app_endpoints.dart';
import 'package:customer_app/core/di/service_locator.dart';
import 'package:customer_app/core/errors/failures.dart';
import 'package:customer_app/core/services/dio_client.dart';
import 'package:customer_app/core/services/network_service.dart';
import 'package:customer_app/src/domain/entities/notifications/notification_entity.dart';
import 'package:customer_app/src/domain/repositories/notifications/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final Dio _dio;
  final NetworkService? _networkService;

  static NotificationRepositoryImpl? _instance;

  factory NotificationRepositoryImpl([Dio? dio, NetworkService? networkService]) {
    _instance ??= NotificationRepositoryImpl._internal(
      dio ?? (sl.isRegistered<Dio>() ? sl<Dio>() : DioClient.create()),
      networkService ??
          (sl.isRegistered<NetworkService>() ? sl<NetworkService>() : null),
    );
    return _instance!;
  }

  NotificationRepositoryImpl._internal(this._dio, this._networkService);

  List<NotificationEntity> _cachedNotifications = [];

  @override
  Future<Either<Failure, List<NotificationEntity>>> getNotifications({
    String? type,
    bool? unreadOnly,
  }) async {
    if (_networkService != null && !await _networkService.isConnected()) {
      return Right(_cachedNotifications);
    }

    try {
      final queryParams = <String, dynamic>{};
      if (type != null && type.isNotEmpty && type != 'all') {
        queryParams['type'] = type;
      }
      if (unreadOnly == true) {
        queryParams['unread_only'] = true;
      }

      final response = await _dio.get(
        AppEndpoints.customerNotifications,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final rawData = response.data;
      List<dynamic> items = [];
      if (rawData is Map && rawData['data'] is List) {
        items = rawData['data'] as List<dynamic>;
      } else if (rawData is List) {
        items = rawData;
      }

      _cachedNotifications = items
          .map((e) => NotificationEntity.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      return Right(_cachedNotifications);
    } on DioException catch (e) {
      debugPrint('⚠️ [NotificationRepositoryImpl.getNotifications] DioException: ${e.message}');
      if (_cachedNotifications.isNotEmpty) {
        return Right(_cachedNotifications);
      }
      final msg = (e.response?.data is Map && e.response?.data['message'] != null)
          ? e.response!.data['message'].toString()
          : (e.message ?? 'Failed to load notifications');
      return Left(APIFailure(errorMessage: msg));
    } catch (e, stackTrace) {
      debugPrint('⚠️ [NotificationRepositoryImpl.getNotifications] Error: $e');
      if (_cachedNotifications.isNotEmpty) {
        return Right(_cachedNotifications);
      }
      return Left(APIFailure(errorMessage: e.toString(), stackTrace: stackTrace));
    }
  }

  @override
  Future<Either<Failure, void>> markAsRead(int id) async {
    try {
      await _dio.patch(AppEndpoints.customerNotificationRead(id));

      _cachedNotifications = _cachedNotifications.map((n) {
        if (n.id == id) {
          return n.copyWith(isRead: true);
        }
        return n;
      }).toList();

      return const Right(null);
    } on DioException catch (e) {
      final msg = (e.response?.data is Map && e.response?.data['message'] != null)
          ? e.response!.data['message'].toString()
          : (e.message ?? 'Failed to mark notification as read');
      return Left(APIFailure(errorMessage: msg));
    } catch (e, stackTrace) {
      return Left(APIFailure(errorMessage: e.toString(), stackTrace: stackTrace));
    }
  }

  @override
  Future<Either<Failure, void>> markAllAsRead() async {
    try {
      await _dio.post(AppEndpoints.customerMarkAllNotificationsRead);

      _cachedNotifications = _cachedNotifications.map((n) {
        return n.copyWith(isRead: true);
      }).toList();

      return const Right(null);
    } on DioException catch (e) {
      final msg = (e.response?.data is Map && e.response?.data['message'] != null)
          ? e.response!.data['message'].toString()
          : (e.message ?? 'Failed to mark all as read');
      return Left(APIFailure(errorMessage: msg));
    } catch (e, stackTrace) {
      return Left(APIFailure(errorMessage: e.toString(), stackTrace: stackTrace));
    }
  }

  @override
  Future<Either<Failure, void>> deleteNotification(int id) async {
    try {
      await _dio.delete(AppEndpoints.customerNotificationDelete(id));

      _cachedNotifications.removeWhere((n) => n.id == id);

      return const Right(null);
    } on DioException catch (e) {
      final msg = (e.response?.data is Map && e.response?.data['message'] != null)
          ? e.response!.data['message'].toString()
          : (e.message ?? 'Failed to delete notification');
      return Left(APIFailure(errorMessage: msg));
    } catch (e, stackTrace) {
      return Left(APIFailure(errorMessage: e.toString(), stackTrace: stackTrace));
    }
  }
}
