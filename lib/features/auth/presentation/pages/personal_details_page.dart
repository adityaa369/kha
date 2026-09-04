import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/constants.dart';
import '../../../../config/theme.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/inputs.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/blocs/auth/auth_cubit.dart';
import '../../../../core/utils/dialog_utils.dart';

class PersonalDetailsPage extends StatefulWidget {
  const PersonalDetailsPage({super.key});

  @override
  State<PersonalDetailsPage> createState() => _PersonalDetailsPageState();
}

class _PersonalDetailsPageState extends State<PersonalDetailsPage> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthCubit>().currentUser;
    if (user != null) {
      _firstNameController.text = user.firstName;
      _lastNameController.text = user.lastName;
      _emailController.text = user.email ?? '';
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          context.read<AuthCubit>().resetToInitial();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (!mounted) return;
          if (state is AuthenticatedEmailVerifiedKycIncomplete || state is AuthenticatedKycComplete || state is AuthenticatedEmailUnverified) {
            context.push(AppConstants.panDetails);
          } else if (state is AuthError) {
            ScaffoldMessenger.of(
              context,
            );
DialogUtils.showErrorDialog(context, state.message);
          }
        },
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Step 1 of 3',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                Center(
                  child: Container(
                    width: 80.w,
                    height: 80.h,
                    decoration: BoxDecoration(
                      color: KhaataTheme.accentGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Icon(
                      Icons.description_rounded,
                      color: KhaataTheme.accentGreen,
                      size: 40.sp,
                    ),
                  ),
                ),
                SizedBox(height: 32.h),
                Text(
                  "Let's get you started",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 8.h),
                Text(
                  'No Spam. Just Credit Insights',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                SizedBox(height: 40.h),
                KhaataTextField(
                  label: 'First Name',
                  hint: 'Enter first name',
                  controller: _firstNameController,
                  validator: (value) =>
                      value!.isEmpty ? 'First name is required' : null,
                ),
                SizedBox(height: 20.h),
                KhaataTextField(
                  label: 'Last Name',
                  hint: 'Enter last name',
                  controller: _lastNameController,
                  validator: (value) =>
                      value!.isEmpty ? 'Last name is required' : null,
                ),
                SizedBox(height: 20.h),
                KhaataTextField(
                  label: 'Email Address',
                  hint: 'Enter email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value!.isEmpty) return 'Email is required';
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value)) {
                      return 'Enter valid email';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 24.h),
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: KhaataTheme.primaryBlue,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          'Your privacy is our priority. Rest assured, we never share your information.',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: KhaataTheme.primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 40.h),
                BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, state) {
                    return PrimaryButton(
                      text: 'Continue',
                      isLoading: state is AuthLoading,
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          final user = context.read<AuthCubit>().currentUser;
                          context.read<AuthCubit>().savePersonalDetails(
                            firstName: _firstNameController.text,
                            lastName: _lastNameController.text,
                            email: _emailController.text,
                            phone: user?.phone ?? '',
                          );
                        }
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}


