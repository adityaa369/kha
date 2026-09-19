import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../config/theme.dart';
import '../../../../data/models/notification_model.dart';
import '../cubit/notification_cubit.dart';
import '../cubit/notification_state.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<NotificationCubit>().fetchNotifications();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<NotificationCubit>().loadMoreNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KhaataTheme.backgroundGrey,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          _CategoryTabBar(),
          Expanded(child: _NotificationList(scrollController: _scrollController)),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(
        'Notifications',
        style: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.w700,
          color: KhaataTheme.textDark,
        ),
      ),
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: KhaataTheme.textDark,
      actions: [
        BlocBuilder<NotificationCubit, NotificationState>(
          builder: (context, state) {
            if (state is NotificationLoaded && state.unreadCount > 0) {
              return TextButton(
                onPressed: () => context.read<NotificationCubit>().markAllAsRead(),
                child: Text(
                  'Mark all read',
                  style: TextStyle(
                    color: KhaataTheme.primaryBlue,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}

class _CategoryTabBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationCubit, NotificationState>(
      builder: (context, state) {
        final selected = state is NotificationLoaded
            ? state.selectedCategory
            : NotificationCategory.all;

        final tabs = [
          (NotificationCategory.all, 'All'),
          (NotificationCategory.loans, 'Loans'),
          (NotificationCategory.payments, 'Payments'),
          (NotificationCategory.security, 'Security'),
          (NotificationCategory.kyc, 'KYC'),
          (NotificationCategory.chitFunds, 'Chit Funds'),
        ];

        return Container(
          color: Colors.white,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            child: Row(
              children: tabs.map((tab) {
                final isSelected = selected == tab.$1;
                return Padding(
                  padding: EdgeInsets.only(right: 8.w),
                  child: GestureDetector(
                    onTap: () => context
                        .read<NotificationCubit>()
                        .selectCategory(tab.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? KhaataTheme.primaryBlue
                            : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        tab.$2,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : KhaataTheme.textGrey,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}

class _NotificationList extends StatelessWidget {
  final ScrollController scrollController;
  const _NotificationList({required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationCubit, NotificationState>(
      builder: (context, state) {
        if (state is NotificationLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is NotificationLoaded) {
          final notifications = state.notifications;

          if (notifications.isEmpty) {
            return _EmptyState();
          }

          // Group by date bucket
          final grouped = _groupByDate(notifications);
          final sections = grouped.entries.toList();

          return ListView.builder(
            controller: scrollController,
            padding: EdgeInsets.only(bottom: 24.h, top: 8.h),
            itemCount: sections.length + (state.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == sections.length) {
                return Padding(
                  padding: EdgeInsets.all(16.h),
                  child: const Center(child: CircularProgressIndicator()),
                );
              }
              final section = sections[index];
              return _DateSection(
                dateLabel: section.key,
                notifications: section.value,
              );
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Map<String, List<NotificationModel>> _groupByDate(
      List<NotificationModel> notifications) {
    final Map<String, List<NotificationModel>> groups = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final n in notifications) {
      final date = DateTime(
          n.createdAt.year, n.createdAt.month, n.createdAt.day);
      String label;
      if (date == today) {
        label = 'Today';
      } else if (date == yesterday) {
        label = 'Yesterday';
      } else {
        label = DateFormat('d MMMM yyyy').format(n.createdAt);
      }
      groups.putIfAbsent(label, () => []).add(n);
    }
    return groups;
  }
}

class _DateSection extends StatelessWidget {
  final String dateLabel;
  final List<NotificationModel> notifications;

  const _DateSection({
    required this.dateLabel,
    required this.notifications,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 6.h),
          child: Text(
            dateLabel,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: KhaataTheme.textGrey,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...notifications.asMap().entries.map(
          (entry) => _NotificationTile(
            notification: entry.value,
            isLast: entry.key == notifications.length - 1,
          ),
        ),
      ],
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final bool isLast;

  const _NotificationTile({
    required this.notification,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final n = notification;
    return GestureDetector(
      onTap: () {
        context.read<NotificationCubit>().markAsRead(n);
        _handleDeepLink(context, n);
      },
      child: Container(
        color: n.isRead ? Colors.white : const Color(0xFFF0FDF4),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon circle
                  Container(
                    width: 42.w,
                    height: 42.w,
                    decoration: BoxDecoration(
                      color: _iconBg(n.eventType),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _iconFor(n.eventType),
                      color: _iconColor(n.eventType),
                      size: 20.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                n.title,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: n.isRead
                                      ? FontWeight.w500
                                      : FontWeight.w700,
                                  color: KhaataTheme.textDark,
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            if (!n.isRead)
                              Container(
                                width: 8.w,
                                height: 8.w,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: KhaataTheme.primaryBlue,
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 3.h),
                        Text(
                          n.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: KhaataTheme.textGrey,
                            height: 1.4,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          _formatTime(n.createdAt),
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: KhaataTheme.textGrey.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (!isLast)
              Divider(
                height: 1,
                indent: 70.w,
                color: KhaataTheme.borderGrey,
              ),
          ],
        ),
      ),
    );
  }

  void _handleDeepLink(BuildContext context, NotificationModel n) {
    // Deep link routing — Phase 8
    final loanId = n.referenceId ?? n.data['loanId'];
    switch (n.eventType) {
      case 'LOAN_CREATED':
      case 'LOAN_RECEIVED':
      case 'AGREEMENT_READY':
      case 'AGREEMENT_ACCEPTED':
      case 'LOAN_ACTIVATED':
      case 'PAYMENT_RECEIVED':
      case 'PAYMENT_FAILED':
      case 'LOAN_COMPLETED':
      case 'LOAN_CLOSED':
        if (loanId != null && loanId is String && loanId.isNotEmpty) {
          Navigator.of(context).pushNamed('/loan-details', arguments: loanId);
        }
        break;
      default:
        break;
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dtDay = DateTime(dt.year, dt.month, dt.day);
    if (dtDay == today) return DateFormat.jm().format(dt);
    return DateFormat('d MMM, ').format(dt) + DateFormat.jm().format(dt);
  }

  IconData _iconFor(String eventType) {
    switch (eventType) {
      case 'LOAN_CREATED':
      case 'LOAN_RECEIVED':
        return Icons.handshake_outlined;
      case 'AGREEMENT_READY':
        return Icons.description_outlined;
      case 'AGREEMENT_ACCEPTED':
      case 'LOAN_ACTIVATED':
        return Icons.check_circle_outline;
      case 'PAYMENT_RECEIVED':
        return Icons.payments_outlined;
      case 'PAYMENT_FAILED':
        return Icons.money_off_outlined;
      case 'LOAN_COMPLETED':
      case 'LOAN_CLOSED':
        return Icons.task_alt_outlined;
      case 'EMAIL_VERIFIED':
        return Icons.mark_email_read_outlined;
      case 'MPIN_CREATED':
      case 'ACCOUNT_CREATED':
        return Icons.lock_outline;
      case 'CHIT_INVITE':
      case 'CHIT_JOINED':
      case 'AUCTION_OPENED':
      case 'AUCTION_CLOSED':
      case 'CHIT_PAYOUT':
        return Icons.group_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _iconBg(String eventType) {
    switch (eventType) {
      case 'PAYMENT_RECEIVED':
      case 'LOAN_COMPLETED':
      case 'LOAN_CLOSED':
      case 'AGREEMENT_ACCEPTED':
      case 'LOAN_ACTIVATED':
        return const Color(0xFFD1FAE5);
      case 'PAYMENT_FAILED':
        return const Color(0xFFFEE2E2);
      case 'AGREEMENT_READY':
      case 'LOAN_CREATED':
      case 'LOAN_RECEIVED':
        return const Color(0xFFFEF3C7);
      case 'EMAIL_VERIFIED':
      case 'MPIN_CREATED':
      case 'ACCOUNT_CREATED':
        return const Color(0xFFE0F2FE);
      case 'CHIT_INVITE':
      case 'CHIT_JOINED':
      case 'AUCTION_OPENED':
      case 'AUCTION_CLOSED':
      case 'CHIT_PAYOUT':
        return const Color(0xFFEDE9FE);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  Color _iconColor(String eventType) {
    switch (eventType) {
      case 'PAYMENT_RECEIVED':
      case 'LOAN_COMPLETED':
      case 'LOAN_CLOSED':
      case 'AGREEMENT_ACCEPTED':
      case 'LOAN_ACTIVATED':
        return const Color(0xFF059669);
      case 'PAYMENT_FAILED':
        return const Color(0xFFDC2626);
      case 'AGREEMENT_READY':
      case 'LOAN_CREATED':
      case 'LOAN_RECEIVED':
        return const Color(0xFFD97706);
      case 'EMAIL_VERIFIED':
      case 'MPIN_CREATED':
      case 'ACCOUNT_CREATED':
        return const Color(0xFF0284C7);
      case 'CHIT_INVITE':
      case 'CHIT_JOINED':
      case 'AUCTION_OPENED':
      case 'AUCTION_CLOSED':
      case 'CHIT_PAYOUT':
        return const Color(0xFF7C3AED);
      default:
        return KhaataTheme.textGrey;
    }
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_outlined,
            size: 64.sp,
            color: KhaataTheme.borderGrey,
          ),
          SizedBox(height: 16.h),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: KhaataTheme.textGrey,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Loan and payment updates\nwill appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.sp,
              color: KhaataTheme.textGrey.withValues(alpha: 0.7),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
