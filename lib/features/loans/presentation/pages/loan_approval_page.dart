import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/blocs/loans/loan_cubit.dart';
import '../../../../core/blocs/loans/loan_state.dart';
import '../../../../data/models/loan_model.dart';
import '../../../../core/services/biometric_auth_service.dart';
import '../../../../config/theme.dart';
import '../../../../config/constants.dart';
import 'dart:async';

class LoanApprovalPage extends StatefulWidget {
  final String loanId;

  const LoanApprovalPage({super.key, required this.loanId});

  @override
  State<LoanApprovalPage> createState() => _LoanApprovalPageState();
}

class _LoanApprovalPageState extends State<LoanApprovalPage> {
  bool _isApproving = false;
  bool _isOtpSent = false;
  String _currentOtp = '';
  LoanModel? _loan;
  bool _isLoading = true;
  int _resendTimer = 30;
  bool _canResend = false;
  String? _verificationId;
  late StreamController<ErrorAnimationType> _errorController;
  final TextEditingController _otpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _errorController = StreamController<ErrorAnimationType>();
    _fetchLoan();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _errorController.close();
    super.dispose();
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

  void _startResendTimer() {
    if (!mounted) return;
    setState(() {
      _canResend = false;
      _resendTimer = 30;
    });
    _tickTimer();
  }

  void _tickTimer() {
    if (!mounted) return;
    if (_resendTimer > 0) {
      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        setState(() {
          _resendTimer--;
        });
        _tickTimer();
      });
    } else {
      setState(() {
        _canResend = true;
      });
    }
  }

  void _requestOtp() async {
    if (_loan == null) return;
    setState(() => _isApproving = true);
    final phone = FirebaseAuth.instance.currentUser?.phoneNumber;
    if (phone == null) {
      if (mounted) setState(() => _isApproving = false);
      return;
    }
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (credential) async {
        // Android may complete verification without showing the SMS field.
        // Use that credential directly instead of leaving the UI loading.
        await FirebaseAuth.instance.signInWithCredential(credential);
        final intentId = _loan?.pendingIntentId;
        if (intentId == null) return;
        final success = await context.read<LoanCubit>().verifyLoan(_loan!.id, intentId);
        if (!mounted) return;
        setState(() => _isApproving = false);
        if (!success) _errorController.add(ErrorAnimationType.shake);
      },
      verificationFailed: (error) {
        if (!mounted) return;
        setState(() => _isApproving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message ?? 'Unable to send OTP')));
      },
      codeSent: (verificationId, _) {
        if (!mounted) return;
        setState(() { _verificationId = verificationId; _isOtpSent = true; _isApproving = false; });
        _startResendTimer();
      },
      codeAutoRetrievalTimeout: (verificationId) => _verificationId = verificationId,
    );
  }

  void _approveLoan() async {
    if (_loan == null || _verificationId == null || _currentOtp.length != 6) return;
    if (_isApproving) return;

    setState(() => _isApproving = true);

    final authenticated = await BiometricAuthService.authenticate();
    if (!authenticated) {
      if (mounted) {
        setState(() => _isApproving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentication required to accept agreement'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (!mounted) return;
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!, smsCode: _currentOtp,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(() => _isApproving = false);
        _errorController.add(ErrorAnimationType.shake);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message ?? 'Invalid OTP')));
      }
      return;
    }

    final intentId = _loan!.pendingIntentId;
    if (intentId == null || intentId.isEmpty) {
      if (mounted) setState(() => _isApproving = false);
      return;
    }
    final success = await context.read<LoanCubit>().verifyLoan(_loan!.id, intentId);

    if (mounted) {
      setState(() => _isApproving = false);
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Agreement accepted successfully!',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
    } else if (!success && mounted) {
      _errorController.add(ErrorAnimationType.shake);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to accept agreement. Check OTP and try again.',
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
        body: const Center(child: Text('Loan not found.')),
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

              if (loan.status == 'pending_approval' && !_isOtpSent)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isApproving ? null : _requestOtp,
                    child: _isApproving
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Send OTP to Sign'),
                  ),
                ),

              if (loan.status == 'pending_approval' && _isOtpSent) ...[
                const SizedBox(height: 16),
                PinCodeTextField(
                  appContext: context,
                  length: 6,
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  errorAnimationController: _errorController,
                  onChanged: (value) => setState(() => _currentOtp = value),
                  onCompleted: (value) => setState(() => _currentOtp = value),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isApproving || _currentOtp.length != 6 ? null : _approveLoan,
                    child: _isApproving
                        ? const CircularProgressIndicator()
                        : const Text('Verify OTP & Accept Agreement'),
                  ),
                ),
              ],

              SizedBox(height: 16.h),
              if (loan.status == 'pending_approval')
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
