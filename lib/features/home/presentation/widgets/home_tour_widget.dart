import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/blocs/auth/auth_cubit.dart';
import '../../../../core/utils/secure_storage.dart';
import '../../../../config/theme.dart';
import 'dart:math' as math;

class HomeTourWidget extends StatefulWidget {
  final VoidCallback onComplete;
  
  const HomeTourWidget({super.key, required this.onComplete});

  @override
  State<HomeTourWidget> createState() => _HomeTourWidgetState();
}

class _HomeTourWidgetState extends State<HomeTourWidget> with TickerProviderStateMixin {
  bool _isLoading = true;
  bool _shouldShow = false;
  int _currentStep = 0;
  String? _userId;

  late AnimationController _entranceController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  late AnimationController _floatController;
  late Animation<Offset> _floatAnimation;

  final List<String> _steps = [
    "Hi! Welcome to Khataa 👋\nI'm here to show you around.",
    "Here you can see your overall money given, money taken and your important financial summary. tuypes of credit hand credit, business and intrest credit",
    "Given Loans shows the money you have lent and what you still need to collect.",
    "My Loans shows the money you've borrowed, repayment progress and monthly payments.",
    "Insights helps you understand your lending, borrowing and repayment activity.",
    "Notifications keeps you updated about payments, loan events, invites and other important activity.",
    "Chit Funds lets you create or join groups, manage contributions and participate in auctions.",
    "From Profile you can manage your account, MPIN, biometrics, email verification and security.",
    "That's Khataa!\nYou're ready to get started."
  ];

  @override
  void initState() {
    super.initState();
    
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutBack),
    );

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    
    _floatAnimation = Tween<Offset>(
      begin: const Offset(0, -0.03),
      end: const Offset(0, 0.03),
    ).animate(CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine));

    _checkTourStatus();
  }

  Future<void> _checkTourStatus() async {
    final user = context.read<AuthCubit>().currentUser;
    if (user == null) {
      if (mounted) widget.onComplete();
      return;
    }
    _userId = user.id;
    final pending = await SecureStorage.isHomeTourPending(_userId!);
    final completed = await SecureStorage.isHomeTourCompleted(_userId!);
    
    if (mounted) {
      if (!pending || completed) {
        widget.onComplete();
      } else {
        setState(() {
          _isLoading = false;
          _shouldShow = true;
        });
        _entranceController.forward();
      }
    }
  }

  Future<void> _finishTour() async {
    if (_userId != null) {
      await SecureStorage.setHomeTourCompleted(_userId!, true);
      await SecureStorage.setHomeTourPending(_userId!, false);
    }
    if (mounted) {
      await _entranceController.reverse();
      setState(() => _shouldShow = false);
      widget.onComplete();
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || !_shouldShow) return const SizedBox.shrink();

    return Positioned.fill(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Material(
          color: Colors.black.withValues(alpha: 0.75),
          child: SafeArea(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Speech Bubble
                    Container(
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.05, 0),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: Text(
                          _steps[_currentStep],
                          key: ValueKey<int>(_currentStep),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16.sp,
                            height: 1.4,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    
                    // Bubble Tail (Triangle pointing down)
                    CustomPaint(
                      size: Size(20.w, 15.h),
                      painter: _BubbleTailPainter(),
                    ),
                    
                    SizedBox(height: 20.h),
                    
                    // Floating Avatar
                    SlideTransition(
                      position: _floatAnimation,
                      child: Image.asset(
                        'assets/images/hero_3d_man.png',
                        height: 220.h,
                        fit: BoxFit.contain,
                      ),
                    ),
                    
                    SizedBox(height: 40.h),
                    
                    // Controls
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Skip Button
                          TextButton(
                            onPressed: _finishTour,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white70,
                            ),
                            child: Text(
                              'Skip',
                              style: TextStyle(fontSize: 14.sp),
                            ),
                          ),
                          
                          // Indicators
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(
                              _steps.length,
                              (index) => AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: EdgeInsets.symmetric(horizontal: 3.w),
                                height: 6.h,
                                width: _currentStep == index ? 20.w : 6.w,
                                decoration: BoxDecoration(
                                  color: _currentStep == index 
                                      ? Colors.white 
                                      : Colors.white.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(3.r),
                                ),
                              ),
                            ),
                          ),
                          
                          // Next / Done Button
                          ElevatedButton(
                            onPressed: () {
                              if (_currentStep < _steps.length - 1) {
                                setState(() => _currentStep++);
                              } else {
                                _finishTour();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: KhaataTheme.primaryBlue,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                            ),
                            child: Text(
                              _currentStep == _steps.length - 1 ? 'Done' : 'Next',
                              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
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
        ),
      ),
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
      
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
      
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
