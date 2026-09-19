with open('lib/features/auth/presentation/pages/otp_page.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("import 'package:flutter/material.dart';", "import 'dart:async';\nimport 'package:flutter/material.dart';")

old_timer = '''  void _startResendTimer() {
    if (!mounted) return;
    setState(() {
      _canResend = false;
      _resendTimer = 30;
      _hasError = false;
    });

    Future.delayed(const Duration(seconds: 1), _tickTimer);
  }

  void _tickTimer() {
    if (!mounted) return;
    if (_resendTimer > 0) {
      setState(() {
        _resendTimer--;
      });
      Future.delayed(const Duration(seconds: 1), _tickTimer);
    } else {
      setState(() {
        _canResend = true;
      });
    }
  }'''

new_timer = '''  Timer? _timer;

  void _startResendTimer() {
    if (!mounted) return;
    setState(() {
      _canResend = false;
      _resendTimer = 30;
      _hasError = false;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendTimer > 0) {
        setState(() {
          _resendTimer--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }'''

content = content.replace(old_timer, new_timer)

content = content.replace("  void dispose() {\n    _otpController.dispose();", "  void dispose() {\n    _timer?.cancel();\n    _otpController.dispose();")

with open('lib/features/auth/presentation/pages/otp_page.dart', 'w', encoding='utf-8') as f:
    f.write(content)
