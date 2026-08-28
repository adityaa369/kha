import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:khatha/core/utils/dialog_utils.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../../../config/theme.dart';
import '../../../../core/blocs/auth/auth_cubit.dart';
import '../../../../core/utils/date_input_formatter.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _pageController = PageController();
  int _currentStep = 0;

  // Form Keys
  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();
  final _step3Key = GlobalKey<FormState>();

  // Step 1 Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();

  // Step 2 Controllers (KYC)
  final _panController = TextEditingController();
  final _aadharController = TextEditingController();
  final _dobController = TextEditingController();
  String _selectedGender = 'Male';

  // Step 3 Controllers (Password)
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _termsAccepted = false;

  // Step 4 Controllers (OTP)
  final _otpController = TextEditingController();
  int _timerSeconds = 30;
  Timer? _resendTimer;
  bool _canResend = false;

  @override
  void dispose() {
    _pageController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _panController.dispose();
    _aadharController.dispose();
    _dobController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    final otpCtrl = _otpController;
    Future.delayed(const Duration(milliseconds: 500), () => otpCtrl.dispose());
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timerSeconds = 30;
    _canResend = false;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_timerSeconds > 0) {
            _timerSeconds--;
          } else {
            _canResend = true;
            _resendTimer?.cancel();
          }
        });
      }
    });
  }

  void _nextPage() {
    setState(() => _currentStep++);
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _prevPage() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.go('/login');
    }
  }

  void _submitStep1() {
    if (_step1Key.currentState?.validate() ?? false) {
      _nextPage();
    }
  }

  void _submitStep2() {
    if (_step2Key.currentState?.validate() ?? false) {
      _nextPage();
    }
  }

  void _submitStep3() {
    if (_step3Key.currentState?.validate() ?? false) {
      if (!_termsAccepted) {
        DialogUtils.showErrorDialog(context, 'Please accept the Terms of Service & Privacy Policy');
        return;
      }

      // Trigger Firebase OTP
      context.read<AuthCubit>().sendOtp(_phoneController.text.trim());
      _startTimer();
      _nextPage();
    }
  }

  void _verifyOtp() {
    if (_otpController.text.length == 6) {
      final phone = _phoneController.text.trim();
      final otp = _otpController.text;

      final registrationDetails = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'city': _cityController.text.trim(),
        'address': _addressController.text.trim(),
        'pan': _panController.text.trim().toUpperCase(),
        'aadhar': _aadharController.text.trim(),
        'dob': _dobController.text.trim(),
        'gender': _selectedGender,
        'password': _passwordController.text,
      };

      context.read<AuthCubit>().verifyOtp(
        phone,
        otp,
        registrationDetails: registrationDetails,
      );
    }
  }

  // Password Strength Logic
  String _getPasswordStrength() {
    final pass = _passwordController.text;
    if (pass.isEmpty) return 'None';
    if (pass.length < 5) return 'Weak';

    bool hasDigits = pass.contains(RegExp(r'[0-9]'));
    bool hasUppercase = pass.contains(RegExp(r'[A-Z]'));

    if (pass.length >= 8 && hasDigits && hasUppercase) {
      return 'Strong';
    }
    return 'Medium';
  }

  @override
  Widget build(BuildContext context) {
    final strength = _getPasswordStrength();

    return Scaffold(
      backgroundColor: KhaataTheme.primaryBlue,
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (!mounted) return;
          if (state is AuthError) {
            DialogUtils.showErrorDialog(context, state.message);
          } else if (state is RegistrationSuccess) {
            DialogUtils.showSuccessDialog(context, 
                  'Registration successful! Please login with your credentials.',
                );
            context.go('/login');
          } else if (state is AuthenticatedUnverified) {
            context.go('/home'); // Fallback direct home routing
          } else if (state is AuthenticatedFull) {
            context.go('/home');
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: Column(
              children: [
                // Custom Header
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 16.h,
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _prevPage,
                        child: Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: const BoxDecoration(
                            color: Colors.white24,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 18.sp,
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        _currentStep == 0 ? 'back to login' : 'Back',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Screen Title
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentStep == 0
                              ? 'Create account'
                              : _currentStep == 1
                              ? 'KYC Verification'
                              : _currentStep == 2
                              ? 'Secure your account'
                              : 'Verify your number',
                          style: TextStyle(
                            fontSize: 26.sp,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          _currentStep == 0
                              ? "Let's get your details set up"
                              : _currentStep == 1
                              ? 'Enter your government IDs'
                              : _currentStep == 2
                              ? 'Create a strong password'
                              : 'One last step to go!',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.white.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24.h),

                // Wizard Card
                Expanded(
                  child: Container(
                    width: double.infinity,
                    margin: EdgeInsets.symmetric(horizontal: 20.w),
                    padding: EdgeInsets.all(24.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24.r),
                        topRight: Radius.circular(24.r),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 20,
                          offset: const Offset(0, -8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Dots Indicator
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(4, (index) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: index == _currentStep ? 16.w : 6.w,
                              height: 6.h,
                              margin: EdgeInsets.symmetric(horizontal: 3.w),
                              decoration: BoxDecoration(
                                color: index == _currentStep
                                    ? KhaataTheme.primaryBlue
                                    : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(3.r),
                              ),
                            );
                          }),
                        ),
                        SizedBox(height: 24.h),

                        // Form Content
                        Expanded(
                          child: PageView(
                            controller: _pageController,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              // Step 1: Personal Details & Address
                              _buildStep1(),

                              // Step 2: KYC Details (PAN, Aadhar, DOB)
                              _buildStep2KYC(),

                              // Step 3: Set Password
                              _buildStep2Password(strength),

                              // Step 4: Verify Number (OTP)
                              _buildStep3OTP(state),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Step 1 Layout
  Widget _buildStep1() {
    return SingleChildScrollView(
      child: Form(
        key: _step1Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal details',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                color: KhaataTheme.textDark,
              ),
            ),
            Text(
              'Tell us who you are',
              style: TextStyle(
                fontSize: 12.sp,
                color: KhaataTheme.textGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 20.h),

            // First & Last Name side-by-side
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'First name',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                          color: KhaataTheme.textDark,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      TextFormField(
                        controller: _firstNameController,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: KhaataTheme.textDark,
                        ),
                        validator: (val) =>
                            val == null || val.isEmpty ? 'Required' : null,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFF3F4F6),
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
                            borderSide: const BorderSide(
                              color: KhaataTheme.primaryBlue,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 14.w,
                            vertical: 12.h,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Last name',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                          color: KhaataTheme.textDark,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      TextFormField(
                        controller: _lastNameController,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: KhaataTheme.textDark,
                        ),
                        validator: (val) =>
                            val == null || val.isEmpty ? 'Required' : null,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFF3F4F6),
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
                            borderSide: const BorderSide(
                              color: KhaataTheme.primaryBlue,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 14.w,
                            vertical: 12.h,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),

            // Mobile number
            Text(
              'Mobile number',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.bold,
                color: KhaataTheme.textDark,
              ),
            ),
            SizedBox(height: 6.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 48.h,
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    children: [
                      Text(
                        'IN',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        '+91',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: KhaataTheme.textGrey,
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 14.sp,
                        color: KhaataTheme.textGrey,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    validator: (val) => val == null || val.length != 10
                        ? 'Enter 10-digit phone number'
                        : null,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: KhaataTheme.textDark,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: const Color(0xFFF3F4F6),
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
                        borderSide: const BorderSide(
                          color: KhaataTheme.primaryBlue,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 12.h,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),

            // Email
            Text(
              'Email address',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.bold,
                color: KhaataTheme.textDark,
              ),
            ),
            SizedBox(height: 6.h),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: (val) {
                if (val == null || val.isEmpty) return 'Email is required';
                if (!val.contains('@')) return 'Enter a valid email';
                return null;
              },
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: KhaataTheme.textDark,
              ),
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.mail_outline,
                  size: 20.sp,
                  color: KhaataTheme.textGrey,
                ),
                filled: true,
                fillColor: const Color(0xFFF3F4F6),
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
                  borderSide: const BorderSide(
                    color: KhaataTheme.primaryBlue,
                    width: 1.5,
                  ),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14.w,
                  vertical: 12.h,
                ),
              ),
            ),
            SizedBox(height: 14.h),

            // Address details
            Text(
              'Address details',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.bold,
                color: KhaataTheme.textDark,
              ),
            ),
            SizedBox(height: 6.h),
            TextFormField(
              controller: _addressController,
              validator: (val) =>
                  val == null || val.isEmpty ? 'Address is required' : null,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: KhaataTheme.textDark,
              ),
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.home_outlined,
                  size: 20.sp,
                  color: KhaataTheme.textGrey,
                ),
                filled: true,
                fillColor: const Color(0xFFF3F4F6),
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
                  borderSide: const BorderSide(
                    color: KhaataTheme.primaryBlue,
                    width: 1.5,
                  ),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14.w,
                  vertical: 12.h,
                ),
              ),
            ),
            SizedBox(height: 14.h),

            // City
            Text(
              'City',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.bold,
                color: KhaataTheme.textDark,
              ),
            ),
            SizedBox(height: 6.h),
            TextFormField(
              controller: _cityController,
              validator: (val) =>
                  val == null || val.isEmpty ? 'City is required' : null,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: KhaataTheme.textDark,
              ),
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.location_city_outlined,
                  size: 20.sp,
                  color: KhaataTheme.textGrey,
                ),
                suffixIcon: Icon(
                  Icons.keyboard_arrow_down,
                  size: 20.sp,
                  color: KhaataTheme.textGrey,
                ),
                filled: true,
                fillColor: const Color(0xFFF3F4F6),
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
                  borderSide: const BorderSide(
                    color: KhaataTheme.primaryBlue,
                    width: 1.5,
                  ),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14.w,
                  vertical: 12.h,
                ),
              ),
            ),
            SizedBox(height: 24.h),

            // Next Button
            SizedBox(
              width: double.infinity,
              height: 50.h,
              child: ElevatedButton(
                onPressed: _submitStep1,
                style: ElevatedButton.styleFrom(
                  backgroundColor: KhaataTheme.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Next',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // Footer sign in link
            Center(
              child: GestureDetector(
                onTap: () => context.go('/login'),
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: KhaataTheme.textGrey,
                      fontWeight: FontWeight.w500,
                    ),
                    children: const [
                      TextSpan(text: 'Already have an account? '),
                      TextSpan(
                        text: 'Sign in',
                        style: TextStyle(
                          color: KhaataTheme.primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Step 2 Layout (KYC details)
  Widget _buildStep2KYC() {
    return SingleChildScrollView(
      child: Form(
        key: _step2Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'KYC Verification',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                color: KhaataTheme.textDark,
              ),
            ),
            Text(
              'Enter your government identity cards',
              style: TextStyle(
                fontSize: 12.sp,
                color: KhaataTheme.textGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 20.h),

            // PAN Card number
            Text(
              'PAN card number',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.bold,
                color: KhaataTheme.textDark,
              ),
            ),
            SizedBox(height: 6.h),
            TextFormField(
              controller: _panController,
              textCapitalization: TextCapitalization.characters,
              validator: (val) {
                if (val == null || val.isEmpty) return 'PAN is required';
                if (!RegExp(
                  r'^[A-Z]{5}[0-9]{4}[A-Z]$',
                ).hasMatch(val.toUpperCase())) {
                  return 'Invalid PAN format';
                }
                return null;
              },
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: KhaataTheme.textDark,
              ),
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.credit_card_rounded,
                  size: 20.sp,
                  color: KhaataTheme.textGrey,
                ),
                filled: true,
                fillColor: const Color(0xFFF3F4F6),
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
                  borderSide: const BorderSide(
                    color: KhaataTheme.primaryBlue,
                    width: 1.5,
                  ),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14.w,
                  vertical: 12.h,
                ),
              ),
            ),
            SizedBox(height: 14.h),

            // Aadhar Number
            Text(
              'Aadhar number',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.bold,
                color: KhaataTheme.textDark,
              ),
            ),
            SizedBox(height: 6.h),
            TextFormField(
              controller: _aadharController,
              keyboardType: TextInputType.number,
              maxLength: 12,
              validator: (val) {
                if (val == null || val.isEmpty) return 'Aadhar is required';
                if (val.length != 12 || !RegExp(r'^[0-9]+$').hasMatch(val)) {
                  return 'Aadhar must be 12 digits';
                }
                return null;
              },
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: KhaataTheme.textDark,
              ),
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.fingerprint_outlined,
                  size: 20.sp,
                  color: KhaataTheme.textGrey,
                ),
                counterText: '',
                filled: true,
                fillColor: const Color(0xFFF3F4F6),
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
                  borderSide: const BorderSide(
                    color: KhaataTheme.primaryBlue,
                    width: 1.5,
                  ),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14.w,
                  vertical: 12.h,
                ),
              ),
            ),
            SizedBox(height: 14.h),

            // Date of birth
            Text(
              'Date of birth',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.bold,
                color: KhaataTheme.textDark,
              ),
            ),
            SizedBox(height: 6.h),
            TextFormField(
              controller: _dobController,
              keyboardType: TextInputType.number,
              inputFormatters: [DateInputFormatter()],
              validator: (val) {
                if (val == null || val.isEmpty) return 'Date of birth is required';
                if (val.length != 10) return 'Enter a valid date (DD/MM/YYYY)';
                return null;
              },
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: KhaataTheme.textDark,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.calendar_today_outlined,
                      size: 20.sp,
                      color: KhaataTheme.textGrey,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF3F4F6),
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
                      borderSide: const BorderSide(
                        color: KhaataTheme.primaryBlue,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 12.h,
                    ),
                  ),
            ),
            SizedBox(height: 14.h),

            // Gender Selection
            Text(
              'Gender',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.bold,
                color: KhaataTheme.textDark,
              ),
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                _buildGenderButton('Male'),
                SizedBox(width: 8.w),
                _buildGenderButton('Female'),
                SizedBox(width: 8.w),
                _buildGenderButton('Others'),
              ],
            ),
            SizedBox(height: 24.h),

            // Next button
            SizedBox(
              width: double.infinity,
              height: 50.h,
              child: ElevatedButton(
                onPressed: _submitStep2,
                style: ElevatedButton.styleFrom(
                  backgroundColor: KhaataTheme.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Next',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderButton(String label) {
    bool isSelected = _selectedGender == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedGender = label),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFE6F4EA)
                : const Color(0xFFF3F4F6),
            border: Border.all(
              color: isSelected ? KhaataTheme.primaryBlue : Colors.transparent,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color: isSelected
                  ? KhaataTheme.primaryBlue
                  : KhaataTheme.textGrey,
            ),
          ),
        ),
      ),
    );
  }

  // Step 3 Layout
  Widget _buildStep2Password(String strength) {
    return SingleChildScrollView(
      child: Form(
        key: _step3Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Set password',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                color: KhaataTheme.textDark,
              ),
            ),
            Text(
              'Minimum 8 characters with a number',
              style: TextStyle(
                fontSize: 12.sp,
                color: KhaataTheme.textGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 20.h),

            // New password
            Text(
              'New password',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.bold,
                color: KhaataTheme.textDark,
              ),
            ),
            SizedBox(height: 6.h),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              onChanged: (_) => setState(() {}),
              validator: (val) {
                if (val == null || val.length < 8) {
                  return 'Must be at least 8 characters';
                }
                if (!val.contains(RegExp(r'[0-9]'))) {
                  return 'Must contain at least one number';
                }
                return null;
              },
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: KhaataTheme.textDark,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF3F4F6),
                prefixIcon: Icon(
                  Icons.lock_outline,
                  size: 20.sp,
                  color: KhaataTheme.textGrey,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20.sp,
                    color: KhaataTheme.textGrey,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
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
                  borderSide: const BorderSide(
                    color: KhaataTheme.primaryBlue,
                    width: 1.5,
                  ),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14.w,
                  vertical: 12.h,
                ),
              ),
            ),
            SizedBox(height: 14.h),

            // Confirm password
            Text(
              'Confirm password',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.bold,
                color: KhaataTheme.textDark,
              ),
            ),
            SizedBox(height: 6.h),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirm,
              validator: (val) {
                if (val != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: KhaataTheme.textDark,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF3F4F6),
                prefixIcon: Icon(
                  Icons.lock_outline,
                  size: 20.sp,
                  color: KhaataTheme.textGrey,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20.sp,
                    color: KhaataTheme.textGrey,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
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
                  borderSide: const BorderSide(
                    color: KhaataTheme.primaryBlue,
                    width: 1.5,
                  ),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14.w,
                  vertical: 12.h,
                ),
              ),
            ),
            SizedBox(height: 12.h),

            // Password strength UI
            Row(
              children: [
                Text(
                  'Password strength',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: KhaataTheme.textGrey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  strength,
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: strength == 'Strong'
                        ? Colors.green
                        : strength == 'Medium'
                        ? Colors.orange
                        : strength == 'Weak'
                        ? Colors.red
                        : KhaataTheme.textGrey,
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            Row(
              children: List.generate(3, (index) {
                Color barColor = Colors.grey.shade200;
                if (strength == 'Weak') {
                  if (index == 0) barColor = Colors.red;
                } else if (strength == 'Medium') {
                  if (index <= 1) barColor = Colors.orange;
                } else if (strength == 'Strong') {
                  barColor = Colors.green;
                }

                return Expanded(
                  child: Container(
                    height: 4.h,
                    margin: EdgeInsets.only(right: index < 2 ? 6.w : 0),
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                );
              }),
            ),
            SizedBox(height: 20.h),

            // Terms checkbox
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24.w,
                  height: 24.h,
                  child: Checkbox(
                    value: _termsAccepted,
                    onChanged: (v) =>
                        setState(() => _termsAccepted = v ?? false),
                    activeColor: KhaataTheme.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: KhaataTheme.textGrey,
                        height: 1.4,
                      ),
                      children: const [
                        TextSpan(text: 'I agree to the '),
                        TextSpan(
                          text: 'Terms of Service',
                          style: TextStyle(
                            color: KhaataTheme.primaryBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: TextStyle(
                            color: KhaataTheme.primaryBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),

            // Continue Button
            SizedBox(
              width: double.infinity,
              height: 50.h,
              child: ElevatedButton(
                onPressed: _submitStep3,
                style: ElevatedButton.styleFrom(
                  backgroundColor: KhaataTheme.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Continue',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Step 4 Layout (OTP Verification)
  Widget _buildStep3OTP(AuthState state) {
    final phone = _phoneController.text.trim();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner showing phone geocoded OTP info
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F4EA), // Light green matching theme
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.phone_android_outlined,
                  color: KhaataTheme.primaryBlue,
                  size: 20.sp,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '+91 $phone',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF065F46),
                        ),
                      ),
                      Text(
                        'sent via SMS',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: const Color(0xFF047857),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _prevPage,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Change number',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: KhaataTheme.primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),

          // 6 OTP Digit code cells (styled as premium boxes matching Screen 4)
          // Firebase OTP requires 6 digits. We show 6 cells for correct operation.
          Text(
            'Enter Verification Code',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: KhaataTheme.textDark,
            ),
          ),
          SizedBox(height: 12.h),
          PinCodeTextField(
            appContext: context,
            length: 6,
            obscureText: false,
            animationType: AnimationType.fade,
            textStyle: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: KhaataTheme.primaryBlue,
            ),
            pinTheme: PinTheme(
              shape: PinCodeFieldShape.box,
              borderRadius: BorderRadius.circular(12.r),
              fieldHeight: 52.h,
              fieldWidth: 44.w,
              activeFillColor: Colors.white,
              inactiveFillColor: Colors.white,
              selectedFillColor: Colors.white,
              activeColor: KhaataTheme.primaryBlue,
              inactiveColor: Colors.grey.shade300,
              selectedColor: KhaataTheme.primaryBlue,
              borderWidth: 1.5,
            ),
            animationDuration: const Duration(milliseconds: 300),
            backgroundColor: Colors.transparent,
            enableActiveFill: true,
            controller: _otpController,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            onCompleted: (_) => _verifyOtp(),
          ),
          SizedBox(height: 16.h),

          // Resend Timer Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_canResend)
                Text(
                  'Resend OTP in 00:${_timerSeconds.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: KhaataTheme.textGrey,
                    fontWeight: FontWeight.w500,
                  ),
                )
              else
                Row(
                  children: [
                    Text(
                      "Didn't get it? ",
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: KhaataTheme.textGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        context.read<AuthCubit>().sendOtp(phone);
                        _startTimer();
                      },
                      child: Text(
                        'Resend OTP',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: KhaataTheme.primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          SizedBox(height: 32.h),

          // Verify button
          SizedBox(
            width: double.infinity,
            height: 52.h,
            child: ElevatedButton(
              onPressed:
                  (state is AuthLoading || _otpController.text.length != 6)
                  ? null
                  : _verifyOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: KhaataTheme.primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 0,
              ),
              child: state is AuthLoading
                  ? SizedBox(
                      width: 20.w,
                      height: 20.h,
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Verify & Create account',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

