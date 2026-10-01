import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:khatha/features/auth/presentation/pages/otp_page.dart';
import 'package:khatha/core/blocs/auth/auth_cubit.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MockAuthCubit extends Mock implements AuthCubit {}

void main() {
  late MockAuthCubit mockAuthCubit;

  setUp(() {
    mockAuthCubit = MockAuthCubit();
    when(() => mockAuthCubit.state).thenReturn(AuthInitial());
    when(() => mockAuthCubit.stream).thenAnswer((_) => const Stream.empty());
  });

  Widget createWidgetUnderTest() {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (_, __) => MaterialApp(
        // Provide a root route so we can push and pop OtpPage naturally
        home: const Scaffold(body: Text('Home')),
        onGenerateRoute: (settings) {
          if (settings.name == '/otp') {
            return MaterialPageRoute(
              builder: (_) => BlocProvider<AuthCubit>.value(
                value: mockAuthCubit,
                child: const OtpPage(phone: '9876543210'),
              ),
            );
          }
          return null;
        },
      ),
    );
  }

  group('OtpPage Lifecycle Tests', () {
    testWidgets('Safe disposal during active resend timer', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Navigate to OTP page
      final BuildContext context = tester.element(find.byType(Scaffold));
      Navigator.pushNamed(context, '/otp');
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(OtpPage), findsOneWidget);

      // Navigate away/dispose the widget while the timer is still ticking
      final BuildContext otpContext = tester.element(find.byType(OtpPage));
      Navigator.pop(otpContext);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Ensure it's disposed
      expect(find.byType(OtpPage), findsNothing);

      // Advance time to allow any dangling timers to fire.
      await tester.pump(const Duration(seconds: 3));
      expect(true, isTrue);
    });

    testWidgets('Safe disposal during async verification', (
      WidgetTester tester,
    ) async {
      // Simulate verification in progress
      when(() => mockAuthCubit.state).thenReturn(OtpVerifying());

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Navigate to OTP page
      final BuildContext context = tester.element(find.byType(Scaffold));
      Navigator.pushNamed(context, '/otp');
      await tester.pump(); // start push
      await tester.pump(const Duration(seconds: 1)); // finish push
      expect(find.byType(OtpPage), findsOneWidget);

      // Navigate away/dispose the widget while async work is happening
      final BuildContext otpContext = tester.element(find.byType(OtpPage));
      Navigator.pop(otpContext);
      await tester.pump(); // start pop
      await tester.pump(const Duration(seconds: 1)); // finish pop

      // Ensure it's disposed
      expect(find.byType(OtpPage), findsNothing);
      expect(true, isTrue);
    });
  });
}
