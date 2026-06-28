import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../../../../config/constants.dart';

class ChitHomePage extends StatelessWidget {
  const ChitHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KhaataTheme.backgroundGrey,
      appBar: AppBar(
        title: const Text('Chit Funds Hub', style: TextStyle(color: Colors.white)),
        backgroundColor: KhaataTheme.primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Subscriptions',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16.h),
            _buildChitCard(
              context: context,
              title: 'My Active Chits',
              subtitle: 'View ongoing groups and ledgers',
              icon: Icons.group,
              onTap: () => context.push(AppConstants.myChits),
            ),
            SizedBox(height: 12.h),
            _buildChitCard(
              context: context,
              title: 'Pending Invites',
              subtitle: 'Accept or decline invitations',
              icon: Icons.mail,
              onTap: () => context.push(AppConstants.chitInvites),
            ),
            SizedBox(height: 12.h),
            _buildChitCard(
              context: context,
              title: 'Live Auction Room',
              subtitle: 'Enter active bidding rooms',
              icon: Icons.gavel,
              color: Colors.orangeAccent.withValues(alpha: 0.2),
              iconColor: Colors.orangeAccent,
              onTap: () => context.push('/chit-live-auction'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppConstants.createChit),
        backgroundColor: KhaataTheme.primaryBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Group', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildChitCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: color ?? KhaataTheme.cardWhite,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: KhaataTheme.borderGrey),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: (iconColor ?? KhaataTheme.primaryBlue).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor ?? KhaataTheme.primaryBlue, size: 24.sp),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16.sp),
          ],
        ),
      ),
    );
  }
}
