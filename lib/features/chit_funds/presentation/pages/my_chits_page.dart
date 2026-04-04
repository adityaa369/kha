import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../config/theme.dart';
import '../../../../core/blocs/chit_funds/chit_fund_cubit.dart';
import '../../../../core/blocs/chit_funds/chit_fund_state.dart';

class MyChitsPage extends StatefulWidget {
  const MyChitsPage({super.key});

  @override
  State<MyChitsPage> createState() => _MyChitsPageState();
}

class _MyChitsPageState extends State<MyChitsPage> {
  final NumberFormat currencyFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChitFundCubit>().loadInvitesAndOwned();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KhaataTheme.backgroundGrey,
      appBar: AppBar(
        backgroundColor: KhaataTheme.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'My Chits',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<ChitFundCubit, ChitFundState>(
        builder: (context, state) {
          if (state is ChitFundLoading || state is ChitFundInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          List<Map<String, dynamic>> subs = [];
          if (state is ChitFundInvitesLoaded) {
            subs = state.mySubscriptions;
          }

          if (subs.isEmpty) {
            return Center(
              child: Text(
                'You have not subscribed to any active Chits yet.',
                style: TextStyle(color: KhaataTheme.textGrey, fontSize: 14.sp),
              ),
            );
          }

          double totalDueOverall = 0;
          for (var sub in subs) {
             num due = sub['dueAmount'] ?? 0;
             totalDueOverall += due;
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  itemCount: subs.length,
                  itemBuilder: (context, index) {
                    return _MyChitCard(
                      index: index,
                      subData: subs[index],
                      currencyFormatter: currencyFormatter,
                    );
                  },
                ),
              ),
              // Bottom Payment Bar
              Container(
                padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 24.h),
                color: KhaataTheme.cardWhite,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currencyFormatter.format(totalDueOverall),
                      style: TextStyle(
                        color: KhaataTheme.dangerRed, // Red
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Total Current Dues',
                      style: TextStyle(
                        color: KhaataTheme.textGrey,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    SizedBox(
                      width: double.infinity,
                      height: 54.h,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: KhaataTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        child: Text(
                          'Checkout / Pay',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          );
        },
      ),
    );
  }
}

class _MyChitCard extends StatelessWidget {
  final int index;
  final Map<String, dynamic> subData;
  final NumberFormat currencyFormatter;
  
  const _MyChitCard({
    required this.index,
    required this.subData,
    required this.currencyFormatter,
  });

  @override
  Widget build(BuildContext context) {
    String chitName = subData['chitName'] ?? 'Unknown Group';
    String branch = subData['branchName'] ?? 'HEAD-OFFICE';
    num totalValue = subData['totalValue'] ?? 0;
    num dueAmount = subData['dueAmount'] ?? 0;
    int totalMonths = subData['totalMonths'] ?? 1;
    int completedMonths = subData['completedMonths'] ?? 0;
    
    double progress = totalMonths > 0 ? (completedMonths / totalMonths) : 0.0;

    return InkWell(
      onTap: () {
        context.push('/chit-admin', extra: subData['chitId'] ?? subData['_id']);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: KhaataTheme.cardWhite,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: KhaataTheme.borderGrey, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
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
                chitName,
                style: TextStyle(
                  color: KhaataTheme.textDark,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: KhaataTheme.backgroundGrey,
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Row(
                  children: [
                    Text(
                      'Details',
                      style: TextStyle(
                        color: KhaataTheme.primaryBlue,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Icon(Icons.arrow_forward_rounded, color: KhaataTheme.primaryBlue, size: 14.sp),
                  ],
                ),
              )
            ],
          ),
          SizedBox(height: 20.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Subscribed Value',
                    style: TextStyle(
                      color: KhaataTheme.textGrey,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    currencyFormatter.format(totalValue),
                    style: TextStyle(
                      color: KhaataTheme.textDark,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Due Amount',
                    style: TextStyle(
                      color: KhaataTheme.textGrey,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    currencyFormatter.format(dueAmount),
                    style: TextStyle(
                      color: KhaataTheme.dangerRed,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              )
            ],
          ),
          SizedBox(height: 20.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Circular Progress
              SizedBox(
                width: 50.w,
                height: 50.w,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 5.w,
                      backgroundColor: KhaataTheme.borderGrey,
                      valueColor: const AlwaysStoppedAnimation<Color>(KhaataTheme.accentGreen), 
                    ),
                    Center(
                      child: Text(
                        '$completedMonths/$totalMonths',
                        style: TextStyle(
                          color: KhaataTheme.textDark,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Branch
              Column(
                children: [
                  Text(
                    'Branch',
                    style: TextStyle(
                      color: KhaataTheme.textGrey,
                      fontSize: 11.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    branch,
                    style: TextStyle(
                      color: KhaataTheme.textDark,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              // Amount Button
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  border: Border.all(color: KhaataTheme.borderGrey),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Row(
                  children: [
                    Icon(Icons.currency_rupee, color: KhaataTheme.textGrey, size: 14.sp),
                    SizedBox(width: 4.w),
                    Text(
                      'Pay Installment',
                      style: TextStyle(
                        color: KhaataTheme.textGrey,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            ],
          )
        ],
      ),
      ),
    );
  }
}
