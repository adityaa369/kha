import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../../../../config/constants.dart';

/// Shown after a credit agreement step completes.
///
/// * Lender (after creating a credit) navigates here with [extra] containing
///   `borrower_name` → shows "Agreement Sent".
/// * Borrower (after accepting) navigates here with no extra → shows
///   "Agreement Accepted".
class LoanSuccessPage extends StatelessWidget {
  final Map<String, dynamic>? extra;

  const LoanSuccessPage({super.key, this.extra});

  bool get _isLenderSent => extra != null && extra!['borrower_name'] != null;

  @override
  Widget build(BuildContext context) {
    final borrowerName = (extra?['borrower_name'] as String?)?.trim();
    final amountPaise = extra?['amountPaise'];
    final amount = amountPaise is num ? amountPaise / 100 : null;

    final IconData icon = _isLenderSent
        ? Icons.send_rounded
        : Icons.check_rounded;
    final String title = _isLenderSent
        ? 'Agreement Sent'
        : 'Agreement Accepted';
    final String subtitle = _isLenderSent
        ? 'Your credit agreement has been sent to '
              '${(borrowerName == null || borrowerName.isEmpty) ? 'the borrower' : borrowerName}'
              '. It will become active once they review and accept it.'
        : 'The credit is now active. Your digital signature has been recorded '
              'and the lender has been notified.';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) context.go(AppConstants.home);
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  // Icon with soft halo
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
                      child: Icon(icon, color: Colors.white, size: 44.sp),
                    ),
                  ),
                  SizedBox(height: 32.h),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w700,
                      color: KhaataTheme.textDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14.sp,
                      height: 1.5,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_isLenderSent && amount != null) ...[
                    SizedBox(height: 24.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 14.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.hourglass_top_rounded,
                            size: 18.sp,
                            color: Colors.orange.shade700,
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              'Awaiting borrower approval',
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: KhaataTheme.textDark,
                              ),
                            ),
                          ),
                          Text(
                            '\u20B9${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 2)}',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: KhaataTheme.primaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
      ),
    );
  }
}
