import 'package:equatable/equatable.dart';
import '../../../../data/models/notification_model.dart';

abstract class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {}

class NotificationLoading extends NotificationState {}

class NotificationLoaded extends NotificationState {
  final List<NotificationModel> notifications;
  final int unreadCount;
  final NotificationCategory selectedCategory;
  final bool hasMore;
  final int currentPage;

  const NotificationLoaded({
    required this.notifications,
    this.unreadCount = 0,
    this.selectedCategory = NotificationCategory.all,
    this.hasMore = false,
    this.currentPage = 1,
  });

  NotificationLoaded copyWith({
    List<NotificationModel>? notifications,
    int? unreadCount,
    NotificationCategory? selectedCategory,
    bool? hasMore,
    int? currentPage,
  }) {
    return NotificationLoaded(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  @override
  List<Object?> get props => [notifications, unreadCount, selectedCategory, hasMore, currentPage];
}

class NotificationError extends NotificationState {
  final String message;

  const NotificationError(this.message);

  @override
  List<Object?> get props => [message];
}
