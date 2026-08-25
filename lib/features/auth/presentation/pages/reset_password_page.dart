import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/blocs/auth/auth_cubit.dart';
import '../../../../config/theme.dart';
import '../../../../core/utils/validators.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleReset() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthCubit>().resetPassword(_passwordController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KhaataTheme.primaryBlue,
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (!mounted) return;
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: KhaataTheme.dangerRed,
              ),
            );
          } else if (state is AuthenticatedFull) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Password reset successfully!'),
                backgroundColor: KhaataTheme.accentGreen,
              ),
            );
            context.go('/home');
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: Form(
              key: _formKey,
              child: CustomScrollView(
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 40.h),
                          IconButton(
                            onPressed: () => context.go('/login'),
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            padding: EdgeInsets.zero,
                            alignment: Alignment.centerLeft,
                          ),
                          SizedBox(height: 20.h),
                          Text(
                            'Reset\nPassword',
                            style: TextStyle(
                              fontSize: 40.sp,
                              height: 1.2,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -1,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            'Enter your new password below.',
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                          SizedBox(height: 40.h),
                          Container(
                            padding: EdgeInsets.all(24.w),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24.r),
                            ),
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  validator: Validators.validatePassword,
                                  decoration: InputDecoration(
                                    labelText: 'New Password',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                    ),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                                  ),
                                ),
                                SizedBox(height: 20.h),
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  obscureText: _obscurePassword,
                                  validator: (val) {
                                    if (val == null || val.isEmpty) return 'Confirm your password';
                                    if (val != _passwordController.text) return 'Passwords do not match';
                                    return null;
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Confirm New Password',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                                  ),
                                ),
                                SizedBox(height: 32.h),
                                SizedBox(
                                  width: double.infinity,
                                  height: 52.h,
                                  child: ElevatedButton(
                                    onPressed: state is AuthLoading ? null : _handleReset,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: KhaataTheme.primaryBlue,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16.r),
                                      ),
                                    ),
                                    child: state is AuthLoading
                                        ? SizedBox(
                                            width: 24.w,
                                            height: 24.w,
                                            child: const CircularProgressIndicator(color: Colors.white),
                                          )
                                        : Text(
                                            'Reset Password',
                                            style: TextStyle(
                                              fontSize: 16.sp,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

