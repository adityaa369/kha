import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart';
import '../../../../data/models/notification_model.dart';
import 'notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  final ApiClient _api;

  NotificationCubit(this._api) : super(NotificationInitial());

  Future<void> fetchNotifications() async {
    try {
      emit(NotificationLoading());
      final res = await _api.get('/notifications');
      if (res.data != null && res.data is List) {
        final notifications = (res.data as List)
            .map((e) => NotificationModel.fromJson(e))
            .toList();
        emit(NotificationLoaded(notifications));
      } else {
        emit(const NotificationLoaded([]));
      }
    } catch (e) {
      // Gracefully handle errors like DioException (e.g., API not deployed yet)
      // We don't throw an aggressive popup for background fetches
      emit(const NotificationLoaded([]));
    }
  }

  Future<void> markAsRead(NotificationModel notif, int index) async {
    if (state is NotificationLoaded) {
      final currentNotifs = List<NotificationModel>.from(
        (state as NotificationLoaded).notifications,
      );
      if (notif.isRead) return;

      try {
        // Optimistic UI update
        currentNotifs[index] = NotificationModel(
          id: notif.id,
          title: notif.title,
          body: notif.body,
          type: notif.type,
          isRead: true,
          createdAt: notif.createdAt,
          data: notif.data,
        );
        emit(NotificationLoaded(currentNotifs));

        await _api.put('/notifications/${notif.id}/read', data: {});
      } catch (e) {
        // Revert on failure
        currentNotifs[index] = notif;
        emit(NotificationLoaded(currentNotifs));
      }
    }
  }
}
