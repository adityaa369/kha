import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../data/models/loan_model.dart';
import '../../../../data/models/interest_schedule_model.dart';
import '../../../../data/repositories/loan_repository.dart';
import '../../../../core/blocs/loans/interest_schedule_cubit.dart';
import '../widgets/flexible_payment_sheet.dart';
import '../widgets/close_loan_sheet.dart';

class InterestLoanDetailsPage extends StatelessWidget {
  final LoanModel loan;

  const InterestLoanDetailsPage({super.key, required this.loan});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          InterestScheduleCubit(repository: context.read<LoanRepository>())
            ..fetchSchedule(loan.id),
      child: _InterestLoanDetailsView(loan: loan),
    );
  }
}

class _InterestLoanDetailsView extends StatelessWidget {
  final LoanModel loan;

  const _InterestLoanDetailsView({required this.loan});

  String _fmt(num amount) {
    return NumberFormat('#,##0', 'en_IN').format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final themePrimary = Colors.teal.shade700;
    final themeBg = Colors.teal.shade50;
    final isClosed = loan.status == 'closed' || loan.status == 'completed';
    final isTerminal =
        isClosed ||
        loan.status == 'rejected' ||
        loan.status == 'cancelled' ||
        loan.status == 'expired';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Interest Credit Details'),
        backgroundColor: themePrimary,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<InterestScheduleCubit>().fetchSchedule(loan.id);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(themePrimary),
              SizedBox(height: 16.h),
              _buildAgreementTerms(themePrimary),
              SizedBox(height: 16.h),
              _buildAuthoritativeBalances(themePrimary, themeBg),
              SizedBox(height: 16.h),
              _buildInterestTimeline(themePrimary),
              SizedBox(height: 24.h),
              if (!isTerminal && loan.financialStatus != 'FROZEN')
                _buildActionButtons(context, themePrimary),
              if (loan.financialStatus == 'FROZEN') _buildFrozenWarning(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color primary) {
    final isClosed = loan.status == 'closed' || loan.status == 'completed';
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loan.borrowerName.isEmpty
                    ? loan.userId ?? 'Unknown'
                    : loan.borrowerName,
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: isClosed ? Colors.grey.shade100 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  loan.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: isClosed
                        ? Colors.grey.shade700
                        : Colors.green.shade700,
                  ),
                ),
              ),
            ],
          ),
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              loan.borrowerName.isNotEmpty
                  ? loan.borrowerName[0].toUpperCase()
                  : 'B',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgreementTerms(Color primary) {
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
            children: [
              Icon(Icons.assignment_outlined, color: primary, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                'Agreement Terms',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Divider(height: 24.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Interest Method',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12.sp),
              ),
              Text(
                'SIMPLE_ORIGINAL_PRINCIPAL',
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Interest Rate',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12.sp),
              ),
              Text(
                loan.displayInterestRate,
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Original Principal',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12.sp),
              ),
              Text(
                '₹${_fmt(loan.amount)}',
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Accrual Convention',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12.sp),
              ),
              Text(
                'ACT/365 Fixed',
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAuthoritativeBalances(Color primary, Color bg) {
    return BlocBuilder<InterestScheduleCubit, InterestScheduleState>(
      builder: (context, state) {
        InterestScheduleModel? schedule;
        if (state is InterestScheduleLoaded) {
          schedule = state.schedule;
        } else if (state is InterestScheduleLoading)
          schedule = state.lastKnownData;
        else if (state is InterestScheduleError)
          schedule = state.lastKnownData;

        return Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: primary,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white70,
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Authoritative Ledger Balances',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (state is InterestScheduleLoading)
                    SizedBox(
                      width: 16.w,
                      height: 16.w,
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  if (state is InterestScheduleError)
                    Icon(
                      Icons.error_outline,
                      color: Colors.red.shade200,
                      size: 20.sp,
                    ),
                ],
              ),
              Divider(height: 24.h, color: Colors.white24),
              Row(
                children: [
                  Expanded(
                    child: _statBox(
                      'Accrued Interest',
                      schedule != null
                          ? '₹${_fmt(schedule.totalAccruedPaise / 100.0)}'
                          : '-',
                      Colors.white,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _statBox(
                      'Interest Paid',
                      schedule != null
                          ? '₹${_fmt(schedule.totalPaidPaise / 100.0)}'
                          : '-',
                      Colors.white,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: _statBox(
                      'Principal Outstanding',
                      '₹${_fmt(loan.principalOutstandingPaise / 100.0)}',
                      Colors.white,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _statBox(
                      'Interest Outstanding',
                      schedule != null
                          ? '₹${_fmt(schedule.outstandingInterestPaise / 100.0)}'
                          : '-',
                      Colors.orange.shade200,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statBox(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white70, fontSize: 11.sp),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildInterestTimeline(Color primary) {
    return BlocBuilder<InterestScheduleCubit, InterestScheduleState>(
      builder: (context, state) {
        InterestScheduleModel? schedule;
        if (state is InterestScheduleLoaded) {
          schedule = state.schedule;
        } else if (state is InterestScheduleLoading)
          schedule = state.lastKnownData;
        else if (state is InterestScheduleError)
          schedule = state.lastKnownData;

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
                children: [
                  Icon(Icons.calendar_month, color: primary, size: 20.sp),
                  SizedBox(width: 8.w),
                  Text(
                    'Interest Timeline',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Divider(height: 24.h),
              if (schedule == null && state is InterestScheduleLoading)
                const Center(child: CircularProgressIndicator())
              else if (schedule == null && state is InterestScheduleError)
                Center(
                  child: Text(
                    'Failed to load schedule',
                    style: TextStyle(color: Colors.red.shade400),
                  ),
                )
              else if (schedule != null && schedule.schedule.isEmpty)
                Center(
                  child: Text(
                    'No interest accrued or paid yet',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                )
              else if (schedule != null)
                ...schedule.schedule.map(
                  (p) => Padding(
                    padding: EdgeInsets.only(bottom: 16.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.month,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.sp,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Accrued',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12.sp,
                              ),
                            ),
                            Text(
                              '₹${_fmt(p.accruedPaise / 100.0)}',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Paid',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12.sp,
                              ),
                            ),
                            Text(
                              '₹${_fmt(p.paidPaise / 100.0)}',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Outstanding',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12.sp,
                              ),
                            ),
                            Text(
                              '₹${_fmt((p.accruedPaise - p.paidPaise) / 100.0)}',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ),
                        Divider(height: 16.h),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFrozenWarning() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.lock, color: Colors.orange.shade800),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'This loan is temporarily locked while its financial records are being verified.',
              style: TextStyle(color: Colors.orange.shade900, fontSize: 12.sp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, Color primary) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => FlexiblePaymentSheet.show(
                  context,
                  loan,
                  'Record Payment',
                  'payment',
                ),
                icon: const Icon(Icons.payment, size: 18),
                label: const Text('Record Payment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => FlexiblePaymentSheet.show(
                  context,
                  loan,
                  'Add Credit',
                  'add_credit',
                ),
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('Add Credit'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primary,
                  side: BorderSide(color: primary),
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => CloseLoanSheet.show(context, loan),
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Close Loan'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade700,
              side: BorderSide(color: Colors.red.shade200),
              padding: EdgeInsets.symmetric(vertical: 12.h),
            ),
          ),
        ),
      ],
    );
  }
}
