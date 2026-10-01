import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:khatha/core/blocs/loans/payment_flow_cubit.dart';
import 'package:khatha/data/repositories/loan_repository.dart';
import 'package:khatha/core/error/failures.dart';
import 'dart:async';
import 'package:dio/dio.dart';

class MockLoanRepository extends Mock implements LoanRepository {}

void main() {
  late MockLoanRepository mockRepo;
  late PaymentFlowCubit cubit;

  setUp(() {
    mockRepo = MockLoanRepository();
    cubit = PaymentFlowCubit(repository: mockRepo, loanId: 'loan1');
  });

  tearDown(() {
    cubit.close();
  });

  group('Phase B - 2-Stage Payment Flow Validation', () {
    test('1. createIntent emits PaymentAwaitingOTP', () async {
      when(
        () =>
            mockRepo.createPaymentIntent(loanId: 'loan1', amountPaise: 500000),
      ).thenAnswer((_) async => 'intent-123');

      await cubit.createIntent(500000);

      expect(cubit.state, isA<PaymentAwaitingOTP>());
      expect((cubit.state as PaymentAwaitingOTP).intentId, 'intent-123');
    });

    test('2. commitPayment emits PaymentSuccess', () async {
      when(
        () =>
            mockRepo.createPaymentIntent(loanId: 'loan1', amountPaise: 500000),
      ).thenAnswer((_) async => 'intent-123');

      await cubit.createIntent(500000);

      when(
        () => mockRepo.commitPayment(
          loanId: 'loan1',
          intentId: 'intent-123',
          otp: '123456',
        ),
      ).thenAnswer((_) async => true);

      await cubit.commitPayment('123456');

      expect(cubit.state, isA<PaymentSuccess>());
    });

    test('3. failed createIntent emits PaymentRejected', () async {
      when(
        () =>
            mockRepo.createPaymentIntent(loanId: 'loan1', amountPaise: 500000),
      ).thenThrow(const BusinessLogicFailure('LOAN_FROZEN'));

      await cubit.createIntent(500000);

      expect(cubit.state, isA<PaymentRejected>());
      expect(
        (cubit.state as PaymentRejected).failure,
        isA<BusinessLogicFailure>(),
      );
    });

    test(
      '4. commitPayment with invalid OTP handles error and reverts to AwaitingOTP',
      () async {
        when(
          () => mockRepo.createPaymentIntent(
            loanId: 'loan1',
            amountPaise: 500000,
          ),
        ).thenAnswer((_) async => 'intent-123');

        await cubit.createIntent(500000);

        final dioOtpInvalid = DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 401,
            data: {'code': 'OTP_INVALID', 'message': 'Invalid OTP'},
          ),
        );

        when(
          () => mockRepo.commitPayment(
            loanId: 'loan1',
            intentId: 'intent-123',
            otp: '000000',
          ),
        ).thenThrow(dioOtpInvalid);

        // We expect a state sequence here: Committing -> Rejected -> AwaitingOTP
        // With await, cubit.state reflects the final state (AwaitingOTP)
        await cubit.commitPayment('000000');

        expect(cubit.state, isA<PaymentAwaitingOTP>());
      },
    );

    test('5. Reconcile network unknown', () async {
      when(
        () =>
            mockRepo.createPaymentIntent(loanId: 'loan1', amountPaise: 500000),
      ).thenAnswer((_) async => 'intent-123');

      await cubit.createIntent(500000);

      final dioTimeout = DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.connectionTimeout,
      );

      when(
        () => mockRepo.commitPayment(
          loanId: 'loan1',
          intentId: 'intent-123',
          otp: '123456',
        ),
      ).thenThrow(dioTimeout);

      // Reconcile is called automatically on timeout inside commitPayment
      when(
        () => mockRepo.checkIntentStatus('intent-123'),
      ).thenAnswer((_) async => 'COMMITTED');

      await cubit.commitPayment('123456');

      expect(cubit.state, isA<PaymentSuccess>());
    });
  });
}
