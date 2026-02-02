import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/constants.dart';
import '../../../../config/theme.dart';

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
                    onPressed: () => Navigator.pop(context),
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
                      child: Column(
                        children: [
                          Container(
                            width: 72.w,
                            height: 72.w,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            child: Center(
                              child: Text(
                                'AA',
                                style: TextStyle(
                                  fontSize: 28.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            'Aditya Amruthaluri',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
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
                            onTap: () {},
                          ),
                          Divider(height: 1, indent: 56.w, color: Colors.grey[200]),
                          _MenuTile(
                            icon: Icons.description_outlined,
                            title: 'Legal Information',
                            subtitle: 'Terms and Conditions',
                            onTap: () {},
                          ),
                          Divider(height: 1, indent: 56.w, color: Colors.grey[200]),
                          _MenuTile(
                            icon: Icons.share_outlined,
                            title: 'Share App',
                            subtitle: 'Refer us to a friend',
                            onTap: () {},
                          ),
                          Divider(height: 1, indent: 56.w, color: Colors.grey[200]),
                          _MenuTile(
                            icon: Icons.chat_bubble_outline,
                            title: 'Alerts on WhatsApp',
                            subtitle: 'Keep up with all important updates',
                            onTap: () {},
                          ),
                          Divider(height: 1, indent: 56.w, color: Colors.grey[200]),
                          _MenuTile(
                            icon: Icons.settings_outlined,
                            title: 'Account Management',
                            subtitle: 'Modify Khaata App Settings',
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 24.h),

                    // Logout
                    TextButton.icon(
                      onPressed: () => context.go(AppConstants.welcome),
                      icon: Icon(
                        Icons.logout,
                        color: KhaataTheme.primaryBlue,
                        size: 18.sp,
                      ),
                      label: Text(
                        'Logout',
                        style: TextStyle(
                          color: KhaataTheme.primaryBlue,
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