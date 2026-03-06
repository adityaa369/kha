import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/blocs/auth/auth_cubit.dart';
import '../../../../config/constants.dart';
import '../../../../config/theme.dart';
import '../../../../core/widgets/buttons.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _mobileController = TextEditingController();
  bool _termsAccepted = false;

  @override
  void dispose() {
    _mobileController.dispose();
    super.dispose();
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
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20.h),
            Center(
              child: Container(
                width: 80.w,
                height: 80.h,
                decoration: BoxDecoration(
                  color: KhaataTheme.accentGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Icon(
                  Icons.phone_android_rounded,
                  color: KhaataTheme.accentGreen,
                  size: 40.sp,
                ),
              ),
            ),
            SizedBox(height: 32.h),
            Text(
              'Enter Mobile Number',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 8.h),
            Text(
              'Linked to your bank account',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 40.h),

            // Mobile Input
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
                    child: Text(
                      '+91',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: KhaataTheme.textDark,
                      ),
                    ),
                  ),
                  Container(width: 1.w, height: 24.h, color: Colors.grey[300]),
                  Expanded(
                    child: TextField(
                      controller: _mobileController,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      decoration: InputDecoration(
                        hintText: 'Mobile Number',
                        counterText: '',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // Checkboxes
            CheckboxTile(
              value: _termsAccepted,
              onChanged: (v) => setState(() => _termsAccepted = v!),
              title: 'By signing up, I agree to the ',
              linkText: 'Terms and Conditions, Privacy Policy',
              onLinkTap: () {},
            ),

            SizedBox(height: 40.h),

            BlocConsumer<AuthCubit, AuthState>(
              listener: (context, state) {
                if (state is OtpSent) {
                  context.push(AppConstants.otp, extra: _mobileController.text);
                } else if (state is AuthError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                }
              },
              builder: (context, state) {
                return PrimaryButton(
                  text: 'Get OTP',
                  isLoading: state is AuthLoading,
                  onPressed: (_termsAccepted &&
                          _mobileController.text.length == 10)
                      ? () => context.read<AuthCubit>().sendOtp(_mobileController.text)
                      : null,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class CheckboxTile extends StatelessWidget {
  final bool value;
  final Function(bool?) onChanged;
  final String title;
  final String linkText;
  final String? subtitle;
  final VoidCallback onLinkTap;

  const CheckboxTile({
    super.key,
    required this.value,
    required this.onChanged,
    required this.title,
    required this.linkText,
    this.subtitle,
    required this.onLinkTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: KhaataTheme.primaryBlue,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.r)),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(!value),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: 13.sp, color: KhaataTheme.textGrey),
                  children: [
                    TextSpan(text: title),
                    TextSpan(
                      text: linkText,
                      style: TextStyle(
                        color: KhaataTheme.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                      recognizer: TapGestureRecognizer()..onTap = onLinkTap,
                    ),
                    if (subtitle != null) TextSpan(text: subtitle),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}