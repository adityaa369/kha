import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme.dart';
import '../../../../config/constants.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/blocs/auth/auth_cubit.dart';
import '../../../../core/blocs/loans/loan_cubit.dart';
import '../../../../core/blocs/loans/loan_state.dart';
import '../../../../core/blocs/navigation/navigation_cubit.dart';
import '../../../../data/models/loan_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoansGivenPage extends StatelessWidget {
  const LoansGivenPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KhaataTheme.backgroundGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.read<NavigationCubit>().changeTab(0);
            }
          },
        ),
        title: Text(
          'Given Loans',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black87),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: BlocBuilder<LoanCubit, LoanState>(
        builder: (context, state) {
          double totalPending = 0;

          if (state is LoansLoaded) {
            var filteredGivenLoans = state.givenLoans
                .where((l) => l.type != 'chit_fund')
                .toList();
            for (var loan in filteredGivenLoans) {
              if (loan.status != 'pending_otp' &&
                  loan.status != 'pending_approval' &&
                  loan.status != 'rejected') {
                totalPending += loan.remainingAmount;
              }
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Card: Balance to Collect
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 24.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2FDF5), // Light green tint
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Balance to Collect',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        '₹${_formatCurrency(totalPending)}',
                        style: TextStyle(
                          fontSize: 32.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // "All Loans" section header
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: Text(
                  'All Loans',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),

              // Expanded ListView
              Expanded(child: _buildLoanList(context, state)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoanList(BuildContext context, LoanState state) {
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
      final filteredGivenList = state.givenLoans
          .where((l) => l.type != 'chit_fund')
          .toList();

      if (filteredGivenList.isEmpty) {
        return RefreshIndicator(
          color: Colors.green.shade700,
          onRefresh: () async {
            await context.read<LoanCubit>().fetchLoans();
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(height: 100.h),
              Icon(
                Icons.handshake_outlined,
                size: 64.sp,
                color: Colors.grey[300],
              ),
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
        color: Colors.green.shade700,
        onRefresh: () async {
          await context.read<LoanCubit>().fetchLoans();
        },
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          itemCount: filteredGivenList.length,
          itemBuilder: (context, index) {
            final loan = filteredGivenList[index];
            final dateStr =
                '${(loan.startDate ?? DateTime.now()).day} ${_getMonthName((loan.startDate ?? DateTime.now()).month)} ${(loan.startDate ?? DateTime.now()).year}';

            // Generate initials color dynamically
            final colorPairs = [
              const _ColorPair(
                bg: Color(0xFFE8F5E9),
                text: Color(0xFF2E7D32),
              ), // Green
              const _ColorPair(
                bg: Color(0xFFE3F2FD),
                text: Color(0xFF1565C0),
              ), // Blue
              const _ColorPair(
                bg: Color(0xFFFFF3E0),
                text: Color(0xFFEF6C00),
              ), // Orange
              const _ColorPair(
                bg: Color(0xFFFFEBEE),
                text: Color(0xFFC62828),
              ), // Red/Pinkish
              const _ColorPair(
                bg: Color(0xFFF3E5F5),
                text: Color(0xFF6A1B9A),
              ), // Purple
            ];
            final colorPair = colorPairs[index % colorPairs.length];

            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: _GivenLoanCard(
                loan: loan,
                name: loan.displayCounterpartyName,
                mobile: loan.mobile ?? '-',
                amount: '₹${_formatCurrency(loan.amount)}',
                date: dateStr,
                status: loan.statusDisplay,
                progress: loan.progress,
                initials:
                    loan.initials ??
                    (loan.borrowerName.isNotEmpty
                        ? loan.borrowerName[0].toUpperCase()
                        : 'L'),
                colorPair: colorPair,
                totalPayable: loan.totalPayable != null
                    ? '₹ ${_formatCurrency(loan.totalPayable!)}'
                    : null,
                onCloseLoan: () async {
                  final router = GoRouter.of(context);
                  final navigator = Navigator.of(context, rootNavigator: true);
                  final sm = ScaffoldMessenger.of(context);
                  final loanCubit = context.read<LoanCubit>();

                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) =>
                        const Center(child: CircularProgressIndicator()),
                  );

                  try {
                    final phone = loan.mobile;
                    if (phone == null || phone.isEmpty) {
                      throw 'Borrower phone number is missing';
                    }
                    final formattedPhone = phone.startsWith('+')
                        ? phone
                        : '+91$phone';

                    String? verificationId;

                    await FirebaseAuth.instance.verifyPhoneNumber(
                      phoneNumber: formattedPhone,
                      verificationCompleted:
                          (PhoneAuthCredential credential) {},
                      verificationFailed: (FirebaseAuthException e) {
                        navigator.pop(); // close loader
                        sm.showSnackBar(
                          SnackBar(
                            backgroundColor: KhaataTheme.dangerRed,
                            content: Text(
                              'Firebase SMS OTP failed: ${e.message}',
                            ),
                          ),
                        );
                      },
                      codeSent: (String vId, int? resendToken) {
                        navigator.pop(); // close loader
                        verificationId = vId;

                        final otpController = TextEditingController();
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (dialogContext) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: const Text(
                              'Finalize Closure',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'An OTP has been sent securely via Firebase SMS to the borrower ($formattedPhone). Enter it below to mutually confirm the agreement closure.',
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: otpController,
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
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade700,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () async {
                                  if (otpController.text.length != 6) return;

                                  Navigator.pop(dialogContext); // hide dialog

                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (_) => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );

                                  final success = await loanCubit.closeLoan(
                                    loan.id,
                                    otpController.text,
                                    verificationId!,
                                  );

                                  navigator.pop(); // hide loader

                                  if (success) {
                                    router.push(AppConstants.loanCloseSuccess);
                                  } else {
                                    final state = loanCubit.state;
                                    final String errorMsg = state is LoanError
                                        ? state.message
                                        : 'Invalid Authentication OTP.';
                                    sm.showSnackBar(
                                      SnackBar(
                                        backgroundColor: KhaataTheme.dangerRed,
                                        content: Text(errorMsg),
                                      ),
                                    );
                                  }
                                },
                                child: const Text('Confirm'),
                              ),
                            ],
                          ),
                        );
                      },
                      codeAutoRetrievalTimeout: (String vId) {
                        verificationId = vId;
                      },
                    );
                  } catch (e) {
                    navigator.pop(); // close loader
                    sm.showSnackBar(
                      SnackBar(
                        backgroundColor: KhaataTheme.dangerRed,
                        content: Text('Failed to initiate closure OTP: $e'),
                      ),
                    );
                  }
                },
              ),
            );
          },
        ),
      );
    }
    return const SizedBox();
  }
}

class _ColorPair {
  final Color bg;
  final Color text;
  const _ColorPair({required this.bg, required this.text});
}

class _GivenLoanCard extends StatelessWidget {
  final LoanModel loan;
  final String name;
  final String mobile;
  final String amount;
  final String date;
  final String status;
  final double progress;
  final String initials;
  final _ColorPair colorPair;
  final String? totalPayable;
  final VoidCallback onCloseLoan;

  const _GivenLoanCard({
    required this.loan,
    required this.name,
    required this.mobile,
    required this.amount,
    required this.date,
    required this.status,
    required this.progress,
    required this.initials,
    required this.colorPair,
    required this.onCloseLoan,
    this.totalPayable,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppConstants.lenderLoanDetails, extra: loan),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.grey.shade100, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Initials Avatar Block
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color: colorPair.bg,
                borderRadius: BorderRadius.circular(12.r),
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: TextStyle(
                  color: colorPair.text,
                  fontWeight: FontWeight.w800,
                  fontSize: 14.sp,
                ),
              ),
            ),
            SizedBox(width: 12.w),

            // Name and Phone
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    mobile,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),

            // Amount and given subtitle
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amount,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Given Amount',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(width: 12.w),

            // Chevron Right
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey.shade400,
              size: 20.sp,
            ),
          ],
        ),
      ),
    );
  }
}

String _formatCurrency(double amount) {
  return amount
      .toStringAsFixed(0)
      .replaceAllMapped(
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
    'Dec',
  ];
  return months[month - 1];
}
