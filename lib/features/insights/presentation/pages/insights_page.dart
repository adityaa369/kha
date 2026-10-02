import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../config/theme.dart';
import '../../../../core/blocs/loans/portfolio_cubit.dart';
import '../../../../data/models/portfolio_summary_model.dart';

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

  String _fmt(double amount) {
    final fmt = NumberFormat('#,##,##0', 'en_IN');
    return fmt.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KhaataTheme.backgroundGrey,
      body: Column(
        children: [
          // ── Header ─────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            color: KhaataTheme.primaryBlue,
            padding: EdgeInsets.fromLTRB(20.w, 48.h, 20.w, 22.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Insights',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Your complete financial picture',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13.sp,
                  ),
                ),
              ],
            ),
          ),
          // ── Body ───────────────────────────────────────────────────────
          Expanded(
            child: BlocBuilder<PortfolioCubit, PortfolioState>(
              builder: (context, state) {
                if (state is PortfolioLoading || state is PortfolioInitial) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: KhaataTheme.primaryBlue,
                    ),
                  );
                }
                if (state is PortfolioError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            color: KhaataTheme.dangerRed, size: 48.sp),
                        SizedBox(height: 12.h),
                        Text(state.message,
                            style: TextStyle(
                                color: KhaataTheme.dangerRed,
                                fontSize: 14.sp),
                            textAlign: TextAlign.center),
                        SizedBox(height: 16.h),
                        TextButton(
                          onPressed: () => context
                              .read<PortfolioCubit>()
                              .fetchPortfolioSummary(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                if (state is PortfolioLoaded) {
                  final summary = state.summary;
                  final lender = summary.lenderStats;
                  final borrower = summary.borrowerStats;
                  final hasLender = lender != null && lender.loanCount > 0;
                  final hasBorrower =
                      borrower != null && borrower.loanCount > 0;

                  if (!hasLender && !hasBorrower) {
                    return _EmptyState();
                  }

                  return RefreshIndicator(
                    color: KhaataTheme.primaryBlue,
                    onRefresh: () => context
                        .read<PortfolioCubit>()
                        .fetchPortfolioSummary(),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 32.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (hasLender) ...[
                            _SectionLabel(
                              icon: Icons.trending_up_rounded,
                              text: 'Loans I\'ve Given',
                            ),
                            SizedBox(height: 12.h),
                            _LenderCard(lender: lender!, fmt: _fmt),
                            SizedBox(height: 12.h),
                            _StatRow(children: [
                              _MiniStat(
                                icon: Icons.download_rounded,
                                iconBg: const Color(0xFFD1FAE5),
                                iconColor: const Color(0xFF059669),
                                label: 'Collected',
                                value: '₹${_fmt(lender.totalCollected)}',
                                valueColor: const Color(0xFF059669),
                              ),
                              _MiniStat(
                                icon: Icons.schedule_rounded,
                                iconBg: const Color(0xFFFEF3C7),
                                iconColor: KhaataTheme.warningYellow,
                                label: 'Outstanding',
                                value: '₹${_fmt(lender.outstanding)}',
                                valueColor: KhaataTheme.warningYellow,
                              ),
                            ]),
                            SizedBox(height: 10.h),
                            _StatRow(children: [
                              _MiniStat(
                                icon: Icons.people_rounded,
                                iconBg: const Color(0xFFD1FAE5),
                                iconColor: const Color(0xFF059669),
                                label: 'Active',
                                value: '${lender.activeLoanCount}',
                                valueColor: KhaataTheme.textDark,
                              ),
                              _MiniStat(
                                icon: Icons.check_circle_rounded,
                                iconBg: KhaataTheme.borderGrey,
                                iconColor: KhaataTheme.textGrey,
                                label: 'Closed',
                                value: '${lender.closedLoanCount}',
                                valueColor: KhaataTheme.textGrey,
                              ),
                            ]),
                            if (lender.monthlyCollections.isNotEmpty) ...[
                              SizedBox(height: 14.h),
                              _MonthlyChart(
                                collections: lender.monthlyCollections,
                                fmt: _fmt,
                              ),
                            ],
                            SizedBox(height: 28.h),
                          ],
                          if (hasBorrower) ...[
                            _SectionLabel(
                              icon: Icons.handshake_rounded,
                              text: 'Loans I\'ve Taken',
                            ),
                            SizedBox(height: 12.h),
                            _BorrowerCard(borrower: borrower!, fmt: _fmt),
                            SizedBox(height: 12.h),
                            _StatRow(children: [
                              _MiniStat(
                                icon: Icons.upload_rounded,
                                iconBg: const Color(0xFFD1FAE5),
                                iconColor: const Color(0xFF059669),
                                label: 'Repaid',
                                value: '₹${_fmt(borrower.totalRepaid)}',
                                valueColor: const Color(0xFF059669),
                              ),
                              _MiniStat(
                                icon: Icons.warning_amber_rounded,
                                iconBg: const Color(0xFFFEE2E2),
                                iconColor: KhaataTheme.dangerRed,
                                label: 'Remaining',
                                value: '₹${_fmt(borrower.outstanding)}',
                                valueColor: KhaataTheme.dangerRed,
                              ),
                            ]),
                            SizedBox(height: 10.h),
                            _StatRow(children: [
                              _MiniStat(
                                icon: Icons.receipt_long_rounded,
                                iconBg: const Color(0xFFD1FAE5),
                                iconColor: const Color(0xFF059669),
                                label: 'Active',
                                value: '${borrower.activeLoanCount}',
                                valueColor: KhaataTheme.textDark,
                              ),
                              _MiniStat(
                                icon: Icons.check_circle_rounded,
                                iconBg: KhaataTheme.borderGrey,
                                iconColor: KhaataTheme.textGrey,
                                label: 'Closed',
                                value: '${borrower.closedLoanCount}',
                                valueColor: KhaataTheme.textGrey,
                              ),
                            ]),
                          ],
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart_rounded,
              size: 64.sp, color: KhaataTheme.borderGrey),
          SizedBox(height: 16.h),
          Text('No loan activity yet',
              style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: KhaataTheme.textGrey)),
          SizedBox(height: 8.h),
          Text(
            'Your financial insights will appear here\nonce you give or take a loan.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.sp, color: KhaataTheme.textGrey),
          ),
        ],
      ),
    );
  }
}

// ── Section label ────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String text;
  const _SectionLabel({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(6.w),
          decoration: BoxDecoration(
            color: KhaataTheme.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, color: KhaataTheme.primaryBlue, size: 16.sp),
        ),
        SizedBox(width: 8.w),
        Text(
          text,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
            color: KhaataTheme.textDark,
          ),
        ),
      ],
    );
  }
}

// ── Lender hero card ─────────────────────────────────────────────────────────
class _LenderCard extends StatelessWidget {
  final LenderStats lender;
  final String Function(double) fmt;
  const _LenderCard({required this.lender, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF10B981)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Lent',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12.sp)),
                SizedBox(height: 2.h),
                Text('₹${fmt(lender.totalLent)}',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w800)),
                SizedBox(height: 6.h),
                Row(children: [
                  _chip('${lender.activeLoanCount} Active'),
                  SizedBox(width: 6.w),
                  _chip('${lender.closedLoanCount} Closed'),
                  if (lender.defaultedLoanCount > 0) ...[
                    SizedBox(width: 6.w),
                    _chip('${lender.defaultedLoanCount} Defaulted'),
                  ],
                ]),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Text('${lender.collectionRatePct}% Collected',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700)),
              ),
              SizedBox(height: 10.h),
              Text('₹${fmt(lender.outstanding)}',
                  style: TextStyle(
                      color: const Color(0xFFFEF3C7),
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700)),
              Text('Outstanding',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 10.sp)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String text) => Container(
        padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Text(text,
            style: TextStyle(
                color: Colors.white,
                fontSize: 9.sp,
                fontWeight: FontWeight.w600)),
      );
}

// ── Borrower hero card ───────────────────────────────────────────────────────
class _BorrowerCard extends StatelessWidget {
  final BorrowerStats borrower;
  final String Function(double) fmt;
  const _BorrowerCard({required this.borrower, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D9488).withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Borrowed',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12.sp)),
                SizedBox(height: 2.h),
                Text('₹${fmt(borrower.totalBorrowed)}',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w800)),
                SizedBox(height: 6.h),
                Row(children: [
                  _chip('${borrower.activeLoanCount} Active'),
                  SizedBox(width: 6.w),
                  _chip('${borrower.closedLoanCount} Closed'),
                ]),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Text('${borrower.repaymentRatePct}% Repaid',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700)),
              ),
              SizedBox(height: 10.h),
              Text('₹${fmt(borrower.outstanding)}',
                  style: TextStyle(
                      color: const Color(0xFFFEE2E2),
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700)),
              Text('Remaining',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 10.sp)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String text) => Container(
        padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Text(text,
            style: TextStyle(
                color: Colors.white,
                fontSize: 9.sp,
                fontWeight: FontWeight.w600)),
      );
}

// ── Stat row (two cards side by side) ────────────────────────────────────────
class _StatRow extends StatelessWidget {
  final List<Widget> children;
  const _StatRow({required this.children});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: children[0]),
        SizedBox(width: 10.w),
        Expanded(child: children[1]),
      ],
    );
  }
}

// ── Mini stat card ───────────────────────────────────────────────────────────
class _MiniStat extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;
  final Color valueColor;

  const _MiniStat({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: KhaataTheme.cardWhite,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: KhaataTheme.borderGrey),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(7.w),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, color: iconColor, size: 16.sp),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 10.sp,
                        color: KhaataTheme.textGrey,
                        fontWeight: FontWeight.w500)),
                SizedBox(height: 1.h),
                Text(value,
                    style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: valueColor),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Monthly chart ────────────────────────────────────────────────────────────
class _MonthlyChart extends StatelessWidget {
  final List<MonthlyCollection> collections;
  final String Function(double) fmt;
  const _MonthlyChart({required this.collections, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final maxVal = collections.fold<int>(
        1, (m, e) => e.amountPaise > m ? e.amountPaise : m);

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: KhaataTheme.cardWhite,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: KhaataTheme.borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Monthly Collections',
                  style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: KhaataTheme.textDark)),
              Text('Last 6 months',
                  style: TextStyle(
                      fontSize: 10.sp, color: KhaataTheme.textGrey)),
            ],
          ),
          SizedBox(height: 14.h),
          SizedBox(
            height: 90.h,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: collections.map((c) {
                final ratio = maxVal > 0 ? c.amountPaise / maxVal : 0.0;
                final barH = (ratio * 70.h).clamp(3.0, 70.h);
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 3.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (c.amountPaise > 0)
                          Text(
                            c.amountRupees >= 1000
                                ? '${_fmtK(c.amountRupees)}k'
                                : '₹${fmt(c.amountRupees)}',
                            style: TextStyle(
                                fontSize: 8.sp,
                                color: KhaataTheme.primaryBlue,
                                fontWeight: FontWeight.w600),
                          ),
                        SizedBox(height: 2.h),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOut,
                          height: barH,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF059669)],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            borderRadius: BorderRadius.vertical(
                                top: Radius.circular(4.r)),
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(c.month,
                            style: TextStyle(
                                fontSize: 9.sp,
                                color: KhaataTheme.textGrey,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtK(double v) {
    return (v / 1000).toStringAsFixed(v % 1000 == 0 ? 0 : 1);
  }
}
