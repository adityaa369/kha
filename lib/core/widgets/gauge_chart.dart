import 'dart:math' show pi, cos, sin;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../config/theme.dart';

class CreditScoreGauge extends StatelessWidget {
  final int score;
  final String? label;
  final double size;

  const CreditScoreGauge({
    super.key,
    required this.score,
    this.label,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size.w,
      height: (size * 0.6).h,
      child: CustomPaint(
        painter: _GaugePainter(score: score),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 20.h),
              Text(
                '$score',
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: KhaataTheme.textDark,
                ),
              ),
              if (label != null)
                Text(
                  label!,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: KhaataTheme.accentGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final int score;

  _GaugePainter({required this.score});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 10.w;

    // Background arc (grey)
    final bgPaint = Paint()
      ..color = Colors.grey[200]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.w
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi, // Start from left (180 degrees)
      pi, // Sweep 180 degrees (half circle)
      false,
      bgPaint,
    );

    // Calculate color based on score
    Color scoreColor;
    if (score < 600) {
      scoreColor = KhaataTheme.dangerRed;
    } else if (score < 750) {
      scoreColor = KhaataTheme.warningYellow;
    } else {
      scoreColor = KhaataTheme.accentGreen;
    }

    // Progress arc
    final progress = (score - 300) / 600; // Normalize 300-900 to 0-1
    final progressPaint = Paint()
      ..color = scoreColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.w
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi,
      pi * progress.clamp(0.0, 1.0),
      false,
      progressPaint,
    );

    // Needle
    final needleAngle = pi + (pi * progress.clamp(0.0, 1.0));
    final needlePaint = Paint()
      ..color = KhaataTheme.textDark
      ..strokeWidth = 2.w
      ..strokeCap = StrokeCap.round;

    final needleLength = radius - 5.w;
    final needleEnd = Offset(
      center.dx + needleLength * cos(needleAngle),
      center.dy + needleLength * sin(needleAngle),
    );

    canvas.drawLine(center, needleEnd, needlePaint);

    // Center dot
    canvas.drawCircle(
      center,
      4.w,
      Paint()..color = KhaataTheme.textDark,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}