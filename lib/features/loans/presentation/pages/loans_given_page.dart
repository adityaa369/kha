import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/blocs/auth/auth_cubit.dart';
import '../../../../core/blocs/loans/loan_cubit.dart';
import '../../../../core/blocs/loans/loan_state.dart';
import '../../../../data/models/loan_model.dart';

class LoansGivenPage extends StatelessWidget {
  const LoansGivenPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KhaataTheme.backgroundGrey,
      body: Column(
        children: [
          // Blue Header - Matching My Loans style
          Container(
            width: double.infinity,
            color: KhaataTheme.primaryBlue,
            padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 16.h),
            child: SafeArea(
              bottom: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Loans Given',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(Icons.add, color: KhaataTheme.primaryBlue, size: 22.sp),
                      onPressed: () => context.push('/create-loan?type=personal'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Stats Row - Like My Loans
          BlocBuilder<LoanCubit, LoanState>(
            builder: (context, state) {
              double totalLent = 0;
              double totalPending = 0;
              
              if (state is LoansLoaded) {
                for (var loan in state.givenLoans) {
                  totalLent += loan.amount;
                  totalPending += loan.remainingAmount;
                }
              }

              return Container(
                color: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatBox(
                        label: 'Total Lent',
                        amount: '₹ ${_formatCurrency(totalLent)}',
                        icon: Icons.arrow_upward,
                        color: KhaataTheme.accentGreen,
                      ),
                    ),
                    Container(width: 1.w, height: 40.h, color: Colors.grey[200]),
                    Expanded(
                      child: _StatBox(
                        label: 'Pending',
                        amount: '₹ ${_formatCurrency(totalPending)}',
                        icon: Icons.arrow_downward,
                        color: KhaataTheme.warningYellow,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Loan List
          Expanded(
            child: BlocBuilder<LoanCubit, LoanState>(
              builder: (context, state) {
                if (state is LoanInitial) {
                  final authState = context.read<AuthCubit>().state;
                  if (authState is Authenticated) {
                    context.read<LoanCubit>().fetchLoans(authState.user.id);
                  }
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (state is LoanLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is LoanError) {
                  return Center(child: Text(state.message));
                }

                if (state is LoansLoaded) {
                  if (state.givenLoans.isEmpty) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.handshake_outlined, size: 64.sp, color: Colors.grey[300]),
                        SizedBox(height: 16.h),
                        Text(
                          'No loans given yet',
                          style: TextStyle(color: Colors.grey, fontSize: 16.sp),
                        ),
                      ],
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.all(16.w),
                    itemCount: state.givenLoans.length,
                    itemBuilder: (context, index) {
                      final loan = state.givenLoans[index];
                      // Format date for the UI
                      final dateStr = '${loan.startDate.day} ${_getMonthName(loan.startDate.month)} ${loan.startDate.year}';
                      
                      return Column(
                        children: [
                          _GivenLoanCard(
                            name: loan.borrowerName,
                            amount: loan.displayAmount,
                            date: dateStr,
                            status: loan.statusDisplay,
                            statusColor: loan.statusColor,
                            progress: loan.progress,
                            initials: loan.initials ?? loan.borrowerName[0].toUpperCase(),
                          ),
                          SizedBox(height: 12.h),
                        ],
                      );
                    },
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String amount;
  final IconData icon;
  final Color color;

  const _StatBox({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14.sp, color: color),
            SizedBox(width: 4.w),
            Text(
              label,
              style: TextStyle(fontSize: 11.sp, color: Colors.grey),
            ),
          ],
        ),
        SizedBox(height: 4.h),
        Text(
          amount,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _GivenLoanCard extends StatelessWidget {
  final String name;
  final String amount;
  final String date;
  final String status;
  final Color statusColor;
  final double progress;
  final String initials;

  const _GivenLoanCard({
    required this.name,
    required this.amount,
    required this.date,
    required this.status,
    required this.statusColor,
    required this.progress,
    required this.initials,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        children: [
          // Header with Avatar and Status
          Padding(
            padding: EdgeInsets.all(12.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18.w,
                      backgroundColor: statusColor.withOpacity(0.1),
                      child: Text(
                        initials,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14.sp,
                          ),
                        ),
                        Text(
                          date,
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 11.sp,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 11.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Amount and Progress
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      amount,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toInt()}% Repaid',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2.r),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    minHeight: 4.h,
                  ),
                ),
                SizedBox(height: 12.h),
              ],
            ),
          ),

          // Action Buttons
          Padding(
            padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.w),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: KhaataTheme.primaryBlue,
                      side: BorderSide(color: KhaataTheme.primaryBlue),
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text(
                      'Reminder',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KhaataTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text(
                      'Details',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _formatCurrency(double amount) {
  return amount.toStringAsFixed(0).replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]},',
  );
}

String _getMonthName(int month) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
  return months[month - 1];
}