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
  int _cooldownSeconds = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCooldown();
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

  Future<void> _handleResend() async {
    if (_cooldownSeconds > 0 || _isLoading) return;

    setState(() => _isLoading = true);
    try {
      await context.read<AuthCubit>().sendVerificationEmail();
      if (mounted) {
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleCheckVerification() async {
    setState(() => _isRefreshing = true);
    try {
      await context.read<AuthCubit>().checkAuthStatus();
      if (!mounted) return;
      
      final state = context.read<AuthCubit>().state;
      bool isVerified = false;
      if (state is AuthenticatedFull && state.user.isEmailVerified) isVerified = true;
      if (state is AuthenticatedUnverified && state.user.isEmailVerified) isVerified = true;

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
            style: TextStyle(
              fontSize: 14.sp,
              color: KhaataTheme.textGrey,
            ),
          ),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: (_cooldownSeconds == 0 && !_isLoading) ? _handleResend : null,
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
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(KhaataTheme.primaryBlue),
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
