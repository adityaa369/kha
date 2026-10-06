import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../core/blocs/loans/repayment_timeline_cubit.dart';
import '../../../../data/models/loan_model.dart';
import '../../../../data/repositories/loan_repository.dart';

class RepaymentTimelineWidget extends StatelessWidget {
  final LoanModel loan;

  const RepaymentTimelineWidget({super.key, required this.loan});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RepaymentTimelineCubit(LoanRepository())..fetchTimeline(loan.id),
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

            if (!model.trackingEnabled || model.timeline.isEmpty) {
              return const SizedBox.shrink();
            }

            return Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    loan.type.toLowerCase().contains('interest') ||
                            loan.type.toLowerCase().contains('home')
                        ? 'Monthly Interest Overview'
                        : 'Monthly Payment Overview',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: model.timeline.map((period) {
                        final statusStr = period.status.toUpperCase();
                        final isPaid = statusStr == 'PAID';
                        final isPartial = statusStr == 'PARTIALLY_PAID' || statusStr == 'PARTIAL';
                        
                        final start = DateFormat('MMM dd').format(period.periodStart);
                        final end = DateFormat('MMM dd').format(period.periodEnd);
                        
                        Color boxColor = Colors.white;
                        Color borderColor = Colors.red.shade200;
                        IconData icon = Icons.close;
                        Color iconColor = Colors.red.shade300;

                        if (isPaid) {
                           boxColor = Colors.green.shade50;
                           borderColor = Colors.green;
                           icon = Icons.check;
                           iconColor = Colors.green;
                        } else if (isPartial) {
                           boxColor = Colors.orange.shade50;
                           borderColor = Colors.orange;
                           icon = Icons.warning_amber_rounded;
                           iconColor = Colors.orange;
                        }

                        return Container(
                          margin: EdgeInsets.only(right: 12.w),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Month ${period.periodIndex}',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.grey.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                '$start - $end',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Container(
                                width: 50.w,
                                height: 55.h,
                                decoration: BoxDecoration(
                                  color: boxColor,
                                  border: Border.all(color: borderColor, width: 1.5),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                alignment: Alignment.center,
                                child: Icon(icon, color: iconColor, size: 20.sp),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
