import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/theme.dart';
import '../../../../data/models/notification_model.dart';
import '../cubit/notification_cubit.dart';
import '../cubit/notification_state.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KhaataTheme.backgroundGrey,
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: KhaataTheme.textDark,
      ),
      body: BlocBuilder<NotificationCubit, NotificationState>(
        builder: (context, state) {
          if (state is NotificationLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          List<NotificationModel> notifications = [];
          if (state is NotificationLoaded) {
            notifications = state.notifications;
          }

          return RefreshIndicator(
            onRefresh: () => context.read<NotificationCubit>().fetchNotifications(),
            color: KhaataTheme.primaryBlue,
            child: notifications.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: 100.h),
                      Icon(
                        Icons.notifications_off_outlined,
                        size: 64.sp,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16.h),
                      Center(
                        child: Text(
                          'No new notifications',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: KhaataTheme.textGrey,
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(16.w),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notif = notifications[index];
                      return _NotificationTile(
                        notification: notif,
                        onTap: () => context.read<NotificationCubit>().markAsRead(notif, index),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isRead = notification.isRead;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : const Color(0xFFF0F7FF), // slight blue tint if unread
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isRead ? Colors.grey.shade200 : KhaataTheme.primaryBlue.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: isRead ? Colors.grey.shade100 : KhaataTheme.primaryBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIcon(notification.type),
                color: isRead ? Colors.grey : KhaataTheme.primaryBlue,
                size: 24.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                            color: KhaataTheme.textDark,
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8.w,
                          height: 8.w,
                          decoration: const BoxDecoration(
                            color: KhaataTheme.primaryBlue,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    notification.body,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: isRead ? Colors.grey.shade600 : Colors.black87,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    _formatTime(notification.createdAt),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'LOAN_INIT_OTP':
      case 'OTP':
        return Icons.security;
      case 'PAYMENT':
        return Icons.payment;
      case 'CREDIT':
        return Icons.account_balance_wallet;
      case 'LOAN_APPROVED':
        return Icons.check_circle_outline;
      default:
        return Icons.notifications_none;
    }
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes}m ago';
      }
      return '${diff.inHours}h ago';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    }
    return DateFormat('MMM d, yyyy').format(date);
  }
}
