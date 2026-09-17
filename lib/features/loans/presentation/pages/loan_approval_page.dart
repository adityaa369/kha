import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/dialog_utils.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../config/theme.dart';
import '../../../../config/constants.dart';
import '../../../../core/blocs/loans/loan_cubit.dart';
import '../../../../core/blocs/loans/loan_state.dart';
import '../../../../data/models/loan_model.dart';
import '../../../../core/services/biometric_auth_service.dart';
import '../../../../core/blocs/auth/auth_cubit.dart';

class LoanApprovalPage extends StatefulWidget {
  final String loanId;

  const LoanApprovalPage({super.key, required this.loanId});

  @override
  State<LoanApprovalPage> createState() => _LoanApprovalPageState();
}

class _LoanApprovalPageState extends State<LoanApprovalPage> with WidgetsBindingObserver {
  bool _isApproving = false;
  bool _waitingForVerification = false;
  LoanModel? _loan;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchLoan();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _waitingForVerification) {
      _checkVerificationStatus();
    }
  }

  Future<void> _checkVerificationStatus() async {
    setState(() => _isApproving = true);
    await context.read<AuthCubit>().syncFirebaseState();
    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated && authState.user.isEmailVerified) {
      setState(() {
        _waitingForVerification = false;
        _isApproving = false;
      });
      if (mounted) {
         DialogUtils.showSuccessDialog(context, 'Email verified successfully!');
      }
    } else {
      setState(() => _isApproving = false);
    }
  }

  Future<void> _fetchLoan() async {
    final loan = await context.read<LoanCubit>().getLoanById(widget.loanId);
    if (mounted) {
      setState(() {
        _loan = loan;
        _isLoading = false;
      });
    }
  }

  void _approveLoan() async {
    if (_loan == null || _isApproving) return;

    setState(() => _isApproving = true);

    final authenticated = await BiometricAuthService.authenticate();
    if (!authenticated) {
      if (mounted) {
        setState(() => _isApproving = false);
        DialogUtils.showErrorDialog(context, 'Biometric signature required to accept agreement.');
      }
      return;
    }

    final cubit = context.read<LoanCubit>();
    
    // 1 Create ACCEPT_LOAN Intent
    final intentId = await cubit.createAcceptIntent(_loan!.id);
    if (intentId == null) {
      if (mounted) {
        setState(() => _isApproving = false);
        final state = context.read<LoanCubit>().state;
        if (state is LoanError && state.message.contains('Email verification is required')) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              title: const Text('Account Verification Required'),
              content: const Text('Please secure your account by verifying your email address before accepting financial agreements.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push('/profile/security').then((_) {
                      // Optionally refresh state or check eligibility again
                      // when returning from Security Hub
                      if (mounted) {
                        setState(() {});
                      }
                    });
                  },
                  child: const Text('Verify Account'),
                ),
              ],
            ),
          );
          return;
        } else {
          final errorMsg = state is LoanError ? state.message : 'Failed to initialize acceptance process.';
          DialogUtils.showErrorDialog(context, errorMsg);
        }
      }
      return;
    }

    // 2 Verify and Activate
    final success = await cubit.verifyLoan(_loan!.id, intentId);

    if (mounted) {
      setState(() => _isApproving = false);
      if (success) {
        DialogUtils.showSuccessDialog(context, 'Agreement accepted successfully!', onOk: () => context.pop(true));
      } else {
        DialogUtils.showErrorDialog(context, 'Failed to accept agreement. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_loan == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Review Agreement'),
          backgroundColor: Colors.white,
          foregroundColor: KhaataTheme.textDark,
        ),
        body: const Center(child: Text('Loan not found.')),
      );
    }

    final loan = _loan!;

    final currentUserId = context.read<AuthCubit>().state.user?.id;
    final isBorrower = loan.userId != null && currentUserId != null && loan.userId == currentUserId;

    return BlocListener<LoanCubit, LoanState>(
      listener: (context, state) {
        if (state is LoanVerificationSuccess) {
          context.go(AppConstants.loanSuccess);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Review Agreement'),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: KhaataTheme.textDark,
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Banner
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.pending_actions, color: Color(0xFFF59E0B)),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        loan.status == 'pending_approval'
                            ? 'Awaiting your signature'
                            : 'Awaiting completion',
                        style: const TextStyle(
                          color: Color(0xFFB45309),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),

              // Lender Info
              Text(
                'Lender',
                style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
              ),
              SizedBox(height: 4.h),
              Text(
                loan.lenderName ?? 'Unknown Lender',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: KhaataTheme.textDark,
                ),
              ),
              SizedBox(height: 32.h),

              // Loan Details Card
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Text(
                      'Amount Requested',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      '₹${NumberFormat('#,##0').format(loan.amount)}',
                      style: TextStyle(
                        fontSize: 32.sp,
                        fontWeight: FontWeight.bold,
                        color: KhaataTheme.primaryBlue,
                      ),
                    ),
                    SizedBox(height: 24.h),

                    const Divider(),
                    SizedBox(height: 16.h),
                    _DetailRow(
                      label: 'Interest',
                      value: (loan.interestRate ?? 0) > 0
                          ? '${loan.interestRate}% PM'
                          : '0% (Hand Loan)',
                    ),
                    SizedBox(height: 12.h),
                    _DetailRow(
                      label: 'Duration',
                      value: '${loan.durationMonths} Months',
                    ),
                    SizedBox(height: 12.h),
                    _DetailRow(label: 'Type', value: loan.type.toUpperCase()),
                    SizedBox(height: 12.h),
                    _DetailRow(
                      label: 'Date',
                      value: DateFormat(
                        'MMM dd, yyyy',
                      ).format(loan.createdAt ?? DateTime.now()),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32.h),

              if (loan.status == 'pending_approval' && isBorrower)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isApproving ? null : _approveLoan,
                    child: _isApproving
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Sign and Accept Agreement'),
                  ),
                ),

              SizedBox(height: 16.h),
              if (loan.status == 'pending_approval' && isBorrower)
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      if (!_isApproving) {
                        context.pop();
                      }
                    },
                    child: Text(
                      'Decline & Return',
                      style: TextStyle(
                        color: Colors.red[400],
                        fontWeight: FontWeight.w600,
                        fontSize: 16.sp,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: 14.sp),
        ),
        Text(
          value,
          style: TextStyle(
            color: KhaataTheme.textDark,
            fontWeight: FontWeight.w600,
            fontSize: 14.sp,
          ),
        ),
      ],
    );
  }
}
