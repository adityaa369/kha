import 'dart:math' show cos, sin;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/constants.dart';
import '../../../../config/theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/blocs/auth/auth_cubit.dart';

class ProcessingPage extends StatefulWidget {
  const ProcessingPage({super.key});

  @override
  State<ProcessingPage> createState() => _ProcessingPageState();
}

class _ProcessingPageState extends State<ProcessingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _completeFlow();
  }

  Future<void> _completeFlow() async {
    try {
      final authCubit = context.read<AuthCubit>();
      await authCubit.completeRegistration();
      
      // Check if registration failed
      if (authCubit.state is AuthError) {
        throw (authCubit.state as AuthError).message;
      }
      
      await authCubit.processCreditScore();
      
      if (authCubit.state is AuthError) {
        throw (authCubit.state as AuthError).message;
      }
      
      if (mounted) {
        context.go(AppConstants.home);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _completeFlow,
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Gauge
            SizedBox(
              width: 150.w,
              height: 150.h,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: GaugePainter(
                      progress: _animationController.value,
                      color: KhaataTheme.accentGreen,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.speed,
                        size: 40.sp,
                        color: KhaataTheme.accentGreen,
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 40.h),
            Text(
              'It will take upto 30 sec to get your\nCredit Score',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                color: KhaataTheme.textGrey,
              ),
            ),
            SizedBox(height: 60.h),
            Text(
              'Score Powered by',
              style: TextStyle(
                fontSize: 12.sp,
                color: KhaataTheme.textGrey,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'CIBIL',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: KhaataTheme.secondaryBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GaugePainter extends CustomPainter {
  final double progress;
  final Color color;

  GaugePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background arc
    final bgPaint = Paint()
      ..color = Colors.grey[200]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12.w
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.14, // Start from left
      3.14, // Half circle
      false,
      bgPaint,
    );

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12.w
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.14,
      3.14 * progress,
      false,
      progressPaint,
    );

    // Needle
    final needleAngle = 3.14 + (3.14 * progress);
    final needlePaint = Paint()
      ..color = KhaataTheme.primaryBlue
      ..strokeWidth = 4.w
      ..strokeCap = StrokeCap.round;

    final needleEnd = Offset(
      center.dx + (radius - 20.w) * cos(needleAngle),
      center.dy + (radius - 20.w) * sin(needleAngle),
    );

    canvas.drawLine(center, needleEnd, needlePaint);

    // Center dot
    canvas.drawCircle(
      center,
      8.w,
      Paint()..color = KhaataTheme.primaryBlue,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}