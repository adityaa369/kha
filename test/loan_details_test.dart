import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:khatha/features/loans/presentation/pages/loan_details_page.dart';
import 'package:khatha/core/blocs/loans/loan_cubit.dart';
import 'package:khatha/core/blocs/auth/auth_cubit.dart';
import 'package:khatha/core/network/api_client.dart';
import 'package:khatha/data/models/loan_model.dart';
import 'package:khatha/data/repositories/loan_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockLoanRepository extends Mock implements LoanRepository {}
class MockApiClient extends Mock implements ApiClient {}

void main() {
  late LoanCubit cubit;
  late AuthCubit authCubit;

  setUp(() {
    cubit = LoanCubit(repository: MockLoanRepository());
    authCubit = AuthCubit(api: MockApiClient());
  });

  Widget buildTestWidget(LoanModel loan) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiBlocProvider(
          providers: [
            BlocProvider<LoanCubit>.value(value: cubit),
            BlocProvider<AuthCubit>.value(value: authCubit),
          ],
          child: MaterialApp(
            home: LoanDetailsPage(loan: loan),
          ),
        );
      },
    );
  }

  testWidgets('Test LoanDetailsPage Hand Credit with durationMonths 0', (WidgetTester tester) async {
    final loan = LoanModel(
      id: '1',
      borrowerName: 'John Doe',
      amount: 10000,
      progress: 0.5,
      startDate: DateTime(2026, 4, 20),
      durationMonths: 0, // Testing 0 duration
      type: 'hand_credit',
      status: 'active',
      mobile: '9908739956',
    );
    await tester.pumpWidget(buildTestWidget(loan));
    await tester.pumpAndSettle();
    expect(find.byType(LoanDetailsPage), findsOneWidget);
  });

  testWidgets('Test LoanDetailsPage Interest Credit with durationMonths 0', (WidgetTester tester) async {
    final loan = LoanModel(
      id: '2',
      borrowerName: 'Jane Doe',
      amount: 20000,
      interestRate: 2.0,
      progress: 0.2,
      startDate: DateTime(2026, 4, 20),
      durationMonths: 0, // Testing 0 duration
      type: 'interest_credit',
      status: 'active',
      mobile: '9908739956',
    );
    await tester.pumpWidget(buildTestWidget(loan));
    await tester.pumpAndSettle();
    expect(find.byType(LoanDetailsPage), findsOneWidget);
  });
}
