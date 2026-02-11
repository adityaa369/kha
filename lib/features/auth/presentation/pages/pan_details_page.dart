import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/constants.dart';
import '../../../../config/theme.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/inputs.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/blocs/auth/auth_cubit.dart';

class PanDetailsPage extends StatefulWidget {
  const PanDetailsPage({super.key});

  @override
  State<PanDetailsPage> createState() => _PanDetailsPageState();
}

class _PanDetailsPageState extends State<PanDetailsPage> {
  String selectedGender = 'Male';
  final TextEditingController _panController = TextEditingController();
  final TextEditingController _aadharController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _panController.dispose();
    _aadharController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: KhaataTheme.primaryBlue,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() {
        _dobController.text = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
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
          icon: Icon(Icons.arrow_back, color: KhaataTheme.textDark),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('Step 2 of 3', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
              SizedBox(height: 20.h),

              Center(
                child: Container(
                  width: 80.w,
                  height: 80.h,
                  decoration: BoxDecoration(
                    color: KhaataTheme.accentGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Icon(
                    Icons.credit_card_rounded,
                    color: KhaataTheme.accentGreen,
                    size: 40.sp,
                  ),
                ),
              ),
              SizedBox(height: 32.h),

              Text(
                'Enter Your PAN details',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 8.h),
              Text(
                'As per your government documents',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              SizedBox(height: 40.h),

              KhaataTextField(
                label: 'PAN',
                hint: 'Enter PAN number',
                controller: _panController,
                inputFormatters: [PanInputFormatter()],
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value!.isEmpty) return 'PAN is required';
                  if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(value)) {
                    return 'Invalid PAN format';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20.h),

              KhaataTextField(
                label: 'Aadhar Number',
                hint: 'Enter 12 digit Aadhar number',
                controller: _aadharController,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) return 'Aadhar is required';
                  if (value.length != 12 || !RegExp(r'^[0-9]+$').hasMatch(value)) {
                    return 'Aadhar must be 12 digits';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20.h),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: KhaataTextField(
                    label: 'Date of Birth',
                    hint: 'DD/MM/YYYY',
                    controller: _dobController,
                    suffix: Icon(Icons.calendar_today, color: KhaataTheme.primaryBlue, size: 20.sp),
                    readOnly: true,
                    validator: (value) => value!.isEmpty ? 'Date of birth is required' : null,
                  ),
                ),
              ),
              SizedBox(height: 20.h),

              Text('Gender', style: Theme.of(context).textTheme.bodyLarge),
              SizedBox(height: 12.h),
              Row(
                children: [
                  _GenderButton(
                    label: 'Male',
                    isSelected: selectedGender == 'Male',
                    onTap: () => setState(() => selectedGender = 'Male'),
                  ),
                  SizedBox(width: 12.w),
                  _GenderButton(
                    label: 'Female',
                    isSelected: selectedGender == 'Female',
                    onTap: () => setState(() => selectedGender = 'Female'),
                  ),
                  SizedBox(width: 12.w),
                  _GenderButton(
                    label: 'Others',
                    isSelected: selectedGender == 'Others',
                    onTap: () => setState(() => selectedGender = 'Others'),
                  ),
                ],
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
                    Icon(Icons.info_outline, color: KhaataTheme.primaryBlue),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        'Please enter the valid PAN information as per your government documents',
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

              PrimaryButton(
                text: 'Continue',
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    context.read<AuthCubit>().savePanDetails(
                      pan: _panController.text.toUpperCase(),
                      aadhar: _aadharController.text,
                      dob: _dobController.text,
                      gender: selectedGender,
                    );
                    context.push(AppConstants.processing);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GenderButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue[50] : Colors.grey[100],
            border: Border.all(
              color: isSelected ? KhaataTheme.primaryBlue : Colors.transparent,
              width: 1.5.w,
            ),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: isSelected ? KhaataTheme.primaryBlue : KhaataTheme.textGrey,
            ),
          ),
        ),
      ),
    );
  }
}