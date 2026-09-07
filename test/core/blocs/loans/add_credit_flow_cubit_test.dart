import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:khatha/core/blocs/loans/add_credit_flow_cubit.dart';
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

  group('4F-4C Add Credit Validation', () {
    test(
      '1 & 2. Create Add Credit intent -> Lender sees "Awaiting consent"',
      () async {
        final cubit = AddCreditFlowCubit(repository: mockRepo, loanId: 'loan1');

        when(
          () => mockRepo.createAddCreditIntent(
            loanId: 'loan1',
            amountRupees: 5000.0,
          ),
        ).thenAnswer((_) async => 'intent123');

        await cubit.createIntent(5000.0);
        expect(cubit.state, isA<AddCreditAwaitingConsent>());
        expect((cubit.state as AddCreditAwaitingConsent).intentId, 'intent123');
        expect((cubit.state as AddCreditAwaitingConsent).amountRupees, 5000.0);
      },
    );

    test(
      '3 & 4. Borrower loads intent -> Correct borrower can authorize',
      () async {
        // Borrower loads Cubit with existing intentId
        final cubit = AddCreditFlowCubit(
          repository: mockRepo,
          loanId: 'loan1',
          initialIntentId: 'intent123',
          initialAmountRupees: 5000.0,
        );

        expect(cubit.state, isA<AddCreditAwaitingConsent>());

        when(
          () => mockRepo.commitAddCredit(
            loanId: 'loan1',
            intentId: 'intent123',
            amountRupees: 5000.0,
          ),
        ).thenAnswer((_) async => true);

        await cubit.approveIntent();
        expect(cubit.state, isA<AddCreditSuccess>());
      },
    );

    test('6. Intent amount cannot be tampered with', () async {
      final cubit = AddCreditFlowCubit(
        repository: mockRepo,
        loanId: 'loan1',
        initialIntentId: 'intent123',
        initialAmountRupees: 5000.0,
      );

      // Try to approve, the Cubit extracts amountRupees purely from the intent state,
      // not from an external parameter, so the UI cannot inject 50,000.0 during approval.
      when(
        () => mockRepo.commitAddCredit(
          loanId: 'loan1',
          intentId: 'intent123',
          amountRupees: 5000.0,
        ),
      ).thenAnswer((_) async => true);

      await cubit.approveIntent();
      verify(
        () => mockRepo.commitAddCredit(
          loanId: 'loan1',
          intentId: 'intent123',
          amountRupees: 5000.0,
        ),
      ).called(1);
    });

    test('7. Expired intent cannot authorize', () async {
      final cubit = AddCreditFlowCubit(
        repository: mockRepo,
        loanId: 'loan1',
        initialIntentId: 'intent123',
        initialAmountRupees: 5000.0,
      );

      final dioException = DioException(
        requestOptions: RequestOptions(path: ''),
        response: Response(
          requestOptions: RequestOptions(path: ''),
          data: {'code': 'INTENT_EXPIRED'},
        ),
      );

      when(
        () => mockRepo.commitAddCredit(
          loanId: 'loan1',
          intentId: 'intent123',
          amountRupees: 5000.0,
        ),
      ).thenThrow(dioException);

      await cubit.approveIntent();
      expect(cubit.state, isA<AddCreditRejectedState>());
      expect(
        (cubit.state as AddCreditRejectedState).failure,
        isA<BusinessLogicFailure>(),
      );
      expect(
        ((cubit.state as AddCreditRejectedState).failure
                as BusinessLogicFailure)
            .message,
        'INTENT_EXPIRED',
      );
    });

    test('8. Consumed intent cannot authorize', () async {
      final cubit = AddCreditFlowCubit(
        repository: mockRepo,
        loanId: 'loan1',
        initialIntentId: 'intent123',
        initialAmountRupees: 5000.0,
      );

      final dioException = DioException(
        requestOptions: RequestOptions(path: ''),
        response: Response(
          requestOptions: RequestOptions(path: ''),
          data: {'code': 'INTENT_CONSUMED'},
        ),
      );

      when(
        () => mockRepo.commitAddCredit(
          loanId: 'loan1',
          intentId: 'intent123',
          amountRupees: 5000.0,
        ),
      ).thenThrow(dioException);

      await cubit.approveIntent();
      expect(cubit.state, isA<AddCreditRejectedState>());
      expect(
        (cubit.state as AddCreditRejectedState).failure,
        isA<IntentConsumedFailure>(),
      );
    });

    test('10. Duplicate taps produce one request', () async {
      final cubit = AddCreditFlowCubit(
        repository: mockRepo,
        loanId: 'loan1',
        initialIntentId: 'intent123',
        initialAmountRupees: 5000.0,
      );

      final completer = Completer<bool>();
      when(
        () => mockRepo.commitAddCredit(
          loanId: 'loan1',
          intentId: 'intent123',
          amountRupees: 5000.0,
        ),
      ).thenAnswer((_) => completer.future);

      cubit.approveIntent();
      cubit.approveIntent(); // duplicate tap

      completer.complete(true);
      await Future.delayed(Duration.zero);

      verify(
        () => mockRepo.commitAddCredit(
          loanId: 'loan1',
          intentId: 'intent123',
          amountRupees: 5000.0,
        ),
      ).called(1);
    });

    test('11. Network timeout reconciles existing intent', () async {
      final cubit = AddCreditFlowCubit(
        repository: mockRepo,
        loanId: 'loan1',
        initialIntentId: 'intent123',
        initialAmountRupees: 5000.0,
      );

      when(
        () => mockRepo.commitAddCredit(
          loanId: 'loan1',
          intentId: 'intent123',
          amountRupees: 5000.0,
        ),
      ).thenThrow(TimeoutException('timeout'));

      // The reconcile method is automatically called on TimeoutException in approveIntent.
      when(
        () => mockRepo.checkIntentStatus('intent123'),
      ).thenAnswer((_) async => 'PENDING');

      await cubit.approveIntent();

      // Should reconcile and go back to AwaitingConsent if PENDING
      expect(cubit.state, isA<AddCreditAwaitingConsent>());
      verify(() => mockRepo.checkIntentStatus('intent123')).called(1);
    });

    test('12. Reconciliation finds committed credit', () async {
      final cubit = AddCreditFlowCubit(
        repository: mockRepo,
        loanId: 'loan1',
        initialIntentId: 'intent123',
        initialAmountRupees: 5000.0,
      );

      when(
        () => mockRepo.commitAddCredit(
          loanId: 'loan1',
          intentId: 'intent123',
          amountRupees: 5000.0,
        ),
      ).thenThrow(TimeoutException('timeout'));

      when(
        () => mockRepo.checkIntentStatus('intent123'),
      ).thenAnswer((_) async => 'COMMITTED');

      await cubit.approveIntent();
      expect(cubit.state, isA<AddCreditSuccess>());
    });

    test('14. Rejected intent causes zero financial delta', () async {
      final cubit = AddCreditFlowCubit(
        repository: mockRepo,
        loanId: 'loan1',
        initialIntentId: 'intent123',
        initialAmountRupees: 5000.0,
      );

      when(() => mockRepo.rejectIntent('intent123')).thenAnswer((_) async {});

      await cubit.rejectIntent();
      expect(cubit.state, isA<AddCreditSuccess>());

      // Ensures commitAddCredit was NEVER called, thus zero financial delta
      verifyNever(
        () => mockRepo.commitAddCredit(
          loanId: any(named: 'loanId'),
          intentId: any(named: 'intentId'),
          amountRupees: any(named: 'amountRupees'),
        ),
      );
    });

    test('15 & 16. Frozen or Terminal loan blocks intent/commit', () async {
      final cubit = AddCreditFlowCubit(repository: mockRepo, loanId: 'loan1');

      final dioException = DioException(
        requestOptions: RequestOptions(path: ''),
        response: Response(
          requestOptions: RequestOptions(path: ''),
          data: {'code': 'LOAN_FROZEN'},
        ),
      );

      when(
        () => mockRepo.createAddCreditIntent(
          loanId: 'loan1',
          amountRupees: 5000.0,
        ),
      ).thenThrow(dioException);

      await cubit.createIntent(5000.0);
      expect(cubit.state, isA<AddCreditRejectedState>());
      expect(
        ((cubit.state as AddCreditRejectedState).failure
                as BusinessLogicFailure)
            .message,
        'LOAN_FROZEN',
      );
    });
  });
}
