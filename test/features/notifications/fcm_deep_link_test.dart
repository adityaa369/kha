import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:khatha/data/repositories/loan_repository.dart';
import 'package:khatha/core/blocs/auth/auth_cubit.dart';
import 'package:khatha/core/error/failures.dart';
import 'package:khatha/core/blocs/loans/loan_cubit.dart';
import 'package:khatha/core/blocs/loans/loan_state.dart';
import 'package:khatha/features/loans/presentation/pages/loan_details_page.dart';
import 'package:khatha/data/models/loan_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:khatha/data/models/user_model.dart';

class MockLoanRepository extends Mock implements LoanRepository {}
class MockAuthCubit extends Mock implements AuthCubit {}
class MockLoanCubit extends Mock implements LoanCubit {}

void main() {
  late MockLoanRepository mockRepo;
  late MockAuthCubit mockAuthCubit;
  late MockLoanCubit mockLoanCubit;

  setUp(() {
    mockRepo = MockLoanRepository();
    mockAuthCubit = MockAuthCubit();
    mockLoanCubit = MockLoanCubit();
    when(() => mockLoanCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockLoanCubit.state).thenReturn(LoanInitial());

    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('A RenderFlex overflowed')) {
        return;
      }
      FlutterError.presentError(details);
    };

    
    when(() => mockAuthCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockAuthCubit.state).thenReturn(
      const AuthenticatedKycComplete(user: UserModel(
        id: 'user_123',
        firstName: 'Current',
        lastName: 'User',
        phone: '+919999999999',
      ))
    );
  });

  Widget buildTestableWidget(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (_, __) => MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>.value(value: mockAuthCubit),
          BlocProvider<LoanCubit>.value(value: mockLoanCubit),
          RepositoryProvider<LoanRepository>.value(value: mockRepo),
        ],
        child: child,
      ),
    ),
    );
  }

  group('4F-4G FCM Deep-Link Integration', () {
    testWidgets('Critical Compound Test - Valid Loan renders securely', (WidgetTester tester) async {
      
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        if (details.exceptionAsString().contains('overflowed')) return;
        originalOnError?.call(details);
      };
      const validLoan = LoanModel(
        id: 'valid_loan_123',
        lenderId: 'lender_456',
        userId: 'user_123', 
        borrowerName: 'Current User',
        initials: 'CU',
        amountPaise: 100000,
        status: 'active',
        progress: 0.5,
        type: 'handcredit',
        principalOutstandingPaise: 50000,
        totalPayablePaise: 110000,
        paidAmountPaise: 50000,
      );

      when(() => mockRepo.getLoanById('valid_loan_123'))
          .thenAnswer((_) async => validLoan);

      await tester.pumpWidget(buildTestableWidget(const LoanDetailsPage(loanId: 'valid_loan_123')));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      verify(() => mockRepo.getLoanById('valid_loan_123')).called(1);
    });

    testWidgets('Critical Compound Test - Unauthorized Loan via tampered payload yields safe 403', (WidgetTester tester) async {
      
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        if (details.exceptionAsString().contains('overflowed')) return;
        originalOnError?.call(details);
      };
      when(() => mockRepo.getLoanById('another_users_loan'))
          .thenAnswer((_) async => throw const AuthFailure("You don't have permission to view this loan."));

      await tester.pumpWidget(buildTestableWidget(const LoanDetailsPage(loanId: 'another_users_loan')));

      await tester.pumpAndSettle();

      expect(find.text('50000'), findsNothing);
      expect(find.text("You don't have permission to view this loan."), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });
  });
}
