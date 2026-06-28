import 'package:flutter/material.dart';
import '../../../../data/models/loan_model.dart';
import 'business_loan_details_page.dart';
import 'hand_loan_details_page.dart';
import 'interest_loan_details_page.dart';

class LoanDetailsPage extends StatelessWidget {
  final LoanModel loan;

  const LoanDetailsPage({super.key, required this.loan});

  @override
  Widget build(BuildContext context) {
    try {
      final type = loan.type.toLowerCase().replaceAll('_', '');
      if (type == 'businesscredit') {
        return BusinessLoanDetailsPage(loan: loan);
      } else if (type == 'interestcredit') {
        return InterestLoanDetailsPage(loan: loan);
      } else if (type == 'handcredit') {
        return HandLoanDetailsPage(loan: loan);
      } else {
        return HandLoanDetailsPage(loan: loan);
      }
    } catch (e, stack) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('Error routing: $e\n$stack')),
      );
    }
  }
}
