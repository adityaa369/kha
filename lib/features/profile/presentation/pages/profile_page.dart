import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/constants.dart';
import '../../../../config/theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/blocs/auth/auth_cubit.dart';
import '../../../../core/blocs/loans/loan_cubit.dart';
import '../../../../core/widgets/looping_avatar.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Header with curved bottom
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: KhaataTheme.primaryBlue,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20.r),
                  bottomRight: Radius.circular(20.r),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white, size: 22.sp),
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Text(
                      'Profile',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: 40.w),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  children: [
                    // Profile Header Card
                    Container(
                      padding: EdgeInsets.all(24.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: BlocBuilder<AuthCubit, AuthState>(
                        builder: (context, state) {
                          String initials = '';
                          String fullName = 'Loading...';
                          String? gender;
                          
                          if (state is AuthenticatedFull) {
                            initials = state.user.initials;
                            fullName = state.user.displayName;
                            gender = state.user.gender;
                          } else if (state is AuthenticatedUnverified) {
                            initials = 'U';
                            fullName = 'Verified User';
                          }

                          return Column(
                            children: [
                              Container(
                                width: 72.w,
                                height: 72.w,
                                decoration: const BoxDecoration(
                                  color: Colors.transparent,
                                  shape: BoxShape.circle,
                                ),
                                child: LoopingAvatar(gender: gender, height: 72.w),
                              ),
                              SizedBox(height: 12.h),
                              Text(
                                fullName,
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    SizedBox(height: 20.h),

                    // Menu Items
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _MenuTile(
                            icon: Icons.person_outline,
                            title: 'Personal Details',
                            subtitle: 'Email, Gender, Pan, DOB, Address',
                            onTap: () => _showComingSoon(context, 'Personal Details'),
                          ),
                          Divider(height: 1, indent: 56.w, color: Colors.grey[200]),
                          _MenuTile(
                            icon: Icons.account_balance_outlined,
                            title: 'Bank Account',
                            subtitle: 'Manage your linked bank accounts',
                            onTap: () => _showComingSoon(context, 'Bank Account Manager'),
                          ),
                          Divider(height: 1, indent: 56.w, color: Colors.grey[200]),
                          _MenuTile(
                            icon: Icons.description_outlined,
                            title: 'Legal Information',
                            subtitle: 'Terms and Conditions',
                            onTap: () => _showComingSoon(context, 'Legal Documents'),
                          ),
                          Divider(height: 1, indent: 56.w, color: Colors.grey[200]),
                          _MenuTile(
                            icon: Icons.notifications_none,
                            title: 'Notifications',
                            subtitle: 'Manage your notification preferences',
                            onTap: () => _showComingSoon(context, 'Notification Settings'),
                          ),
                          Divider(height: 1, indent: 56.w, color: Colors.grey[200]),
                          _MenuTile(
                            icon: Icons.share_outlined,
                            title: 'Share App',
                            subtitle: 'Refer us to a friend',
                            onTap: () {
                               // Implement Share functionality or show dialog
                               _showComingSoon(context, 'Share App');
                            },
                          ),
                          Divider(height: 1, indent: 56.w, color: Colors.grey[200]),
                          _MenuTile(
                            icon: Icons.chat_bubble_outline,
                            title: 'Alerts on WhatsApp',
                            subtitle: 'Keep up with all important updates',
                            onTap: () => _showComingSoon(context, 'WhatsApp Alerts'),
                          ),
                          Divider(height: 1, indent: 56.w, color: Colors.grey[200]),
                          _MenuTile(
                            icon: Icons.settings_outlined,
                            title: 'Account Management',
                            subtitle: 'Modify Khaata App Settings',
                            onTap: () {},
                          ),
                          Divider(height: 1, indent: 56.w, color: Colors.grey[200]),
                          _MenuTile(
                            icon: Icons.lock_outline,
                            title: 'Lock App',
                            subtitle: 'Secure with Biometrics',
                            onTap: () {
                               context.go(AppConstants.splash);
                            },
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 24.h),

                    // Logout
                    TextButton.icon(
                      onPressed: () {
                        // Capture Router from the parent context before opening the dialog
                        final router = GoRouter.of(context);
                        final authCubit = context.read<AuthCubit>();
                        final loanCubit = context.read<LoanCubit>();
                        
                        showDialog(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: const Text('Logout?'),
                            content: const Text('This will clear your session and you will need an OTP to login again.\n\nUse "Lock App" if you just want to secure the device.'),
                            actions: [
                              TextButton(
                                onPressed: () => dialogContext.pop(),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  dialogContext.pop(); // Close dialog first
                                  
                                  // Clear safe cubits if possible
                                  try { loanCubit.clear(); } catch (_) {}
                                  
                                  authCubit.logout().then((_) {
                                    router.go(AppConstants.login);
                                  });
                                },
                                child: const Text('Logout', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: Icon(
                        Icons.logout,
                        color: Colors.red[400],
                        size: 18.sp,
                      ),
                      label: Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.red[400],
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    SizedBox(height: 8.h),
                    Text(
                      'App Version 3.15.49',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: KhaataTheme.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature is coming soon!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: KhaataTheme.primaryBlue,
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      leading: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(icon, color: KhaataTheme.textDark, size: 18.sp),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13.sp,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 11.sp,
          color: KhaataTheme.textGrey,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Colors.grey,
        size: 18.sp,
      ),
    );
  }
}