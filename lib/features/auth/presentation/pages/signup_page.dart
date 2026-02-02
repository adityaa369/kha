import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../../../../core/utils/validators.dart';
import '../widgets/animated_text_field.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage>
    with SingleTickerProviderStateMixin {
  final _pageController = PageController();
  int _currentStep = 0;

  // Controllers
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _panController = TextEditingController();
  final _aadharController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  void _nextStep() {
    if (_validateCurrentStep()) {
      _animationController.reverse().then((_) {
        setState(() => _currentStep++);
        _pageController.nextPage(
          duration: Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
        _animationController.forward();
      });
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return Validators.validatePhone(_phoneController.text) == null;
      case 1:
        return _otpController.text.length == 6;
      case 2:
        return Validators.validateEmail(_emailController.text) == null &&
            _firstNameController.text.isNotEmpty;
      case 3:
        return Validators.validatePAN(_panController.text) == null &&
            Validators.validateAadhar(_aadharController.text) == null;
      case 4:
        return Validators.validatePassword(_passwordController.text) == null &&
            _passwordController.text == _confirmPasswordController.text;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: KhaataTheme.textDark),
          onPressed: () => _currentStep == 0
              ? context.pop()
              : _pageController.previousPage(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          ),
        ),
        title: Text(
          'Create Account',
          style: TextStyle(
            color: KhaataTheme.textDark,
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          // Progress Indicator
          _StepIndicator(currentStep: _currentStep, totalSteps: 5),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: NeverScrollableScrollPhysics(),
              children: [
                _PhoneStep(controller: _phoneController, onNext: _nextStep),
                _OTPStep(controller: _otpController, onNext: _nextStep),
                _PersonalStep(
                  firstName: _firstNameController,
                  lastName: _lastNameController,
                  email: _emailController,
                  onNext: _nextStep,
                ),
                _KYCStep(
                  pan: _panController,
                  aadhar: _aadharController,
                  onNext: _nextStep,
                ),
                _PasswordStep(
                  password: _passwordController,
                  confirm: _confirmPasswordController,
                  onComplete: _completeSignup,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _completeSignup() {
    // Collect all data and send to backend
    final userData = {
      'phone': _phoneController.text,
      'firstName': _firstNameController.text,
      'lastName': _lastNameController.text,
      'email': _emailController.text,
      'pan': _panController.text.toUpperCase(),
      'aadhar': _aadharController.text.replaceAll(' ', ''),
      'password': _passwordController.text,
    };

    context.go('/home');
  }
}

// Step 1: Phone Input
class _PhoneStep extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onNext;

  const _PhoneStep({required this.controller, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter Mobile Number',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'We will send an OTP to verify your number',
            style: TextStyle(
              fontSize: 14.sp,
              color: KhaataTheme.textGrey,
            ),
          ),
          SizedBox(height: 32.h),
          AnimatedTextField(
            label: 'Mobile Number',
            hint: '10-digit number',
            controller: controller,
            keyboardType: TextInputType.phone,
            prefix: Text('+91 ', style: TextStyle(fontSize: 16.sp)),
            maxLength: 10,
            validator: Validators.validatePhone,
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: onNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: KhaataTheme.primaryBlue,
              minimumSize: Size(double.infinity, 56.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: Text('Send OTP', style: TextStyle(fontSize: 16.sp)),
          ),
        ],
      ),
    );
  }
}

// Step 3: KYC (PAN + Aadhar)
class _KYCStep extends StatelessWidget {
  final TextEditingController pan;
  final TextEditingController aadhar;
  final VoidCallback onNext;

  const _KYCStep({
    required this.pan,
    required this.aadhar,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Verify Identity',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Enter your PAN and Aadhar for KYC verification',
            style: TextStyle(
              fontSize: 14.sp,
              color: KhaataTheme.textGrey,
            ),
          ),
          SizedBox(height: 32.h),
          AnimatedTextField(
            label: 'PAN Number',
            hint: 'ABCDE1234F',
            controller: pan,
            textCapitalization: TextCapitalization.characters,
            maxLength: 10,
            validator: Validators.validatePAN,
          ),
          SizedBox(height: 20.h),
          AnimatedTextField(
            label: 'Aadhar Number',
            hint: '1234 5678 9012',
            controller: aadhar,
            keyboardType: TextInputType.number,
            maxLength: 14, // With spaces
            validator: Validators.validateAadhar,
          ),
          SizedBox(height: 8.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                Icon(Icons.security, size: 16.sp, color: KhaataTheme.primaryBlue),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'Your Aadhar and mobile will be used as unique identifiers for secure transactions.',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: KhaataTheme.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: onNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: KhaataTheme.primaryBlue,
              minimumSize: Size(double.infinity, 56.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: Text('Continue', style: TextStyle(fontSize: 16.sp)),
          ),
        ],
      ),
    );
  }
}

// Step 5: Password Creation
class _PasswordStep extends StatefulWidget {
  final TextEditingController password;
  final TextEditingController confirm;
  final VoidCallback onComplete;

  const _PasswordStep({
    required this.password,
    required this.confirm,
    required this.onComplete,
  });

  @override
  State<_PasswordStep> createState() => _PasswordStepState();
}

class _PasswordStepState extends State<_PasswordStep> {
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create Password',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Secure your account with a strong password',
            style: TextStyle(
              fontSize: 14.sp,
              color: KhaataTheme.textGrey,
            ),
          ),
          SizedBox(height: 32.h),
          AnimatedTextField(
            label: 'Password',
            hint: 'Min 8 chars, include A-Z, a-z, 0-9, @#\$%',
            controller: widget.password,
            obscureText: _obscurePassword,
            suffix: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: Validators.validatePassword,
          ),
          SizedBox(height: 16.h),
          AnimatedTextField(
            label: 'Confirm Password',
            hint: 'Re-enter password',
            controller: widget.confirm,
            obscureText: _obscureConfirm,
            suffix: IconButton(
              icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            validator: (val) {
              if (val != widget.password.text) return 'Passwords do not match';
              return null;
            },
          ),
          SizedBox(height: 24.h),
          // Password Requirements
          _PasswordRequirements(controller: widget.password),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: widget.onComplete,
            style: ElevatedButton.styleFrom(
              backgroundColor: KhaataTheme.primaryBlue,
              minimumSize: Size(double.infinity, 56.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: Text('Complete Registration', style: TextStyle(fontSize: 16.sp)),
          ),
        ],
      ),
    );
  }
}

class _PasswordRequirements extends StatelessWidget {
  final TextEditingController controller;

  const _PasswordRequirements({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final text = controller.text;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Requirement(text: 'At least 8 characters', valid: text.length >= 8),
            _Requirement(text: 'One uppercase letter (A-Z)', valid: RegExp(r'[A-Z]').hasMatch(text)),
            _Requirement(text: 'One lowercase letter (a-z)', valid: RegExp(r'[a-z]').hasMatch(text)),
            _Requirement(text: 'One number (0-9)', valid: RegExp(r'[0-9]').hasMatch(text)),
            _Requirement(text: 'One special character (@\$!%*?&)', valid: RegExp(r'[@$!%*?&]').hasMatch(text)),
          ],
        );
      },
    );
  }
}

class _Requirement extends StatelessWidget {
  final String text;
  final bool valid;

  const _Requirement({required this.text, required this.valid});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Icon(
            valid ? Icons.check_circle : Icons.circle_outlined,
            size: 16.sp,
            color: valid ? KhaataTheme.accentGreen : Colors.grey,
          ),
          SizedBox(width: 8.w),
          Text(
            text,
            style: TextStyle(
              fontSize: 12.sp,
              color: valid ? KhaataTheme.accentGreen : Colors.grey,
              fontWeight: valid ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}