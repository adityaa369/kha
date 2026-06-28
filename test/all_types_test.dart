import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:khatha/features/loans/presentation/pages/interest_loan_details_page.dart';
import 'package:khatha/features/loans/presentation/pages/business_loan_details_page.dart';
import 'package:khatha/features/loans/presentation/pages/hand_loan_details_page.dart';
import 'package:khatha/data/models/loan_model.dart';
import 'package:khatha/core/blocs/loans/loan_cubit.dart';
import 'package:khatha/core/blocs/loans/loan_state.dart';
import 'package:khatha/core/blocs/auth/auth_cubit.dart';

class MockLoanCubit extends Cubit<LoanState> implements LoanCubit {
  MockLoanCubit() : super(LoanInitial());
  @override
  Future<void> fetchLoans() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockAuthCubit extends Cubit<AuthState> implements AuthCubit {
  MockAuthCubit() : super(AuthInitial());
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget buildApp(Widget child) {
  return MaterialApp(
    home: ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, _) => MultiBlocProvider(
        providers: [
          BlocProvider<LoanCubit>(create: (_) => MockLoanCubit()),
          BlocProvider<AuthCubit>(create: (_) => MockAuthCubit()),
        ],
        child: child,
      ),
    ),
  );
}

void main() {
  testWidgets('InterestLoanDetailsPage renders without layout errors', (WidgetTester tester) async {
    final loan = LoanModel(
      id: 'mock_interest_1',
      borrowerName: 'Amit Patel',
      amount: 50000.0,
      interestRate: 2.5,
      durationMonths: 12,
      status: 'active',
      progress: 0.25,
      startDate: DateTime.now().subtract(const Duration(days: 45)),
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
      type: 'interest_credit',
      mobile: '9876543210',
    );
    await tester.pumpWidget(buildApp(InterestLoanDetailsPage(loan: loan)));
    await tester.pumpAndSettle();
    expect(find.byType(InterestLoanDetailsPage), findsOneWidget);
  });

  testWidgets('BusinessLoanDetailsPage renders without layout errors', (WidgetTester tester) async {
    final loan = LoanModel(
      id: 'mock_business_1',
      borrowerName: 'Ravi Kirana Store',
      amount: 250000.0,
      interestRate: 1.5,
      durationMonths: 24,
      status: 'active',
      progress: 0.1,
      startDate: DateTime.now().subtract(const Duration(days: 90)),
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
      type: 'business_credit',
      mobile: '8888888888',
    );
    await tester.pumpWidget(buildApp(BusinessLoanDetailsPage(loan: loan)));
    await tester.pumpAndSettle();
    expect(find.byType(BusinessLoanDetailsPage), findsOneWidget);
  });

  testWidgets('HandLoanDetailsPage renders without layout errors', (WidgetTester tester) async {
    final loan = LoanModel(
      id: 'mock_hand_1',
      borrowerName: 'Suresh Kumar',
      amount: 15000.0,
      status: 'pending_otp',
      progress: 0.0,
      startDate: DateTime.now().subtract(const Duration(days: 2)),
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      type: 'hand_credit',
      mobile: '7777777777',
    );
    await tester.pumpWidget(buildApp(HandLoanDetailsPage(loan: loan)));
    await tester.pumpAndSettle();
    expect(find.byType(HandLoanDetailsPage), findsOneWidget);
  });
}
