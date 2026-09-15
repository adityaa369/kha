import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:khatha/core/blocs/loans/close_loan_flow_cubit.dart';
import 'package:khatha/data/repositories/loan_repository.dart';
import 'package:khatha/core/error/failures.dart';
import 'dart:async';
import 'package:dio/dio.dart';

class MockLoanRepository extends Mock implements LoanRepository {}

void main() {
  late MockLoanRepository mockRepo;

  setUp(() {
    mockRepo = MockLoanRepository();
    registerFallbackValue('dummy_id');
  });

  group('4F-4D Close Loan Validation', () {
    test('1. Close loan direct intent creation and commit success', () async {
      final cubit = CloseLoanFlowCubit(repository: mockRepo, loanId: 'loan1');

      when(
        () => mockRepo.commitClose(loanId: 'loan1', intentId: any(named: 'intentId')),
      ).thenAnswer((_) async => true);

      await cubit.createIntent();
      expect(cubit.state, isA<CloseLoanSuccess>());
    });

    test('2. Close loan commit failure emits RejectedState', () async {
      final cubit = CloseLoanFlowCubit(repository: mockRepo, loanId: 'loan1');

      when(
        () => mockRepo.commitClose(loanId: 'loan1', intentId: any(named: 'intentId')),
      ).thenAnswer((_) async => false);

      await cubit.createIntent();
      expect(cubit.state, isA<CloseLoanRejectedState>());
    });

    test('3. DioException during commit emits mapped failure', () async {
      final cubit = CloseLoanFlowCubit(repository: mockRepo, loanId: 'loan1');

      final dioException = DioException(
        requestOptions: RequestOptions(path: ''),
        response: Response(
          requestOptions: RequestOptions(path: ''),
          data: {'code': 'INTENT_EXPIRED'},
        ),
      );

      when(
        () => mockRepo.commitClose(loanId: 'loan1', intentId: any(named: 'intentId')),
      ).thenThrow(dioException);

      await cubit.createIntent();
      expect(cubit.state, isA<CloseLoanRejectedState>());
    });
  });
}
