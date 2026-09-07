import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/blocs/auth/auth_cubit.dart';
import '../../../../core/utils/dialog_utils.dart';
import '../../../../config/theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      final phone = _phoneController.text.trim();
      final password = _passwordController.text;
      context.read<AuthCubit>().loginWithPassword(phone, password);
    } else {}
  }

  void _handleForgotPassword() {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 10) {
      DialogUtils.showErrorDialog(
        context,
        'Please enter your 10-digit phone number first.',
      );
      return;
    }

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Password'),
        content: Text(
          'We will send an OTP to +91 $phone to verify your identity.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: KhaataTheme.primaryBlue,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              // context.read<AuthCubit>().startPasswordReset(phone);
              context.push('/otp', extra: phone);
            },
            child: const Text(
              'Send OTP',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KhaataTheme.primaryBlue,
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (!mounted) return;

          if (state is AuthError) {
            DialogUtils.showErrorDialog(context, state.message);
          } else if (state is AuthenticatedKycComplete) {
            context.go('/home');
          } else if (state is AuthenticatedEmailUnverified) {
            context.go('/home');
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 52.h),

                  Text(
                    'Hand Credit',
                    style: TextStyle(
                      fontSize: 26.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'Digital Loan Agreements',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.white.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Login White Card
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 20.w),
                    padding: EdgeInsets.all(24.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back',
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w800,
                              color: KhaataTheme.textDark,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Sign in to manage your loans & credits',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: KhaataTheme.textGrey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 24.h),

                          // Mobile Number Section
                          Text(
                            'Mobile number',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: KhaataTheme.textDark,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Country Code box
                              Container(
                                height: 48.h,
                                padding: EdgeInsets.symmetric(horizontal: 12.w),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                alignment: Alignment.center,
                                child: Row(
                                  children: [
                                    Text(
                                      'IN',
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w800,
                                        color: KhaataTheme.textDark,
                                      ),
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      '+91',
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w500,
                                        color: KhaataTheme.textGrey,
                                      ),
                                    ),
                                    SizedBox(width: 4.w),
                                    Icon(
                                      Icons.keyboard_arrow_down,
                                      size: 14.sp,
                                      color: KhaataTheme.textGrey,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 8.w),
                              // Phone Number Input
                              Expanded(
                                child: TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  maxLength: 10,
                                  validator: (val) {
                                    if (val == null || val.length != 10) {
                                      return 'Enter a valid 10-digit number';
                                    }
                                    return null;
                                  },
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: KhaataTheme.textDark,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '98765 43210',
                                    hintStyle: TextStyle(
                                      color: KhaataTheme.textGrey,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    counterText: '',
                                    filled: true,
                                    fillColor: const Color(0xFFF3F4F6),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                      borderSide: const BorderSide(
                                        color: KhaataTheme.primaryBlue,
                                        width: 1.5,
                                      ),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16.w,
                                      vertical: 14.h,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.h),

                          // Password Section
                          Text(
                            'Password',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: KhaataTheme.textDark,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Password is required';
                              }
                              return null;
                            },
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: KhaataTheme.textDark,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Enter your password',
                              hintStyle: TextStyle(
                                color: KhaataTheme.textGrey,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF3F4F6),
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                size: 20.sp,
                                color: KhaataTheme.textGrey,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 20.sp,
                                  color: KhaataTheme.textGrey,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                borderSide: const BorderSide(
                                  color: KhaataTheme.primaryBlue,
                                  width: 1.5,
                                ),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 14.h,
                              ),
                            ),
                          ),
                          SizedBox(height: 8.h),

                          // Forgot Password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _handleForgotPassword,
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Forgot password?',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: KhaataTheme.primaryBlue,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 24.h),

                          // Sign In Button
                          SizedBox(
                            width: double.infinity,
                            height: 52.h,
                            child: ElevatedButton(
                              onPressed: state is AuthLoading
                                  ? null
                                  : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: KhaataTheme.primaryBlue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                elevation: 0,
                              ),
                              child: state is AuthLoading
                                  ? SizedBox(
                                      width: 20.w,
                                      height: 20.h,
                                      child: const CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      'Sign In',
                                      style: TextStyle(
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          SizedBox(height: 20.h),

                          // "Or continue with" Section
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: Colors.grey.shade200,
                                  thickness: 1,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12.w),
                                child: Text(
                                  'or continue with',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: KhaataTheme.textGrey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: Colors.grey.shade200,
                                  thickness: 1,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.h),

                          // Social Login Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Google Button
                              _SocialButton(
                                child: Text(
                                  'G',
                                  style: TextStyle(
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.blue.shade600,
                                    fontFamily: 'sans-serif',
                                  ),
                                ),
                                onTap: () {},
                              ),
                              SizedBox(width: 16.w),
                              // Apple Button
                              _SocialButton(
                                child: Icon(
                                  Icons.apple,
                                  size: 24.sp,
                                  color: Colors.black,
                                ),
                                onTap: () {},
                              ),
                            ],
                          ),
                          SizedBox(height: 24.h),

                          // Create Account Footer Link
                          Center(
                            child: GestureDetector(
                              onTap: () => context.go('/signup'),
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: KhaataTheme.textGrey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  children: const [
                                    TextSpan(text: 'New to Hand Credit? '),
                                    TextSpan(
                                      text: 'Create account',
                                      style: TextStyle(
                                        color: KhaataTheme.primaryBlue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 32.h),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const _SocialButton({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48.w,
        height: 48.h,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}
