import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/constants.dart';
import '../../../../config/theme.dart';
import '../../../../core/widgets/buttons.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              SizedBox(height: 60.h),
              Text(
                'Welcome to',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: KhaataTheme.textGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                AppConstants.appName,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: KhaataTheme.primaryBlue,
                  fontSize: 40.sp,
                ),
              ),
              SizedBox(height: 12.h),
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: KhaataTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 60.h),
              Row(
                children: [
                  Expanded(
                    child: _FeatureCard(
                      icon: Icons.handshake_rounded,
                      title: 'Digital Loan Agreements',
                      color: KhaataTheme.primaryBlue,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: _FeatureCard(
                      icon: Icons.verified_user_rounded,
                      title: 'Legally Binding & Secure',
                      color: KhaataTheme.accentGreen,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: _FeatureCard(
                      icon: Icons.track_changes_rounded,
                      title: 'Track Repayments',
                      color: KhaataTheme.warningYellow,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: _FeatureCard(
                      icon: Icons.notifications_active_rounded,
                      title: 'Timely Reminders',
                      color: KhaataTheme.secondaryBlue,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              PrimaryButton(
                text: 'Get Started',
                onPressed: () => context.push(AppConstants.login),
              ),
              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28.sp),
          ),
          SizedBox(height: 12.h),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: KhaataTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }
}