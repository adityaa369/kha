import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../../../config/constants.dart';
import '../../../../config/theme.dart';
import '../../../../core/widgets/buttons.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class LoanConfirmationPage extends StatefulWidget {
  final Map<String, dynamic> loanData;

  const LoanConfirmationPage({super.key, required this.loanData});

  @override
  State<LoanConfirmationPage> createState() => _LoanConfirmationPageState();
}

class _LoanConfirmationPageState extends State<LoanConfirmationPage> {
  final TextEditingController _otpController = TextEditingController();
  int _resendTimer = 30;
  bool _canResend = false;
  bool _isLoading = false;
  String _currentOtp = '';

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    setState(() {
      _canResend = false;
      _resendTimer = 30;
    });
    Future.delayed(Duration(seconds: 1), _tickTimer);
  }

  void _tickTimer() {
    if (mounted) {
      setState(() {
        _resendTimer--;
        if (_resendTimer <= 0) {
          _canResend = true;
        } else {
          Future.delayed(Duration(seconds: 1), _tickTimer);
        }
      });
    }
  }

  void _verifyOtp() {
    if (_currentOtp.length == 6) {
      setState(() => _isLoading = true);

      // Simulate API verification
      Future.delayed(Duration(seconds: 2), () {
        setState(() => _isLoading = false);

        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: KhaataTheme.accentGreen.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: KhaataTheme.accentGreen,
                    size: 48.sp,
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  'Agreement Confirmed!',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Loan agreement has been established with ${widget.loanData['borrowerName']}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: KhaataTheme.textGrey,
                  ),
                ),
                SizedBox(height: 24.h),
                PrimaryButton(
                  text: 'View Agreement',
                  onPressed: () {
                    context.pop();
                    context.go(AppConstants.home);
                  },
                ),
              ],
            ),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: KhaataTheme.textDark),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Confirm Agreement',
          style: TextStyle(
            color: KhaataTheme.textDark,
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Agreement Summary Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: KhaataTheme.primaryBlue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: KhaataTheme.primaryBlue.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Loan Agreement Summary',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: KhaataTheme.textGrey,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      '₹ ${widget.loanData['amount']}',
                      style: TextStyle(
                        fontSize: 32.sp,
                        fontWeight: FontWeight.bold,
                        color: KhaataTheme.primaryBlue,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'to ${widget.loanData['borrowerName']}',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        'Pending Borrower OTP',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: KhaataTheme.warningYellow,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 40.h),

              // OTP Section
              Text(
                'Enter OTP sent to',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: KhaataTheme.textGrey,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                '+91 ${widget.loanData['mobile']}',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 32.h),

              PinCodeTextField(
                appContext: context,
                length: 6,
                controller: _otpController,
                keyboardType: TextInputType.number,
                autoFocus: true,
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
                onCompleted: (value) {
                  setState(() => _currentOtp = value);
                  _verifyOtp();
                },
                onChanged: (value) {
                  setState(() => _currentOtp = value);
                },
              ),

              SizedBox(height: 24.h),

              // Resend Section
              _canResend
                  ? TextButton(
                onPressed: () {
                  _otpController.clear();
                  _startResendTimer();
                },
                child: Text(
                  'Resend OTP',
                  style: TextStyle(
                    color: KhaataTheme.primaryBlue,
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                  ),
                ),
              )
                  : Text(
                'Resend OTP in $_resendTimer seconds',
                style: TextStyle(
                  color: KhaataTheme.textGrey,
                  fontSize: 14.sp,
                ),
              ),

              SizedBox(height: 40.h),

              PrimaryButton(
                text: 'Verify & Confirm',
                isLoading: _isLoading,
                onPressed: _currentOtp.length == 6 ? _verifyOtp : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}