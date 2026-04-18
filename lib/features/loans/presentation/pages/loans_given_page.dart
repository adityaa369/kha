import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme.dart';
import '../../../../config/constants.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/blocs/auth/auth_cubit.dart';
import '../../../../core/blocs/loans/loan_cubit.dart';
import '../../../../core/blocs/loans/loan_state.dart';
import '../../../../core/widgets/buttons.dart';

class LoansGivenPage extends StatelessWidget {
  const LoansGivenPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KhaataTheme.backgroundGrey,
      body: Column(
        children: [
          // Blue Header - Matching My Loans style
          Container(
            width: double.infinity,
            color: KhaataTheme.primaryBlue,
            padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 16.h),
            child: SafeArea(
              bottom: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Loans Given',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Stats Row - Like My Loans
          BlocBuilder<LoanCubit, LoanState>(
            builder: (context, state) {
              double totalLent = 0;
              double totalPending = 0;
              
              if (state is LoansLoaded) {
                for (var loan in state.givenLoans) {
                  if (loan.status != 'pending_otp' && loan.status != 'pending_approval' && loan.status != 'rejected') {
                    totalLent += loan.amount;
                    totalPending += loan.remainingAmount;
                  }
                }
              }

              return Container(
                color: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: Row(
                  children: [

                    Expanded(
                      child: _StatBox(
                        label: 'Pending',
                        amount: '₹ ${_formatCurrency(totalPending)}',
                        icon: Icons.arrow_downward,
                        color: KhaataTheme.warningYellow,
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
                  final authState = context.read<AuthCubit>().state;
                  if (authState is AuthenticatedFull) {
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
                  if (state.givenLoans.isEmpty) {
                    return RefreshIndicator(
                      color: KhaataTheme.primaryBlue,
                      onRefresh: () async {
                        await context.read<LoanCubit>().fetchLoans();
                      },
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(height: 100.h),
                          Icon(Icons.handshake_outlined, size: 64.sp, color: Colors.grey[300]),
                          SizedBox(height: 16.h),
                          Center(
                            child: Text(
                              'No active accounts',
                              style: TextStyle(color: Colors.grey, fontSize: 16.sp),
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
                    itemCount: state.givenLoans.length,
                    itemBuilder: (context, index) {
                      final loan = state.givenLoans[index];
                      // Format date for the UI
                      final dateStr = '${loan.startDate.day} ${_getMonthName(loan.startDate.month)} ${loan.startDate.year}';
                      
                      return Column(
                        children: [
                          _GivenLoanCard(
                            name: loan.displayCounterpartyName,
                            amount: loan.displayAmount,
                            date: dateStr,
                            status: loan.statusDisplay,
                            statusColor: loan.statusColor,
                            progress: loan.progress,
                            initials: loan.initials ?? loan.borrowerName[0].toUpperCase(),
                            totalPayable: loan.totalPayable != null ? '₹ ${_formatCurrency(loan.totalPayable!)}' : null,
                            onCloseLoan: () async {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => const Center(child: CircularProgressIndicator()),
                              );
                              
                              // Dispatch OTP dynamically
                              final otpSent = await context.read<LoanCubit>().requestClosureOtp(loan.id);
                              
                              if (!context.mounted) return;
                              Navigator.pop(context); // close loader
                              
                              if (otpSent) {
                                  // Prompt Secure Input from Lender
                                  final otpController = TextEditingController();
                                  showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (dialogContext) => AlertDialog(
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                          title: const Text('Finalize Closure', style: TextStyle(fontWeight: FontWeight.bold)),
                                          content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                  const Text('An OTP has been sent securely via Push Notification to the borrower. Enter it below to mutually confirm the agreement closure.'),
                                                  const SizedBox(height: 16),
                                                  TextField(
                                                      controller: otpController,
                                                      keyboardType: TextInputType.number,
                                                      maxLength: 6,
                                                      decoration: InputDecoration(
                                                          hintText: '6-digit OTP',
                                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                                                      backgroundColor: KhaataTheme.primaryBlue,
                                                      foregroundColor: Colors.white,
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                  ),
                                                  onPressed: () async {
                                                      if (otpController.text.length != 6) return;
                                                      
                                                      Navigator.pop(dialogContext); // hide dialog
                                                      
                                                      // Execute mutual closure natively
                                                      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
                                                      final success = await context.read<LoanCubit>().closeLoan(loan.id, otpController.text);
                                                      
                                                      if (!context.mounted) return;
                                                      Navigator.pop(context); // hide loader
                                                      
                                                      if (success) {
                                                          context.push(AppConstants.loanCloseSuccess);
                                                      } else {
                                                          final state = context.read<LoanCubit>().state;
                                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                                              backgroundColor: KhaataTheme.dangerRed,
                                                              content: Text(state is LoanError ? state.message : 'Invalid Authentication OTP.')
                                                          ));
                                                      }
                                                  },
                                                  child: const Text('Confirm'),
                                              ),
                                          ],
                                      ),
                                  );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Failed to initiate closure OTP.')),
                                );
                              }
                            },
                          ),
                          SizedBox(height: 12.h),
                        ],
                      );
                    },
                    ),
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
  final String label;
  final String amount;
  final IconData icon;
  final Color color;

  const _StatBox({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14.sp, color: color),
            SizedBox(width: 4.w),
            Text(
              label,
              style: TextStyle(fontSize: 11.sp, color: Colors.grey),
            ),
          ],
        ),
        SizedBox(height: 4.h),
        Text(
          amount,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _GivenLoanCard extends StatelessWidget {
  final String name;
  final String amount;
  final String date;
  final String status;
  final Color statusColor;
  final double progress;
  final String initials;
  final String? totalPayable;
  final VoidCallback onCloseLoan;

  const _GivenLoanCard({
    required this.name,
    required this.amount,
    required this.date,
    required this.status,
    required this.statusColor,
    required this.progress,
    required this.initials,
    required this.onCloseLoan,
    this.totalPayable,
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
          // Header with Avatar and Status
          Padding(
            padding: EdgeInsets.all(12.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18.w,
                      backgroundColor: statusColor.withOpacity(0.1),
                      child: Text(
                        initials,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14.sp,
                          ),
                        ),
                        Text(
                          date,
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 11.sp,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 11.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Amount and Progress
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      amount,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      status == 'Pending OTP' ? 'OTP Not Verified' : '${(progress * 100).toInt()}% Repaid',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: status == 'Pending OTP' ? Colors.redAccent : Colors.grey,
                        fontWeight: status == 'Pending OTP' ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2.r),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    minHeight: 4.h,
                  ),
                ),
                SizedBox(height: 12.h),
              ],
            ),
          ),

          // Action Buttons
          Padding(
            padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.w),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                          title: const Text('Reminder Sent'),
                          content: const Text('A payment reminder has been sent to the borrower.'),
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
                      side: const BorderSide(color: KhaataTheme.primaryBlue),
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text(
                      'Reminder',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
                        ),
                        builder: (context) => Container(
                          padding: EdgeInsets.all(20.w),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Loan Details',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: KhaataTheme.primaryBlue,
                                ),
                              ),
                              SizedBox(height: 16.h),
                              _DetailRow(label: 'Borrower', value: name),
                              _DetailRow(label: 'Amount', value: amount),
                              _DetailRow(label: 'Date', value: date),
                              _DetailRow(label: 'Status', value: status),
                              _DetailRow(label: 'Repaid', value: '${(progress * 100).toInt()}%'),
                              if (totalPayable != null) _DetailRow(label: 'Total Payable', value: totalPayable!),
                              SizedBox(height: 20.h),
                              if (status != 'Closed' && status != 'Completed')
                                SizedBox(
                                  width: double.infinity,
                                  child: PrimaryButton(
                                    text: 'Close Loan',
                                    onPressed: () {
                                      context.pop();
                                      onCloseLoan();
                                    },
                                  ),
                                ),
                              if (status != 'Closed' && status != 'Completed') SizedBox(height: 12.h),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: () => context.pop(),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: KhaataTheme.primaryBlue,
                                    side: BorderSide(color: KhaataTheme.primaryBlue),
                                    padding: EdgeInsets.symmetric(vertical: 14.h),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                  ),
                                  child: Text(
                                    'Back',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KhaataTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text(
                      'Details',
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
    'Dec'
  ];
  return months[month - 1];
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey, fontSize: 14.sp)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp)),
        ],
      ),
    );
  }
}