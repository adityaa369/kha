import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:khatha/features/auth/presentation/pages/otp_page.dart';
import 'package:khatha/core/blocs/auth/auth_cubit.dart';

class MockAuthCubit extends Mock implements AuthCubit {}

void main() {
  late MockAuthCubit mockAuthCubit;

  setUp(() {
    mockAuthCubit = MockAuthCubit();
    when(() => mockAuthCubit.state).thenReturn(AuthInitial());
    when(() => mockAuthCubit.stream).thenAnswer((_) => const Stream.empty());
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: BlocProvider<AuthCubit>.value(
        value: mockAuthCubit,
        child: const OtpPage(phone: '9876543210'),
      ),
    );
  }

  group('OtpPage Lifecycle Tests', () {
    testWidgets('Safe disposal during active resend timer', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      
      // Timer starts on init. Verify the widget builds properly.
      expect(find.byType(OtpPage), findsOneWidget);
      
      // Navigate away/dispose the widget while the timer is still ticking
      await tester.pumpWidget(const SizedBox.shrink());
      
      // Advance time to allow any dangling timers to fire. If setState after dispose is called, this will throw.
      await tester.pump(const Duration(seconds: 3));
      
      // Should complete without error
      expect(true, isTrue);
    });
    
    testWidgets('Safe disposal during async verification', (WidgetTester tester) async {
      // Simulate verification in progress
      when(() => mockAuthCubit.state).thenReturn(OtpVerifying());
      
      await tester.pumpWidget(createWidgetUnderTest());
      
      // Dispose the widget
      await tester.pumpWidget(const SizedBox.shrink());
      
      // Ensure no exceptions occur when state changes
      await tester.pumpAndSettle();
      
      expect(true, isTrue);
    });
  });
}
