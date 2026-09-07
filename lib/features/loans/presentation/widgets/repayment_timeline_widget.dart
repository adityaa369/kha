import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../config/theme.dart';
import '../../../../core/blocs/loans/repayment_timeline_cubit.dart';
import '../../../../data/models/loan_model.dart';
import '../../../../core/utils/pdf_generator.dart';
import '../../../../data/repositories/loan_repository.dart';

class RepaymentTimelineWidget extends StatelessWidget {
  final LoanModel loan;

  const RepaymentTimelineWidget({super.key, required this.loan});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          RepaymentTimelineCubit(LoanRepository())..fetchTimeline(loan.id),
      child: BlocBuilder<RepaymentTimelineCubit, RepaymentTimelineState>(
        builder: (context, state) {
          if (state is RepaymentTimelineLoading) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(),
              ),
            );
          } else if (state is RepaymentTimelineError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  state.message,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          } else if (state is RepaymentTimelineLoaded) {
            final model = state.timelineModel;

            if (!model.trackingEnabled) {
              return const SizedBox.shrink(); // Hide for chit loans or inactive
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Payment Activity',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: KhaataTheme.textDark,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.picture_as_pdf,
                          color: KhaataTheme.primaryBlue,
                        ),
                        onPressed: () {
                          PdfGenerator.generateAndShareStatement(loan, model);
                        },
                        tooltip: 'Download Statement',
                      ),
                    ],
                  ),
                ),
                ...model.timeline.map((period) => _buildPeriodCard(period)),
                if (model.postTermTransactions.isNotEmpty) ...[
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    child: Text(
                      'Post-Term Activity',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ),
                  ...model.postTermTransactions.map(
                    (tx) => _buildTransactionRow(tx, isPostTerm: true),
                  ),
                ],
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildPeriodCard(dynamic period) {
    final dateFormat = DateFormat('MMM dd');
    final currencyFmt = NumberFormat('#,##0', 'en_IN');

    final bool hasActivity = period.hasPayments;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: hasActivity
                    ? Colors.green.shade50
                    : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasActivity ? Icons.check_circle : Icons.radio_button_unchecked,
                color: hasActivity ? Colors.green : Colors.grey,
                size: 16.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Month ${period.periodIndex}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.sp,
                    color: KhaataTheme.textDark,
                  ),
                ),
                Text(
                  '${dateFormat.format(period.periodStart)} - ${dateFormat.format(period.periodEnd)}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: KhaataTheme.textGrey,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Text(
          hasActivity
              ? '₹${currencyFmt.format(period.totalPaid)}'
              : 'No Activity',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14.sp,
            color: hasActivity ? Colors.green.shade700 : KhaataTheme.textGrey,
          ),
        ),
        children: period.transactions.isEmpty
            ? [
                Padding(
                  padding: EdgeInsets.only(
                    bottom: 16.h,
                    left: 16.w,
                    right: 16.w,
                  ),
                  child: Text(
                    'No payments recorded during this period.',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: KhaataTheme.textGrey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ]
            : period.transactions
                  .map<Widget>((tx) => _buildTransactionRow(tx))
                  .toList(),
      ),
    );
  }

  Widget _buildTransactionRow(dynamic tx, {bool isPostTerm = false}) {
    final currencyFmt = NumberFormat('#,##0', 'en_IN');
    final dateFmt = DateFormat('MMM dd, yyyy');

    return Container(
      margin: isPostTerm
          ? EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h)
          : EdgeInsets.only(left: 48.w, right: 16.w, bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isPostTerm ? Colors.orange.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: isPostTerm ? Colors.orange.shade200 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tx.type == 'interest_payment'
                    ? 'Interest Payment'
                    : 'Principal Payment',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.sp),
              ),
              SizedBox(height: 4.h),
              Text(
                dateFmt.format(tx.recordedAt),
                style: TextStyle(color: KhaataTheme.textGrey, fontSize: 11.sp),
              ),
            ],
          ),
          Text(
            '₹${currencyFmt.format(tx.amount)}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14.sp,
              color: KhaataTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
