import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/constants.dart';
import '../../../../config/theme.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/inputs.dart';

class CreateLoanPage extends StatefulWidget {
  final String loanType;

  const CreateLoanPage({super.key, required this.loanType});

  @override
  State<CreateLoanPage> createState() => _CreateLoanPageState();
}

class _CreateLoanPageState extends State<CreateLoanPage> {
  final _formKey = GlobalKey<FormState>();
  final _borrowerNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _aadharController = TextEditingController();
  final _addressController = TextEditingController();
  final _amountController = TextEditingController();
  final _interestController = TextEditingController();
  final _durationController = TextEditingController();

  DateTime _startDate = DateTime.now();
  String _durationType = 'Months';
  bool _isLoading = false;

  @override
  void dispose() {
    _borrowerNameController.dispose();
    _mobileController.dispose();
    _aadharController.dispose();
    _addressController.dispose();
    _amountController.dispose();
    _interestController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  String getLoanTypeTitle() {
    switch (widget.loanType) {
      case 'personal':
        return 'Personal Loan';
      case 'business':
        return 'Business Loan';
      case 'home':
        return 'Home Loan';
      case 'chitfund':
        return 'Chit Fund';
      default:
        return 'New Loan';
    }
  }

  IconData getLoanTypeIcon() {
    switch (widget.loanType) {
      case 'personal':
        return Icons.account_balance_wallet;
      case 'business':
        return Icons.business_center;
      case 'home':
        return Icons.home;
      case 'chitfund':
        return Icons.groups;
      default:
        return Icons.money;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
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
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Navigate to OTP confirmation with full loan data
      context.push(
        '/loan-confirmation',
        extra: {
          'borrower_name': _borrowerNameController.text,
          'borrower_phone': _mobileController.text,
          'borrower_aadhar': _aadharController.text,
          'borrower_address': _addressController.text,
          'amount': double.tryParse(_amountController.text) ?? 0.0,
          'interest_rate': double.tryParse(_interestController.text) ?? 0.0,
          'duration_months': _calculateMonths(),
          'start_date': _startDate.toIso8601String(),
          'type': widget.loanType,
        },
      );
    }
  }

  int _calculateMonths() {
    int val = int.tryParse(_durationController.text) ?? 0;
    if (_durationType == 'Years') {
      return val * 12;
    }
    return val;
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
          onPressed: () => context.pop(),
        ),
        title: Text(
          getLoanTypeTitle(),
          style: TextStyle(
            color: KhaataTheme.textDark,
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: KhaataTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: KhaataTheme.primaryBlue.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        getLoanTypeIcon(),
                        color: KhaataTheme.primaryBlue,
                        size: 28.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create Agreement',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: KhaataTheme.primaryBlue,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Fill borrower details & loan terms',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: KhaataTheme.textGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              // Borrower Details Section
              _SectionTitle(title: 'Borrower Details', icon: Icons.person),
              SizedBox(height: 16.h),

              KhaataTextField(
                label: 'Full Name *',
                hint: 'Enter borrower full name',
                controller: _borrowerNameController,
                textCapitalization: TextCapitalization.words,
              ),
              SizedBox(height: 16.h),

              KhaataTextField(
                label: 'Mobile Number *',
                hint: '10 digit mobile number',
                controller: _mobileController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
              ),
              SizedBox(height: 16.h),

              KhaataTextField(
                label: 'Aadhar Number',
                hint: '12 digit Aadhar number',
                controller: _aadharController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(12),
                ],
              ),
              SizedBox(height: 16.h),

              KhaataTextField(
                label: 'Address',
                hint: 'Complete address',
                controller: _addressController,
                maxLines: 2,
              ),

              SizedBox(height: 24.h),

              // Loan Details Section
              _SectionTitle(title: 'Loan Terms', icon: Icons.description),
              SizedBox(height: 16.h),

              KhaataTextField(
                label: 'Loan Amount (₹) *',
                hint: 'Enter amount',
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
              ),
              SizedBox(height: 16.h),

              Row(
                children: [
                  Expanded(
                    child: KhaataTextField(
                      label: 'Interest Rate (%)',
                      hint: 'e.g. 12',
                      controller: _interestController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Start Date',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: KhaataTheme.textDark,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        GestureDetector(
                          onTap: () => _selectDate(context),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 16.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                                  style: TextStyle(fontSize: 14.sp),
                                ),
                                Icon(
                                  Icons.calendar_today,
                                  size: 18.sp,
                                  color: KhaataTheme.primaryBlue,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: KhaataTextField(
                      label: 'Duration',
                      hint: 'e.g. 12',
                      controller: _durationController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Period',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: KhaataTheme.textDark,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _durationType,
                              isExpanded: true,
                              items: ['Months', 'Years']
                                  .map((e) => DropdownMenuItem(
                                value: e,
                                child: Text(e, style: TextStyle(fontSize: 14.sp)),
                              ))
                                  .toList(),
                              onChanged: (val) {
                                setState(() {
                                  _durationType = val!;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 32.h),

              // Info Card
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: KhaataTheme.primaryBlue,
                      size: 20.sp,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        'An OTP will be sent to borrower\'s mobile for agreement confirmation.',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: KhaataTheme.primaryBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              PrimaryButton(
                text: 'Send Agreement',
                isLoading: _isLoading,
                onPressed: _submitForm,
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20.sp, color: KhaataTheme.primaryBlue),
        SizedBox(width: 8.w),
        Text(
          title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: KhaataTheme.textDark,
          ),
        ),
      ],
    );
  }
}