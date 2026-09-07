import 'package:khatha/core/utils/error_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../../config/theme.dart';
import '../../../../core/blocs/security/security_cubit.dart';
import '../../../../data/models/session_model.dart';
import '../../../../data/models/security_event_model.dart';

class SecurityHubPage extends StatefulWidget {
  const SecurityHubPage({super.key});

  @override
  State<SecurityHubPage> createState() => _SecurityHubPageState();
}

class _SecurityHubPageState extends State<SecurityHubPage> {
  @override
  void initState() {
    super.initState();
    context.read<SecurityCubit>().loadSecurityData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KhaataTheme.backgroundGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Security & Sessions',
          style: TextStyle(
            color: KhaataTheme.primaryBlue,
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<SecurityCubit, SecurityState>(
        listener: (context, state) {
          if (state.error != null) {
            ErrorHandler.showError(context, state.error!);
          }
        },
        builder: (context, state) {
          if (state.isLoading && state.sessions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final currentSession = state.sessions
              .where((s) => s.isCurrent)
              .firstOrNull;
          final otherSessions = state.sessions
              .where((s) => !s.isCurrent)
              .toList();

          return RefreshIndicator(
            onRefresh: () => context.read<SecurityCubit>().loadSecurityData(),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (currentSession != null) ...[
                    _buildSectionTitle('Your Current Session'),
                    _buildSessionCard(context, currentSession),
                    SizedBox(height: 24.h),
                  ],
                  if (otherSessions.isNotEmpty) ...[
                    _buildSectionTitle('Active Sessions'),
                    ...otherSessions.map((s) => _buildSessionCard(context, s)),
                    SizedBox(height: 12.h),
                    _buildRevokeOthersButton(context),
                    SizedBox(height: 24.h),
                  ],
                  if (state.events.isNotEmpty) ...[
                    _buildSectionTitle('Recent Security Activity'),
                    _buildSecurityEvents(state.events),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildSessionCard(BuildContext context, SessionModel session) {
    final bool isCurrent = session.isCurrent;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isCurrent ? KhaataTheme.primaryBlue : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: isCurrent ? Colors.blue.shade50 : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.devices,
              color: isCurrent ? KhaataTheme.primaryBlue : Colors.grey.shade600,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (isCurrent)
                      Container(
                        margin: EdgeInsets.only(right: 8.w),
                        width: 8.w,
                        height: 8.w,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                    Expanded(
                      child: Text(
                        session.deviceInfo,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  isCurrent
                      ? 'Current device \u2022 Active now'
                      : 'Last active: ${_formatDate(session.lastUsedAt)}',
                  style: TextStyle(fontSize: 12.sp, color: Colors.black54),
                ),
              ],
            ),
          ),
          if (!isCurrent)
            IconButton(
              icon: Icon(Icons.logout, color: Colors.red.shade700, size: 20.sp),
              onPressed: () => _confirmRevoke(context, session.id),
              tooltip: 'Revoke Session',
            ),
        ],
      ),
    );
  }

  Widget _buildRevokeOthersButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _confirmRevokeOthers(context),
        icon: Icon(Icons.power_settings_new, size: 18.sp),
        label: const Text('Sign out of all other devices'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red.shade700,
          side: BorderSide(color: Colors.red.shade200),
          padding: EdgeInsets.symmetric(vertical: 14.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityEvents(List<SecurityEventModel> events) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: events.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: Colors.grey.shade100),
        itemBuilder: (context, index) {
          final event = events[index];
          IconData icon;
          Color color;

          if (event.result == 'FAILED') {
            icon = Icons.warning_amber_rounded;
            color = Colors.orange;
          } else if (event.eventType.contains('REVOKED') ||
              event.eventType.contains('LOGOUT')) {
            icon = Icons.logout;
            color = Colors.blueGrey;
          } else {
            icon = Icons.check_circle_outline;
            color = Colors.green;
          }

          return ListTile(
            leading: Icon(icon, color: color, size: 20.sp),
            title: Text(
              _formatEventType(event.eventType),
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            subtitle: Text(
              _formatDate(event.createdAt),
              style: TextStyle(fontSize: 11.sp, color: Colors.black54),
            ),
            dense: true,
          );
        },
      ),
    );
  }

  String _formatEventType(String type) {
    return type
        .replaceAll('_', ' ')
        .toLowerCase()
        .split(' ')
        .map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';

    return DateFormat('MMM d, h:mm a').format(date);
  }

  void _confirmRevoke(BuildContext context, String sessionId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Revoke Session'),
        content: const Text('Are you sure you want to sign out this device?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<SecurityCubit>().revokeSession(sessionId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _confirmRevokeOthers(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out of all other devices'),
        content: const Text(
          'This will sign you out of every other active device. Your current device will remain signed in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<SecurityCubit>().revokeOtherSessions();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sign Out Other Devices'),
          ),
        ],
      ),
    );
  }
}
