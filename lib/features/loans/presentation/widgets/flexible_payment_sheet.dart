import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/loan_model.dart';
import '../../../../core/blocs/loans/loan_cubit.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/error/failures.dart';

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
  int _step = 0; // 0: Amount, 1: Success
  bool _isLoading = false;
  
  final _amountCtrl = TextEditingController();
  final _currencyFmt = NumberFormat('#,##0', 'en_IN');

  @override
  void initState() {
    super.initState();
    _amountCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  double get _enteredAmount => double.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0;

  double get _currentBalance => widget.loan.remainingAmount;

  double get _newBalance {
    if (widget.actionType == 'add_credit') {
      return _currentBalance + _enteredAmount;
    }
    return (_currentBalance - _enteredAmount).clamp(0, double.infinity);
  }

  double get _totalReceived {
    if (widget.actionType == 'add_credit') return 0;
    return widget.loan.paidAmount + _enteredAmount;
  }

  Future<void> _processPayment() async {
    if (_enteredAmount <= 0) return;
    
    setState(() => _isLoading = true);

    final cubit = context.read<LoanCubit>();
    bool success = false;

    try {
      if (widget.actionType == 'record_payment') {
        success = await cubit.recordPayment(widget.loan.id, (_enteredAmount * 100).toInt());
      } else if (widget.actionType == 'add_credit') {
        success = await cubit.addCredit(widget.loan.id, (_enteredAmount * 100).toInt());
      } else if (widget.actionType == 'record_interest') {
        success = await cubit.recordInterest(widget.loan.id, (_enteredAmount * 100).toInt());
      }

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        setState(() => _step = 1);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      
      // F.3 Financial UX Alignment: Differentiate error states
      String errorMsg = 'An unexpected error occurred.';
      if (e is ServerFailure) {
        // Distinguish Kill Switch / 503
        if (e.message.contains('temporarily suspended') || e.message.contains('503')) {
          errorMsg = 'Service Paused: Financial operations are temporarily suspended. Your funds are safe.';
        } else {
          errorMsg = 'Server Error: ${e.message}';
        }
      } else if (e is ValidationFailure) {
        errorMsg = 'Validation Error: ${e.message}';
      } else if (e is AuthFailure) {
        errorMsg = 'Authentication Error: Please log in again.';
      } else if (e is NetworkFailure) {
        errorMsg = 'Network Error: Please check your internet connection.';
      } else {
        errorMsg = e.toString();
      }

      ErrorHandler.showError(context, errorMsg);
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
                          '₹${_currencyFmt.format(isAddCredit ? _currentBalance : widget.loan.paidAmount)}',
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
          onPressed: (_enteredAmount > 0 && !_isLoading) ? _processPayment : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 14.h),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            elevation: 0,
          ),
          child: _isLoading 
              ? SizedBox(width: 20.w, height: 20.w, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text('Record Transaction', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
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
          child: _step == 0 ? _buildAmountStep() : _buildSuccessStep(),
        ),
      ),
    );
  }
}

