import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/blocs/loans/close_loan_flow_cubit.dart';
import '../../../../data/repositories/loan_repository.dart';
import '../../../../config/theme.dart';
import '../../../../core/utils/error_handler.dart';

class CloseLoanApprovalPage extends StatelessWidget {
  final String loanId;
  final String intentId;

  const CloseLoanApprovalPage({
    super.key,
    required this.loanId,
    required this.intentId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CloseLoanFlowCubit(
        repository: context.read<LoanRepository>(),
        loanId: loanId,
        initialIntentId: intentId,
      ),
      child: const _CloseLoanApprovalView(),
    );
  }
}

class _CloseLoanApprovalView extends StatelessWidget {
  const _CloseLoanApprovalView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Close Loan Request'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            if (GoRouter.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: BlocConsumer<CloseLoanFlowCubit, CloseLoanFlowState>(
        listener: (context, state) {
          if (state is CloseLoanSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Loan closed successfully.'),
                backgroundColor: Colors.green,
              ),
            );
            Future.delayed(const Duration(seconds: 1), () {
              if (GoRouter.of(context).canPop()) {
                context.pop(true);
              } else {
                context.go('/home');
              }
            });
          } else if (state is CloseLoanRejectedState) {
            ErrorHandler.showError(context, state.failure.message);
          }
        },
        builder: (context, state) {
          if (state is CloseLoanAuthorizing || state is CloseLoanCommitting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Processing closure...',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }

          if (state is CloseLoanSuccess) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 64),
                  SizedBox(height: 16),
                  Text(
                    'Loan Closed',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }

          if (state is CloseLoanAwaitingConsent) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 64,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Lender Requested to Close Loan',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Any remaining outstanding balance will be written off.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(height: 32),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              context.read<CloseLoanFlowCubit>().rejectIntent(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'Reject',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => context
                              .read<CloseLoanFlowCubit>()
                              .approveIntent(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: KhaataTheme.primaryBlue,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'Approve Closure',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
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
                const Text('Unable to process close intent.'),
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
}
