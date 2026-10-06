import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../../../../config/constants.dart';

class ChitSuccessPage extends StatelessWidget {
  const ChitSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              children: [
                const Spacer(flex: 3),
                Container(
                  padding: EdgeInsets.all(18.w),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: KhaataTheme.primaryBlue.withValues(alpha: 0.08),
                  ),
                  child: Container(
                    padding: EdgeInsets.all(22.w),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: KhaataTheme.primaryBlue,
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 44.sp,
                    ),
                  ),
                ),
                SizedBox(height: 32.h),
                Text(
                  'Success!',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w700,
                    color: KhaataTheme.textDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12.h),
                Text(
                  'Your Chit Fund action has been processed successfully. Notifications have been dispatched accordingly.',
                  style: TextStyle(
                    fontSize: 14.sp,
                    height: 1.5,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Spacer(flex: 4),
                SizedBox(
                  width: double.infinity,
                  height: 52.h,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KhaataTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                    onPressed: () => context.go(AppConstants.home),
                    child: Text(
                      'Back to Home',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
