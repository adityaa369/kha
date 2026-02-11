import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../../../../core/utils/validators.dart';

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
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _panController.dispose();
    _aadharController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_validateCurrentStep()) {
      _animationController.reverse().then((_) {
        setState(() => _currentStep++);
        _pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
        _animationController.forward();
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _animationController.reverse().then((_) {
        setState(() => _currentStep--);
        _pageController.previousPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
        _animationController.forward();
      });
    } else {
      context.pop();
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

  void _completeSignup() {
    final userData = {
      'phone': _phoneController.text,
      'firstName': _firstNameController.text,
      'lastName': _lastNameController.text,
      'email': _emailController.text,
      'pan': _panController.text.toUpperCase(),
      'aadhar': _aadharController.text.replaceAll(' ', ''),
      'password': _passwordController.text,
    };

    // TODO: Send to backend
    context.go('/home');
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
          onPressed: _previousStep,
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
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _PhoneStep(controller: _phoneController, onNext: _nextStep),
                _OtpStep(controller: _otpController, onNext: _nextStep),
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
}

// Step Indicator Widget
class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const _StepIndicator({
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      child: Row(
        children: List.generate(totalSteps, (index) {
          return Expanded(
            child: Container(
              height: 4.h,
              margin: EdgeInsets.only(right: index < totalSteps - 1 ? 8.w : 0),
              decoration: BoxDecoration(
                color: index <= currentStep
                    ? KhaataTheme.primaryBlue
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// Animated Text Field Widget
class _AnimatedTextField extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? prefix;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final int? maxLength;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;

  const _AnimatedTextField({
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.prefix,
    this.suffix,
    this.validator,
    this.maxLength,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
  });

  @override
  State<_AnimatedTextField> createState() => _AnimatedTextFieldState();
}

class _AnimatedTextFieldState extends State<_AnimatedTextField> {
  bool _hasError = false;
  String? _errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: KhaataTheme.textDark,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          obscureText: widget.obscureText,
          maxLength: widget.maxLength,
          textCapitalization: widget.textCapitalization,
          inputFormatters: widget.inputFormatters,
          validator: (value) {
            if (widget.validator != null) {
              _errorText = widget.validator!(value);
              _hasError = _errorText != null;
            }
            return _errorText;
          },
          onChanged: (value) {
            if (_hasError) {
              setState(() {
                _hasError = false;
                _errorText = null;
              });
            }
          },
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: widget.prefix != null
                ? Padding(
              padding: EdgeInsets.only(left: 16.w),
              child: widget.prefix,
            )
                : null,
            suffixIcon: widget.suffix,
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: KhaataTheme.primaryBlue,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: KhaataTheme.dangerRed,
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 16.h,
            ),
            counterText: '',
          ),
        ),
        if (_hasError && _errorText != null)
          Padding(
            padding: EdgeInsets.only(top: 4.h, left: 4.w),
            child: Text(
              _errorText!,
              style: TextStyle(
                color: KhaataTheme.dangerRed,
                fontSize: 12.sp,
              ),
            ),
          ),
      ],
    );
  }
}

// Step 1: Phone Input
class _PhoneStep extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onNext;

  const _PhoneStep({required this.controller, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
          _AnimatedTextField(
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

// Step 2: OTP
class _OtpStep extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onNext;

  const _OtpStep({required this.controller, required this.onNext});

  @override
  State<_OtpStep> createState() => _OtpStepState();
}

class _OtpStepState extends State<_OtpStep> {
  int _resendTimer = 30;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          if (_resendTimer > 0) {
            _resendTimer--;
            _startTimer();
          } else {
            _canResend = true;
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter OTP',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Enter the 6-digit code sent to your mobile',
            style: TextStyle(
              fontSize: 14.sp,
              color: KhaataTheme.textGrey,
            ),
          ),
          SizedBox(height: 32.h),
          _AnimatedTextField(
            label: 'OTP',
            hint: '6-digit OTP',
            controller: widget.controller,
            keyboardType: TextInputType.number,
            maxLength: 6,
            validator: (value) => value?.length != 6 ? 'Enter 6-digit OTP' : null,
          ),
          SizedBox(height: 16.h),
          if (_canResend)
            TextButton(
              onPressed: () {
                setState(() {
                  _resendTimer = 30;
                  _canResend = false;
                });
                _startTimer();
              },
              child: Text(
                'Resend OTP',
                style: TextStyle(color: KhaataTheme.primaryBlue),
              ),
            )
          else
            Text(
              'Resend in $_resendTimer seconds',
              style: TextStyle(color: KhaataTheme.textGrey),
            ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: widget.onNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: KhaataTheme.primaryBlue,
              minimumSize: Size(double.infinity, 56.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: Text('Verify', style: TextStyle(fontSize: 16.sp)),
          ),
        ],
      ),
    );
  }
}

// Step 3: Personal Details
class _PersonalStep extends StatelessWidget {
  final TextEditingController firstName;
  final TextEditingController lastName;
  final TextEditingController email;
  final VoidCallback onNext;

  const _PersonalStep({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Details',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Tell us about yourself',
            style: TextStyle(
              fontSize: 14.sp,
              color: KhaataTheme.textGrey,
            ),
          ),
          SizedBox(height: 32.h),
          _AnimatedTextField(
            label: 'First Name',
            hint: 'Enter first name',
            controller: firstName,
            textCapitalization: TextCapitalization.words,
            validator: (value) => value!.isEmpty ? 'First name required' : null,
          ),
          SizedBox(height: 16.h),
          _AnimatedTextField(
            label: 'Last Name',
            hint: 'Enter last name',
            controller: lastName,
            textCapitalization: TextCapitalization.words,
            validator: (value) => value!.isEmpty ? 'Last name required' : null,
          ),
          SizedBox(height: 16.h),
          _AnimatedTextField(
            label: 'Email',
            hint: 'Enter email address',
            controller: email,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.validateEmail,
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

// Step 4: KYC (PAN + Aadhar)
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
    return SingleChildScrollView(
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
          _AnimatedTextField(
            label: 'PAN Number',
            hint: 'ABCDE1234F',
            controller: pan,
            textCapitalization: TextCapitalization.characters,
            maxLength: 10,
            validator: Validators.validatePAN,
          ),
          SizedBox(height: 16.h),
          _AnimatedTextField(
            label: 'Aadhar Number',
            hint: '1234 5678 9012',
            controller: aadhar,
            keyboardType: TextInputType.number,
            maxLength: 14,
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
    return SingleChildScrollView(
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
          _AnimatedTextField(
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
          _AnimatedTextField(
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
          SizedBox(height: 16.h),
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
            _Requirement(text: 'One uppercase (A-Z)', valid: RegExp(r'[A-Z]').hasMatch(text)),
            _Requirement(text: 'One lowercase (a-z)', valid: RegExp(r'[a-z]').hasMatch(text)),
            _Requirement(text: 'One number (0-9)', valid: RegExp(r'[0-9]').hasMatch(text)),
            _Requirement(text: 'One special char', valid: RegExp(r'[@$!%*?&]').hasMatch(text)),
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
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        children: [
          Icon(
            valid ? Icons.check_circle : Icons.circle_outlined,
            size: 14.sp,
            color: valid ? KhaataTheme.accentGreen : Colors.grey,
          ),
          SizedBox(width: 8.w),
          Text(
            text,
            style: TextStyle(
              fontSize: 11.sp,
              color: valid ? KhaataTheme.accentGreen : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}