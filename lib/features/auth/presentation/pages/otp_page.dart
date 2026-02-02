import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'dart:async';
import '../../../../config/constants.dart';
import '../../../../config/theme.dart';
import '../../../../core/widgets/buttons.dart';

class OtpPage extends StatefulWidget {
  const OtpPage({super.key});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final TextEditingController _otpController = TextEditingController();
  StreamController<ErrorAnimationType>? _errorController;
  int _resendTimer = 30;
  bool _canResend = false;
  bool _isLoading = false;
  bool _hasError = false;
  String _currentOtp = '';

  @override
  void initState() {
    super.initState();
    _errorController = StreamController<ErrorAnimationType>.broadcast();
    _startResendTimer();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _errorController?.close();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _canResend = false;
      _resendTimer = 30;
      _hasError = false;
    });

    Future.delayed(Duration(seconds: 1), _tickTimer);
  }

  void _tickTimer() {
    if (mounted && _resendTimer > 0) { // ADD: && _resendTimer > 0 check
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

        // Mock validation - in real app, verify with backend
        if (_currentOtp == '000000') {
          setState(() => _hasError = true);
          _errorController?.add(ErrorAnimationType.shake);
        } else {
          context.push(AppConstants.personalDetails);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: KhaataTheme.textDark),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20.h),

              // Icon
              Container(
                width: 80.w,
                height: 80.h,
                decoration: BoxDecoration(
                  color: _hasError
                      ? KhaataTheme.dangerRed.withOpacity(0.1)
                      : KhaataTheme.accentGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Icon(
                  _hasError ? Icons.error_outline : Icons.lock_outline,
                  color: _hasError ? KhaataTheme.dangerRed : KhaataTheme.accentGreen,
                  size: 40.sp,
                ),
              ),

              SizedBox(height: 32.h),

              // Title
              Text(
                'Verify OTP',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 8.h),

              // Subtitle with phone number
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: KhaataTheme.textGrey,
                    height: 1.5,
                  ),
                  children: [
                    TextSpan(text: 'Enter the 6-digit code sent to\n'),
                    TextSpan(
                      text: '+91 98765 43210',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: KhaataTheme.textDark,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 40.h),

              // PIN Code Fields
              PinCodeTextField(
                appContext: context,
                length: 6,
                controller: _otpController,
                animationType: AnimationType.fade,
                keyboardType: TextInputType.number,
                enablePinAutofill: true,
                autoFocus: true,
                errorAnimationController: _errorController,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(12.r),
                  fieldHeight: 56.h,
                  fieldWidth: 48.w,
                  activeFillColor: Colors.white,
                  inactiveFillColor: Colors.grey[100],
                  selectedFillColor: Colors.blue[50],
                  activeColor: _hasError ? KhaataTheme.dangerRed : KhaataTheme.primaryBlue,
                  inactiveColor: Colors.grey[300],
                  selectedColor: KhaataTheme.primaryBlue,
                  errorBorderColor: KhaataTheme.dangerRed,
                ),
                cursorColor: KhaataTheme.primaryBlue,
                animationDuration: Duration(milliseconds: 300),
                textStyle: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: KhaataTheme.textDark,
                ),
                backgroundColor: Colors.transparent,
                enableActiveFill: true,

                onCompleted: (value) {
                  setState(() => _currentOtp = value);
                  _verifyOtp();
                },
                onChanged: (value) {
                  setState(() {
                    _currentOtp = value;
                    if (_hasError) _hasError = false;
                  });
                },
                beforeTextPaste: (text) {
                  if (text != null && RegExp(r'^\d{6}$').hasMatch(text)) {
                    return true;
                  }
                  return false;
                },
              ),

              if (_hasError) ...[
                SizedBox(height: 12.h),
                Text(
                  'Invalid OTP. Please try again.',
                  style: TextStyle(
                    color: KhaataTheme.dangerRed,
                    fontSize: 14.sp,
                  ),
                ),
              ],

              SizedBox(height: 32.h),

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

              // Verify Button
              PrimaryButton(
                text: 'Verify',
                isLoading: _isLoading,
                onPressed: _currentOtp.length == 6 ? _verifyOtp : null,
              ),

              SizedBox(height: 24.h),

              // Help Section
              TextButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20.r),
                      ),
                    ),
                    builder: (context) => Container(
                      padding: EdgeInsets.all(24.w),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Didn\'t receive OTP?',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          SizedBox(height: 16.h),
                          _buildHelpItem('1. Check your mobile number',
                              'Ensure +91 98765 43210 is correct'),
                          SizedBox(height: 12.h),
                          _buildHelpItem('2. Check SMS inbox/spam',
                              'The OTP might be in your spam folder'),
                          SizedBox(height: 12.h),
                          _buildHelpItem('3. Wait before resending',
                              'You can request a new OTP after 30 seconds'),
                          SizedBox(height: 24.h),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: KhaataTheme.primaryBlue,
                              ),
                              child: Text('Got it'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                icon: Icon(Icons.help_outline, size: 18.sp),
                label: Text(
                  'Having trouble?',
                  style: TextStyle(fontSize: 14.sp),
                ),
              ),

              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHelpItem(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14.sp,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            color: KhaataTheme.textGrey,
            fontSize: 12.sp,
          ),
        ),
      ],
    );
  }
}