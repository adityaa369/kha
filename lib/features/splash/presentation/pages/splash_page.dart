import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/services/biometric_auth_service.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/blocs/auth/auth_cubit.dart';
import '../../../../config/constants.dart';
import '../../../../config/theme.dart';
import '../../../../core/utils/dialog_utils.dart';

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
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
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
    // 1 Kick off auth check
    await context.read<AuthCubit>().checkAuthStatus();

    // 2 Keep checking for 3 seconds if auth is still loading
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

    // 3 Fallback if still stuck (likely unauthenticated or error)
    if (!navigated && mounted) {
      _handleNavigation(context.read<AuthCubit>().state);
    }
  }

  bool _isLocked = false;

  void _handleNavigation(AuthState state) async {
    if (!mounted) return;

    if (state is Authenticated || state is AuthOffline) {
      // Token valid but require Biometric Unlock
      setState(() => _isLocked = true);
      _attemptBiometricUnlock(showFailureMessage: false);
    } else if (state is Unauthenticated || state is AuthError) {
      context.go(AppConstants.login);
    }
  }

  Future<void> _attemptBiometricUnlock({
    bool showFailureMessage = false,
  }) async {
    final authenticated = await BiometricAuthService.authenticate();
    if (authenticated && mounted) {
      context.go(AppConstants.home);
    } else if (mounted && showFailureMessage) {
      DialogUtils.showErrorDialog(
        context,
        'Authentication failed. Please try again.',
      );
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
        if (_controller.isCompleted) {
          _handleNavigation(state);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFEFDF8),
        body: Center(
          child: _isLocked
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      color: KhaataTheme.primaryBlue,
                      size: 60.sp,
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      'App Locked',
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: KhaataTheme.primaryBlue,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      'Please authenticate to continue',
                      style: TextStyle(color: Colors.black54, fontSize: 14.sp),
                    ),
                    SizedBox(height: 30.h),
                    ElevatedButton.icon(
                      onPressed: () =>
                          _attemptBiometricUnlock(showFailureMessage: true),
                      icon: const Icon(Icons.fingerprint),
                      label: const Text('Unlock'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KhaataTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 32.w,
                          vertical: 12.h,
                        ),
                      ),
                    ),
                  ],
                )
              : AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Center(
                            child: SvgPicture.asset(
                              'assets/images/hand_credit_logo_splash.svg',
                              width: MediaQuery.of(context).size.width * 0.75,
                              fit: BoxFit.contain,
                            ),
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

class TextUntil extends StatelessWidget {
  final String text;
  final TextStyle style;
  const TextUntil(this.text, {super.key, required this.style});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: style);
  }
}

