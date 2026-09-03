import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:intl/intl.dart';

import '../../../../data/models/loan_model.dart';
import '../../../../core/blocs/loans/loan_cubit.dart';
import '../../../../core/blocs/loans/payment_flow_cubit.dart';
import '../../../../core/blocs/loans/add_credit_flow_cubit.dart';
import '../../../../data/repositories/loan_repository.dart' as khatha;
import '../../../../core/utils/error_handler.dart';

class FlexiblePaymentSheet extends StatelessWidget {
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
      builder: (_) {
        if (actionType == 'add_credit') {
          return BlocProvider(
            create: (ctx) => AddCreditFlowCubit(
              repository: ctx.read<khatha.LoanRepository>(),
              loanId: loan.id,
            ),
            child: FlexiblePaymentSheet(loan: loan, title: title, actionType: actionType),
          );
        } else {
          return BlocProvider(
            create: (ctx) => PaymentFlowCubit(
              repository: ctx.read<khatha.LoanRepository>(),
              loanId: loan.id,
            ),
            child: FlexiblePaymentSheet(loan: loan, title: title, actionType: actionType),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _FlexiblePaymentSheetView(loan: loan, title: title, actionType: actionType);
  }
}

class _FlexiblePaymentSheetView extends StatefulWidget {
  final LoanModel loan;
  final String title;
  final String actionType;

  const _FlexiblePaymentSheetView({
    required this.loan,
    required this.title,
    required this.actionType,
  });

  @override
  State<_FlexiblePaymentSheetView> createState() => _FlexiblePaymentSheetViewState();
}

class _FlexiblePaymentSheetViewState extends State<_FlexiblePaymentSheetView> {
  final _amountCtrl = TextEditingController();
  final _currencyFmt = NumberFormat('#,##0', 'en_IN');

  @override
  void initState() {
    super.initState();
    _amountCtrl.addListener(() => setState(() {}));
  }

  double get _enteredAmount => double.tryParse(_amountCtrl.text) ?? 0;
  
  double get _newBalance {
    final currentBalance = (widget.loan.principalOutstandingPaise + 
                           widget.loan.interestOutstandingPaise + 
                           widget.loan.feesOutstandingPaise) / 100.0;
    if (widget.actionType == 'add_credit') {
      return currentBalance + _enteredAmount;
    }
    return (currentBalance - _enteredAmount).clamp(0.0, double.infinity);
  }

  void _processPayment() {
    if (_enteredAmount <= 0) return;
    
    if (widget.actionType == 'add_credit') {
      context.read<AddCreditFlowCubit>().createIntent(_enteredAmount);
    } else {
      context.read<PaymentFlowCubit>().submitPayment(_enteredAmount);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.actionType == 'add_credit') {
      return _buildAddCreditConsumer();
    }
    return _buildPaymentConsumer();
  }

  Widget _buildAddCreditConsumer() {
    return BlocConsumer<AddCreditFlowCubit, AddCreditFlowState>(
      listener: (context, state) {
        if (state is AddCreditSuccess) {
           context.read<LoanCubit>().fetchLoans();
        } else if (state is AddCreditRejectedState) {
           ErrorHandler.showError(context, state.failure.message);
        }
      },
      builder: (context, state) {
        return _buildSheetLayout(
          isProcessing: state is AddCreditCreatingIntent || state is AddCreditCommitting,
          isSuccess: state is AddCreditAwaitingConsent, // For lender, intent creation success
          isUnknown: false,
          successMessage: 'Add Credit intent sent to borrower for approval.',
          onAction: _processPayment,
          isActionDisabled: state is AddCreditCreatingIntent || _enteredAmount <= 0,
        );
      },
    );
  }

  Widget _buildPaymentConsumer() {
    return BlocConsumer<PaymentFlowCubit, PaymentFlowState>(
      listener: (context, state) {
        if (state is PaymentSuccess) {
           context.read<LoanCubit>().fetchLoans();
        } else if (state is PaymentRejected) {
           ErrorHandler.showError(context, state.failure.message);
        }
      },
      builder: (context, state) {
        return _buildSheetLayout(
          isProcessing: state is PaymentSubmitting || state is PaymentReconciling,
          isSuccess: state is PaymentSuccess,
          isUnknown: state is PaymentUnknown,
          successMessage: 'Payment Recorded Successfully',
          onAction: _processPayment,
          isActionDisabled: state is PaymentSubmitting || state is PaymentReconciling || _enteredAmount <= 0,
          onReconcile: state is PaymentUnknown ? () => context.read<PaymentFlowCubit>().reconcile(state.attempt) : null,
        );
      },
    );
  }

  Widget _buildSheetLayout({
    required bool isProcessing,
    required bool isSuccess,
    required bool isUnknown,
    required String successMessage,
    required VoidCallback onAction,
    required bool isActionDisabled,
    VoidCallback? onReconcile,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 24),
            if (isSuccess) ...[
              const Icon(Icons.check_circle, color: Colors.green, size: 64),
              const SizedBox(height: 16),
              Text(successMessage, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              )
            ] else if (isUnknown) ...[
              const Icon(Icons.hourglass_empty, color: Colors.orange, size: 64),
              const SizedBox(height: 16),
              const Text('Payment Processing...', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('We are checking the status of your transaction with the server.', textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onReconcile,
                child: const Text('Refresh Status'),
              )
            ] else ...[
              TextField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount (₹)',
                  prefixText: '₹ ',
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Remaining Balance:'),
                  Text('₹ ${_currencyFmt.format(_newBalance)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: isActionDisabled ? null : onAction,
                child: Text(isProcessing ? 'Processing...' : 'Submit ₹${_currencyFmt.format(_enteredAmount)}'),
              )
            ],
          ],
        ),
      ),
    );
  }
}
