import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/blocs/loans/close_loan_flow_cubit.dart';
import '../../../../core/blocs/loans/loan_cubit.dart';
import '../../../../data/models/loan_model.dart';

import '../../../../core/utils/error_handler.dart';

class CloseLoanSheet extends StatelessWidget {
  final LoanModel loan;

  const CloseLoanSheet({super.key, required this.loan});

  static void show(BuildContext context, LoanModel loan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CloseLoanSheet(loan: loan),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          CloseLoanFlowCubit(repository: context.read(), loanId: loan.id),
      child: _CloseLoanSheetView(loan: loan),
    );
  }
}

class _CloseLoanSheetView extends StatelessWidget {
  final LoanModel loan;

  const _CloseLoanSheetView({required this.loan});

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat('#,##0', 'en_IN');
    final outstanding =
        (loan.principalOutstandingPaise +
            loan.interestOutstandingPaise +
            loan.feesOutstandingPaise) /
        100.0;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: BlocConsumer<CloseLoanFlowCubit, CloseLoanFlowState>(
          listener: (context, state) {
            if (state is CloseLoanSuccess) {
              context.read<LoanCubit>().fetchLoans();
            } else if (state is CloseLoanRejectedState) {
              ErrorHandler.showError(context, state.failure.message);
            }
          },
          builder: (context, state) {
            if (state is CloseLoanAwaitingConsent) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Close Loan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Icon(Icons.check_circle, color: Colors.green, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'Closure Intent Created',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'The request to close this loan has been sent to the borrower for final approval.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Done'),
                  ),
                ],
              );
            }

            if (state is CloseLoanSuccess) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Close Loan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Icon(Icons.check_circle, color: Colors.green, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'Loan Closed',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Done'),
                  ),
                ],
              );
            }

            final isProcessing = state is CloseLoanCreatingIntent;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Close Loan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 64,
                ),
                const SizedBox(height: 16),
                if (outstanding > 0) ...[
                  Text(
                    'Outstanding Balance: ₹${currencyFmt.format(outstanding)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Closing this loan will write off the remaining balance. The borrower must explicitly consent to this closure.',
                    textAlign: TextAlign.center,
                  ),
                ] else ...[
                  const Text(
                    'This loan is fully repaid.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Proceeding will officially mark this loan as completed.',
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: isProcessing
                      ? null
                      : () => context.read<CloseLoanFlowCubit>().createIntent(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                  ),
                  child: Text(
                    isProcessing ? 'Processing...' : 'Request Closure',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
