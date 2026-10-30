import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:customer_app/src/domain/entities/notifications/notification_entity.dart';
import 'package:customer_app/src/domain/repositories/notifications/notification_repository.dart';
import 'package:customer_app/src/presentation/cubits/notifications/notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  final NotificationRepository _repository;

  NotificationCubit(this._repository) : super(const NotificationInitial());

  List<NotificationEntity> _allNotifications = [];
  String _currentFilter = 'all';

  int get unreadCount => _allNotifications.where((n) => !n.isRead).length;

  Future<void> loadNotifications({bool showLoading = true}) async {
    if (showLoading && state is! NotificationLoaded) {
      emit(const NotificationLoading());
    }

    final result = await _repository.getNotifications();
    result.fold(
      (failure) {
        if (state is! NotificationLoaded) {
          emit(NotificationError(failure.errorMessage));
        }
      },
      (notifications) {
        _allNotifications = notifications;
        _emitFiltered();
      },
    );
  }

  void setFilter(String filter) {
    _currentFilter = filter;
    _emitFiltered();
  }

  void _emitFiltered() {
    List<NotificationEntity> filtered;
    if (_currentFilter == 'unread') {
      filtered = _allNotifications.where((n) => !n.isRead).toList();
    } else if (_currentFilter == 'all') {
      filtered = List.from(_allNotifications);
    } else if (_currentFilter == 'job') {
      filtered = _allNotifications
          .where((n) =>
              n.type == 'job' ||
              n.type == 'quotation' ||
              n.type == 'booking')
          .toList();
    } else {
      filtered = _allNotifications.where((n) => n.type == _currentFilter).toList();
    }

    emit(NotificationLoaded(
      notifications: filtered,
      activeFilter: _currentFilter,
      unreadCount: unreadCount,
    ));
  }

  Future<void> markAsRead(int id) async {
    // Optimistic update
    _allNotifications = _allNotifications.map((n) {
      if (n.id == id) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();
    _emitFiltered();

    await _repository.markAsRead(id);
  }

  Future<void> markAllAsRead() async {
    // Optimistic update
    _allNotifications = _allNotifications.map((n) => n.copyWith(isRead: true)).toList();
    _emitFiltered();

    await _repository.markAllAsRead();
  }

  Future<void> deleteNotification(int id) async {
    // Optimistic update
    _allNotifications.removeWhere((n) => n.id == id);
    _emitFiltered();

    await _repository.deleteNotification(id);
  }
}
