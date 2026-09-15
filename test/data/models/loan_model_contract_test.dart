import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import '../../../lib/data/models/loan_model.dart';

void main() {
  group('P0-4 Loan Serialization Contract', () {
    test('backend HTTP JSON parses through real LoanModel.fromJson', () {
      final file = File('test/fixtures/p04_given_response.json');
      if (!file.existsSync()) {
        fail('Fixture file missing. Run the backend HTTP contract tests first.');
      }
      
      final json = jsonDecode(file.readAsStringSync());
      final loans = json['loans'] as List;
      
      expect(() => LoanModel.fromJson(loans[0] as Map<String, dynamic>), returnsNormally);
      
      final model = LoanModel.fromJson(loans[0] as Map<String, dynamic>);
      expect(model.amountPaise, greaterThan(0));
      if (model.principalOutstandingPaise != null) {
        expect(model.principalOutstandingPaise, greaterThanOrEqualTo(0));
      } else {
        expect(model.principalOutstandingPaise, isNull);
      }
    });
  });
}
