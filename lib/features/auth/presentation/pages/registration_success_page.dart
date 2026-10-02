import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../../../../config/constants.dart';
import '../../../../core/blocs/auth/auth_cubit.dart';
import '../../../../core/utils/secure_storage.dart';

class RegistrationSuccessPage extends StatefulWidget {
  const RegistrationSuccessPage({super.key});

  @override
  State<RegistrationSuccessPage> createState() =>
      _RegistrationSuccessPageState();
}

class _RegistrationSuccessPageState extends State<RegistrationSuccessPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _hasAnimated = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeIn));

    // Play animation only once
    if (!_hasAnimated) {
      _hasAnimated = true;
      _animController.forward();
    }

    // Auto-navigate after 2.5 seconds
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted && !_hasNavigated) {
        _hasNavigated = true;
        // Emit Authenticated to transition from RegistrationComplete → Authenticated
        // so the router allows navigation to home
        final authCubit = context.read<AuthCubit>();
        final user = authCubit.currentUser;
                  if (user != null) {
            // Set pending flag for home tour so it survives email verification
            SecureStorage.setHomeTourPending(user.id, true);
            authCubit.checkAuthStatus();
          }
          context.go(AppConstants.home);
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    final userName = authState.user?.firstName ?? 'User';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated check circle
                AnimatedBuilder(
                  animation: _animController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    width: 120.w,
                    height: 120.h,
                    decoration: BoxDecoration(
                      color: KhaataTheme.primaryBlue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Container(
                        width: 80.w,
                        height: 80.h,
                        decoration: const BoxDecoration(
                          color: KhaataTheme.primaryBlue,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 48.sp,
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 40.h),

                // Title
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    'Account Created\nSuccessfully',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26.sp,
                      fontWeight: FontWeight.bold,
                      color: KhaataTheme.textDark,
                      height: 1.3,
                    ),
                  ),
                ),

                SizedBox(height: 16.h),

                // Welcome message
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    'Welcome, $userName!',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: KhaataTheme.primaryBlue,
                    ),
                  ),
                ),

                SizedBox(height: 12.h),

                // Description
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    'Your Khaata account is ready.\nStart managing your loans securely.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: KhaataTheme.textGrey,
                      height: 1.5,
                    ),
                  ),
                ),

                SizedBox(height: 48.h),

                // Loading dots to indicate auto-navigation
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16.sp,
                        height: 16.sp,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: KhaataTheme.textGrey,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Taking you to your dashboard...',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: KhaataTheme.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
