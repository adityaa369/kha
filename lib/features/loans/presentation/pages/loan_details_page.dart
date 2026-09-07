import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/models/loan_model.dart';
import '../../../../data/repositories/loan_repository.dart';
import '../../../../core/blocs/auth/auth_cubit.dart';
import '../../../../core/error/failures.dart';
import 'business_loan_details_page.dart';
import 'hand_loan_details_page.dart';
import 'interest_loan_details_page.dart';
import 'lender_loan_details_page.dart';

class LoanDetailsPage extends StatefulWidget {
  final String loanId;

  const LoanDetailsPage({super.key, required this.loanId});

  @override
  State<LoanDetailsPage> createState() => _LoanDetailsPageState();
}

class _LoanDetailsPageState extends State<LoanDetailsPage> {
  late Future<LoanModel> _loanFuture;

  @override
  void initState() {
    super.initState();
    _fetchLoan();
  }

  void _fetchLoan() {
    _loanFuture = context.read<LoanRepository>().getLoanById(widget.loanId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<LoanModel>(
        future: _loanFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error);
          }
          if (!snapshot.hasData) {
            return _buildErrorState('Loan not found');
          }

          final loan = snapshot.data!;
          final authState = context.read<AuthCubit>().state;
          String? currentUserId;
          // Note: In actual code, AuthState doesn't have AuthenticatedKycComplete directly if it's the old one, but let's check
          // Wait, auth_cubit uses AuthenticatedKycComplete! Let me just get it from SecureStorage or check authState
          if (authState is AuthenticatedKycComplete) {
            currentUserId = authState.user.id;
          } else if (authState is AuthOffline) {
            currentUserId = authState.user.id;
          } else if (authState is AuthenticatedEmailVerifiedKycIncomplete) {
            currentUserId = authState.user.id;
          }

          final isLender =
              currentUserId != null && loan.lenderId == currentUserId;

          if (isLender) {
            return LenderLoanDetailsPage(
              loan: loan,
            ); // Passing the model we just fetched
          } else {
            final type = loan.type.toLowerCase().replaceAll('_', '');
            if (type == 'businesscredit') {
              return BusinessLoanDetailsPage(loan: loan);
            } else if (type == 'interestcredit') {
              return InterestLoanDetailsPage(loan: loan);
            } else {
              return HandLoanDetailsPage(loan: loan);
            }
          }
        },
      ),
    );
  }

  Widget _buildErrorState(Object? error) {
    String message = 'Failed to load loan.';
    if (error is AuthFailure) {
      message = "You don't have permission to view this loan.";
    } else if (error is ValidationFailure) {
      message = 'Loan not found.';
    } else if (error is BusinessLogicFailure) {
      message = 'Cannot display this loan.';
    } else if (error is Failure) {
      message = error.message;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, color: Colors.red.shade300, size: 64),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
