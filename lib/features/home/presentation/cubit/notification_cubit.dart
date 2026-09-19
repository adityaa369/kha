import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart';
import '../../../../data/models/notification_model.dart';
import 'notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  final ApiClient _api;

  NotificationCubit(this._api) : super(NotificationInitial());

  /// Fetch first page of notifications, optionally filtered by category
  Future<void> fetchNotifications({
    NotificationCategory category = NotificationCategory.all,
  }) async {
    try {
      emit(NotificationLoading());
      final categoryParam = _categoryToParam(category);
      final query = categoryParam != null ? '?eventCategory=$categoryParam' : '';
      final res = await _api.get('/notifications$query');

      final data = res.data;
      if (data != null && data is Map) {
        final list = (data['notifications'] as List? ?? [])
            .map((e) => NotificationModel.fromJson(e))
            .toList();
        emit(NotificationLoaded(
          notifications: list,
          unreadCount: (data['unreadCount'] as num?)?.toInt() ?? 0,
          selectedCategory: category,
          hasMore: data['pagination']?['hasMore'] == true,
          currentPage: 1,
        ));
      } else {
        emit(const NotificationLoaded(notifications: []));
      }
    } catch (_) {
      emit(const NotificationLoaded(notifications: []));
    }
  }

  /// Load the next page and append
  Future<void> loadMoreNotifications() async {
    final current = state;
    if (current is! NotificationLoaded || !current.hasMore) return;

    final nextPage = current.currentPage + 1;
    final categoryParam = _categoryToParam(current.selectedCategory);
    final query = StringBuffer('?page=$nextPage&limit=20');
    if (categoryParam != null) query.write('&eventCategory=$categoryParam');

    try {
      final res = await _api.get('/notifications$query');
      final data = res.data;
      if (data != null && data is Map) {
        final more = (data['notifications'] as List? ?? [])
            .map((e) => NotificationModel.fromJson(e))
            .toList();
        emit(current.copyWith(
          notifications: [...current.notifications, ...more],
          hasMore: data['pagination']?['hasMore'] == true,
          currentPage: nextPage,
        ));
      }
    } catch (_) {
      // Silently ignore load-more failures
    }
  }

  /// Change category tab
  Future<void> selectCategory(NotificationCategory category) async {
    if (state is NotificationLoaded &&
        (state as NotificationLoaded).selectedCategory == category) {
      return;
    }
    await fetchNotifications(category: category);
  }

  /// Mark a single notification as read (optimistic)
  Future<void> markAsRead(NotificationModel notif) async {
    if (notif.isRead) return;
    final current = state;
    if (current is! NotificationLoaded) return;

    final updated = current.notifications
        .map((n) => n.id == notif.id ? n.copyWith(isRead: true, readAt: DateTime.now()) : n)
        .toList();
    final newUnread = (current.unreadCount - 1).clamp(0, 99999);
    emit(current.copyWith(notifications: updated, unreadCount: newUnread));

    try {
      await _api.put('/notifications/${notif.id}/read', data: {});
    } catch (_) {
      // Revert on failure
      emit(current);
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    final current = state;
    if (current is! NotificationLoaded) return;

    final updated = current.notifications
        .map((n) => n.copyWith(isRead: true, readAt: DateTime.now()))
        .toList();
    emit(current.copyWith(notifications: updated, unreadCount: 0));

    try {
      await _api.put('/notifications/read-all', data: {});
    } catch (_) {
      emit(current);
    }
  }

  /// Poll unread count only (for badge in nav bar)
  Future<int> fetchUnreadCount() async {
    try {
      final res = await _api.get('/notifications/unread-count');
      final count = (res.data?['count'] as num?)?.toInt() ?? 0;
      if (state is NotificationLoaded) {
        emit((state as NotificationLoaded).copyWith(unreadCount: count));
      }
      return count;
    } catch (_) {
      return 0;
    }
  }

  String? _categoryToParam(NotificationCategory cat) {
    switch (cat) {
      case NotificationCategory.loans:
        return 'LOANS';
      case NotificationCategory.payments:
        return 'PAYMENTS';
      case NotificationCategory.security:
        return 'SECURITY';
      case NotificationCategory.kyc:
        return 'KYC';
      case NotificationCategory.chitFunds:
        return 'CHIT_FUNDS';
      case NotificationCategory.all:
        return null;
    }
  }
}
