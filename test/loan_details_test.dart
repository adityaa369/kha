import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:khatha/features/loans/presentation/pages/loan_details_page.dart';
import 'package:khatha/core/blocs/loans/loan_cubit.dart';
import 'package:khatha/core/blocs/loans/loan_state.dart';
import 'package:khatha/core/blocs/auth/auth_cubit.dart';
import 'package:khatha/data/models/loan_model.dart';
import 'package:khatha/data/models/user_model.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthCubit extends Mock implements AuthCubit {}

class MockLoanCubit extends Mock implements LoanCubit {}

void main() {
  late MockAuthCubit authCubit;
  late MockLoanCubit loanCubit;
  late UserModel borrowerUser;
  late UserModel lenderUser;

  setUp(() {
    authCubit = MockAuthCubit();
    loanCubit = MockLoanCubit();

    borrowerUser = const UserModel(
      id: 'borrower_123',
      firstName: 'John',
      lastName: 'Borrower',
      phone: '9908739956',
    );

    lenderUser = const UserModel(
      id: 'lender_123',
      firstName: 'Jane',
      lastName: 'Lender',
      phone: '9908739957',
    );

    when(
      () => authCubit.state,
    ).thenReturn(AuthenticatedFull(user: borrowerUser));
    when(() => authCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => loanCubit.state).thenReturn(LoanInitial());
    when(() => loanCubit.stream).thenAnswer((_) => const Stream.empty());
  });

  Widget buildTestWidget(LoanModel loan) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiBlocProvider(
          providers: [
            BlocProvider<LoanCubit>.value(value: loanCubit),
            BlocProvider<AuthCubit>.value(value: authCubit),
          ],
          child: MaterialApp(home: LoanDetailsPage(loan: loan)),
        );
      },
    );
  }

  testWidgets(
    'Borrower views active Hand Credit loan details - should build without exception',
    (WidgetTester tester) async {
      final loan = LoanModel(
        id: '1',
        lenderId: 'lender_123',
        userId: 'borrower_123',
        borrowerName: 'John Borrower',
        lenderName: 'Jane Lender',
        amount: 10000,
        progress: 0.5,
        startDate: DateTime(2026, 4, 20),
        durationMonths: 6,
        type: 'hand_credit',
        status: 'active',
        mobile: '9908739956',
      );

      await tester.pumpWidget(buildTestWidget(loan));
      await tester.pumpAndSettle();
      expect(find.byType(LoanDetailsPage), findsOneWidget);
      expect(find.text('Hand Credit Details'), findsOneWidget);
      expect(find.text('Principal Amount'), findsAtLeastNWidgets(1));
      expect(find.text('Jane Lender'), findsOneWidget);
    },
  );

  testWidgets(
    'Borrower views active Interest Credit loan details - should build without exception',
    (WidgetTester tester) async {
      final loan = LoanModel(
        id: '2',
        lenderId: 'lender_123',
        userId: 'borrower_123',
        borrowerName: 'John Borrower',
        lenderName: 'Jane Lender',
        amount: 20000,
        interestRate: 2.0,
        progress: 0.2,
        startDate: DateTime(2026, 4, 20),
        durationMonths: 12,
        type: 'interest_credit',
        status: 'active',
        mobile: '9908739956',
      );

      await tester.pumpWidget(buildTestWidget(loan));
      await tester.pumpAndSettle();
      expect(find.byType(LoanDetailsPage), findsOneWidget);
      expect(find.text('Interest Credit Details'), findsOneWidget);
      expect(find.text('Principal Amount'), findsAtLeastNWidgets(1));
      expect(find.text('Jane Lender'), findsOneWidget);
    },
  );

  testWidgets(
    'Borrower views active Interest Credit loan with null duration/interest - should build without exception',
    (WidgetTester tester) async {
      final loan = LoanModel(
        id: '2-nulls',
        lenderId: 'lender_123',
        userId: 'borrower_123',
        borrowerName: 'John Borrower',
        lenderName: 'Jane Lender',
        amount: 20000,
        interestRate: null,
        progress: 0.2,
        startDate: DateTime(2026, 4, 20),
        durationMonths: null,
        type: 'interest_credit',
        status: 'active',
        mobile: '9908739956',
      );

      await tester.pumpWidget(buildTestWidget(loan));
      await tester.pumpAndSettle();
      expect(find.byType(LoanDetailsPage), findsOneWidget);
    },
  );

  testWidgets(
    'Lender views active Hand Credit loan details - should build without exception',
    (WidgetTester tester) async {
      when(
        () => authCubit.state,
      ).thenReturn(AuthenticatedFull(user: lenderUser));
      final loan = LoanModel(
        id: '1',
        lenderId: 'lender_123',
        userId: 'borrower_123',
        borrowerName: 'John Borrower',
        lenderName: 'Jane Lender',
        amount: 10000,
        progress: 0.5,
        startDate: DateTime(2026, 4, 20),
        durationMonths: 6,
        type: 'hand_credit',
        status: 'active',
        mobile: '9908739956',
      );

      await tester.pumpWidget(buildTestWidget(loan));
      await tester.pumpAndSettle();
      expect(find.byType(LoanDetailsPage), findsOneWidget);
    },
  );
}
