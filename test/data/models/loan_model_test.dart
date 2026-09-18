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

    test('parses populated lender and borrower objects correctly', () {
      final json = {
        '_id': 'loan-456',
        'lender': {
          '_id': 'mongo_id_1',
          'id': 'lender-id-xyz',
          'firstName': 'John',
          'lastName': 'Doe',
          'phone': '9876543210'
        },
        'borrower': {
          '_id': 'mongo_id_2',
          'id': 'borrower-id-abc',
          'firstName': 'Jane',
          'lastName': 'Smith',
          'phone': '1234567890'
        },
        'amountPaise': 200000,
        'status': 'pending_approval',
        'type': 'personal',
        'progress': 0,
      };

      final loan = LoanModel.fromJson(json);

      expect(loan.id, 'loan-456');
      expect(loan.lenderId, 'mongo_id_1'); // because extractId prefers _id
      expect(loan.userId, 'mongo_id_2');
      expect(loan.lenderName, 'John Doe');
      expect(loan.borrowerName, 'Jane Smith');
      expect(loan.lenderPhone, '9876543210');
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
