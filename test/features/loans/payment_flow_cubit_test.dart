import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:khatha/core/blocs/loans/payment_flow_cubit.dart';
import 'package:khatha/data/repositories/loan_repository.dart';
import 'package:khatha/core/error/failures.dart';

class MockLoanRepository extends Mock implements LoanRepository {}

void main() {
  late PaymentFlowCubit cubit;
  late MockLoanRepository mockRepo;

  setUp(() {
    mockRepo = MockLoanRepository();
    cubit = PaymentFlowCubit(
      repository: mockRepo,
      loanId: 'test-loan-id',
      initialIntentId: 'test-intent-id',
      initialAmountPaise: 1000,
    );
  });

  tearDown(() {
    cubit.close();
  });

  test('wrong OTP -> 400 (ClientFailure), user remains authenticated', () async {
    // Arrange
    when(() => mockRepo.commitPayment(
          loanId: any(named: 'loanId'),
          intentId: any(named: 'intentId'),
          otp: any(named: 'otp'),
        )).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/commit'),
        response: Response(
          requestOptions: RequestOptions(path: '/commit'),
          statusCode: 400,
          data: {'code': 'OTP_INVALID'},
        ),
      ),
    );

    // Act
    await cubit.commitPayment('000000');

    // Assert
    expect(cubit.state, isA<PaymentRejected>());
    final state = cubit.state as PaymentRejected;
    expect(state.failure, isA<BusinessLogicFailure>());
    expect(state.failure.message, 'OTP_INVALID');
  });
  
  test('correct OTP -> payment succeeds', () async {
    when(() => mockRepo.commitPayment(
          loanId: any(named: 'loanId'),
          intentId: any(named: 'intentId'),
          otp: any(named: 'otp'),
        )).thenAnswer((_) async => true);

    await cubit.commitPayment('123456');

    expect(cubit.state, isA<PaymentSuccess>());
  });
}
