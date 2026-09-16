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

class MpinSetupPage extends StatefulWidget {
  const MpinSetupPage({super.key});

  @override
  State<MpinSetupPage> createState() => _MpinSetupPageState();
}

class _MpinSetupPageState extends State<MpinSetupPage> {
  final GlobalKey<DynamicMpinKeypadState> _keypadKey = GlobalKey();
  String? _firstMpin;
  String _title = 'Set MPIN';
  String _subtitle = 'Create a 6-digit MPIN for faster login';

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
    if (_firstMpin == null) {
      setState(() {
        _firstMpin = mpin;
        _title = 'Confirm MPIN';
        _subtitle = 'Re-enter your 6-digit MPIN';
      });
      _keypadKey.currentState?.reshuffle();
    } else {
      if (_firstMpin == mpin) {
        context.read<AuthCubit>().setupMpin(mpin);
      } else {
        DialogUtils.showErrorDialog(context, 'MPINs do not match. Try again.');
        setState(() {
          _firstMpin = null;
          _title = 'Set MPIN';
          _subtitle = 'Create a 6-digit MPIN for faster login';
        });
        _keypadKey.currentState?.reshuffle();
      }
    }
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
              Icon(Icons.security, size: 48.sp, color: KhaataTheme.primaryBlue),
              SizedBox(height: 16.h),
              Text(
                _title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: KhaataTheme.textDark,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                _subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: KhaataTheme.textGrey,
                ),
              ),
              SizedBox(height: 40.h),
              
              BlocConsumer<AuthCubit, AuthState>(
                listener: (context, state) {
                  if (state is Authenticated) {
                    SecurityUtils.unsecureScreen(); 
                    DialogUtils.showSuccessDialog(context, 'MPIN set successfully.', onOk: () => context.pop(true));
                  } else if (state is AuthError) {
                    DialogUtils.showErrorDialog(context, state.message);
                    setState(() {
                      _firstMpin = null;
                      _title = 'Set MPIN';
                      _subtitle = 'Create a 6-digit MPIN for faster login';
                    });
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