import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
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
    
    final success = await context.read<LoanCubit>().requestConsentOtp(_loan!.id);
    
    if (!mounted) return;
    setState(() => _isApproving = false);
    
    if (success) {
      setState(() {
        _isOtpSent = true;
      });
      _startResendTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP requested successfully', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to request OTP', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _approveLoan() async {
    if (_loan == null) return;
    
    final authenticated = await BiometricAuthService.authenticate();
    if (!authenticated) {
      if (mounted) {
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
    
    if (_loan!.pendingIntentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Missing consent intent. Please refresh.', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isApproving = true);

    final success = await context.read<LoanCubit>().verifyLoan(_loan!.id, _loan!.pendingIntentId!, _currentOtp);

    if (mounted) {
      setState(() => _isApproving = false);
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agreement accepted successfully!', style: TextStyle(color: Colors.white)),
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
                        : Text('Request OTP to Sign'),
                  ),
                ),

              if (loan.status == 'pending_approval' && _isOtpSent) ...[
                Text(
                  'Enter 6-digit OTP sent to your phone',
                  style: TextStyle(fontSize: 14.sp, color: KhaataTheme.textGrey),
                ),
                SizedBox(height: 16.h),
                PinCodeTextField(
                  appContext: context,
                  length: 6,
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  autoFocus: true,
                  errorAnimationController: _errorController,
                  pinTheme: PinTheme(
                    shape: PinCodeFieldShape.box,
                    borderRadius: BorderRadius.circular(12.r),
                    fieldHeight: 50.h,
                    fieldWidth: 45.w,
                    activeFillColor: Colors.grey[100],
                    inactiveFillColor: Colors.grey[100],
                    selectedFillColor: Colors.blue[50],
                    activeColor: KhaataTheme.primaryBlue,
                    inactiveColor: Colors.grey[300],
                    selectedColor: KhaataTheme.primaryBlue,
                  ),
                  cursorColor: KhaataTheme.primaryBlue,
                  enableActiveFill: true,
                  onChanged: (value) {
                    setState(() => _currentOtp = value);
                  },
                ),
                SizedBox(height: 16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Didn\'t receive code? ',
                      style: TextStyle(fontSize: 14.sp, color: KhaataTheme.textGrey),
                    ),
                    TextButton(
                      onPressed: _canResend ? _requestOtp : null,
                      child: Text(
                        _canResend ? 'Resend' : 'Resend in ${_resendTimer}s',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: _canResend ? KhaataTheme.primaryBlue : Colors.grey[400],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _currentOtp.length == 6
                        ? (_isApproving ? null : _approveLoan)
                        : null,
                    child: _isApproving
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('Sign & Accept Terms'),
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
