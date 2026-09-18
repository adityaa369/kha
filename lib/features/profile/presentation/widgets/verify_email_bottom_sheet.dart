import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/blocs/auth/auth_cubit.dart';
import '../../../../config/theme.dart';
import '../../../../core/widgets/buttons.dart';

class VerifyEmailBottomSheet extends StatefulWidget {
  final String email;

  const VerifyEmailBottomSheet({super.key, required this.email});

  static void show(BuildContext context, String email) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VerifyEmailBottomSheet(email: email),
    );
  }

  @override
  State<VerifyEmailBottomSheet> createState() => _VerifyEmailBottomSheetState();
}

class _VerifyEmailBottomSheetState extends State<VerifyEmailBottomSheet> {
  bool _isLoading = false;
  bool _isRefreshing = false;
  bool _initialSendDone = false;
  String? _errorMessage;
  int _cooldownSeconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Fire the initial send immediately when the sheet opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendEmail(isInitial: true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _cooldownSeconds = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_cooldownSeconds > 0) {
          _cooldownSeconds--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  Future<void> _sendEmail({bool isInitial = false}) async {
    if (_isLoading) return;
    if (!isInitial && _cooldownSeconds > 0) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await context.read<AuthCubit>().sendVerificationEmail();
      if (mounted) {
        setState(() => _initialSendDone = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _startCooldown();
      }
    } catch (e) {
      if (mounted) {
        String msg = 'Failed to send verification email. Please try again.';
        final errStr = e.toString();
        if (errStr.contains('too-many-requests')) {
          msg = 'Too many requests. Please wait a few minutes and try again.';
        } else if (errStr.contains('No email address is attached')) {
          msg = 'No email address is attached to your account. Please re-login with OTP.';
        }
        setState(() => _errorMessage = msg);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleResend() async {
    await _sendEmail();
  }

  Future<void> _handleCheckVerification() async {
    setState(() => _isRefreshing = true);
    try {
      await context.read<AuthCubit>().checkAuthStatus();
      if (!mounted) return;

      final state = context.read<AuthCubit>().state;
      bool isVerified = false;
      if (state is Authenticated && state.user.isEmailVerified)
        isVerified = true;
      if (state is Authenticated && state.user.isEmailVerified)
        isVerified = true;

      if (isVerified) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email successfully verified!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email not verified yet. Please check your inbox.'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to refresh status'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final name = parts[0];
    if (name.length <= 2) return email;
    return '${name[0]}***@${parts[1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24.h,
        top: 24.h,
        left: 24.w,
        right: 24.w,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 24.h),
          Icon(
            Icons.mark_email_unread_rounded,
            size: 64.sp,
            color: KhaataTheme.primaryBlue,
          ),
          SizedBox(height: 16.h),
          Text(
            'Verify Your Email',
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: KhaataTheme.textDark,
            ),
          ),
          SizedBox(height: 8.h),
          if (_isLoading && !_initialSendDone)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  SizedBox(height: 12.h),
                  Text(
                    'Sending verification email...',
                    style: TextStyle(fontSize: 15.sp, color: KhaataTheme.textGrey),
                  ),
                ],
              ),
            )
          else if (_errorMessage != null)
            Container(
              padding: EdgeInsets.all(12.w),
              margin: EdgeInsets.only(bottom: 8.h),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14.sp, color: Colors.red[800]),
              ),
            )
          else
            Text(
              'We sent a verification link to:\n${_maskEmail(widget.email)}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15.sp,
                color: KhaataTheme.textGrey,
                height: 1.4,
              ),
            ),
          SizedBox(height: 32.h),
          PrimaryButton(
            text: 'I\'ve Verified My Email',
            isLoading: _isRefreshing,
            onPressed: _handleCheckVerification,
          ),
          SizedBox(height: 24.h),
          Text(
            'Didn\'t receive it?',
            style: TextStyle(fontSize: 14.sp, color: KhaataTheme.textGrey),
          ),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: (_cooldownSeconds == 0 && !_isLoading)
                  ? _handleResend
                  : null,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 14.h),
                side: BorderSide(
                  color: _cooldownSeconds == 0
                      ? KhaataTheme.primaryBlue
                      : Colors.grey[300]!,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: _isLoading
                  ? SizedBox(
                      height: 20.sp,
                      width: 20.sp,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(
                          KhaataTheme.primaryBlue,
                        ),
                      ),
                    )
                  : Text(
                      _cooldownSeconds > 0
                          ? 'Resend available in ${_cooldownSeconds}s'
                          : 'Resend Email',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: _cooldownSeconds == 0
                            ? KhaataTheme.primaryBlue
                            : Colors.grey,
                      ),
                    ),
            ),
          ),
          SizedBox(height: 12.h),
        ],
      ),
    );
  }
}

