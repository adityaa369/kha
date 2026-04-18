import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../../../../config/constants.dart';
import '../../../../core/blocs/loans/loan_cubit.dart';
import '../../../../core/blocs/loans/loan_state.dart';
import '../../../../data/models/loan_model.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KhaataTheme.backgroundGrey,
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: KhaataTheme.textDark,
      ),
      body: BlocBuilder<LoanCubit, LoanState>(
        builder: (context, state) {
          if (state is LoanLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          List<LoanModel> pendingLoans = [];
          if (state is LoansLoaded) {
            pendingLoans = state.myLoans
                .where((l) => l.status == 'pending_approval' || l.status == 'pending_otp')
                .toList();
          }

          if (pendingLoans.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined,
                      size: 64.sp, color: Colors.grey),
                  SizedBox(height: 16.h),
                  Text(
                    'No new notifications',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: KhaataTheme.textGrey,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: pendingLoans.length,
            itemBuilder: (context, index) {
              final loan = pendingLoans[index];
              return _NotificationCard(loan: loan);
            },
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final LoanModel loan;

  const _NotificationCard({required this.loan});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (loan.status == 'pending_otp') {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                title: Text('Setup Passcode', style: TextStyle(color: KhaataTheme.textDark, fontWeight: FontWeight.bold)),
                content: Text(
                  'A lender is currently setting up a loan for you of ₹${NumberFormat('#,##0').format(loan.amount)}.\n\nProvide them this Secure OTP: ${loan.otp ?? "N/A"}\n\nIt is required to finalize the draft before you can digitally sign it.',
                  style: TextStyle(fontSize: 14.sp, height: 1.5),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('OK', style: TextStyle(color: KhaataTheme.primaryBlue)),
                  )
                ],
              ),
            );
        } else {
            context.push(AppConstants.loanApproval, extra: loan);
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: loan.status == 'pending_otp' ? KhaataTheme.warningYellow.withOpacity(0.1) : KhaataTheme.primaryBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  loan.status == 'pending_otp' ? Icons.lock_outline : Icons.description_outlined,
                  color: loan.status == 'pending_otp' ? KhaataTheme.warningYellow : KhaataTheme.primaryBlue,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loan.status == 'pending_otp' ? 'Action Required: Setup OTP' : 'New Loan Agreement',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: KhaataTheme.textDark,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      loan.status == 'pending_otp'
                          ? '${loan.lenderName} is drafting an agreement of ₹${NumberFormat('#,##0').format(loan.amount)}.'
                          : '${loan.lenderName} has sent you a loan agreement of ₹${NumberFormat('#,##0').format(loan.amount)}.',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: KhaataTheme.textGrey,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('MMM dd, yyyy').format(loan.createdAt ?? DateTime.now()),
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          'Tap to review',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: KhaataTheme.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
