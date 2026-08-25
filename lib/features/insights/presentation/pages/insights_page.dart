import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../config/theme.dart';
import '../../../../core/blocs/loans/portfolio_cubit.dart';

class InsightsPage extends StatefulWidget {
  const InsightsPage({super.key});

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PortfolioCubit>().fetchPortfolioSummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KhaataTheme.backgroundGrey,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: KhaataTheme.primaryBlue,
            padding: EdgeInsets.fromLTRB(16.w, 40.h, 16.w, 20.h),
            child: Column(
              children: [
                Text(
                  'Lender Portfolio',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Your lending performance at a glance',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Portfolio Summary',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  BlocBuilder<PortfolioCubit, PortfolioState>(
                    builder: (context, state) {
                      if (state is PortfolioLoading) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (state is PortfolioError) {
                        return Center(child: Text(state.message, style: TextStyle(color: Colors.red)));
                      } else if (state is PortfolioLoaded) {
                        final summary = state.summary;
                        final fmt = NumberFormat('#,##0', 'en_IN');

                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: 12.h,
                          crossAxisSpacing: 12.w,
                          childAspectRatio: 0.85,
                          children: [
                            _FactorCard(
                              title: 'Outstanding',
                              subtitle: 'Total Remaining',
                              value: '₹ ${fmt.format(summary.outstanding)}',
                              detailLabel: 'Across all loans',
                              valueColor: Colors.orange.shade700,
                              isGood: null,
                              icon: Icons.account_balance,
                            ),
                            _FactorCard(
                              title: 'Total Lent',
                              subtitle: 'Original Principal',
                              value: '₹ ${fmt.format(summary.totalLent)}',
                              detailLabel: 'Disbursed',
                              valueColor: KhaataTheme.textDark,
                              isGood: true,
                              icon: Icons.upload,
                            ),
                            _FactorCard(
                              title: 'Collected',
                              subtitle: 'Total Received',
                              value: '₹ ${fmt.format(summary.totalCollected)}',
                              detailLabel: 'Paid back',
                              valueColor: Colors.green.shade700,
                              isGood: true,
                              icon: Icons.download,
                            ),
                            _FactorCard(
                              title: 'Active Loans',
                              subtitle: 'Current Portfolio',
                              value: '${summary.activeLoanCount}',
                              detailLabel: 'Total active',
                              valueColor: KhaataTheme.textDark,
                              isGood: null,
                              icon: Icons.people,
                            ),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
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
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.sp),
          ),
          Text(
            subtitle,
            style: TextStyle(fontSize: 11.sp, color: Colors.grey),
          ),
          const Spacer(),
          Container(
            padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
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
