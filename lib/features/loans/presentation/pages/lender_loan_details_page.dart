import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../config/constants.dart';
import '../../../../config/theme.dart';
import '../../../../data/models/loan_model.dart';
import '../../../../core/blocs/loans/loan_cubit.dart';
import '../../../../core/blocs/system/system_state_cubit.dart';
import '../widgets/repayment_timeline_widget.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/blocs/loans/loan_state.dart';
import '../widgets/flexible_payment_sheet.dart';

class LenderLoanDetailsPage extends StatelessWidget {
  final LoanModel loan;
  const LenderLoanDetailsPage({super.key, required this.loan});

  // â”€â”€â”€ Theme by loan type â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static final Map<String, _TypeTheme> _typeColors = {
    'hand_credit': const _TypeTheme(
      Color(0xFF1B5E20),
      Color(0xFFE8F5E9),
      'Hand Credit',
    ),
    'business_credit': const _TypeTheme(
      Color(0xFF1565C0),
      Color(0xFFE3F2FD),
      'Business Credit',
    ),
    'interest_credit': const _TypeTheme(
      Color(0xFFE65100),
      Color(0xFFFFF3E0),
      'Interest Credit',
    ),
  };

  _TypeTheme _theme(String type) =>
      _typeColors[type] ??
      const _TypeTheme(Color(0xFF37474F), Color(0xFFECEFF1), 'Loan');

  // â”€â”€â”€ Build â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LoanCubit, LoanState>(
      listener: (context, state) {
        if (state is LoanError) {
          ErrorHandler.showError(context, state.message);
        }
      },
      builder: (context, state) {
        final activeLoan = state is LoansLoaded
            ? (state.myLoans + state.givenLoans).firstWhere(
                (l) => l.id == loan.id,
                orElse: () => loan,
              )
            : loan;

        final theme = _theme(activeLoan.type);
        final duration = activeLoan.durationMonths ?? 1;
        final progress = activeLoan.progress.clamp(0.0, 1.0);
        final paidMonths = (duration * progress).round();
        final isClosed =
            activeLoan.status == 'closed' || activeLoan.status == 'completed';
        final isPending =
            activeLoan.status == 'pending_otp' ||
            activeLoan.status == 'pending_approval';
        final isLoading = state is LoanLoading;

        return Scaffold(
          backgroundColor: KhaataTheme.backgroundGrey,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => context.pop(),
            ),
            title: Text(
              '${theme.label} — Lender View',
              style: TextStyle(
                color: theme.primary,
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            centerTitle: true,
          ),
          bottomNavigationBar: _bottomBar(
            context,
            activeLoan,
            theme,
            isClosed,
            isPending,
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _borrowerCard(activeLoan, theme),
                    SizedBox(height: 14.h),
                    _summaryCard(
                      activeLoan,
                      theme,
                      duration,
                      paidMonths,
                      progress,
                    ),
                    SizedBox(height: 14.h),
                    if (!isPending) ...[
                      _repaymentChecklist(
                        context,
                        activeLoan,
                        theme,
                        duration,
                        paidMonths,
                      ),
                      SizedBox(height: 14.h),
                      _loanProgressCard(activeLoan, theme, duration, paidMonths, progress),
                      SizedBox(height: 14.h),
                      _recentTransactions(activeLoan, theme),
                      SizedBox(height: 14.h),
                      if (activeLoan.documentUrl != null &&
                          activeLoan.documentUrl!.isNotEmpty) ...[
                        _documentSection(context, activeLoan, theme),
                        SizedBox(height: 16.h),
                      ],
                    ],
                    if (isPending) _pendingCard(context, activeLoan),
                    SizedBox(height: 80.h), // space for bottom bar
                  ],
                ),
              ),
              if (isLoading)
                Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        );
      },
    );
  }

  // â”€â”€â”€ Borrower Card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _borrowerCard(LoanModel loan, _TypeTheme theme) {
    final name = loan.borrowerName.isNotEmpty ? loan.borrowerName : 'Borrower';
    final initial = name[0].toUpperCase();
    final phone = loan.mobile ?? '';

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 52.w,
            height: 52.w,
            decoration: BoxDecoration(color: theme.bg, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: TextStyle(
                color: theme.primary,
                fontWeight: FontWeight.w800,
                fontSize: 18.sp,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                if (phone.isNotEmpty) ...[
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      Icon(
                        Icons.phone_outlined,
                        size: 12.sp,
                        color: Colors.grey,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        phone,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (phone.isNotEmpty)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _iconActionBtn(Icons.phone, 'Call', Colors.green.shade600, () {
                  Clipboard.setData(ClipboardData(text: phone));
                }),
                SizedBox(width: 16.w),
                _iconActionBtn(
                  Icons.chat_bubble_outline,
                  'WhatsApp',
                  Colors.green.shade600,
                  () async {
                    final uri = Uri.parse('https://wa.me/91$phone');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _iconActionBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22.sp, color: color),
          SizedBox(height: 2.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€â”€ Summary Card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _summaryCard(
    LoanModel loan,
    _TypeTheme theme,
    int duration,
    int paidMonths,
    double progress,
  ) {
    final actualStart = loan.startDate ?? loan.activatedAt ?? loan.createdAt ?? DateTime.now();
    final start = _dateStr(actualStart);
    final end = loan.endDate != null ? _dateStr(loan.endDate!) : _dateStr(actualStart.add(Duration(days: (loan.durationMonths ?? duration) * 30)));
    final rate = loan.interestRate ?? 0.0;
    final monthly = rate > 0
        ? loan.amount * rate / 100
        : (loan.emiAmount ?? 0.0);
    // originalTotal = what was owed at activation
    final originalTotal = (loan.totalPayableAmount != null && loan.paidAmount != null && loan.paidAmount! > 0)
        ? loan.totalPayableAmount! + loan.paidAmount!
        : ((loan.totalPayableAmount ?? 0.0) > 0
            ? loan.totalPayableAmount!
            : loan.amount + (monthly * duration));
    // remaining = what the backend says is still owed (totalPayableAmount is updated on each payment)
    final remaining = loan.totalPayableAmount ?? (originalTotal * (1 - progress));
    final collected = originalTotal - remaining;
    final isInterest = loan.type.toLowerCase().contains('interest') || loan.type.toLowerCase().contains('home');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badges
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: theme.bg,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isInterest) ...[
                         Text('% Interest Credit', style: TextStyle(color: theme.primary, fontSize: 12.sp, fontWeight: FontWeight.bold)),
                      ] else ...[
                         Text('💰 Hand Credit', style: TextStyle(color: theme.primary, fontSize: 12.sp, fontWeight: FontWeight.bold)),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    'Active Loan',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade100),
          // Amounts Row
          Padding(
            padding: EdgeInsets.all(14.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _stat(
                    isInterest ? 'Principal' : 'Given Amount',
                    '₹${_fmt(loan.amount)}',
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _stat(
                    isInterest ? 'Monthly Interest' : 'Received Amount',
                    isInterest ? '₹${_fmt(monthly)}' : '₹${_fmt(collected)}',
                    valueColor: isInterest ? theme.primary : Colors.green.shade700,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _stat(
                    isInterest ? 'Total Interest' : 'Remaining Amount',
                    isInterest ? '₹${_fmt(monthly * duration)}' : '₹${_fmt(remaining)}',
                    valueColor: isInterest ? Colors.black87 : Colors.red.shade600,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade100),
          // Dates Row
          Padding(
            padding: EdgeInsets.all(14.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _stat('Start Date', start)),
                SizedBox(width: 12.w),
                Expanded(child: _stat('Duration', '$duration Months')),
                SizedBox(width: 12.w),
                Expanded(child: _stat('End Date', end)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _loanProgressCard(LoanModel loan, _TypeTheme theme, int duration, int paidMonths, double progress) {
    final nextDue = (loan.startDate ?? DateTime.now()).add(Duration(days: (paidMonths + 1) * 30));
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Loan Progress',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              Text(
                '$paidMonths of $duration months completed',
                style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade100,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF22C55E)), // Green
              minHeight: 8.h,
            ),
          ),
          SizedBox(height: 16.h),
          Divider(height: 1, color: Colors.grey.shade100),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Next Payment Due Date: ',
                        style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600),
                      ),
                      TextSpan(
                        text: _dateStr(nextDue),
                        style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today, size: 12.sp, color: Colors.red.shade600),
                    SizedBox(width: 4.w),
                    Text(
                      'View Schedule',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _recentTransactions(LoanModel loan, _TypeTheme theme) {
    final txns = loan.transactions.reversed.toList(); // newest first
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Transactions',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: Colors.black87),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: theme.bg,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                '${txns.length} records',
                style: TextStyle(fontSize: 11.sp, color: theme.primary, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        if (txns.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Icon(Icons.receipt_long_outlined, color: Colors.grey.shade400, size: 32.sp),
                SizedBox(height: 8.h),
                Text('No transactions recorded yet', style: TextStyle(color: Colors.grey, fontSize: 12.sp)),
                SizedBox(height: 4.h),
                Text('Use Record Payment below to log payments', style: TextStyle(color: Colors.grey.shade400, fontSize: 11.sp)),
              ],
            ),
          )
        else
          ...txns.map((tx) => _txItem(
            _txIcon(tx.type as String? ?? ''),
            _txColor(tx.type as String? ?? ''),
            _txTitle(tx.type as String? ?? ''),
            tx.note as String? ?? '',
            _txAmountStr(tx.type as String? ?? '', (tx.amount as num?)?.toDouble() ?? 0),
            _txDateStr(tx.recordedAt),
            _txIsPositive(tx.type as String? ?? ''),
          )),
      ],
    );
  }

  IconData _txIcon(String type) {
    switch (type) {
      case 'payment': return Icons.arrow_downward;
      case 'interest_payment': return Icons.percent;
      case 'credit_added': return Icons.add_circle_outline;
      case 'loan_given': return Icons.arrow_upward;
      default: return Icons.swap_horiz;
    }
  }

  Color _txColor(String type) {
    switch (type) {
      case 'payment': return Colors.green.shade600;
      case 'interest_payment': return Colors.teal.shade600;
      case 'credit_added': return Colors.orange.shade600;
      case 'loan_given': return Colors.red.shade400;
      default: return Colors.grey;
    }
  }

  String _txTitle(String type) {
    switch (type) {
      case 'payment': return 'Payment Received';
      case 'interest_payment': return 'Interest Received';
      case 'credit_added': return 'Credit Added';
      case 'loan_given': return 'Loan Disbursed';
      default: return 'Transaction';
    }
  }

  String _txAmountStr(String type, double amount) {
    final sign = type == 'loan_given' ? '-' : '+';
    return '$sign₹${_fmt(amount)}';
  }

  bool _txIsPositive(String type) => type != 'loan_given';

  String _txDateStr(dynamic rawDate) {
    if (rawDate == null) return '';
    try {
      final dt = DateTime.parse(rawDate.toString()).toLocal();
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return '';
    }
  }

  Widget _txItem(IconData icon, Color color, String title, String subtitle, String amount, String date, bool isPositive) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 16.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp, color: Colors.black87)),
                SizedBox(height: 2.h),
                Text(subtitle, style: TextStyle(color: Colors.grey, fontSize: 11.sp)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp, color: isPositive ? Colors.green.shade700 : Colors.red.shade600)),
              SizedBox(height: 2.h),
              Text(date, style: TextStyle(color: Colors.grey, fontSize: 11.sp)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w400,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 3.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: valueColor ?? Colors.black87,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // â”€â”€â”€ Repayment Checklist â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _repaymentChecklist(
    BuildContext context,
    LoanModel loan,
    _TypeTheme theme,
    int duration,
    int paidMonths,
  ) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loan.type.toLowerCase().contains('interest') || loan.type.toLowerCase().contains('home')
                ? 'Monthly Interest Overview'
                : 'Monthly Payment Overview',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12.h),
          if (duration > 0)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: List.generate(duration, (index) {
                  final isPaid = index < paidMonths;
                  final dueDate = (loan.startDate ?? DateTime.now()).add(
                    Duration(days: (index + 1) * 30),
                  );

                  return GestureDetector(
                    onTap: () => _toggleMonth(
                      context,
                      loan,
                      index,
                      paidMonths,
                      duration,
                    ),
                    child: Container(
                      margin: EdgeInsets.only(right: 12.w),
                      child: Column(
                        children: [
                          Text(
                            '${_monthName(dueDate.month)} ${dueDate.year}',
                            style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade600),
                          ),
                          SizedBox(height: 6.h),
                          Container(
                            width: 50.w,
                            height: 55.h,
                            decoration: BoxDecoration(
                              color: isPaid ? Colors.green.shade50 : Colors.white,
                              border: Border.all(
                                color: isPaid ? Colors.green : Colors.red.shade200,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              isPaid ? Icons.check : Icons.close,
                              color: isPaid ? Colors.green : Colors.red.shade300,
                              size: 20.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Icon(Icons.info_outline, size: 12.sp, color: Colors.grey),
              SizedBox(width: 4.w),
              Text(
                'Tick (âœ“) if paid, Cross (âœ—) if not paid.',
                style: TextStyle(fontSize: 10.sp, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _toggleMonth(
    BuildContext context,
    LoanModel loan,
    int monthIndex,
    int currentPaid,
    int duration,
  ) {
    final loanCubit = context.read<LoanCubit>();
    double newProgress;

    if (monthIndex < currentPaid) {
      // Mark this month and all after it as unpaid â†’ set progress to monthIndex/duration
      newProgress = monthIndex / duration;
    } else {
      // Mark up to and including this month as paid
      newProgress = (monthIndex + 1) / duration;
    }

    newProgress = newProgress.clamp(0.0, 1.0);
    loanCubit.updateProgress(loan.id, newProgress);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: newProgress > loan.progress
            ? Colors.green.shade700
            : Colors.orange.shade700,
        content: Text(
          newProgress > loan.progress
              ? 'Month ${monthIndex + 1} marked as paid âœ“'
              : 'Month ${monthIndex + 1} marked as unpaid',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // â”€â”€â”€ Document Section â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _documentSection(
    BuildContext context,
    LoanModel loan,
    _TypeTheme theme,
  ) {
    if (loan.documentUrl == null || loan.documentUrl!.trim().isEmpty) {
      return Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(
              Icons.description_outlined,
              color: Colors.grey.shade300,
              size: 28.sp,
            ),
            SizedBox(width: 12.w),
            Text(
              'No document was uploaded',
              style: TextStyle(color: Colors.grey, fontSize: 13.sp),
            ),
          ],
        ),
      );
    }

    final url = loan.documentUrl!;
    final isPdf = url.toLowerCase().contains('.pdf');

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Agreement & Proof Document',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12.h),
          InkWell(
            onTap: () => _showDocumentDialog(context, url, isPdf, theme),
            borderRadius: BorderRadius.circular(12.r),
            child: Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: theme.bg,
                border: Border.all(color: theme.primary.withValues(alpha: 0.2)),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40.w,
                    height: 40.w,
                    decoration: BoxDecoration(
                      color: theme.bg,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: isPdf
                        ? const Icon(
                            Icons.picture_as_pdf,
                            color: Color(0xFFDC2626),
                            size: 22,
                          )
                        : Image.network(
                            url,
                            fit: BoxFit.cover,
                            loadingBuilder: (ctx, child, p) => p == null
                                ? child
                                : const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.image,
                              color: theme.primary,
                              size: 22,
                            ),
                          ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPdf ? 'Signed_Agreement.pdf' : 'Proof_Document.jpg',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Tap to view uploaded document',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.visibility_outlined,
                    color: theme.primary,
                    size: 18.sp,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDocumentDialog(
    BuildContext context,
    String url,
    bool isPdf,
    _TypeTheme theme,
  ) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        backgroundColor: Colors.white,
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isPdf ? 'Agreement & Signature' : 'Proof Document',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black54),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            // Body
            Flexible(
              child: Container(
                color: Colors.grey.shade50,
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
                child: isPdf
                    ? _pdfWidget(context, url, theme)
                    : _imageWidget(url),
              ),
            ),
            // Footer
            Container(
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade100)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final uri = Uri.parse(url);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                      icon: Icon(Icons.open_in_new, size: 15.sp),
                      label: Text(
                        'Open External',
                        style: TextStyle(fontSize: 12.sp),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.primary,
                        side: BorderSide(color: theme.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      child: Text(
                        'Close',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageWidget(String url) {
    return SizedBox(
      width: double.infinity,
      height: 300.h,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.network(
            url,
            fit: BoxFit.contain,
            cacheWidth: 1080,
            loadingBuilder: (_, child, p) => p == null
                ? child
                : const Center(child: CircularProgressIndicator()),
            errorBuilder: (_, __, ___) => const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.broken_image, size: 48, color: Colors.grey),
                  Text(
                    'Failed to load image',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pdfWidget(BuildContext context, String url, _TypeTheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFFEE2E2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.picture_as_pdf,
              color: Color(0xFFDC2626),
              size: 48,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'PDF Document',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "Open External" to view in browser or PDF reader.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€â”€ Pending Card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    void _confirmCancel(BuildContext context, LoanModel loan) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Request'),
        content: const Text('Are you sure you want to cancel this pending loan request? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('No')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await context.read<LoanCubit>().deleteLoan(loan.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Request cancelled successfully')),
                  );
                  context.pop();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to cancel: $e')),
                  );
                }
              }
            },
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

    Widget _pendingCard(BuildContext context, LoanModel loan) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.access_time_filled,
            color: const Color(0xFFD97706),
            size: 24.sp,
          ),
          SizedBox(height: 8.h),
          Text(
            loan.status == 'pending_otp'
                ? 'Pending OTP Verification'
                : 'Pending Borrower Signature',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14.sp,
              color: const Color(0xFF92400E),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            loan.status == 'pending_otp'
                ? 'An OTP was sent to the borrower. They must verify it to activate the loan.'
                : 'The borrower must accept and sign the agreement.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.sp, color: const Color(0xFFB45309)),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              if (loan.status == 'pending_otp') ...[
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => context.push('/loan-confirmation', extra: {
                        'loan_id': loan.id,
                        'borrower_name': loan.borrowerName,
                        'borrower_phone': loan.mobile,
                        'amount': loan.amountPaise,
                      }),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      foregroundColor: Colors.white,
                      minimumSize: Size(0, 40.h),
                    ),
                    child: const Text('Verify OTP Now'),
                  ),
                ),
                SizedBox(width: 8.w),
              ],
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _confirmCancel(context, loan),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade300),
                    minimumSize: Size(0, 40.h),
                  ),
                  child: const Text('Cancel Request'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  // â”€â”€â”€ Bottom Bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _bottomBar(
    BuildContext context,
    LoanModel loan,
    _TypeTheme theme,
    bool isClosed,
    bool isPending,
  ) {
    if (isClosed || isPending) return const SizedBox.shrink();
    
    final t = loan.type.toLowerCase();
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (t.contains('interest') || t.contains('home')) ...[
              Expanded(
                child: _bottomActionButton(context, loan, '% Record Interest Payment', theme.primary, theme.bg, 'record_interest'),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _bottomActionButton(context, loan, 'ðŸ’³ Record Principal Payment', Colors.blue.shade700, Colors.blue.shade50, 'record_payment'),
              ),
            ] else ...[
              Expanded(
                child: _bottomActionButton(context, loan, 'ðŸ’³ Record Payment', Colors.green.shade700, Colors.green.shade50, 'record_payment'),
              ),
            ],
            SizedBox(width: 8.w),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _initiateLoanClose(context, loan),
                icon: Icon(Icons.delete, size: 14.sp),
                label: Text('Close Loan', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red.shade700,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomActionButton(BuildContext context, LoanModel loan, String label, Color color, Color bgColor, String actionType) {
    return ElevatedButton(
      onPressed: () => FlexiblePaymentSheet.show(context, loan, label.replaceAll(RegExp(r'[^a-zA-Z\s]'), '').trim(), actionType),
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: color,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 4.w),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold),
      ),
    );
  }

  // â”€â”€â”€ Close Loan (OTP) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void _initiateLoanClose(BuildContext context, LoanModel loan) {
    final loanCubit = context.read<LoanCubit>();
    final sm = ScaffoldMessenger.of(context);
    final phone = loan.mobile ?? '';
    if (phone.isEmpty) {
      sm.showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Borrower phone number missing'),
        ),
      );
      return;
    }

    final formatted = phone.startsWith('+') ? phone : '+91$phone';

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: formatted,
      verificationCompleted: (_) {},
      verificationFailed: (e) {
        if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
        sm.showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('OTP failed: ${e.message}'),
          ),
        );
      },
      codeSent: (String vId, int? _) {
        if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
        _showOtpDialog(context, loan, loanCubit, vId, formatted, sm);
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  void _showOtpDialog(
    BuildContext context,
    LoanModel loan,
    LoanCubit loanCubit,
    String vId,
    String phone,
    ScaffoldMessengerState sm,
  ) {
    final otpCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Confirm Closure',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'An OTP has been sent to the borrower ($phone). Enter it to confirm closure.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: otpCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                hintText: '6-digit OTP',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              if (otpCtrl.text.length != 6) return;
              Navigator.pop(dialogContext);
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) =>
                    const Center(child: CircularProgressIndicator()),
              );

              final success = await loanCubit.closeLoan(
                loan.id,
                otpCtrl.text,
                vId,
              );
              if (context.mounted) {
                Navigator.of(context, rootNavigator: true).pop();
              }

              if (success && context.mounted) {
                context.go(AppConstants.loanCloseSuccess);
              } else {
                sm.showSnackBar(
                  const SnackBar(
                    backgroundColor: Colors.red,
                    content: Text('Invalid OTP. Closure failed.'),
                  ),
                );
              }
            },
            child: const Text('Confirm Close'),
          ),
        ],
      ),
    );
  }

  // â”€â”€â”€ Helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  String _fmt(double v) {
    if (v.isNaN || v.isInfinite) return '0';
    return NumberFormat('#,##,##0', 'en_IN').format(v);
  }

  String _dateStr(DateTime d) => '${d.day} ${_monthName(d.month)} ${d.year}';

  String _monthName(int m) {
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
      'Dec',
    ];
    if (m < 1 || m > 12) return 'Jan';
    return months[m - 1];
  }

}


// â”€â”€â”€ Theme helper class â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _TypeTheme {
  final Color primary;
  final Color bg;
  final String label;
  const _TypeTheme(this.primary, this.bg, this.label);
}



