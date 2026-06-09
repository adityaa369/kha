import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../config/theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/blocs/loans/loan_cubit.dart';
import '../../../../core/blocs/loans/loan_state.dart';
import '../../../../core/blocs/auth/auth_cubit.dart';

class InsightsPage extends StatelessWidget {
  const InsightsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KhaataTheme.backgroundGrey,
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            color: KhaataTheme.primaryBlue,
            padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 0),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Text(
                    'Financial Insights',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 16.h),
                ],
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Activity',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 16.h),

                  BlocBuilder<LoanCubit, LoanState>(
                    builder: (context, loanState) {
                      String startPayment = '₹ 0';
                      String totalAccounts = '0';
                      String age = '0 days';
                      String limit = '₹ 10,000'; // Default base limit
                      
                      if (loanState is LoansLoaded) {
                        // Calculate typical monthly payments
                        double monthlyPayment = 0;
                        for (var loan in loanState.myLoans) {
                          if (loan.status == 'active' && loan.durationMonths != null && loan.durationMonths! > 0) {
                            monthlyPayment += (loan.amount / loan.durationMonths!);
                          }
                        }
                        startPayment = '₹ ${(monthlyPayment).toStringAsFixed(0)}';
                        
                        // Total Accounts
                        totalAccounts = (loanState.myLoans.length + loanState.givenLoans.length).toString();
                        
                        final authState = context.read<AuthCubit>().state;
                        if (authState is AuthenticatedFull && authState.user.createdAt != null) {
                           age = '${DateTime.now().difference(authState.user.createdAt!).inDays} days';
                        } else {
                           age = '0 days';
                        }
                        
                        // Dynamic limit based on accounts
                        if (loanState.myLoans.isNotEmpty) {
                           limit = '₹ 50,000'; // Increase limit if user has history
                        }
                      }

                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 12.h,
                        crossAxisSpacing: 12.w,
                        childAspectRatio: 0.85,
                        children: [
                          _FactorCard(
                            title: 'Payments',
                            subtitle: 'High Impact',
                            value: startPayment,
                            detailLabel: 'Timely payments',
                            valueColor: KhaataTheme.textGrey,
                            isGood: true,
                            icon: Icons.access_time,
                          ),
                          _FactorCard(
                            title: 'Limit',
                            subtitle: 'High Impact',
                             value: limit,
                             detailLabel: 'Credit limit available',
                            valueColor: KhaataTheme.textGrey,
                            isGood: true,
                            icon: Icons.show_chart,
                          ),
                          _FactorCard(
                            title: 'Age',
                            subtitle: 'Medium Impact',
                            value: age,
                            detailLabel: 'Account age',
                            valueColor: KhaataTheme.textDark,
                            isGood: true,
                            icon: Icons.calendar_today,
                          ),
                          _FactorCard(
                            title: 'Accounts',
                            subtitle: 'Low Impact',
                            value: totalAccounts,
                            detailLabel: 'Total accounts',
                            valueColor: KhaataTheme.textDark,
                            isGood: true,
                            icon: Icons.account_balance_wallet,
                          ),
                        ],
                      );
                    }
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FactorCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;
  final String detailLabel;
  final Color valueColor;
  final bool? isGood;
  final IconData icon;

  const _FactorCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.detailLabel,
    required this.valueColor,
    required this.isGood,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: isGood == null
            ? Colors.grey[50]
            : (isGood! ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2)),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isGood == null
              ? Colors.grey[200]!
              : (isGood! ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 18.sp, color: Colors.grey),
              if (isGood != null)
                Container(
                  width: 6.w,
                  height: 6.w,
                  decoration: BoxDecoration(
                    color: isGood! ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14.sp,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.grey,
            ),
          ),
          const Spacer(),
          Container(
            padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    detailLabel,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: KhaataTheme.textGrey,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        color: valueColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.sp,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12.sp,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}