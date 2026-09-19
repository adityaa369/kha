import re
with open('lib/features/auth/presentation/pages/signup_page.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("final otpCtrl = _otpController;\n    Future.delayed(const Duration(milliseconds: 500), () => otpCtrl.dispose());", "_otpController.dispose();")
with open('lib/features/auth/presentation/pages/signup_page.dart', 'w', encoding='utf-8') as f:
    f.write(content)
