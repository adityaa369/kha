import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/blocs/auth/auth_cubit.dart';
import '../../../../core/utils/security_utils.dart';
import '../../../../core/utils/dialog_utils.dart';
import '../../../../config/theme.dart';
import '../../../../config/constants.dart';
import '../widgets/dynamic_mpin_keypad.dart';

class MpinLoginPage extends StatefulWidget {
  final String phone;
  const MpinLoginPage({super.key, required this.phone});

  @override
  State<MpinLoginPage> createState() => _MpinLoginPageState();
}

class _MpinLoginPageState extends State<MpinLoginPage> {
  final GlobalKey<DynamicMpinKeypadState> _keypadKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    SecurityUtils.secureScreen();
  }

  @override
  void dispose() {
    SecurityUtils.unsecureScreen();
    super.dispose();
  }

  void _onMpinEntered(String mpin) {
    context.read<AuthCubit>().loginWithMpin(widget.phone, mpin);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: KhaataTheme.textDark),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20.h),
              Icon(Icons.lock_outline, size: 48.sp, color: KhaataTheme.primaryBlue),
              SizedBox(height: 16.h),
              Text(
                'Enter MPIN',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: KhaataTheme.textDark,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Please enter your 6-digit MPIN to login.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: KhaataTheme.textGrey,
                ),
              ),
              SizedBox(height: 40.h),
              
              SizedBox(height: 16.h),
              TextButton(
                onPressed: () {
                  SecurityUtils.unsecureScreen();
                  context.go(AppConstants.login);
                },
                child: Text(
                  'Forgot MPIN? Login with SMS',
                  style: TextStyle(
                    color: KhaataTheme.primaryBlue,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              BlocConsumer<AuthCubit, AuthState>(
                listener: (context, state) {
                  if (state is Authenticated) {
                    SecurityUtils.unsecureScreen(); context.go(AppConstants.home);
                  } else if (state is AuthError) {
                    DialogUtils.showErrorDialog(context, state.message);
                    _keypadKey.currentState?.reshuffle();
                  }
                },
                builder: (context, state) {
                  if (state is AuthLoading) {
                    return const Expanded(
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  
                  return Expanded(
                    child: DynamicMpinKeypad(
                      key: _keypadKey,
                      onMpinEntered: _onMpinEntered,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}