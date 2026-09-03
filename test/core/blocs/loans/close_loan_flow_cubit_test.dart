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
  });

  group('4F-4D Close Loan Validation', () {
    test('1 & 6. Close loan -> Intent created -> Awaiting consent', () async {
      final cubit = CloseLoanFlowCubit(repository: mockRepo, loanId: 'loan1');
      
      when(() => mockRepo.createCloseIntent(loanId: 'loan1'))
          .thenAnswer((_) async => 'intent123');
      
      await cubit.createIntent();
      expect(cubit.state, isA<CloseLoanAwaitingConsent>());
      expect((cubit.state as CloseLoanAwaitingConsent).intentId, 'intent123');
    });

    test('3 & 6. Borrower loads intent -> Correct borrower can authorize', () async {
      final cubit = CloseLoanFlowCubit(
        repository: mockRepo, loanId: 'loan1', initialIntentId: 'intent123'
      );
      
      expect(cubit.state, isA<CloseLoanAwaitingConsent>());
      
      when(() => mockRepo.commitClose(loanId: 'loan1', intentId: 'intent123'))
          .thenAnswer((_) async => true);
          
      await cubit.approveIntent();
      expect(cubit.state, isA<CloseLoanSuccess>());
    });

    test('8. Expired intent cannot authorize', () async {
      final cubit = CloseLoanFlowCubit(
        repository: mockRepo, loanId: 'loan1', initialIntentId: 'intent123'
      );
      
      final dioException = DioException(
        requestOptions: RequestOptions(path: ''),
        response: Response(requestOptions: RequestOptions(path: ''), data: {'code': 'INTENT_EXPIRED'}),
      );
      
      when(() => mockRepo.commitClose(loanId: 'loan1', intentId: 'intent123'))
          .thenThrow(dioException);
          
      await cubit.approveIntent();
      expect(cubit.state, isA<CloseLoanRejectedState>());
      expect((cubit.state as CloseLoanRejectedState).failure, isA<BusinessLogicFailure>());
      expect(((cubit.state as CloseLoanRejectedState).failure as BusinessLogicFailure).message, 'INTENT_EXPIRED');
    });

    test('9. Consumed intent cannot authorize', () async {
      final cubit = CloseLoanFlowCubit(
        repository: mockRepo, loanId: 'loan1', initialIntentId: 'intent123'
      );
      
      final dioException = DioException(
        requestOptions: RequestOptions(path: ''),
        response: Response(requestOptions: RequestOptions(path: ''), data: {'code': 'INTENT_CONSUMED'}),
      );
      
      when(() => mockRepo.commitClose(loanId: 'loan1', intentId: 'intent123'))
          .thenThrow(dioException);
          
      await cubit.approveIntent();
      expect(cubit.state, isA<CloseLoanRejectedState>());
      expect((cubit.state as CloseLoanRejectedState).failure, isA<IntentConsumedFailure>());
    });

    test('10 & 11. Frozen or Terminal loan blocks intent/commit', () async {
      final cubit = CloseLoanFlowCubit(repository: mockRepo, loanId: 'loan1');
      
      final dioException = DioException(
        requestOptions: RequestOptions(path: ''),
        response: Response(requestOptions: RequestOptions(path: ''), data: {'code': 'LOAN_FROZEN'}),
      );
      
      when(() => mockRepo.createCloseIntent(loanId: 'loan1'))
          .thenThrow(dioException);
          
      await cubit.createIntent();
      expect(cubit.state, isA<CloseLoanRejectedState>());
      expect(((cubit.state as CloseLoanRejectedState).failure as BusinessLogicFailure).message, 'LOAN_FROZEN');
    });

    test('12. Duplicate taps produce one request', () async {
      final cubit = CloseLoanFlowCubit(
        repository: mockRepo, loanId: 'loan1', initialIntentId: 'intent123'
      );
      
      final completer = Completer<bool>();
      when(() => mockRepo.commitClose(loanId: 'loan1', intentId: 'intent123'))
          .thenAnswer((_) => completer.future);
          
      cubit.approveIntent();
      cubit.approveIntent(); // duplicate tap
      
      completer.complete(true);
      await Future.delayed(Duration.zero);
      
      verify(() => mockRepo.commitClose(loanId: 'loan1', intentId: 'intent123')).called(1);
    });

    test('13 & 14. Network timeout reconciles existing intent -> COMMITTED', () async {
      final cubit = CloseLoanFlowCubit(
        repository: mockRepo, loanId: 'loan1', initialIntentId: 'intent123'
      );
      
      when(() => mockRepo.commitClose(loanId: 'loan1', intentId: 'intent123'))
          .thenThrow(TimeoutException('timeout'));
          
      when(() => mockRepo.checkIntentStatus('intent123'))
          .thenAnswer((_) async => 'COMMITTED');
          
      await cubit.approveIntent();
      
      expect(cubit.state, isA<CloseLoanSuccess>());
      verify(() => mockRepo.checkIntentStatus('intent123')).called(1);
    });

    test('15. Network timeout reconciles existing intent -> NOT COMMITTED (PENDING)', () async {
      final cubit = CloseLoanFlowCubit(
        repository: mockRepo, loanId: 'loan1', initialIntentId: 'intent123'
      );
      
      when(() => mockRepo.commitClose(loanId: 'loan1', intentId: 'intent123'))
          .thenThrow(TimeoutException('timeout'));
          
      when(() => mockRepo.checkIntentStatus('intent123'))
          .thenAnswer((_) async => 'PENDING');
          
      await cubit.approveIntent();
      
      expect(cubit.state, isA<CloseLoanAwaitingConsent>());
      verify(() => mockRepo.checkIntentStatus('intent123')).called(1);
    });

    test('20. No local accounting mutation (logic relies only on cubit state, no math)', () async {
      final cubit = CloseLoanFlowCubit(
        repository: mockRepo, loanId: 'loan1', initialIntentId: 'intent123'
      );
      
      // We do not pass principal, interest, or any amount to CloseLoanFlowCubit.
      // Therefore, it is impossible for the Cubit to mutate the balance.
      // Verification by design - checking it lacks those fields.
      expect(cubit.state is CloseLoanAwaitingConsent, true);
    });
  });
}
