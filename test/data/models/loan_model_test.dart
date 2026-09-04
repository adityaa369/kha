import 'package:flutter_test/flutter_test.dart';
import 'package:khatha/data/models/loan_model.dart';

void main() {
  group('LoanModel', () {
    test('parses pendingIntentId from JSON', () {
      final json = {
        '_id': 'loan-123',
        'borrower_name': 'Test Borrower',
        'initials': 'TB',
        'amountPaise': 100000,
        'status': 'pending_approval',
        'pendingIntentId': 'intent-xyz',
        'type': 'personal',
      };

      final loan = LoanModel.fromJson(json);

      expect(loan.id, 'loan-123');
      expect(loan.pendingIntentId, 'intent-xyz');
      expect(loan.status, 'pending_approval');
    });

    test('props includes pendingIntentId for Equatable', () {
      const loan1 = LoanModel(
        id: '1',
        borrowerName: 'Test',
        initials: 'T',
        amountPaise: 100,
        status: 'pending',
        progress: 0,
        type: 'personal',
        pendingIntentId: 'abc',
      );

      const loan2 = LoanModel(
        id: '1',
        borrowerName: 'Test',
        initials: 'T',
        amountPaise: 100,
        status: 'pending',
        progress: 0,
        type: 'personal',
        pendingIntentId: 'def', // different intent ID
      );

      expect(loan1 == loan2, isFalse);
    });
  });
}
