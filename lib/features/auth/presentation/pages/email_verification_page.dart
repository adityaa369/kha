import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../config/theme.dart';
import '../../../../config/constants.dart';
import '../../../../core/blocs/auth/auth_cubit.dart';
import '../../../../core/blocs/auth/email_verification_cubit.dart';

class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({super.key});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  bool _initialSendDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendInitialEmail();
    });
  }

  Future<void> _sendInitialEmail() async {
    if (_initialSendDone) return;
    _initialSendDone = true;
    await context.read<EmailVerificationCubit>().sendVerificationEmail();
  }

  String _maskEmail(String? email) {
    if (email == null || email.isEmpty) return '';
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final name = parts[0];
    if (name.length <= 2) return email;
    return '${name.substring(0, 2)}****@${parts[1]}';
  }

    Future<void> _openEmailApp() async {
    // 1. googlegmail:// opens Gmail inbox directly (works on most devices)
    final gmailUri = Uri.parse('googlegmail://');
    if (await canLaunchUrl(gmailUri)) {
      await launchUrl(gmailUri, mode: LaunchMode.externalApplication);
      return;
    }
    // 2. Android Intent URI targeting Gmail package specifically
    //    This opens Gmail inbox even when googlegmail:// scheme isn't registered
    final gmailIntentUri = Uri.parse(
      'intent://inbox#Intent;scheme=googlegmail;package=com.google.android.gm;end',
    );
    if (await canLaunchUrl(gmailIntentUri)) {
      await launchUrl(gmailIntentUri, mode: LaunchMode.externalApplication);
      return;
    }
    // 3. Last resort: open Gmail web in browser
    final webUri = Uri.parse('https://mail.google.com/');
    try {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    final email = authState.user?.email;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: BlocListener<EmailVerificationCubit, EmailVerificationState>(
          listener: (context, state) {
            if (state is EmailVerified) {
              context.go(AppConstants.registrationSuccess);
            }
          },
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              children: [
                SizedBox(height: 60.h),

                // Mail Icon
                Container(
                  width: 100.w,
                  height: 100.h,
                  decoration: BoxDecoration(
                    color: KhaataTheme.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(28.r),
                  ),
                  child: Icon(
                    Icons.mark_email_unread_rounded,
                    size: 56.sp,
                    color: KhaataTheme.primaryBlue,
                  ),
                ),

                SizedBox(height: 32.h),

                // Title
                Text(
                  'Verify Your Email',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: KhaataTheme.textDark,
                  ),
                ),

                SizedBox(height: 12.h),

                // Subtitle
                Text(
                  "We've sent a verification link to",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15.sp,
                    color: KhaataTheme.textGrey,
                    height: 1.4,
                  ),
                ),

                SizedBox(height: 8.h),

                // Masked email
                Text(
                  _maskEmail(email),
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: KhaataTheme.textDark,
                  ),
                ),

                SizedBox(height: 8.h),

                Text(
                  'Open your email and tap the verification link\nto continue setting up your account.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: KhaataTheme.textGrey,
                    height: 1.5,
                  ),
                ),

                SizedBox(height: 40.h),

                // State-driven UI
                BlocBuilder<EmailVerificationCubit, EmailVerificationState>(
                  builder: (context, state) {
                    if (state is EmailVerificationSending) {
                      return Column(
                        children: [
                          const CircularProgressIndicator(
                            color: KhaataTheme.primaryBlue,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'Sending verification email...',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: KhaataTheme.textGrey,
                            ),
                          ),
                        ],
                      );
                    }

                    if (state is EmailVerificationChecking) {
                      return Column(
                        children: [
                          const CircularProgressIndicator(
                            color: KhaataTheme.primaryBlue,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'Checking verification status...',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: KhaataTheme.textGrey,
                            ),
                          ),
                        ],
                      );
                    }

                    if (state is EmailVerificationError) {
                      return Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: KhaataTheme.dangerRed.withValues(
                                alpha: 0.08,
                              ),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: KhaataTheme.dangerRed.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: KhaataTheme.dangerRed,
                                  size: 20.sp,
                                ),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Text(
                                    state.message,
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      color: KhaataTheme.dangerRed,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 24.h),
                          _buildActionButtons(context),
                        ],
                      );
                    }

                    // Default: sent state or initial
                    return _buildActionButtons(context);
                  },
                ),

                SizedBox(height: 32.h),

                // Auto-check indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 14.sp,
                      height: 14.sp,
                      child: const CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: KhaataTheme.textGrey,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      "We'll detect automatically when you verify",
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: KhaataTheme.textGrey,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 40.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final cubit = context.read<EmailVerificationCubit>();

    return Column(
      children: [
        // Open Email App button
        SizedBox(
          width: double.infinity,
          height: 52.h,
          child: ElevatedButton.icon(
            onPressed: _openEmailApp,
            icon: Icon(Icons.email_outlined, size: 20.sp),
                          label: Text(
                'Open Gmail',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: KhaataTheme.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 0,
              ),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            "Didn't receive the email? Check your Spam or Junk folder.",
            style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),

        // Resend Email button
        SizedBox(
          width: double.infinity,
          height: 52.h,
          child: OutlinedButton(
            onPressed: cubit.cooldownSeconds == 0
                ? () => cubit.resendVerificationEmail()
                : null,
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: cubit.cooldownSeconds == 0
                    ? KhaataTheme.primaryBlue
                    : KhaataTheme.borderGrey,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: Text(
              cubit.cooldownSeconds > 0
                  ? 'Resend available in ${cubit.cooldownSeconds}s'
                  : 'Resend Email',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: cubit.cooldownSeconds == 0
                    ? KhaataTheme.primaryBlue
                    : KhaataTheme.textGrey,
              ),
            ),
          ),
        ),

        SizedBox(height: 16.h),

        // Manual check button
        TextButton(
          onPressed: () => cubit.checkVerificationStatus(),
          child: Text(
            "I've already verified my email",
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: KhaataTheme.primaryBlue,
            ),
          ),
        ),
      ],
    );
  }
}
