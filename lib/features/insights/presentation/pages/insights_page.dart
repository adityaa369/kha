
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../config/theme.dart';
import '../../../../core/widgets/gauge_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/blocs/credit_score/credit_score_cubit.dart';
import '../../../../core/blocs/credit_score/credit_score_state.dart';
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
                    'Report Summary',
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
                  // Score Display Card
                  BlocBuilder<CreditScoreCubit, CreditScoreState>(
                    builder: (context, state) {
                      int cibil = 0;
                      int experian = 0;
                      String status = 'Processing';
                      
                      if (state is CreditScoreLoaded) {
                        cibil = state.cibilScore;
                        experian = state.experianScore;
                        status = state.status;
                      }

                      return Container(
                        padding: EdgeInsets.all(20.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Credit Score',
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w700,
                                    color: KhaataTheme.primaryBlue,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20.h),

                            // GAUGE
                            CreditScoreGauge(score: cibil, size: 140),

                            // Min-Max labels
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20.w),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                   Text(
                                    '300',
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    status,
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: status == 'Excellent' || status == 'Good' 
                                          ? KhaataTheme.accentGreen 
                                          : (status == 'Fair' ? KhaataTheme.warningYellow : KhaataTheme.dangerRed),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                   Text(
                                    '900',
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 16.h),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              child: Text(
                                'Based on loans taken & timely monthly repayments.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: KhaataTheme.textGrey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  SizedBox(height: 16.h),

                  // Improve Score Card
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F4FD),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.trending_up,
                              color: KhaataTheme.primaryBlue,
                              size: 20.sp,
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                'Know what you need to do to improve your score',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
                                ),
                                builder: (context) {
                                  return Container(
                                    padding: EdgeInsets.all(24.w),
                                    child: SingleChildScrollView(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.trending_up, color: KhaataTheme.accentGreen, size: 28.sp),
                                              SizedBox(width: 12.w),
                                              Text(
                                                'How to Improve Score',
                                                style: TextStyle(
                                                  fontSize: 20.sp,
                                                  fontWeight: FontWeight.bold,
                                                  color: KhaataTheme.textDark,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 20.h),
                                          Text(
                                            'Here are the most effective ways to build your credit score quickly:',
                                            style: TextStyle(fontSize: 14.sp, color: Colors.grey[700]),
                                          ),
                                          SizedBox(height: 24.h),
                                          _BuildScoreStep(
                                            icon: Icons.check_circle,
                                            title: 'Clear Active Loans',
                                            description: 'If you have any outstanding active loans, try to clear them as soon as possible. Paying off debt lowers your credit utilization ratio.',
                                          ),
                                          SizedBox(height: 16.h),
                                          _BuildScoreStep(
                                            icon: Icons.calendar_month,
                                            title: 'Consistent Payment Dues',
                                            description: 'Ensure you maintain a consistent track record of paying all your monthly EMIs and dues exactly on time. Consistency is key!',
                                          ),
                                          SizedBox(height: 32.h),
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: KhaataTheme.primaryBlue,
                                                padding: EdgeInsets.symmetric(vertical: 14.h),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                                              ),
                                              onPressed: () => Navigator.pop(context),
                                              child: Text('Got It', style: TextStyle(fontSize: 16.sp, color: Colors.white)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: KhaataTheme.primaryBlue,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                            ),
                            child: Text(
                              'Improve Score',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24.h),

                  Text(
                    'See what changed',
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
                      String limit = '₹ 0';
                      
                      if (loanState is LoansLoaded) {
                        // Calculate typical monthly payments (Mock logic: sum of amount/duration)
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
                      
                      final creditState = context.read<CreditScoreCubit>().state;
                      if (creditState is CreditScoreLoaded) {
                         if (creditState.cibilScore >= 750) {
                           limit = '₹ 5,00,000';
                         } else if (creditState.cibilScore >= 650) limit = '₹ 2,00,000';
                         else if (creditState.cibilScore >= 550) limit = '₹ 50,000';
                         else if (creditState.cibilScore > 0) limit = '₹ 10,000';
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

class _BuildScoreStep extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _BuildScoreStep({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: KhaataTheme.primaryBlue.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: KhaataTheme.primaryBlue, size: 24.sp),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: KhaataTheme.textDark,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}