import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khatha/features/loans/presentation/pages/interest_loan_details_page.dart';
import 'package:khatha/data/models/loan_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khatha/core/blocs/loans/loan_cubit.dart';
import 'package:khatha/core/blocs/loans/loan_state.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MockLoanCubit extends Cubit<LoanState> implements LoanCubit {
  MockLoanCubit() : super(LoanInitial());
  @override
  Future<void> fetchLoans() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('Test layout', (WidgetTester tester) async {
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
    
    await tester.pumpWidget(
      MaterialApp(
        home: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, child) => BlocProvider<LoanCubit>(
            create: (_) => MockLoanCubit(),
            child: InterestLoanDetailsPage(loan: loan),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  });
}
