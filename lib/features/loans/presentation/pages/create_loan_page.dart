import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/inputs.dart';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/blocs/loans/loan_cubit.dart';
import '../../../../core/blocs/loans/loan_state.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/services/biometric_auth_service.dart';

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
  String? _selectedDocumentName;
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
      case 'hand_credit':
        return 'Hand Credit';
      case 'business_credit':
        return 'Business Credit';
      case 'interest_credit':
        return 'Interest Credit';
      case 'chitfund':
        return 'Chit Funds';
      default:
        return 'New Loan';
    }
  }

  IconData getLoanTypeIcon() {
    switch (widget.loanType) {
      case 'hand_credit':
        return Icons.account_balance_wallet;
      case 'business_credit':
        return Icons.business_center;
      case 'interest_credit':
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
            colorScheme: const ColorScheme.light(
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

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      _showPreviewDialog();
    }
  }

  void _showPreviewDialog() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final rate = widget.loanType == 'interest_credit' ? (double.tryParse(_interestController.text) ?? 0.0) : 0.0;
    final months = _calculateMonths();
    
    // Calculate simple interest assuming rate is Annual (APR)
    final totalInterest = widget.loanType == 'interest_credit' ? (amount * rate * (months / 12)) / 100 : 0.0;
    final totalAmount = amount + totalInterest;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Loan Summary', style: TextStyle(color: KhaataTheme.primaryBlue, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Borrower: ${_borrowerNameController.text}'),
            SizedBox(height: 8.h),
            Text('Principal: ₹${amount.toStringAsFixed(2)}'),
            if (widget.loanType == 'interest_credit') ...[
              SizedBox(height: 8.h),
              Text('Interest Rate: $rate% (Annual)'),
              SizedBox(height: 8.h),
              Text('Total Interest: ₹${totalInterest.toStringAsFixed(2)}'),
            ],
            SizedBox(height: 8.h),
            Text('Duration: $months Months'),
            Divider(height: 24.h),
            Text('Total Repayment: ₹${totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('EMI: ₹${(totalAmount / (months > 0 ? months : 1)).toStringAsFixed(2)}/month', style: TextStyle(color: KhaataTheme.textGrey, fontSize: 12.sp)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: KhaataTheme.primaryBlue),
            onPressed: () {
              context.pop();
              _processLoanCreation();
            },
            child: const Text('Confirm & Send', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _processLoanCreation() async {
    final authenticated = await BiometricAuthService.authenticate();
    if (!authenticated) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometric signature required to create agreement.', style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    final phone = _mobileController.text;
    final cubit = context.read<LoanCubit>();

    // 1. Check if borrower exists
    final borrower = await cubit.checkBorrower(phone);

    if (borrower == null) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      _showBorrowerNotFoundDialog();
      return;
    }

    // 2. Create Loan (Sends OTP to borrower)
    final idempotencyKey = const Uuid().v4();
    
    final loanData = {
      'idempotency_key': idempotencyKey,
      'borrower_phone': phone,
      'borrower_name': _borrowerNameController.text,
      'borrower_aadhar': _aadharController.text,
      'borrower_address': _addressController.text,
      'amount': double.tryParse(_amountController.text) ?? 0.0,
      'interest_rate': widget.loanType == 'interest_credit' ? (double.tryParse(_interestController.text) ?? 0.0) : 0.0,
      'duration_months': _calculateMonths(),
      'start_date': _startDate.toIso8601String(),
      'type': widget.loanType,
    };

    final result = await cubit.createLoan(loanData);
    
    setState(() => _isLoading = false);

    if (result != null && mounted) {
      // Show Success and Navigate Back
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Loan agreement sent to borrower for approval.', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
    } else if (mounted) {
      // Show error if failed
      final state = cubit.state;
      if (state is LoanError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.message, style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showBorrowerNotFoundDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('User Not Found'),
        content: const Text('This phone number is not registered on Khaata. Please ask the borrower to register first.'),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
          icon: const Icon(Icons.arrow_back, color: KhaataTheme.textDark),
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
              const _SectionTitle(title: 'Borrower Details', icon: Icons.person),
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
              const _SectionTitle(title: 'Loan Terms', icon: Icons.description),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.loanType == 'interest_credit') ...[
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
                  ],
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
                  SizedBox(
                    width: 110.w,
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
                        'The borrower will receive a notification to verify and approve this agreement.',
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

              // Document Upload UI
              const _SectionTitle(title: 'Supporting Documents', icon: Icons.attach_file),
              SizedBox(height: 16.h),
              GestureDetector(
                onTap: () {
                  // TODO: Implement actual file picker hook
                  setState(() {
                    _selectedDocumentName = 'agreement_scan.pdf';
                  });
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: _selectedDocumentName != null ? KhaataTheme.accentGreen : KhaataTheme.primaryBlue,
                      style: BorderStyle.solid,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _selectedDocumentName != null ? Icons.check_circle : Icons.cloud_upload_outlined,
                        color: _selectedDocumentName != null ? KhaataTheme.accentGreen : KhaataTheme.primaryBlue,
                        size: 32.sp,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        _selectedDocumentName ?? 'Tap to Upload Agreement/Proof',
                        style: TextStyle(
                          color: _selectedDocumentName != null ? KhaataTheme.accentGreen : KhaataTheme.textDark,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_selectedDocumentName == null) ...[
                        SizedBox(height: 4.h),
                        Text(
                          'PDF, JPG, PNG (Max 5MB)',
                          style: TextStyle(
                            color: KhaataTheme.textGrey,
                            fontSize: 12.sp,
                          ),
                        ),
                      ] else ...[
                        SizedBox(height: 8.h),
                        GestureDetector(
                          onTap: () => setState(() => _selectedDocumentName = null),
                          child: Text('Remove File', style: TextStyle(color: Colors.red, fontSize: 13.sp, fontWeight: FontWeight.normal)),
                        )
                      ]
                    ],
                  ),
                ),
              ),

              SizedBox(height: 32.h),

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