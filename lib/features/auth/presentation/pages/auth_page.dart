import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../../../../core/utils/validators.dart';


class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage>
    with SingleTickerProviderStateMixin {
  bool isLogin = true;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  // Controllers
  final _loginPhoneController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _loginAadharController = TextEditingController();

  final _signupPhoneController = TextEditingController();
  final _signupNameController = TextEditingController();
  final _signupEmailController = TextEditingController();
  final _signupPanController = TextEditingController();
  final _signupAadharController = TextEditingController();
  final _signupPasswordController = TextEditingController();
  final _signupConfirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    // Dispose all controllers...
    super.dispose();
  }

  void toggleAuthMode() {
    setState(() {
      isLogin = !isLogin;
    });
    if (isLogin) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              KhaataTheme.primaryBlue,
              Color(0xFF1E40AF),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(height: 40.h),
              // Logo
              Hero(
                tag: 'logo',
                child: Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Text(
                    'K',
                    style: TextStyle(
                      fontSize: 40.sp,
                      fontWeight: FontWeight.bold,
                      color: KhaataTheme.primaryBlue,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 30.h),

              // Sliding Toggle
              SlidingToggle(
                isLogin: isLogin,
                onToggle: toggleAuthMode,
              ),

              SizedBox(height: 30.h),

              // Content Area
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30.r),
                      topRight: Radius.circular(30.r),
                    ),
                  ),
                  child: ClipRect(
                    child: AnimatedSwitcher(
                      duration: Duration(milliseconds: 400),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: Offset(isLogin ? -1 : 1, 0),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: isLogin
                          ? _LoginForm(
                        key: ValueKey('login'),
                        phoneController: _loginPhoneController,
                        aadharController: _loginAadharController,
                        passwordController: _loginPasswordController,
                      )
                          : _SignupForm(
                        key: ValueKey('signup'),
                        phoneController: _signupPhoneController,
                        nameController: _signupNameController,
                        emailController: _signupEmailController,
                        panController: _signupPanController,
                        aadharController: _signupAadharController,
                        passwordController: _signupPasswordController,
                        confirmPasswordController: _signupConfirmPasswordController,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Sliding Toggle Widget
class SlidingToggle extends StatelessWidget {
  final bool isLogin;
  final VoidCallback onToggle;

  const SlidingToggle({
    required this.isLogin,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280.w,
      height: 50.h,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(25.r),
      ),
      child: Stack(
        children: [
          // Sliding Background
          AnimatedPositioned(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            left: isLogin ? 0 : 140.w,
            child: Container(
              width: 140.w,
              height: 50.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
          ),
          // Text Buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: isLogin ? null : onToggle,
                  child: Container(
                    height: 50.h,
                    alignment: Alignment.center,
                    child: Text(
                      'Sign In',
                      style: TextStyle(
                        color: isLogin ? KhaataTheme.primaryBlue : Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: isLogin ? onToggle : null,
                  child: Container(
                    height: 50.h,
                    alignment: Alignment.center,
                    child: Text(
                      'Sign Up',
                      style: TextStyle(
                        color: !isLogin ? KhaataTheme.primaryBlue : Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Login Form
class _LoginForm extends StatefulWidget {
  final TextEditingController phoneController;
  final TextEditingController aadharController;
  final TextEditingController passwordController;

  const _LoginForm({
    super.key,
    required this.phoneController,
    required this.aadharController,
    required this.passwordController,
  });

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  bool useAadhar = false;
  bool obscurePassword = true;
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20.h),
            Text(
              'Welcome Back!',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: KhaataTheme.textDark,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Sign in to continue',
              style: TextStyle(
                fontSize: 14.sp,
                color: KhaataTheme.textGrey,
              ),
            ),
            SizedBox(height: 30.h),

            // Toggle: Phone or Aadhar
            Row(
              children: [
                _LoginMethodChip(
                  label: 'Mobile',
                  isSelected: !useAadhar,
                  onTap: () => setState(() => useAadhar = false),
                ),
                SizedBox(width: 12.w),
                _LoginMethodChip(
                  label: 'Aadhar',
                  isSelected: useAadhar,
                  onTap: () => setState(() => useAadhar = true),
                ),
              ],
            ),
            SizedBox(height: 24.h),

            // Input Field
            if (!useAadhar)
              _AnimatedInputField(
                label: 'Mobile Number',
                hint: '10-digit number',
                controller: widget.phoneController,
                keyboardType: TextInputType.phone,
                prefix: Text('+91 ', style: TextStyle(fontSize: 16.sp)),
                validator: Validators.validatePhone,
                maxLength: 10,
              )
            else
              _AnimatedInputField(
                label: 'Aadhar Number',
                hint: '1234 5678 9012',
                controller: widget.aadharController,
                keyboardType: TextInputType.number,
                validator: Validators.validateAadhar,
                maxLength: 14,
              ),

            SizedBox(height: 20.h),

            _AnimatedInputField(
              label: 'Password',
              hint: 'Enter your password',
              controller: widget.passwordController,
              obscureText: obscurePassword,
              validator: Validators.validatePassword,
              suffix: IconButton(
                icon: Icon(
                  obscurePassword ? Icons.visibility_off : Icons.visibility,
                  size: 20.sp,
                ),
                onPressed: () => setState(() => obscurePassword = !obscurePassword),
              ),
            ),

            SizedBox(height: 12.h),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                child: Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: KhaataTheme.primaryBlue,
                    fontSize: 12.sp,
                  ),
                ),
              ),
            ),

            SizedBox(height: 24.h),

            ElevatedButton(
              onPressed: _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: KhaataTheme.primaryBlue,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 56.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 0,
              ),
              child: Text(
                'Sign In',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            SizedBox(height: 20.h),

            // Biometric Option
            Center(
              child: TextButton.icon(
                onPressed: () {},
                icon: Icon(Icons.fingerprint, color: KhaataTheme.primaryBlue),
                label: Text(
                  'Use Biometric',
                  style: TextStyle(color: KhaataTheme.primaryBlue),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      // API Call
      context.go('/home');
    }
  }
}

// Signup Form
class _SignupForm extends StatefulWidget {
  final TextEditingController phoneController;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController panController;
  final TextEditingController aadharController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;

  const _SignupForm({
    super.key,
    required this.phoneController,
    required this.nameController,
    required this.emailController,
    required this.panController,
    required this.aadharController,
    required this.passwordController,
    required this.confirmPasswordController,
  });

  @override
  State<_SignupForm> createState() => _SignupFormState();
}

class _SignupFormState extends State<_SignupForm> {
  int currentStep = 0;
  bool obscurePassword = true;
  bool obscureConfirm = true;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20.h),
          Text(
            'Create Account',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: KhaataTheme.textDark,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Step ${currentStep + 1} of 4',
            style: TextStyle(
              fontSize: 14.sp,
              color: KhaataTheme.primaryBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 30.h),

          // Step Indicator
          Row(
            children: List.generate(4, (index) {
              return Expanded(
                child: Container(
                  height: 4.h,
                  margin: EdgeInsets.only(right: index < 3 ? 8.w : 0),
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
          SizedBox(height: 30.h),

          // Step Content
          _buildStepContent(),

          SizedBox(height: 30.h),

          Row(
            children: [
              if (currentStep > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => currentStep--),
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size(double.infinity, 56.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text('Back'),
                  ),
                ),
              if (currentStep > 0) SizedBox(width: 12.w),
              Expanded(
                flex: currentStep > 0 ? 1 : 2,
                child: ElevatedButton(
                  onPressed: _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KhaataTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 56.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    currentStep == 3 ? 'Complete' : 'Next',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (currentStep) {
      case 0:
        return Column(
          children: [
            _AnimatedInputField(
              label: 'Full Name',
              hint: 'Enter your full name',
              controller: widget.nameController,
              textCapitalization: TextCapitalization.words,
              validator: (val) => val!.length < 3 ? 'Name too short' : null,
            ),
            SizedBox(height: 20.h),
            _AnimatedInputField(
              label: 'Mobile Number',
              hint: '10-digit number',
              controller: widget.phoneController,
              keyboardType: TextInputType.phone,
              prefix: Text('+91 ', style: TextStyle(fontSize: 16.sp)),
              validator: Validators.validatePhone,
              maxLength: 10,
            ),
          ],
        );
      case 1:
        return Column(
          children: [
            _AnimatedInputField(
              label: 'Email Address',
              hint: 'name@example.com',
              controller: widget.emailController,
              keyboardType: TextInputType.emailAddress,
              validator: Validators.validateEmail,
            ),
            SizedBox(height: 20.h),
            _AnimatedInputField(
              label: 'PAN Number',
              hint: 'ABCDE1234F',
              controller: widget.panController,
              textCapitalization: TextCapitalization.characters,
              validator: Validators.validatePAN,
              maxLength: 10,
            ),
          ],
        );
      case 2:
        return Column(
          children: [
            _AnimatedInputField(
              label: 'Aadhar Number',
              hint: '1234 5678 9012',
              controller: widget.aadharController,
              keyboardType: TextInputType.number,
              validator: Validators.validateAadhar,
              maxLength: 14,
            ),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 16.sp,
                      color: KhaataTheme.primaryBlue),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Aadhar is your unique identifier for secure transactions',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: KhaataTheme.primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      case 3:
        return Column(
          children: [
            _AnimatedInputField(
              label: 'Password',
              hint: 'Min 8 chars with A-Z, a-z, 0-9, @#\$%',
              controller: widget.passwordController,
              obscureText: obscurePassword,
              validator: Validators.validatePassword,
              suffix: IconButton(
                icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => obscurePassword = !obscurePassword),
              ),
            ),
            SizedBox(height: 20.h),
            _AnimatedInputField(
              label: 'Confirm Password',
              hint: 'Re-enter password',
              controller: widget.confirmPasswordController,
              obscureText: obscureConfirm,
              validator: (val) {
                if (val != widget.passwordController.text) return 'Passwords don\'t match';
                return null;
              },
              suffix: IconButton(
                icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => obscureConfirm = !obscureConfirm),
              ),
            ),
          ],
        );
      default:
        return SizedBox();
    }
  }

  void _nextStep() {
    if (currentStep < 3) {
      setState(() => currentStep++);
    } else {
      // Complete signup
      context.go('/home');
    }
  }
}

// Supporting Widgets
class _LoginMethodChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LoginMethodChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? KhaataTheme.primaryBlue : Colors.grey[200],
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : KhaataTheme.textGrey,
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _AnimatedInputField extends StatefulWidget {
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

  const _AnimatedInputField({
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
  });

  @override
  State<_AnimatedInputField> createState() => _AnimatedInputFieldState();
}

class _AnimatedInputFieldState extends State<_AnimatedInputField> {
  bool isFocused = false;
  bool hasError = false;
  String? errorText;

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
          validator: (value) {
            if (widget.validator != null) {
              errorText = widget.validator!(value);
              hasError = errorText != null;
            }
            return errorText;
          },
          onChanged: (value) {
            if (hasError) {
              setState(() {
                hasError = false;
                errorText = null;
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
          ),
        ),
        if (hasError && errorText != null)
          Padding(
            padding: EdgeInsets.only(top: 4.h, left: 4.w),
            child: Text(
              errorText!,
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