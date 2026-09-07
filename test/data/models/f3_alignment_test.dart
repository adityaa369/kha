import 'package:flutter_test/flutter_test.dart';
import 'package:khatha/data/models/loan_model.dart';

void main() {
  group('F.3 Financial Model Alignment', () {
    test('Converts legacy amount to amountPaise and displays Rupees', () {
      final json = {'id': '123', 'borrowerName': 'Test', 'amount': 500.50};

      final loan = LoanModel.fromJson(json);

      expect(loan.amountPaise, 50050);
      expect(loan.amount, 500.50);
      expect(loan.displayAmount, '₹ 501');
    });

    test('Faithfully relies on backend totalPayablePaise even if 0', () {
      final json = {
        'id': '123',
        'borrowerName': 'Test',
        'amountPaise': 50000,
        'totalPayablePaise': 0,
        'paidAmountPaise': 0,
        'progress': 0.0,
      };

      final loan = LoanModel.fromJson(json);
      expect(loan.totalPayablePaise, 0);
      expect(loan.remainingAmount, 0.0);
    });

    test(
      'Calculates remaining amount correctly strictly using backend fields',
      () {
        final json = {
          'id': '123',
          'borrowerName': 'Test',
          'amountPaise': 50000,
          'totalPayablePaise': 60000,
          'paidAmountPaise': 20000,
        };

        final loan = LoanModel.fromJson(json);
        expect(loan.remainingAmount, 400.0);
      },
    );

    test('Maps embedded transactions using amountPaise', () {
      final json = {
        'id': '123',
        'borrowerName': 'Test',
        'transactions': [
          {'type': 'payment', 'amountPaise': 15000},
          {'type': 'interest_payment', 'amount': 50.0},
        ],
      };

      final loan = LoanModel.fromJson(json);
      expect(loan.transactions.length, 2);
      expect(loan.transactions[0].amountPaise, 15000);
      expect(loan.transactions[0].amount, 150.0);
      expect(loan.transactions[1].amountPaise, 5000);
      expect(loan.transactions[1].amount, 50.0);
    });
  });
}
