import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/blocs/auth/auth_cubit.dart';
import 'dart:async';
import '../../../../config/constants.dart';
import '../../../../config/theme.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/utils/dialog_utils.dart';

class RegistrationOtpPage extends StatefulWidget {
  final String phone;
  const RegistrationOtpPage({super.key, required this.phone});

  @override
  State<RegistrationOtpPage> createState() => _RegistrationOtpPageState();
}

class _RegistrationOtpPageState extends State<RegistrationOtpPage> {
  final TextEditingController _otpController = TextEditingController();
  StreamController<ErrorAnimationType>? _errorController;
  int _resendTimer = 30;
  bool _canResend = false;
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
    if (!mounted) return;
    setState(() {
      _canResend = false;
      _resendTimer = 30;
      _hasError = false;
    });

    Future.delayed(const Duration(seconds: 1), _tickTimer);
  }

  void _tickTimer() {
    if (!mounted) return;
    if (_resendTimer > 0) {
      setState(() {
        _resendTimer--;
      });
      Future.delayed(const Duration(seconds: 1), _tickTimer);
    } else {
      setState(() {
        _canResend = true;
      });
    }
  }

  void _verifyOtp() {
    if (_currentOtp.length == 6) {
      context.read<AuthCubit>().verifyOtp(widget.phone, _currentOtp);
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
          icon: const Icon(Icons.arrow_back, color: KhaataTheme.textDark),
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

              Container(
                width: 80.w,
                height: 80.h,
                decoration: BoxDecoration(
                  color: _hasError
                      ? KhaataTheme.dangerRed.withValues(alpha: 0.1)
                      : KhaataTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Icon(
                  _hasError
                      ? Icons.error_outline
                      : Icons.verified_user_outlined,
                  color: _hasError
                      ? KhaataTheme.dangerRed
                      : KhaataTheme.primaryBlue,
                  size: 40.sp,
                ),
              ),

              SizedBox(height: 32.h),

              Text(
                'Final Confirmation',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 8.h),

              Text(
                'Confirm your registration with the second OTP sent to your mobile.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: KhaataTheme.textGrey,
                  height: 1.5,
                ),
              ),

              SizedBox(height: 40.h),

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
                  activeColor: _hasError
                      ? KhaataTheme.dangerRed
                      : KhaataTheme.primaryBlue,
                  inactiveColor: Colors.grey[300],
                  selectedColor: KhaataTheme.primaryBlue,
                  errorBorderColor: KhaataTheme.dangerRed,
                ),
                cursorColor: KhaataTheme.primaryBlue,
                animationDuration: const Duration(milliseconds: 300),
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

              _canResend
                  ? TextButton(
                      onPressed: () {
                        _otpController.clear();
                        context.read<AuthCubit>().sendOtp(widget.phone);
                        _startResendTimer();
                      },
                      child: const Text(
                        'Resend OTP',
                        style: TextStyle(
                          color: KhaataTheme.primaryBlue,
                          fontWeight: FontWeight.w600,
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

              BlocConsumer<AuthCubit, AuthState>(
                listener: (context, state) {
                  if (state is RegistrationOtpVerified) {
                    context.go(AppConstants.processing);
                  } else if (state is AuthError) {
                    setState(() {
                      _hasError = true;
                      _errorController?.add(ErrorAnimationType.shake);
                    });
                    ScaffoldMessenger.of(
                      context,
                    );
DialogUtils.showErrorDialog(context, state.message);
                  }
                },
                builder: (context, state) {
                  return PrimaryButton(
                    text: 'Finish Registration',
                    isLoading: state is AuthLoading,
                    onPressed: _currentOtp.length == 6 ? _verifyOtp : null,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

