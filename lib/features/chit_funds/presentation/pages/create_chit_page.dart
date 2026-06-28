import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/theme.dart';
import '../../../../core/blocs/chit_funds/chit_fund_cubit.dart';

class CreateChitGroupPage extends StatefulWidget {
  const CreateChitGroupPage({super.key});

  @override
  State<CreateChitGroupPage> createState() => _CreateChitGroupPageState();
}

class _CreateChitGroupPageState extends State<CreateChitGroupPage> {
  final _formKey = GlobalKey<FormState>();
  String name = '';
  double totalValue = 0;
  int totalMonths = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KhaataTheme.backgroundGrey,
      appBar: AppBar(
        title: Text(
          'Create Chit Group',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Group Details',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: KhaataTheme.textDark,
                ),
              ),
              SizedBox(height: 16.h),
              _buildTextField(
                label: 'Chit Group Name',
                hint: 'e.g. Diwali Savings 2026',
                onSaved: (val) => name = val ?? '',
              ),
              SizedBox(height: 16.h),
              _buildTextField(
                label: 'Total Value (₹)',
                hint: 'e.g. 500000',
                isNumber: true,
                onSaved: (val) => totalValue = double.tryParse(val ?? '0') ?? 0,
              ),
              SizedBox(height: 16.h),
              SizedBox(height: 16.h),
              _buildTextField(
                label: 'Duration (Months)',
                hint: 'e.g. 50',
                isNumber: true,
                onSaved: (val) => totalMonths = int.tryParse(val ?? '0') ?? 0,
              ),
              SizedBox(height: 32.h),
              SizedBox(
                width: double.infinity,
                height: 54.h,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      context.read<ChitFundCubit>().createChitGroup(
                        name: name,
                        totalValue: totalValue,
                        totalMonths: totalMonths,
                      );
                      context.pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KhaataTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: Text(
                    'Create Group & Start Inviting',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
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

  Widget _buildTextField({
    required String label,
    required String hint,
    required Function(String?) onSaved,
    bool isNumber = false,
    String? initialValue,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: KhaataTheme.textDark,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          initialValue: initialValue,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: KhaataTheme.textGrey, fontSize: 14.sp),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(color: KhaataTheme.borderGrey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(color: KhaataTheme.borderGrey),
            ),
          ),
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          validator: (val) =>
              val == null || val.isEmpty ? 'Required field' : null,
          onSaved: onSaved,
        ),
      ],
    );
  }
}
