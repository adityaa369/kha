import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khatha/features/loans/presentation/pages/create_loan_page.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() {
  Widget buildTestWidget(String loanType) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          home: CreateLoanPage(loanType: loanType),
        );
      },
    );
  }

  testWidgets('Test CreateLoanPage Business Credit Layout', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestWidget('business_credit'));
    expect(find.byType(CreateLoanPage), findsOneWidget);
  });

  testWidgets('Test CreateLoanPage Interest Credit Layout', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestWidget('interest_credit'));
    expect(find.byType(CreateLoanPage), findsOneWidget);
  });

  testWidgets('Test CreateLoanPage Hand Credit Layout', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestWidget('hand_credit'));
    expect(find.byType(CreateLoanPage), findsOneWidget);
  });
}

