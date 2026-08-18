import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/loan_model.dart';
import '../../../../core/blocs/loans/loan_cubit.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/utils/dialog_utils.dart';
class FlexiblePaymentSheet extends StatefulWidget {
  final LoanModel loan;
  final String title;
  final String actionType;

  const FlexiblePaymentSheet({
    super.key,
    required this.loan,
    required this.title,
    required this.actionType,
  });

  static void show(BuildContext context, LoanModel loan, String title, String actionType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FlexiblePaymentSheet(loan: loan, title: title, actionType: actionType),
    );
  }

  @override
  State<FlexiblePaymentSheet> createState() => _FlexiblePaymentSheetState();
}

class _FlexiblePaymentSheetState extends State<FlexiblePaymentSheet> {
  int _step = 0; // 0: Amount, 1: OTP, 2: Success
  bool _isLoading = false;
  String _verificationId = '';
  
  final _amountCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  final _currencyFmt = NumberFormat('#,##0', 'en_IN');

  @override
  void initState() {
    super.initState();
    _amountCtrl.addListener(() => setState(() {}));
    _otpCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  double get _enteredAmount => double.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0;

  double get _currentBalance => widget.loan.totalPayable ?? widget.loan.amount;

  double get _newBalance {
    if (widget.actionType == 'add_credit') {
      return _currentBalance + _enteredAmount;
    }
    return (_currentBalance - _enteredAmount).clamp(0, double.infinity);
  }

  double get _totalReceived {
    if (widget.actionType == 'add_credit') return 0;
    final originalAmount = widget.loan.amount;
    final totalReceivedSoFar = (originalAmount - _currentBalance).clamp(0, double.infinity);
    return totalReceivedSoFar + _enteredAmount;
  }

  void _requestOtp() {
    if (_enteredAmount <= 0) return;
    
    setState(() => _isLoading = true);
    
    final phone = widget.loan.mobile ?? '';
    final formatted = phone.startsWith('+') ? phone : '+91$phone';

    FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: formatted,
      verificationCompleted: (_) {},
      verificationFailed: (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        DialogUtils.showErrorDialog(context, 'OTP failed: ${e.message}');
      },
      codeSent: (String vId, int? _) {
        if (!mounted) return;
        setState(() {
          _verificationId = vId;
          _isLoading = false;
          _step = 1;
        });
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<void> _verifyOtp() async {
    final otp = _otpCtrl.text.trim();
    if (otp.length != 6) return;

    setState(() => _isLoading = true);

    final cubit = context.read<LoanCubit>();
    bool success = false;

    if (widget.actionType == 'record_payment') {
      success = await cubit.recordPayment(widget.loan.id, _enteredAmount, otp, _verificationId);
    } else if (widget.actionType == 'add_credit') {
      success = await cubit.addCredit(widget.loan.id, _enteredAmount, otp, _verificationId);
    } else if (widget.actionType == 'record_interest') {
      success = await cubit.recordInterest(widget.loan.id, _enteredAmount, otp, _verificationId);
    }

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      setState(() => _step = 2);
    } else {
      ErrorHandler.showError(context, 'Transaction failed. Invalid OTP.');
    }
  }

  Widget _buildAmountStep() {
    final isAddCredit = widget.actionType == 'add_credit';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(widget.title, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Text('Enter Amount', style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
        SizedBox(height: 8.h),
        TextField(
          controller: _amountCtrl,
          keyboardType: TextInputType.number,
          style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            prefixText: '₹ ',
            prefixStyle: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: Colors.black87),
            hintText: '0',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: Colors.grey.shade300)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        SizedBox(height: 16.h),
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('After this transaction', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: Colors.black87)),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(isAddCredit ? 'Current Balance' : 'Total Received', style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600)),
                        SizedBox(height: 4.h),
                        Text(
                          '₹${_currencyFmt.format(isAddCredit ? _currentBalance : _totalReceived)}',
                          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 40.h, color: Colors.green.shade200),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(isAddCredit ? 'New Balance' : 'Remaining Amount', style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600)),
                        SizedBox(height: 4.h),
                        Text(
                          '₹${_currencyFmt.format(_newBalance)}',
                          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.orange.shade700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 24.h),
        ElevatedButton(
          onPressed: (_enteredAmount > 0 && !_isLoading) ? _requestOtp : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 14.h),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            elevation: 0,
          ),
          child: _isLoading 
              ? SizedBox(width: 20.w, height: 20.w, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text('Request OTP Confirmation', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
        ),
        SizedBox(height: 8.h),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
        ),
      ],
    );
  }

  Widget _buildOtpStep() {
    final borrowerName = widget.loan.borrowerName.isNotEmpty ? widget.loan.borrowerName : 'Borrower';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('OTP Sent to Borrower', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        Center(
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
            child: Icon(Icons.mobile_friendly, color: Colors.green.shade700, size: 40.sp),
          ),
        ),
        SizedBox(height: 16.h),
        Center(
          child: Text('OTP has been sent to $borrowerName', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.black87)),
        ),
        SizedBox(height: 4.h),
        Center(
          child: Text('Ask the borrower to share the OTP with you.', style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600)),
        ),
        SizedBox(height: 24.h),
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Enter OTP', style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
              SizedBox(height: 12.h),
              TextField(
                controller: _otpCtrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24.sp, letterSpacing: 16.w, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: Colors.grey.shade300)),
                ),
                onChanged: (val) {
                  if (val.length == 6) {
                    FocusScope.of(context).unfocus();
                  }
                },
              ),
            ],
          ),
        ),
        SizedBox(height: 24.h),
        ElevatedButton(
          onPressed: (_otpCtrl.text.length == 6 && !_isLoading) ? _verifyOtp : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 14.h),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            elevation: 0,
          ),
          child: _isLoading 
              ? SizedBox(width: 20.w, height: 20.w, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text('Verify OTP', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
        ),
        SizedBox(height: 8.h),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
        ),
      ],
    );
  }

  Widget _buildSuccessStep() {
    final isAddCredit = widget.actionType == 'add_credit';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 24.h),
        Center(
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.green.shade700, width: 2),
            ),
            child: Icon(Icons.check, color: Colors.green.shade700, size: 40.sp),
          ),
        ),
        SizedBox(height: 16.h),
        Center(
          child: Text('Transaction Recorded Successfully!', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.black87)),
        ),
        SizedBox(height: 4.h),
        Center(
          child: Text('₹${_currencyFmt.format(_enteredAmount)} has been recorded.', style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade600)),
        ),
        SizedBox(height: 24.h),
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(isAddCredit ? 'Current Balance' : 'Total Received', style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600)),
                        SizedBox(height: 4.h),
                        Text(
                          '₹${_currencyFmt.format(isAddCredit ? _currentBalance : _totalReceived)}',
                          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(isAddCredit ? 'New Balance' : 'Remaining Amount', style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600)),
                        SizedBox(height: 4.h),
                        Text(
                          '₹${_currencyFmt.format(_newBalance)}',
                          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.orange.shade700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Text('Status', style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600)),
              SizedBox(height: 4.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text('On Track', style: TextStyle(color: Colors.green.shade800, fontSize: 12.sp, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        SizedBox(height: 24.h),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 14.h),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            elevation: 0,
          ),
          child: Text('Done', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
        ),
        SizedBox(height: 16.h),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 16.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _step == 0 
              ? _buildAmountStep() 
              : (_step == 1 ? _buildOtpStep() : _buildSuccessStep()),
        ),
      ),
    );
  }
}
