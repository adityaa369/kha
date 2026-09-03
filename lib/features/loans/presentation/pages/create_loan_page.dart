import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../config/theme.dart';
import '../../../../core/widgets/inputs.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/blocs/loans/loan_cubit.dart';
import '../../../../core/blocs/loans/loan_state.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/services/biometric_auth_service.dart';
import 'package:firebase_storage/firebase_storage.dart';

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
  final _notesController = TextEditingController();
  final _shopNameController = TextEditingController();

  DateTime _startDate = DateTime.now();
  DateTime? _dueDate;
  final String _durationType = 'Months';
  String? _selectedDocumentName;
  File? _selectedDocumentFile;
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
    _notesController.dispose();
    _shopNameController.dispose();
    super.dispose();
  }

  Future<void> _pickDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png', 'jpeg'],
    );

    if (result != null) {
      setState(() {
        _selectedDocumentFile = File(result.files.single.path!);
        _selectedDocumentName = result.files.single.name;
      });
    }
  }

  String getLoanTypeTitle() {
    switch (widget.loanType) {
      case 'hand_credit':
        return 'Add Hand Credit';
      case 'business_credit':
        return 'Add Business Credit';
      case 'interest_credit':
        return 'Interest Credit';
      case 'chitfund':
        return 'Chit Funds';
      default:
        return 'New Loan';
    }
  }

  Future<void> _selectDate(BuildContext context, {required bool isDue}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isDue
          ? (_dueDate ?? DateTime.now().add(const Duration(days: 30)))
          : _startDate,
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
    if (picked != null) {
      setState(() {
        if (isDue) {
          _dueDate = picked;
        } else {
          _startDate = picked;
        }
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
    final rate = widget.loanType == 'interest_credit'
        ? (double.tryParse(_interestController.text) ?? 0.0)
        : 0.0;
    final months = _calculateMonths();

    final totalInterest = widget.loanType == 'interest_credit'
        ? (amount * rate * months) / 100
        : 0.0;
    final totalAmount = amount + totalInterest;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Loan Summary',
          style: TextStyle(
            color: KhaataTheme.primaryBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
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
            Text(
              'Total Repayment: ₹${totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: KhaataTheme.primaryBlue,
            ),
            onPressed: () {
              context.pop();
              _processLoanCreation();
            },
            child: const Text(
              'Confirm & Send',
              style: TextStyle(color: Colors.white),
            ),
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
            content: Text(
              'Biometric signature required to create agreement.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    final phone = _mobileController.text;
    final cubit = context.read<LoanCubit>();

    final borrower = await cubit.checkBorrower(phone);

    if (borrower == null) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      _showBorrowerNotFoundDialog();
      return;
    }

    if (_selectedDocumentFile != null) {
      try {
        final ref = FirebaseStorage.instance
            .ref()
            .child('documents')
            .child(
              '${DateTime.now().millisecondsSinceEpoch}_${_selectedDocumentName ?? 'doc'}',
            );
        final uploadTask = ref.putFile(_selectedDocumentFile!);
        final snapshot = await uploadTask;
        final documentId = snapshot.ref.fullPath;
        _finalizeLoanCreation(phone, documentId);
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          _showUploadFailedDialog(phone, 'Failed to upload document: $e');
        }
      }
    } else {
      _finalizeLoanCreation(phone, null);
    }
  }

  void _showUploadFailedDialog(String phone, String errorMessage) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.amber),
            SizedBox(width: 8),
            Text('Upload Failed'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(errorMessage),
            const SizedBox(height: 16),
            const Text(
              'Do you want to proceed with creating this agreement without the attached document?',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: KhaataTheme.primaryBlue,
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              _finalizeLoanCreation(phone, null);
            },
            child: const Text(
              'Proceed Without Document',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _finalizeLoanCreation(String phone, String? documentId) async {
    setState(() => _isLoading = true);
    final cubit = context.read<LoanCubit>();
    final idempotencyKey = const Uuid().v4();

    final loanData = {
      'idempotency_key': idempotencyKey,
      'borrower_phone': phone,
      'borrower_name': _borrowerNameController.text,
      'borrower_aadhar': _aadharController.text,
      'borrower_address': _addressController.text,
      'amount': double.tryParse(_amountController.text) ?? 0.0,
      'interest_rate': widget.loanType == 'interest_credit'
          ? (double.tryParse(_interestController.text) ?? 0.0)
          : 0.0,
      'duration_months': _calculateMonths(),
      'duration_type': _durationType,
      'start_date': _startDate.toIso8601String(),
      'due_date': _dueDate?.toIso8601String(),
      'notes': _notesController.text,
      'shop_name': _shopNameController.text,
      'type': widget.loanType,
      'documentId': documentId,
    };

    final result = await cubit.createLoan(loanData);

    setState(() => _isLoading = false);

    if (result != null && mounted) {
      context.pushReplacement(
        '/loan-confirmation',
        extra: {
          'loan_id': result['id'],
          'borrower_name': _borrowerNameController.text,
          'borrower_phone': phone,
          'amount': double.tryParse(_amountController.text) ?? 0.0,
        },
      );
    } else if (mounted) {
      final state = cubit.state;
      if (state is LoanError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              state.message,
              style: const TextStyle(color: Colors.white),
            ),
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
        content: const Text(
          'This phone number is not registered on Khaata. Please ask the borrower to register first.',
        ),
        actions: [
          TextButton(onPressed: () => context.pop(), child: const Text('OK')),
        ],
      ),
    );
  }

  int _calculateMonths() {
    if (_dueDate != null) {
      return (_dueDate!.difference(_startDate).inDays / 30).round();
    }
    int val = int.tryParse(_durationController.text) ?? 1;
    if (_durationType == 'Years') {
      return val * 12;
    }
    return val;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: Column(
          children: [
            Text(
              getLoanTypeTitle(),
              style: TextStyle(
                color: Colors.black87,
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (widget.loanType == 'hand_credit' ||
                widget.loanType == 'interest_credit')
              Text(
                widget.loanType == 'interest_credit'
                    ? 'Credit interest to borrower'
                    : 'You are lending money',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w400,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              widget.loanType == 'business_credit'
                  ? Icons.help_outline
                  : Icons.info_outline,
              color: Colors.green.shade700,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.loanType == 'business_credit')
                _buildBusinessCreditLayout()
              else if (widget.loanType == 'interest_credit')
                _buildInterestCreditLayout()
              else
                _buildHandCreditLayout(),

              SizedBox(height: 24.h),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  onPressed: _isLoading ? null : _submitForm,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              widget.loanType == 'business_credit'
                                  ? Icons.save
                                  : Icons.description,
                              color: Colors.white,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'Save Agreement',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              SizedBox(height: 32.h), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInterestCreditLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card 1: Borrower Details
        _FormCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _NumberedHeader(
                number: 1,
                title: 'Borrower Details',
                trailing: Icon(
                  Icons.person_outline,
                  color: Colors.green.shade700,
                  size: 24.sp,
                ),
              ),
              SizedBox(height: 16.h),
              KhaataTextField(
                label: 'Full Name',
                hint: 'Enter full name',
                controller: _borrowerNameController,
                prefixIcon: const Icon(Icons.person_outline),
                textCapitalization: TextCapitalization.words,
                validator: (val) => val == null || val.trim().length < 3 ? 'Name is required (min 3 chars)' : null,
              ),
              SizedBox(height: 16.h),
              KhaataTextField(
                label: 'Mobile Number',
                hint: 'Enter mobile number',
                controller: _mobileController,
                prefixIcon: const Icon(Icons.phone_outlined),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: (val) => val == null || val.length != 10 ? 'Enter valid 10-digit number' : null,
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),

        // Card 2: Interest Details
        _FormCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _NumberedHeader(
                number: 2,
                title: 'Interest Details',
              ),
              SizedBox(height: 16.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: KhaataTextField(
                      label: 'Interest Amount',
                      hint: 'Enter amount',
                      controller: _amountController,
                      prefixIcon: Container(
                        margin: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Icon(
                          Icons.currency_rupee,
                          color: Colors.green.shade700,
                          size: 18.sp,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (val) => val == null || val.isEmpty || (double.tryParse(val) ?? 0) <= 0 ? 'Enter a valid amount' : null,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: KhaataTextField(
                      label: 'Rate of Interest',
                      hint: 'Enter rate',
                      controller: _interestController,
                      prefixIcon: Container(
                        margin: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Icon(
                          Icons.percent,
                          color: Colors.green.shade700,
                          size: 18.sp,
                        ),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Required';
                        final r = double.tryParse(val);
                        if (r == null || r <= 0 || r > 100) return 'Enter 0-100%';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: _DateSelector(
                      label: 'Start Date',
                      date: _startDate,
                      onTap: () => _selectDate(context, isDue: false),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: _DateSelector(
                      label: 'End Date',
                      date: _dueDate,
                      hint: 'Select end date',
                      onTap: () => _selectDate(context, isDue: true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),

        // Card 3: Upload
        _FormCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _NumberedHeader(
                number: 3,
                title: 'Upload (Optional)',
                trailing: Icon(
                  Icons.attach_file,
                  color: Colors.green.shade700,
                  size: 24.sp,
                ),
              ),
              SizedBox(height: 16.h),
              _DashedUploadBox(
                fileName: _selectedDocumentName,
                onTap: _pickDocument,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHandCreditLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card 1: Borrower Details
        _FormCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _NumberedHeader(number: 1, title: 'Borrower Details'),
              SizedBox(height: 16.h),
              KhaataTextField(
                label: 'Full Name',
                hint: 'Enter full name',
                controller: _borrowerNameController,
                prefixIcon: const Icon(Icons.person_outline),
                textCapitalization: TextCapitalization.words,
                validator: (val) => val == null || val.trim().length < 3 ? 'Name is required (min 3 chars)' : null,
              ),
              SizedBox(height: 16.h),
              KhaataTextField(
                label: 'Mobile Number',
                hint: 'Enter mobile number',
                controller: _mobileController,
                prefixIcon: const Icon(Icons.phone_outlined),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: (val) => val == null || val.length != 10 ? 'Enter valid 10-digit number' : null,
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),

        // Card 2: Loan Details
        _FormCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _NumberedHeader(number: 2, title: 'Loan Details'),
              SizedBox(height: 16.h),
              KhaataTextField(
                label: 'Loan Amount',
                hint: 'Enter loan amount',
                controller: _amountController,
                prefixIcon: const Icon(Icons.currency_rupee),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (val) => val == null || val.isEmpty || (double.tryParse(val) ?? 0) <= 0 ? 'Enter a valid amount' : null,
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: _DateSelector(
                      label: 'Start Date',
                      date: _startDate,
                      onTap: () => _selectDate(context, isDue: false),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: _DateSelector(
                      label: 'Due Date',
                      date: _dueDate,
                      hint: 'Select due date',
                      onTap: () => _selectDate(context, isDue: true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),

        // Card 3: Additional
        _FormCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _NumberedHeader(number: 3, title: 'Additional (Optional)'),
              SizedBox(height: 16.h),
              Text(
                'Add Proof (Optional)',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              SizedBox(height: 8.h),
              _DashedUploadBox(
                fileName: _selectedDocumentName,
                onTap: _pickDocument,
              ),
              SizedBox(height: 16.h),
              KhaataTextField(
                label: 'Notes (Optional)',
                hint: 'Add any notes (optional)',
                controller: _notesController,
                prefixIcon: const Icon(Icons.sticky_note_2_outlined),
                maxLines: 3,
                maxLength: 200,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBusinessCreditLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Banner
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.green.shade100),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(Icons.storefront, color: Colors.green.shade700),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Business Credit',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Add credit given to your customer for goods/services.',
                      style: TextStyle(fontSize: 13.sp, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),

        // Card 1: Customer Details
        _FormCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customer Details',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 16.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: KhaataTextField(
                      label: 'Customer Name *',
                      hint: 'Enter customer name',
                      controller: _borrowerNameController,
                      prefixIcon: const Icon(Icons.person_outline),
                      validator: (val) => val == null || val.trim().length < 3 ? 'Name is required (min 3 chars)' : null,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: KhaataTextField(
                      label: 'Mobile Number',
                      hint: 'Enter mobile number',
                      controller: _mobileController,
                      prefixIcon: const Icon(Icons.phone_outlined),
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      validator: (val) => val == null || val.length != 10 ? 'Enter valid 10-digit number' : null,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              KhaataTextField(
                label: 'Business/Shop Name (Optional)',
                hint: 'Enter business or shop name',
                controller: _shopNameController,
                prefixIcon: const Icon(Icons.storefront_outlined),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),

        // Card 2: Credit Details
        _FormCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Credit Details',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 16.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: KhaataTextField(
                      label: 'Bill Amount *',
                      hint: 'Enter bill amount',
                      controller: _amountController,
                      prefixIcon: const Icon(Icons.currency_rupee),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (val) => val == null || val.isEmpty || (double.tryParse(val) ?? 0) <= 0 ? 'Enter a valid amount' : null,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: _DateSelector(
                      label: 'Date *',
                      date: _startDate,
                      onTap: () => _selectDate(context, isDue: false),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              _DateSelector(
                label: 'Due Date (Optional)',
                date: _dueDate,
                hint: 'Select due date',
                onTap: () => _selectDate(context, isDue: true),
                icon: Icons.calendar_today_outlined,
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),

        // Card 3: Attachments
        _FormCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Attachments (Optional)',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 16.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        Icons.image_outlined,
                        color: Colors.green.shade700,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedDocumentName ?? 'Upload Bill / Photo',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13.sp,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (_selectedDocumentName == null)
                            Text(
                              'JPG, PNG up to 5MB',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 11.sp,
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Flexible(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.green.shade600),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 8.h,
                          ),
                        ),
                        onPressed: _pickDocument,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _selectedDocumentName == null
                                ? 'Choose from Gallery'
                                : 'Change',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ----------------------
// Reusable UI Components
// ----------------------

class _FormCard extends StatelessWidget {
  final Widget child;
  const _FormCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _NumberedHeader extends StatelessWidget {
  final int number;
  final String title;
  final Widget? trailing;

  const _NumberedHeader({
    required this.number,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24.w,
          height: 24.w,
          decoration: BoxDecoration(
            color: Colors.green.shade700,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number.toString(),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12.sp,
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ),
        if (trailing != null) ...[SizedBox(width: 8.w), trailing!],
      ],
    );
  }
}

class _DateSelector extends StatelessWidget {
  final String label;
  final DateTime? date;
  final String? hint;
  final VoidCallback onTap;
  final IconData icon;

  const _DateSelector({
    required this.label,
    required this.date,
    required this.onTap,
    this.hint,
    this.icon = Icons.calendar_today_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyLarge),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: 14.h,
            ), // Matched TextField height
            decoration: BoxDecoration(
              color: Colors
                  .white, // In designs, it looks outlined, wait... textfields are outlined?
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18.sp, color: Colors.grey.shade600),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    date != null
                        ? '${date!.day} ${_getMonthAbbr(date!.month)} ${date!.year}'
                        : (hint ?? ''),
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: date != null
                          ? Colors.black87
                          : Colors.grey.shade500,
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 20.sp,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getMonthAbbr(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}

class _DashedUploadBox extends StatelessWidget {
  final String? fileName;
  final VoidCallback onTap;

  const _DashedUploadBox({required this.fileName, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          // Custom dashed border can be complex without extra package. We'll use a normal light grey border.
          // Wait, the design has a dashed border. We can use a package if available, or just use a soft border.
          border: Border.all(
            color: Colors.grey.shade300,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Icon(
                    Icons.image_outlined,
                    color: Colors.green.shade700,
                    size: 24.sp,
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add_circle,
                      color: Colors.green.shade700,
                      size: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName ?? 'Upload image',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (fileName == null)
                    Text(
                      'Tap to choose from gallery',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey.shade500,
                      ),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}


