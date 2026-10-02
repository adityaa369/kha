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
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [KhaataTheme.primaryBlue, const Color(0xFF1A5499)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: EdgeInsets.fromLTRB(20.w, 48.h, 20.w, 24.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Insights',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Your complete financial picture',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 13.sp,
                  ),
                ),
              ],
            ),
          ),
          // ── Body ────────────────────────────────────────────────────────────
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
                            color: Colors.red.shade400, size: 48.sp),
                        SizedBox(height: 12.h),
                        Text(
                          state.message,
                          style: TextStyle(
                              color: Colors.red.shade400, fontSize: 14.sp),
                          textAlign: TextAlign.center,
                        ),
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

                  final hasLenderData = lender != null && lender.loanCount > 0;
                  final hasBorrowerData =
                      borrower != null && borrower.loanCount > 0;

                  if (!hasLenderData && !hasBorrowerData) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bar_chart_rounded,
                              size: 64.sp,
                              color: Colors.grey.shade300),
                          SizedBox(height: 16.h),
                          Text(
                            'No loan activity yet',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Your financial insights will appear here\nonce you give or take a loan.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    );
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
                          // ── LENDER SECTION ──────────────────────────────
                          if (hasLenderData) ...[
                            _SectionHeader(
                              icon: Icons.trending_up_rounded,
                              label: 'Loans I\'ve Given',
                              color: KhaataTheme.primaryBlue,
                            ),
                            SizedBox(height: 12.h),
                            _LenderBanner(
                                lender: lender!, fmt: _fmt),
                            SizedBox(height: 12.h),
                            _LenderStatGrid(lender: lender, fmt: _fmt),
                            SizedBox(height: 12.h),
                            if (lender.monthlyCollections.isNotEmpty)
                              _MonthlyChart(
                                  collections: lender.monthlyCollections,
                                  fmt: _fmt),
                            SizedBox(height: 28.h),
                          ],
                          // ── BORROWER SECTION ─────────────────────────────
                          if (hasBorrowerData) ...[
                            _SectionHeader(
                              icon: Icons.handshake_rounded,
                              label: 'Loans I\'ve Taken',
                              color: const Color(0xFF2E8B3C),
                            ),
                            SizedBox(height: 12.h),
                            _BorrowerBanner(borrower: borrower!, fmt: _fmt),
                            SizedBox(height: 12.h),
                            _BorrowerStatGrid(borrower: borrower, fmt: _fmt),
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

// ── Section header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _SectionHeader(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(6.w),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, color: color, size: 18.sp),
        ),
        SizedBox(width: 10.w),
        Text(
          label,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}

// ── Lender banner ─────────────────────────────────────────────────────────────
class _LenderBanner extends StatelessWidget {
  final LenderStats lender;
  final String Function(double) fmt;
  const _LenderBanner({required this.lender, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF184277), Color(0xFF1E5799)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF184277).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Lent',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '₹${fmt(lender.totalLent)}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    _miniChip(
                        '${lender.activeLoanCount} Active', Colors.white24),
                    SizedBox(width: 6.w),
                    _miniChip(
                        '${lender.closedLoanCount} Closed', Colors.white24),
                    if (lender.defaultedLoanCount > 0) ...[
                      SizedBox(width: 6.w),
                      _miniChip('${lender.defaultedLoanCount} Defaulted',
                          Colors.red.withValues(alpha: 0.35)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: lender.collectionRatePct >= 75
                      ? const Color(0xFF4CAF50)
                      : lender.collectionRatePct >= 50
                          ? Colors.orange
                          : Colors.red.shade400,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  '${lender.collectionRatePct}% Collected',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                '₹${fmt(lender.outstanding)}',
                style: TextStyle(
                  color: Colors.orange.shade200,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Outstanding',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 11.sp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniChip(String text, Color bg) => Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Text(
          text,
          style: TextStyle(
              color: Colors.white,
              fontSize: 10.sp,
              fontWeight: FontWeight.w600),
        ),
      );
}

// ── Lender stat grid ──────────────────────────────────────────────────────────
class _LenderStatGrid extends StatelessWidget {
  final LenderStats lender;
  final String Function(double) fmt;
  const _LenderStatGrid({required this.lender, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10.w,
      mainAxisSpacing: 10.h,
      childAspectRatio: 1.6,
      children: [
        _StatCard(
          icon: Icons.download_rounded,
          iconColor: const Color(0xFF2E8B3C),
          iconBg: const Color(0xFFE8F5E9),
          label: 'Collected',
          value: '₹${fmt(lender.totalCollected)}',
          valueColor: const Color(0xFF2E8B3C),
        ),
        _StatCard(
          icon: Icons.schedule_rounded,
          iconColor: Colors.orange.shade700,
          iconBg: Colors.orange.shade50,
          label: 'Outstanding',
          value: '₹${fmt(lender.outstanding)}',
          valueColor: Colors.orange.shade700,
        ),
        _StatCard(
          icon: Icons.people_rounded,
          iconColor: KhaataTheme.primaryBlue,
          iconBg: const Color(0xFFE3F0FF),
          label: 'Active Loans',
          value: '${lender.activeLoanCount}',
          valueColor: KhaataTheme.primaryBlue,
        ),
        _StatCard(
          icon: Icons.check_circle_rounded,
          iconColor: Colors.grey.shade600,
          iconBg: Colors.grey.shade100,
          label: 'Closed Loans',
          value: '${lender.closedLoanCount}',
          valueColor: Colors.grey.shade700,
        ),
      ],
    );
  }
}

// ── Monthly bar chart ─────────────────────────────────────────────────────────
class _MonthlyChart extends StatelessWidget {
  final List<MonthlyCollection> collections;
  final String Function(double) fmt;
  const _MonthlyChart({required this.collections, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final maxVal = collections.fold<int>(
        1, (m, e) => e.amountPaise > m ? e.amountPaise : m);

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Monthly Collections',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
              Text(
                'Last 6 months',
                style: TextStyle(
                    fontSize: 11.sp, color: Colors.grey.shade500),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          SizedBox(
            height: 100.h,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: collections.map((c) {
                final ratio = maxVal > 0 ? c.amountPaise / maxVal : 0.0;
                final barH = (ratio * 80.h).clamp(4.0, 80.h);
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (c.amountPaise > 0)
                          Text(
                            '₹${fmt(c.amountRupees ~/ 1000 > 0 ? c.amountRupees / 1000 : c.amountRupees)}${c.amountRupees >= 1000 ? 'k' : ''}',
                            style: TextStyle(
                              fontSize: 8.sp,
                              color: KhaataTheme.primaryBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        SizedBox(height: 2.h),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOut,
                          height: barH,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF1E5799),
                                KhaataTheme.primaryBlue,
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(4.r),
                            ),
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          c.month,
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
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
}

// ── Borrower banner ───────────────────────────────────────────────────────────
class _BorrowerBanner extends StatelessWidget {
  final BorrowerStats borrower;
  final String Function(double) fmt;
  const _BorrowerBanner({required this.borrower, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E8B3C), Color(0xFF3DA64A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E8B3C).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Borrowed',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '₹${fmt(borrower.totalBorrowed)}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    _miniChip(
                        '${borrower.activeLoanCount} Active', Colors.white24),
                    SizedBox(width: 6.w),
                    _miniChip(
                        '${borrower.closedLoanCount} Closed', Colors.white24),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: KhaataTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  '${borrower.repaymentRatePct}% Repaid',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                '₹${fmt(borrower.outstanding)}',
                style: TextStyle(
                  color: Colors.yellow.shade200,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Remaining',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 11.sp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniChip(String text, Color bg) => Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Text(
          text,
          style: TextStyle(
              color: Colors.white,
              fontSize: 10.sp,
              fontWeight: FontWeight.w600),
        ),
      );
}

// ── Borrower stat grid ────────────────────────────────────────────────────────
class _BorrowerStatGrid extends StatelessWidget {
  final BorrowerStats borrower;
  final String Function(double) fmt;
  const _BorrowerStatGrid({required this.borrower, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10.w,
      mainAxisSpacing: 10.h,
      childAspectRatio: 1.6,
      children: [
        _StatCard(
          icon: Icons.upload_rounded,
          iconColor: const Color(0xFF2E8B3C),
          iconBg: const Color(0xFFE8F5E9),
          label: 'Repaid',
          value: '₹${fmt(borrower.totalRepaid)}',
          valueColor: const Color(0xFF2E8B3C),
        ),
        _StatCard(
          icon: Icons.warning_amber_rounded,
          iconColor: Colors.red.shade600,
          iconBg: Colors.red.shade50,
          label: 'Remaining',
          value: '₹${fmt(borrower.outstanding)}',
          valueColor: Colors.red.shade600,
        ),
        _StatCard(
          icon: Icons.receipt_long_rounded,
          iconColor: const Color(0xFF2E8B3C),
          iconBg: const Color(0xFFE8F5E9),
          label: 'Active Loans',
          value: '${borrower.activeLoanCount}',
          valueColor: const Color(0xFF2E8B3C),
        ),
        _StatCard(
          icon: Icons.check_circle_rounded,
          iconColor: Colors.grey.shade600,
          iconBg: Colors.grey.shade100,
          label: 'Closed Loans',
          value: '${borrower.closedLoanCount}',
          valueColor: Colors.grey.shade700,
        ),
      ],
    );
  }
}

// ── Reusable stat card ────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;
  final Color valueColor;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: iconColor, size: 18.sp),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                    color: valueColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
