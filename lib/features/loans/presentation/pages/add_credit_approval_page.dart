import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/blocs/loans/add_credit_flow_cubit.dart';
import '../../../../data/repositories/loan_repository.dart';
import '../../../../config/theme.dart';
import '../../../../core/utils/error_handler.dart';

class AddCreditApprovalPage extends StatelessWidget {
  final String loanId;
  final String intentId;
  final double amountRupees;

  const AddCreditApprovalPage({
    super.key,
    required this.loanId,
    required this.intentId,
    required this.amountRupees,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AddCreditFlowCubit(
        repository: context.read<LoanRepository>(),
        loanId: loanId,
        initialIntentId: intentId,
        initialAmountRupees: amountRupees,
      ),
      child: const _AddCreditApprovalView(),
    );
  }
}

class _AddCreditApprovalView extends StatelessWidget {
  const _AddCreditApprovalView();

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat('#,##0', 'en_IN');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Credit Request'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
             // Let user close without explicitly rejecting if they want to decide later
             if (GoRouter.of(context).canPop()) {
               context.pop();
             } else {
               context.go('/home');
             }
          },
        ),
      ),
      body: BlocConsumer<AddCreditFlowCubit, AddCreditFlowState>(
        listener: (context, state) {
          if (state is AddCreditSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Request processed successfully.'), backgroundColor: Colors.green),
            );
            Future.delayed(const Duration(seconds: 1), () {
              if (GoRouter.of(context).canPop()) {
                context.pop(true);
              } else {
                context.go('/home'); // Fallback route
              }
            });
          } else if (state is AddCreditRejectedState) {
            ErrorHandler.showError(context, state.failure.message);
          }
        },
        builder: (context, state) {
          if (state is AddCreditAuthorizing || state is AddCreditCommitting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Processing your decision...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }
          
          if (state is AddCreditSuccess) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 64),
                  SizedBox(height: 16),
                  Text('Done', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }
          
          if (state is AddCreditAwaitingConsent) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.info_outline, color: KhaataTheme.primaryBlue, size: 48),
                  const SizedBox(height: 24),
                  const Text(
                    'Additional Credit Requested',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 32),
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildRow('Amount:', '₹ ${currencyFmt.format(state.amountRupees)}', true),
                          const SizedBox(height: 12),
                          _buildRow('Intent ID:', state.intentId.length > 8 ? state.intentId.substring(0,8) : state.intentId, false),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'By approving, this amount will be added to your outstanding loan balance.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => context.read<AddCreditFlowCubit>().rejectIntent(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Reject', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => context.read<AddCreditFlowCubit>().approveIntent(),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Approve', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }
          
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                const Text('Unable to process intent.'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (GoRouter.of(context).canPop()) {
                      context.pop();
                    } else {
                      context.go('/home');
                    }
                  },
                  child: const Text('Go Back'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRow(String label, String value, bool highlight) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, color: Colors.black54)),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: highlight ? FontWeight.bold : FontWeight.normal, color: highlight ? KhaataTheme.primaryBlue : Colors.black87)),
      ],
    );
  }
}