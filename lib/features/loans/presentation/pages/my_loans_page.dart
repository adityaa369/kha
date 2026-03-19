import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/blocs/auth/auth_cubit.dart';
import '../../../../core/blocs/loans/loan_cubit.dart';
import '../../../../core/blocs/loans/loan_state.dart';
import '../../../../data/models/loan_model.dart';

class MyLoansPage extends StatefulWidget {
  const MyLoansPage({super.key});

  @override
  State<MyLoansPage> createState() => _MyLoansPageState();
}

class _MyLoansPageState extends State<MyLoansPage> {
  String _selectedTab = 'All';

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
            padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 16.h),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manage Your Loans & Cards',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  // Dynamic Tabs are built inside the BlocBuilder below to access the loans
                  BlocBuilder<LoanCubit, LoanState>(
                    builder: (context, state) {
                      List<String> tabs = ['All'];
                      if (state is LoansLoaded) {
                        final types = state.myLoans.map((l) => l.type).toSet().toList();
                        // Format types to be title case (e.g. "hand_credit" -> "Hand Credit")
                        final formattedTypes = types.map((t) {
                          return t.split('_').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
                        }).toList();
                        tabs.addAll(formattedTypes);
                      }

                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: tabs.map((tab) {
                            return Padding(
                              padding: EdgeInsets.only(right: 20.w),
                              child: _Tab(
                                text: tab,
                                isSelected: _selectedTab == tab,
                                onTap: () {
                                  setState(() {
                                    _selectedTab = tab;
                                  });
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    },
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
                 // Filter loans based on selected tab for stats
                final filteredForStats = _selectedTab == 'All' 
                    ? state.myLoans 
                    : state.myLoans.where((l) {
                        final formattedType = l.type.split('_').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
                        return formattedType == _selectedTab;
                      }).toList();

                activeCount = filteredForStats.where((l) => l.status != 'completed' && l.status != 'pending_otp' && l.status != 'pending_approval' && l.status != 'rejected').length;
                closedCount = filteredForStats.where((l) => l.status == 'completed').length;
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
                          color: KhaataTheme.accentGreen),
                    ),
                    Container(
                        width: 1.w,
                        height: 40.h,
                        color: Colors.grey[200]),
                    Expanded(
                      child: _StatBox(
                          count: closedCount.toString(),
                          label: 'Closed Accounts',
                          color: Colors.grey),
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
                  final authState = context.read<AuthCubit>().state;
                  if (authState is Authenticated) {
                    context.read<LoanCubit>().fetchLoans();
                  }
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (state is LoanLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is LoanError) {
                  return Center(child: Text(state.message));
                }

                if (state is LoansLoaded) {
                  final displayedLoans = _selectedTab == 'All' 
                    ? state.myLoans 
                    : state.myLoans.where((l) {
                        final formattedType = l.type.split('_').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
                        return formattedType == _selectedTab;
                      }).toList();

                  if (displayedLoans.isEmpty) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 64.sp, color: Colors.grey[300]),
                        SizedBox(height: 16.h),
                        Text(
                          'No active accounts',
                          style: TextStyle(color: Colors.grey, fontSize: 16.sp),
                        ),
                      ],
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.all(16.w),
                    itemCount: displayedLoans.length,
                    itemBuilder: (context, index) {
                      final loan = displayedLoans[index];
                      return Column(
                        children: [
                          _LoanCard(
                            loan: loan,
                          ),
                          SizedBox(height: 12.h),
                        ],
                      );
                    },
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

class _Tab extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const _Tab({required this.text, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: isSelected ? 0 : 0),
        decoration: BoxDecoration(
          border: isSelected
              ? Border(
            bottom: BorderSide(
              color: Colors.white,
              width: 2.w,
            ),
          )
              : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: isSelected ? 14.sp : 13.sp,
          ),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String count;
  final String label;
  final Color color;

  const _StatBox({required this.count, required this.label, required this.color});

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
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}

class _LoanCard extends StatelessWidget {
  final LoanModel loan;

  const _LoanCard({
    required this.loan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Bank Header - Blue background
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F4FD), // Very light blue
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
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          loan.initials ?? 'UL',
                          style: TextStyle(
                            color: Colors.blue,
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
                Icon(
                  Icons.person_outline,
                  color: Colors.grey,
                  size: 20.sp,
                ),
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
                if (loan.status == 'pending_otp' || loan.status == 'pending_approval')
                  SizedBox(
                    width: double.infinity,
                    height: 48.h,
                    child: ElevatedButton(
                      onPressed: () {
                        context.push(
                          '/loan-approval',
                          extra: loan,
                        );
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                            title: const Text('Reminder Set'),
                            content: const Text('You will be reminded 3 days before the next due date.'),
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
                        side: BorderSide(color: KhaataTheme.primaryBlue),
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
    );
  }
}

String _formatCurrency(double amount) {
  return amount.toStringAsFixed(0).replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
  );
}

String _getMonthName(int month) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return months[month - 1];
}