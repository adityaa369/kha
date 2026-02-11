import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/blocs/auth/auth_cubit.dart';
import '../../../../config/constants.dart';
import '../../../../config/theme.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Smooth fade in
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // Gentle scale up
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    // Slide up slightly
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    // Start animation
    _controller.forward();

    _startNavigationSequence();
  }

  Future<void> _startNavigationSequence() async {
    // 1. Kick off auth check
    await context.read<AuthCubit>().checkAuthStatus();

    // 2. Wait for animation to finish (at least 2 seconds)
    await Future.delayed(const Duration(milliseconds: 2000));

    // 3. Keep checking for 3 seconds if auth is still loading
    bool navigated = false;
    for (int i = 0; i < 30; i++) {
      if (!mounted) return;
      
      final state = context.read<AuthCubit>().state;
      if (state is! AuthLoading && state is! AuthInitial) {
        _handleNavigation(state);
        navigated = true;
        break;
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // 4. Fallback if still stuck (likely unauthenticated or error)
    if (!navigated && mounted) {
      _handleNavigation(context.read<AuthCubit>().state);
    }
  }

  void _handleNavigation(AuthState state) {
    if (!mounted) return;

    if (state is Authenticated) {
      context.go(AppConstants.home);
    } else if (state is OtpVerified) {
      context.go(AppConstants.personalDetails);
    } else {
      // For Initial, Loading (timeout), Error or Unauthenticated
      context.go(AppConstants.welcome);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        // If animation is already done and a final state arrives, navigate immediately
        if (_controller.isCompleted) {
          _handleNavigation(state);
        }
      },
      child: Scaffold(
        backgroundColor: KhaataTheme.primaryBlue,
        body: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Khaata',
                          style: TextStyle(
                            fontSize: 48.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 2.w,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        AnimatedOpacity(
                          opacity: _controller.value > 0.5 ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 500),
                          child: Text(
                            'Digital Loan Agreements',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.white70,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
