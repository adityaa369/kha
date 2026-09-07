import 'package:flutter_test/flutter_test.dart';
import 'package:khatha/data/models/loan_model.dart';
import 'package:intl/intl.dart';

void main() {
  String formatCurrency(double amount) {
    final format = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '',
      decimalDigits: 0,
    );
    return format.format(amount).trim();
  }

  group('Batch 2A Frontend Regression', () {
    test(
      'LoanModel strictly parses amountPaise and does not infer from legacy amount',
      () {
        final validJson = {
          '_id': 'loan_123',
          'lender': 'lender1',
          'borrower': 'borrower1',
          'amountPaise': 68000000,
          'principalOutstandingPaise': 68000000,
          'amount': 6800.0,
        };

        final loan = LoanModel.fromJson(validJson);

        expect(loan.amountPaise, 68000000);
        expect(loan.principalOutstandingPaise, 68000000);

        expect(loan.amount, 680000.0);
        expect(loan.amount, isNot(6800.0));

        final displayAmount = '₹${formatCurrency(loan.amount)}';
        expect(displayAmount, '₹6,80,000');
      },
    );

    test('LoanModel throws FormatException if amountPaise is missing', () {
      final invalidJson = {
        '_id': 'loan_123',
        'lender': 'lender1',
        'borrower': 'borrower1',
        'principalOutstandingPaise': 68000000,
        'amount': 680000.0,
      };

      expect(
        () => LoanModel.fromJson(invalidJson),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
