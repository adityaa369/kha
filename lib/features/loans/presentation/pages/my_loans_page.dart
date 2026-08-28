import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/blocs/auth/auth_cubit.dart';
import '../../../../core/blocs/loans/loan_cubit.dart';
import '../../../../core/blocs/loans/loan_state.dart';
import '../../../../data/models/loan_model.dart';
import '../../../../config/constants.dart';

class MyLoansPage extends StatefulWidget {
  const MyLoansPage({super.key});

  @override
  State<MyLoansPage> createState() => _MyLoansPageState();
}

class _MyLoansPageState extends State<MyLoansPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = [
    'All',
    'Hand Credit',
    'Business Credit',
    'Interest Credit',
    'Chit Funds',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KhaataTheme.backgroundGrey,
      body: Column(
        children: [
          // Blue Header
          Container(
            width: double.infinity,
            color: KhaataTheme.primaryBlue,
            padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 0),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manage Your Credits',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    indicatorColor: Colors.white,
                    indicatorWeight: 3.h,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    dividerColor: Colors.transparent,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.sp,
                    ),
                    unselectedLabelStyle: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13.sp,
                    ),
                    tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
                  ),
                ],
              ),
            ),
          ),

          // Stats Row
          BlocBuilder<LoanCubit, LoanState>(
            builder: (context, state) {
              int activeCount = 0;
              int closedCount = 0;
              if (state is LoansLoaded) {
                final selectedTabName = _tabs[_tabController.index];
                final filteredForStats = selectedTabName == 'All'
                    ? state.myLoans
                    : state.myLoans
                          .where((l) => l.displayType == selectedTabName)
                          .toList();

                activeCount = filteredForStats
                    .where(
                      (l) =>
                          l.status != 'completed' &&
                          l.status != 'pending_otp' &&
                          l.status != 'pending_approval' &&
                          l.status != 'rejected',
                    )
                    .length;
                closedCount = filteredForStats
                    .where((l) => l.status == 'completed')
                    .length;
              }

              return Container(
                color: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatBox(
                        count: activeCount.toString(),
                        label: 'Active Accounts',
                        color: KhaataTheme.accentGreen,
                      ),
                    ),
                    Container(
                      width: 1.w,
                      height: 40.h,
                      color: Colors.grey[200],
                    ),
                    Expanded(
                      child: _StatBox(
                        count: closedCount.toString(),
                        label: 'Closed Accounts',
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Loan List
          Expanded(
            child: BlocBuilder<LoanCubit, LoanState>(
              builder: (context, state) {
                if (state is LoanInitial) {
                  context.read<LoanCubit>().fetchLoans();
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is LoanLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is LoanError) {
                  return Center(child: Text(state.message));
                }

                if (state is LoansLoaded) {
                  return TabBarView(
                    controller: _tabController,
                    children: _tabs.map((tabName) {
                      final displayedLoans = tabName == 'All'
                          ? state.myLoans
                          : state.myLoans.where((l) {
                              return l.displayType == tabName;
                            }).toList();

                      if (displayedLoans.isEmpty) {
                        return RefreshIndicator(
                          color: KhaataTheme.primaryBlue,
                          onRefresh: () async {
                            await context.read<LoanCubit>().fetchLoans();
                          },
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(height: 100.h),
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 64.sp,
                                color: Colors.grey[300],
                              ),
                              SizedBox(height: 16.h),
                              Center(
                                child: Text(
                                  'No active accounts',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16.sp,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return RefreshIndicator(
                        color: KhaataTheme.primaryBlue,
                        onRefresh: () async {
                          await context.read<LoanCubit>().fetchLoans();
                        },
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.all(16.w),
                          itemCount: displayedLoans.length,
                          itemBuilder: (context, index) {
                            final loan = displayedLoans[index];
                            return Column(
                              children: [
                                _LoanCard(loan: loan),
                                SizedBox(height: 12.h),
                              ],
                            );
                          },
                        ),
                      );
                    }).toList(),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String count;
  final String label;
  final Color color;

  const _StatBox({
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 6.w,
              height: 6.w,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            SizedBox(width: 6.w),
            Text(
              count,
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(fontSize: 11.sp, color: Colors.grey),
        ),
      ],
    );
  }
}

class _LoanCard extends StatelessWidget {
  final LoanModel loan;

  const _LoanCard({required this.loan});

  Color _getBackgroundColor(String type) {
    switch (type.toLowerCase().replaceAll('_', '')) {
      case 'handcredit':
        return const Color(0xFFE8F5E9); // Light Green
      case 'businesscredit':
        return const Color(0xFFF3E5F5); // Light Purple
      case 'interestcredit':
        return const Color(0xFFFFF3E0); // Light Orange
      case 'chitfund':
      case 'chitfunds':
        return const Color(0xFFFCE8F3); // Light Pink
      default:
        return const Color(0xFFE8F4FD); // Light Blue
    }
  }

  Color _getTextColor(String type) {
    switch (type.toLowerCase().replaceAll('_', '')) {
      case 'handcredit':
        return const Color(0xFF1B5E20); // Dark Green
      case 'businesscredit':
        return const Color(0xFF4A148C); // Dark Violet
      case 'interestcredit':
        return const Color(0xFFE65100); // Dark Orange
      case 'chitfund':
      case 'chitfunds':
        return const Color(0xFF880E4F); // Dark Pinkish
      default:
        return const Color(0xFF1565C0); // Dark Blue
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.push(AppConstants.loanDetails, extra: loan);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Bank Header - Colored background
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: _getBackgroundColor(loan.type),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12.r),
                  topRight: Radius.circular(12.r),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36.w,
                        height: 36.w,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            loan.initials ?? 'UL',
                            style: TextStyle(
                              color: _getTextColor(loan.type),
                              fontWeight: FontWeight.bold,
                              fontSize: 16.sp,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loan.displayCounterpartyName, // Uses Lender's name if available, else borrower Name
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14.sp,
                            ),
                          ),
                          Text(
                            loan.type.toUpperCase(),
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Icon(Icons.person_outline, color: Colors.grey, size: 20.sp),
                ],
              ),
            ),
            // Body
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Loan Amount',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 11.sp,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            loan.displayAmount,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Status',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 11.sp,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            loan.statusDisplay,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: loan.statusColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  if (loan.loanStatus.isPending)
                    SizedBox(
                      width: double.infinity,
                      height: 48.h,
                      child: ElevatedButton(
                        onPressed: () {
                          context.push('/loan-approval', extra: loan);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: KhaataTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        child: Text(
                          'Review Agreement',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 48.h,
                      child: OutlinedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              title: const Text('Reminder Set'),
                              content: const Text(
                                'You will be reminded 3 days before the next due date.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => context.pop(),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: KhaataTheme.primaryBlue,
                          side: const BorderSide(
                            color: KhaataTheme.primaryBlue,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        child: Text(
                          'Set Reminder',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
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
}
