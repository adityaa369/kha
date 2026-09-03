import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/blocs/loans/loan_cubit.dart';
import '../../../../core/blocs/loans/loan_state.dart';
import '../../../../data/models/loan_model.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/biometric_auth_service.dart';
import '../../../../config/constants.dart';

class LoanApprovalPage extends StatefulWidget {
  final String loanId;

  const LoanApprovalPage({super.key, required this.loanId});

  @override
  State<LoanApprovalPage> createState() => _LoanApprovalPageState();
}

class _LoanApprovalPageState extends State<LoanApprovalPage> {
  bool _isApproving = false;
  LoanModel? _loan;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLoan();
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
    if (_loan == null) return;
    
    final authenticated = await BiometricAuthService.authenticate();
    if (!authenticated) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Biometric signature required to accept loan.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (!mounted) return;
    setState(() => _isApproving = true);

    final success = await context.read<LoanCubit>().verifyLoan(_loan!.id);

    if (mounted) {
      setState(() => _isApproving = false);
    }

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to accept agreement. Try again.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
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
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Review Agreement'),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: KhaataTheme.textDark,
        ),
        body: const Center(
          child: Text('Loan not found.'),
        ),
      );
    }

    final loan = _loan!;

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
                    const Icon(
                      Icons.pending_actions,
                      color: Color(0xFFF59E0B),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        loan.status == 'pending_otp'
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
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[600],
                ),
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
                      '₹${NumberFormat('#,##0').format(loan.amount / 100)}',
                      style: TextStyle(
                        fontSize: 32.sp,
                        fontWeight: FontWeight.bold,
                        color: KhaataTheme.primaryBlue,
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // Temporary OTP Display Box for Testing
                    if (loan.status == 'pending_otp') ...[
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Share this OTP with Lender',
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 12.h),
                            Text(
                              loan.otp == 'FIREBASE_OTP'
                                  ? 'Verified by App'
                                  : (loan.otp ?? '-'),
                              style: TextStyle(
                                fontSize: loan.otp == 'FIREBASE_OTP'
                                    ? 24.sp
                                    : 32.sp,
                                fontWeight: FontWeight.bold,
                                color: KhaataTheme.textDark,
                                letterSpacing: loan.otp == 'FIREBASE_OTP'
                                    ? 1
                                    : 4,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              loan.otp == 'FIREBASE_OTP'
                                  ? 'Digital handshake complete'
                                  : 'This confirms your agreement to the loan terms',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24.h),
                    ],

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
                    _DetailRow(
                      label: 'Type',
                      value: loan.type.toUpperCase(),
                    ),
                    SizedBox(height: 12.h),
                    _DetailRow(
                      label: 'Date',
                      value: DateFormat('MMM dd, yyyy')
                          .format(loan.createdAt ?? DateTime.now()),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32.h),

              // Action Buttons
              if (loan.status == 'pending_otp')
                PrimaryButton(
                  text: 'Sign & Accept Terms',
                  isLoading: _isApproving,
                  onPressed: _approveLoan,
                ),
              SizedBox(height: 16.h),
              if (loan.status == 'pending_otp')
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

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14.sp,
          ),
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
