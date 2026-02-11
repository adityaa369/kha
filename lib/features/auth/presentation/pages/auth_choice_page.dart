import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/constants.dart';
import '../../../../config/theme.dart';

class AuthChoicePage extends StatelessWidget {
  const AuthChoicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [KhaataTheme.primaryBlue, KhaataTheme.secondaryBlue],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              children: [
                SizedBox(height: 60.h),
                // Logo Container (replaced AnimatedLogo)
                Container(
                  width: 100.w,
                  height: 100.w,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'K',
                      style: TextStyle(
                        fontSize: 48.sp,
                        fontWeight: FontWeight.bold,
                        color: KhaataTheme.primaryBlue,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 40.h),
                Text(
                  'Welcome to Khaata',
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  'Digital Loan Agreements Made Simple',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.white70,
                  ),
                ),
                const Spacer(),
                // Login Button
                _AuthButton(
                  text: 'Login',
                  isOutlined: false,
                  onTap: () => context.push(AppConstants.login),
                ),
                SizedBox(height: 16.h),
                // Signup Button - Navigate to login (same flow) or welcome
                _AuthButton(
                  text: 'Create Account',
                  isOutlined: true,
                  onTap: () => context.push(AppConstants.login), // Same as login for now
                ),
                SizedBox(height: 40.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthButton extends StatelessWidget {
  final String text;
  final bool isOutlined;
  final VoidCallback onTap;

  const _AuthButton({
    required this.text,
    required this.isOutlined,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56.h,
        decoration: BoxDecoration(
          color: isOutlined ? Colors.transparent : Colors.white,
          border: Border.all(color: Colors.white, width: 2),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: isOutlined ? Colors.white : KhaataTheme.primaryBlue,
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}