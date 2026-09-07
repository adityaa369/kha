import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../../../../config/constants.dart';

class LoanConfirmationPage extends StatelessWidget {
  final Map<String, dynamic> loanData;

  const LoanConfirmationPage({super.key, required this.loanData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: KhaataTheme.textDark),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Confirm Agreement',
          style: TextStyle(
            color: KhaataTheme.textDark,
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Agreement Summary Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: KhaataTheme.primaryBlue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: KhaataTheme.primaryBlue.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Loan Agreement Summary',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: KhaataTheme.textGrey,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      '₹ ${(loanData['amountPaise'] ?? 0) / 100}',
                      style: TextStyle(
                        fontSize: 32.sp,
                        fontWeight: FontWeight.bold,
                        color: KhaataTheme.primaryBlue,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'to ${loanData['borrower_name']}',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        'Pending Approval',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: KhaataTheme.warningYellow,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 40.h),

              // Pending Status Section
              Icon(
                Icons.mark_email_unread_outlined,
                size: 64.sp,
                color: KhaataTheme.primaryBlue,
              ),
              SizedBox(height: 16.h),
              Text(
                'Approval Request Sent',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: KhaataTheme.textDark,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'The borrower has been notified. The agreement will remain in pending state until they review and approve it on their device.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: KhaataTheme.textGrey,
                  height: 1.5,
                ),
              ),

              SizedBox(height: 48.h),

              ElevatedButton(
                child: Text('Go to Given Loans'),
                onPressed: () {
                  context.go(AppConstants.loansGiven);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
